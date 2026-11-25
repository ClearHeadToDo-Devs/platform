---
id: 01a0dcfd-f33a-731b-9fa7-94bdafc8bc4f
alias: root-next-default
parent: platform
state: Active
---
# Root Next Default

The unified-workspace-root charter made `charters/next.actions` the root's action anchor but left the default capture target at `inbox.actions`. The spec (`workspace.md`, `configuration.md`), the CLI's `default_file`, and the nvim plugin all still point at the inbox, so capture lands in a legacy child charter instead of the root.

## Decision (2026-09-26)

The root action file is `next.actions`, and it is also the default capture target. One rule replaces the old question of whether something goes in the inbox or in next. `inbox.actions` stops being special: where it still exists it is an ordinary child charter. If triage ever needs a signal again, a tag carries it, not a separate file.

Considered and rejected: keeping the inbox as a distinct unprocessed queue. It preserves a triage signal, but in real use the inbox was simply the top-level list, so the extra file was ceremony.

## Done when

- The spec names the root `next.actions` as the default target, and says `default_file` resolves relative to `charters/` (the CLI's behavior; the spec's "relative to data_dir" was also drift).
- The CLI and nvim defaults agree with the spec, with tests.
- The user workspace is migrated with identity preserved: `inbox.*` becomes the root anchors, and `plans/inbox/` becomes `plans/next/`.
- The paused calendar sync on the homelab resumes against the migrated layout.
