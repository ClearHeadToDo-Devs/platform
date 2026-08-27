# Current architecture

ClearHead is a local-first intention-management platform. Human-readable
workspace files are the durable source of truth. Calendar VTODO resources and
RDF datasets are standards-based projections rather than private authoritative
databases.

Structurizr relationships encode dependency awareness rather than event or data
flow: the source knows about or depends on the target. Runtime request/response
order is documented separately with Mermaid sequence diagrams.

The central implementation rule is **Core decides; adapters deliver**.
`clearhead_core` owns the domain model, pure algorithms, RDF projection, and the
host-neutral resource/effect protocol, but performs no filesystem or network
I/O. The native `clearhead-workspace-fs` adapter inventories files and executes
prepared effects with revision checks, locking, journaling, fsync, and atomic
rename. Both native hosts compose these same libraries:

- `clearhead` owns synchronous terminal workflows, durable mutations, calendar
  reconciliation, RDF export, and optional ephemeral SPARQL.
- `clearhead-lsp` owns open-document state and standard editor protocol
  providers. It does not depend on the CLI.
- `clearhead.nvim` owns Neovim orchestration and invokes the CLI when an editor
  workflow requires a durable mutation.

## Current constraints

- There is no graph daemon, persistent graph database, or ClearHead network
  service. RDF publication lives in Core, and SPARQL is optional and in-process.
- Objective files exist in the specifications and workspaces, but Objective
  integration into the loaded domain model is still pending.
- The native filesystem adapter is currently the only delivery adapter.
- Calendar networking remains external; tools such as vdirsyncer synchronize
  the plans vdir with CalDAV servers and clients.

The model describes implemented runtime boundaries, not the complete product
vision.
