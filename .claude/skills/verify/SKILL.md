---
name: verify
description: Drive the clearhead CLI against a scratch workspace to verify core/CLI changes end-to-end
---

# Verifying clearhead changes

The surface for both `clearhead-core` and `clearhead-cli` changes is the CLI
binary. Build it from the working tree (the CLI depends on core by path):

```bash
cd clearhead-cli && cargo build --bin clearhead
# binary: clearhead-cli/target/debug/clearhead
```

The installed `~/.cargo/bin/clearhead` is the *previous* release — useful as
an old-vs-new comparison when the change alters observable behavior.

## Scratch workspace

Create one in the session scratchpad, never in a real workspace:

```bash
mkdir -p $SCRATCH/ws/.clearhead/charters
printf '[ ] task name #01951111-0000-7000-0000-000000000001\n' \
  > $SCRATCH/ws/.clearhead/charters/home.actions
cd $SCRATCH/ws   # the CLI resolves the workspace by cwd-walk
```

## Gotchas

- **`read actions` (no `--charter`) bypasses the workspace loader** — it lists
  files and parses each directly (`collect_all_actions`), touching no sidecars,
  no journal recovery, no load warnings. To exercise the load path use
  `read charters`, `read actions --charter <x>`, `query`, or `debug`.
- `clearhead debug` prints the resolved config and data root *and* runs a full
  workspace load — fastest way to see load warnings.
- Load warnings go to stderr; capture separately (`2>file`) when checking
  stdout purity for `--format json-ld` scripting.
- Useful fixtures: corrupt sidecar = `echo '{ bad' > .clearhead/charters/.home.json`;
  interrupted batch = write `.tmp.x` + a `.pending` file of
  `<tmp-abs-path>\t<final-abs-path>` lines in `charters/`.
