# ClearHead runtime workflows

These Mermaid sequence diagrams describe **event order and information flow**.
They intentionally complement rather than duplicate the
[Structurizr model](../structurizr/README.md): Structurizr arrows mean that the
source is architecturally aware of or depends on the target; arrows here mean
that an interaction happens next and may include responses.

## Edit an action in an LSP client

Neovim is the first-party experience, but the server is not aware of Neovim.
It implements standard LSP for whichever compatible client starts it.

```mermaid
sequenceDiagram
    actor Person
    participant Editor as Neovim / LSP client
    participant Plugin as clearhead.nvim
    participant LSP as clearhead-lsp
    participant Core as clearhead_core
    participant Parser as tree-sitter-actions

    Person->>Editor: Edit an .actions buffer
    opt First-party Neovim integration
        Plugin->>LSP: Start server over stdio
    end
    Editor->>LSP: didOpen / didChange
    LSP->>Parser: Update tolerant syntax tree
    LSP->>Core: Parse and compute editor semantics
    Core-->>LSP: Parsed document and provider results
    LSP-->>Editor: Diagnostics, tokens, completion, etc.
    Person->>Editor: Save buffer
    Editor->>LSP: didSave
```

## Deliver a durable mutation

This is the central **Core decides; adapters deliver** round trip.

```mermaid
sequenceDiagram
    actor Caller as Person / editor adapter / agent
    participant CLI as clearhead CLI
    participant FS as clearhead-workspace-fs
    participant Store as Workspace files
    participant Core as clearhead_core

    Caller->>CLI: Request mutation
    CLI->>FS: Invoke native workspace operation
    FS->>FS: Acquire lock and recover pending journal
    FS->>Store: Inventory and read bytes
    Store-->>FS: Current resources
    FS->>Core: Supply snapshots and expected revisions
    Core->>Core: Parse, validate, and decide next state
    Core-->>FS: PreparedMutation + EffectBatch
    FS->>Store: Recheck resource preconditions
    alt Revisions still match
        FS->>Store: Journal and atomically deliver effects
        Store-->>FS: Delivery succeeded
        FS->>Core: Adopt prepared outcome
        Core-->>FS: Committed outcome
        FS-->>CLI: Mutation result
        CLI-->>Caller: Success
    else Concurrent change or delivery failure
        FS-->>CLI: Conflict or delivery error
        CLI-->>Caller: Failure — speculative state discarded
    end
```

## Synchronize calendar projections

ClearHead and the CalDAV client are not mutually aware. They coordinate through
a standard VTODO vdir and external synchronization tooling.

```mermaid
sequenceDiagram
    participant Client as Calendar/task client
    participant Server as CalDAV server
    participant Sync as vdirsyncer or equivalent
    participant Vdir as Plans VTODO vdir
    participant CLI as clearhead CLI
    participant Core as clearhead_core
    participant Workspace as Plaintext workspace

    Client->>Server: Create or change a VTODO
    Sync->>Server: Synchronize CalDAV collection
    Server-->>Sync: Changed VTODO resources
    Sync->>Vdir: Update filesystem vdir
    CLI->>Vdir: Observe VTODO resources
    CLI->>Workspace: Read authoritative workspace facts
    CLI->>Core: Supply both observations
    Core->>Core: Reconcile fields and occurrence state
    Core-->>CLI: Prepared workspace/vdir effects
    CLI->>Workspace: Durably deliver accepted plaintext effects
    CLI->>Vdir: Durably deliver accepted VTODO effects
    Sync->>Server: Synchronize resulting VTODO changes
    Server-->>Client: Standard CalDAV propagation
```

## Publish and query RDF

RDF is a deterministic, replaceable projection. Neither the RDF dataset nor the
optional in-memory query engine becomes authoritative.

```mermaid
sequenceDiagram
    actor Caller as Person / agent
    participant CLI as clearhead CLI
    participant FS as clearhead-workspace-fs
    participant Workspace as Plaintext workspace
    participant Core as clearhead_core
    participant RDF as Core RDF projection
    participant Query as Optional in-memory SPARQL
    participant Consumer as External RDF tooling

    Caller->>CLI: Request export or query
    CLI->>FS: Load workspace snapshot
    FS->>Workspace: Read authoritative resources
    Workspace-->>FS: Plaintext bytes and metadata
    FS->>Core: Supply immutable snapshots
    Core-->>CLI: DomainModel
    CLI->>RDF: Project canonical dataset
    RDF-->>CLI: Deterministic quads
    alt Export
        CLI-->>Consumer: TriG, N-Quads, JSON-LD, or graph RDF
    else Local query
        CLI->>Query: Load ephemeral dataset and execute SPARQL
        Query-->>CLI: Standard SPARQL results or RDF
        CLI-->>Caller: Query result
    end
```
