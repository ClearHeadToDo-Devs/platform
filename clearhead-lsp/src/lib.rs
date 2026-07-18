//! Standalone ClearHead Language Server Protocol runtime.
//!
//! Protocol providers are being migrated from `clearhead-cli`. This scaffold
//! establishes the final process and dependency boundary: standard LSP over
//! stdio, editor document state here, and domain parsing in `clearhead-core`.

use clearhead_core::ParsedDocument;
use dashmap::DashMap;
use tower_lsp_server::ls_types::*;
use tower_lsp_server::{Client, LanguageServer, LspService, Server};
use tracing::{debug, error};
use tree_sitter::{Parser, Tree};

#[derive(Debug)]
struct DocumentState {
    text: String,
    tree: Tree,
    parsed: Option<ParsedDocument>,
}

#[derive(Debug)]
struct Backend {
    client: Client,
    documents: DashMap<Uri, DocumentState>,
}

impl Backend {
    fn parser() -> Parser {
        let mut parser = Parser::new();
        parser
            .set_language(&tree_sitter_actions::LANGUAGE.into())
            .expect("actions grammar must be loadable");
        parser
    }

    async fn update_document(&self, uri: Uri, text: String) {
        let mut parser = Self::parser();
        let Some(tree) = parser.parse(&text, None) else {
            error!(?uri, "failed to parse document tree");
            return;
        };
        let parsed = clearhead_core::parse_document(&text).ok();
        debug!(?uri, parsed = parsed.is_some(), "document updated");
        self.documents
            .insert(uri.clone(), DocumentState { text, tree, parsed });
        self.client.publish_diagnostics(uri, Vec::new(), None).await;
    }
}

impl LanguageServer for Backend {
    async fn initialize(
        &self,
        _params: InitializeParams,
    ) -> tower_lsp_server::jsonrpc::Result<InitializeResult> {
        Ok(InitializeResult {
            server_info: Some(ServerInfo {
                name: "clearhead-lsp".to_string(),
                version: Some(env!("CARGO_PKG_VERSION").to_string()),
            }),
            capabilities: ServerCapabilities {
                text_document_sync: Some(TextDocumentSyncCapability::Kind(
                    TextDocumentSyncKind::FULL,
                )),
                ..Default::default()
            },
            ..Default::default()
        })
    }

    async fn shutdown(&self) -> tower_lsp_server::jsonrpc::Result<()> {
        Ok(())
    }

    async fn did_open(&self, params: DidOpenTextDocumentParams) {
        self.update_document(params.text_document.uri, params.text_document.text)
            .await;
    }

    async fn did_change(&self, params: DidChangeTextDocumentParams) {
        if let Some(change) = params.content_changes.into_iter().next() {
            self.update_document(params.text_document.uri, change.text)
                .await;
        }
    }

    async fn did_save(&self, params: DidSaveTextDocumentParams) {
        if let Some(document) = self.documents.get(&params.text_document.uri) {
            debug!(
                uri = ?params.text_document.uri,
                bytes = document.text.len(),
                syntax_bytes = document.tree.root_node().end_byte(),
                actions = document.parsed.as_ref().map_or(0, |parsed| parsed.actions.len()),
                "document saved"
            );
        }
    }
}

/// Run the canonical stdio language-server process until the client exits.
pub async fn serve_stdio() {
    let stdin = tokio::io::stdin();
    let stdout = tokio::io::stdout();
    let (service, socket) = LspService::new(|client| Backend {
        client,
        documents: DashMap::new(),
    });
    Server::new(stdin, stdout, socket).serve(service).await;
}

#[cfg(test)]
mod tests {
    use super::*;

    fn service() -> LspService<Backend> {
        LspService::new(|client| Backend {
            client,
            documents: DashMap::new(),
        })
        .0
    }

    #[tokio::test]
    async fn initialize_advertises_standalone_identity_and_full_sync() {
        let service = service();
        let initialized = service
            .inner()
            .initialize(InitializeParams::default())
            .await
            .unwrap();

        assert_eq!(initialized.server_info.unwrap().name, "clearhead-lsp");
        assert_eq!(
            initialized.capabilities.text_document_sync,
            Some(TextDocumentSyncCapability::Kind(TextDocumentSyncKind::FULL))
        );
    }

    #[tokio::test]
    async fn open_and_change_are_owned_by_the_new_runtime() {
        let service = service();
        let backend = service.inner();
        let uri = Uri::from_file_path("/tmp/scaffold.actions").unwrap();

        backend
            .did_open(DidOpenTextDocumentParams {
                text_document: TextDocumentItem {
                    uri: uri.clone(),
                    language_id: "actions".to_string(),
                    version: 1,
                    text: "[ ] First".to_string(),
                },
            })
            .await;
        backend
            .did_change(DidChangeTextDocumentParams {
                text_document: VersionedTextDocumentIdentifier {
                    uri: uri.clone(),
                    version: 2,
                },
                content_changes: vec![TextDocumentContentChangeEvent {
                    range: None,
                    range_length: None,
                    text: "[ ] First\n[ ] Second".to_string(),
                }],
            })
            .await;

        let document = backend.documents.get(&uri).unwrap();
        assert_eq!(document.text, "[ ] First\n[ ] Second");
        assert!(document.tree.root_node().end_byte() > 0);
        assert_eq!(document.parsed.as_ref().unwrap().actions.len(), 2);
    }
}
