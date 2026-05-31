---
id: 019e7d01-0ad0-7810-8b02-738d577996e8
alias: workspace-identity
parent: platform-model
state: Active
---
# Workspace Identity

Workspaces need durable identifiers. A path is how you find a workspace on disk — it is not what the workspace is. Paths and display names are ephemeral: directories get moved, projects get renamed. This causes the same class of bugs that led us to UUIDs on Charters and Actions.

## Design Decisions

**Workspace identity lives in the existing workspace config, under a `[workspace]` group.**
No new file is introduced. The config already exists at `.clearhead/config.toml` and is the right home for workspace-level properties. Identity fields are just another group within it, populated by `clearhead init`.

```toml
[workspace]
id = "019e7d01-..."
name = "platform"
created_at = "2026-05-31"
```

**`WorkspaceConfig` gains a `workspace` sub-struct for identity.**
`workspace: Option<WorkspaceIdentity>` where `WorkspaceIdentity { id: Uuid, name: Option<String>, created_at: Option<Date> }`. If absent, fall back to a deterministic UUIDv5 derived from the root path — graceful degradation, no hard failure.

**`clearhead init` populates the identity section.**
Creates `.clearhead/config.toml` (and `.clearhead/` if absent), generates a UUIDv7, and optionally prompts for a display name. Idempotent — running again on an existing workspace is a no-op unless `--force` is passed.

**The `Workspace` struct carries `id` and `name` as first-class fields.**
Loaded from `WorkspaceConfig.workspace`, falling back to the deterministic UUID. The path remains the HashMap key for filesystem operations only.

**The workspace vocabulary gains a `Workspace` class and `inWorkspace` property.**
`clearhead-ws:Workspace` is an OWL class. `clearhead-ws:inWorkspace` links an Action to its workspace IRI (`clearhead-ws:workspace/<uuid>`). Workspace provenance becomes queryable in SPARQL across multi-workspace loads.
