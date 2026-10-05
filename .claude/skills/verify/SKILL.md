---
name: verify
description: Drive the clearhead CLI against a scratch workspace to verify core/CLI changes end-to-end
---

# Verifying clearhead changes

The surface for both `clearhead-core` and `clearhead-cli` changes is the CLI binary. Both crates live in the `clearhead-core/` cargo workspace (`crates/clearhead-core`, `crates/clearhead-cli`); build from there (the CLI depends on core by path):

```bash
cd clearhead-core && cargo build --bin clearhead
# binary: clearhead-core/target/debug/clearhead
```

File verbs take a `file` subcommand: `clearhead format file <path>`, `clearhead lint file <path>`.

The installed `~/.cargo/bin/clearhead` is the *previous* release — useful as an old-vs-new comparison when the change alters observable behavior.

## Scratch workspace

Create one in the session scratchpad, never in a real workspace:

```bash
mkdir -p $SCRATCH/ws/.clearhead/charters
printf '[ ] task name #01951111-0000-7000-0000-000000000001\n' \
  > $SCRATCH/ws/.clearhead/charters/home.actions
cd $SCRATCH/ws   # the CLI resolves the workspace by cwd-walk
```

## Gotchas

- **Loads print at most one stderr line**, and only when the workspace has violations; warnings appear only in `clearhead doctor`, which is where to see every finding. A read naming a quarantined target (`read actions --file`/`--charter`) exits 1 with the reason. Fixtures: a malformed `.actions` file or a corrupt sidecar each give one violation.
- `clearhead debug` prints the resolved config and data root *and* runs a full workspace load.
- Capture stderr separately (`2>file`) when checking stdout purity. In this shell (zsh), an unquoted `$cmd` is not word-split: loop over commands with `eval`.
- Useful fixtures: corrupt sidecar = `echo '{ bad' > .clearhead/charters/.home.json`; interrupted batch = write `.tmp.x` + a `.pending` file of `<tmp-abs-path>\t<final-abs-path>` lines in `charters/`.
