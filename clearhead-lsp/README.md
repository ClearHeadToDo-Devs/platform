# clearhead-lsp

Standalone Language Server Protocol runtime for ClearHead.

The server speaks standard LSP JSON-RPC over stdio:

```sh
clearhead-lsp
```

`clearhead-lsp` owns the asynchronous editor runtime and depends directly on
`clearhead-core` for parsing and domain/workspace behavior. It does not depend
on `clearhead-cli`.

This crate is currently the extraction target for the LSP implementation still
shipped by `clearhead-cli`. The scaffold owns Tokio, Tower LSP, DashMap,
tree-sitter document state, and stdio startup; protocol providers and their
tests move here in the next migration slice.

## Development

Sibling checkouts are used for path development:

```sh
cargo test --manifest-path clearhead-lsp/Cargo.toml
```
