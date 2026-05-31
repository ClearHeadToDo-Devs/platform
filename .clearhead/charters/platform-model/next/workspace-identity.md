---
id: 019e7d01-0ad0-7810-8b02-738d577996e8
alias: workspace-identity
parent: platform-model
state: Active
---
# Workspace Identity

Workspaces need durable identifiers. A path is how you find a workspace on disk — it is not what the workspace is. Paths change; UUIDs do not.

`workspace_id` and `workspace_name` already exist as flat fields in `.clearhead/config.json` and `WorkspaceConfig`. The spec documents the named graph URI pattern `urn:clearhead:workspace:<uuid>`. The identity story is largely correct — what is missing is the `Workspace` struct threading these fields through as first-class properties, and a `created_at` field to complete the identity record.

## Design Decisions

**Identity lives in `.clearhead/config.json` as flat fields.**
`workspace_id`, `workspace_name`, and `created_at` at the top level alongside other workspace-level config overrides. No sub-grouping needed — the field names are already self-descriptive.

```json
{
  "workspace_id": "019e43e4-...",
  "workspace_name": "platform",
  "created_at": "2026-05-31",
  "additional_workspaces": [...]
}
```

**`WorkspaceConfig` already has `workspace_id` and `workspace_name`.**
Add `created_at: Option<String>`. No structural change needed.

**The `Workspace` struct carries `id` and `name` from `WorkspaceConfig`.**
Loaded by the CLI and passed into core. Falls back to a deterministic UUIDv5 from the root path for workspaces without an explicit ID. The path remains the `Workspaces` HashMap key for filesystem operations only.

**`clearhead init` populates the identity fields.**
Generates a UUIDv7, infers `workspace_name` from the project directory, writes `created_at`. Idempotent — rerunning is a no-op unless `--force` is passed.

**Named graph URI is `urn:clearhead:workspace:<uuid>`.**
Already specified in workspace.md. Workspace vocabulary will add a `clearhead-ws:Workspace` class and `clearhead-ws:inWorkspace` property once the `Workspace` struct carries the ID.
