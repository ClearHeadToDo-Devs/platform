# The ClearHead Platform

This is my attempt to create a free, open personal data platform that is:

- local-first, relying on local storage and computation where possible
- human-centric, which is why the authoritative workspace remains human-readable plaintext: `.actions`, charter Markdown, and their explicit metadata
- FAIR data: meaning this data is Findable, Accessible, Interoperable, and Reusable
- Ontologically grounded, meaning that data is structured according to well-defined ontologies to ensure semantic clarity and interoperability

## Context

This is my attempt at a higher-order repository, or in other words, a repository meant to maintain other repositories.

As the clearhead platform grows, I find myself wanting to separate out orthogonal concerns into their own repositories.

On the one hand, these are different tools with their own toolschains and lifecycles. On the other hand, as a platform, they are deeply coupled and a change in one repository often cascades into changes in other repositories.

### Getting Started

With Git and Rust installed, bootstrap a checkout from the repository root:

```sh
scripts/startup
```

The script initializes the pinned submodules, then builds and installs the main user-facing Rust binaries: `clearhead` and `clearhead-lsp`. It is safe to rerun after pulling platform changes; Cargo rebuilds and replaces the installed binaries. Cargo's bin directory (normally `~/.cargo/bin`) must be on `PATH`.

To validate the exact submodule revisions pinned by the platform, run:

```sh
scripts/validate-pinned
```

The command first rejects uninitialized, dirty, or gitlink-mismatched submodules, then runs each repository's own pre-push gate. It deliberately adds no second test framework; `specifications` currently has no executable repository gate.

### Working with Submodules

Git submodules are notoriously tricky to work with, so we have laid out documentation in [Submodules](./SUBMODULES.md) to help you get started. including:

- Day-to-day workflows
- Cloning the repository
- Updating submodules

### Working with Git Worktrees

For branch-per-task development (including multiple parallel agent branches), see [Worktrees](./WORKTREES.md).

### Architecture

Documentation has one owner per question:

- [Specifications](./specifications/README.md) define normative, implementation-independent behavior.
- The [Structurizr workspace](./structurizr/README.md) records current platform structure and dependency awareness.
- [Workflow diagrams](./docs/workflows.md) record runtime event order and information flow.
- [`clearhead_core` architecture](./clearhead-core/docs/ARCHITECTURE.md) describes only Core's internal boundary and organization.
- [Decisions](./DECISIONS.md) preserve rationale, rejected alternatives, and supersession history.

Clickable source entries in Structurizr are reading starting points, not a second exhaustive source map.

### Tracking Decisions

we maintain the [DECISIONS.md](./DECISIONS.md) file to track important architectural and design decisions made throughout the development of the platform. This helps provide context and reasoning behind certain choices, making it easier for contributors to understand the project's evolution.

## Index of Repositories

Please review product-specific documentation for more details on each repository

- [Specifications](./specifications/README.md): The normative platform contracts, written in human-readable formats such as Markdown, examples, and data schemas
  - all downstream dependencies rely on this repository, but usually not directly, we vendor examples so that downstream repositories can be more self-contained, and where possible the products may simply conform to the specifications without needing to reference them directly
- [Ontology](./ontology/README.md): The ontologies that provide the semantic backbone for the platform, ensuring that data is structured and interpreted consistently across different tools and repositories
  - Aligned with the CCO ontology, which itself is a BFO-aligned ontology format.
  - Creates the semantic backbone that enables interoperability and data integration across the platform
  - tools like the CLI use it to do semantic reasoning and validation on the data ingested
- [Action File Parser](./tree-sitter-actions/README.md) a parser for the action file format, built using tree-sitter
  - used by the CLI and other tools to parse and validate action files
- [Core Library](./clearhead-core/README.md) the pure Rust domain library at the heart of the platform: it owns the model and the algorithms and *decides* mutations, but performs no I/O
  - shared by every downstream host (CLI, LSP, and any future native or WebAssembly client) so they agree on one domain model without coordinating implementations
  - reading and durably writing files is delegated to a delivery adapter (below), which is what keeps Core portable
- [Workspace FS Adapter](./clearhead-core/crates/clearhead-workspace-fs/README.md) the native filesystem delivery adapter — the I/O half of the seam
  - turns Core's logical decisions into durable filesystem reads and writes (locking, journaling, atomic rename, calendar sync)
  - the CLI and LSP compose it with clearhead-core; a non-filesystem host would supply its own adapter instead
- [CLI](./clearhead-core/crates/clearhead-cli/README.md) the synchronous command client for the specifications outlined
  - handles terminal workflows and durable workspace mutations through clearhead-core
  - evaluates SPARQL and the saved query families in-process (default `sparql` feature)
  - parses action files with the above tree-sitter parser
- [LSP](./clearhead-core/crates/clearhead-lsp/README.md) the standalone editor protocol runtime
  - owns Tokio, Tower LSP, open-document state, diagnostics, providers, and stdio lifecycle
  - depends directly on clearhead-core rather than the CLI
- [Neovim App](./clearhead.nvim/README.md) a neovim plugin that uses the CLI for mutations and clearhead-lsp for editor analysis
  - provides syntax highlighting, linting, and validation for action files within neovim
  - launches `clearhead-lsp` directly for real-time feedback and assistance
  - also leverages the tree-sitter parser for accurate syntax parsing, folding, and highlighting
