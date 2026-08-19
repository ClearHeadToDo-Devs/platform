# Code Context

## Files Retrieved

### Platform composition, bootstrap, validation, and documentation

1. `.gitmodules` (lines 19-21) - graphd is a first-class platform submodule.
2. `scripts/startup` (lines 18-42) - initializes every submodule and installs `clearhead-graphd` alongside CLI/LSP.
3. `scripts/validate-pinned` (lines 7-18, 27-40, 48-64) - requires a clean/matching graphd gitlink, runs graphd's pre-push gate, and runs its spec-conformance test with `CLEARHEAD_SPEC_DIR`.
4. `README.md` (lines 18-32, 73-77) - user bootstrap promises graphd installation and describes graph queries as graphd-owned.
5. `.clearhead/config.json` (lines 1-8) - platform workspace discovery includes `../clearhead-graphd`.
6. `.cargo/config.toml` (lines 1-21) - comments include graphd in the local Cargo patch/dependency model; actual patch entries only target Core and tree-sitter-actions, so removing graphd needs no patch-table edit.

### CLI: hard runtime consumer and CI build dependency

7. `clearhead-cli/src/graph_backend.rs` (lines 1-64) - executable discovery via `CLEARHEAD_GRAPHD`, process invocation, stdin/stdout/error contract, and `export-jsonld` bridge.
2. `clearhead-cli/src/commands/query.rs` (lines 1-66) - `clearhead query` is an inherited-stdio facade over `graphd --workspace <dir> query ...`; exit status is propagated and `chain` adds a canonical-ID adapter.
3. `clearhead-cli/src/commands/action.rs` (lines 688-692), `src/commands/plan.rs` (lines 175-179), `src/commands/charter.rs` (lines 108-112) - CLI `--format jsonld` paths synchronously require graphd serialization.
4. `clearhead-cli/src/argparser.rs` (lines 186, 723-778) - public query command and mirrored graphd formats/parameters are exposed by CLI.
5. `clearhead-cli/.github/workflows/ci.yml` (lines 38-68) - CI independently checks out/builds graphd and injects its binary with `CLEARHEAD_GRAPHD` for the full CLI test suite.
6. `clearhead-cli/tests/common/mod.rs` (lines 111-117) - integration harness auto-selects the sibling graphd binary.
7. `clearhead-cli/tests/query_facade.rs` (lines 14-72, 78-125) - asserts byte-identical stdout, exit-code propagation, transact loop, and chain adapter; skips when graphd is absent.
8. `clearhead-cli/tests/query_to_transact.rs` (lines 18-78) - asserts graphd `--format ids` emits canonical IDs accepted verbatim by CLI mutation targets; skips if binary absent.
9. `clearhead-cli/README.md` (lines 5, 60-64), `docs/UI.md` (lines 22-55), `man/clearhead.1` (lines 199-200, 619-621, 803, 1096-1098) - installation/interface documentation explicitly directs graph work to graphd, although implementation currently also forwards `clearhead query`.

### Neovim: hard direct process consumer

16. `clearhead.nvim/lua/clearhead/config.lua` (lines 45-65, 104-116) - supports `CLEARHEAD_NVIM_GRAPHD_BINARY_PATH`; resolution order is explicit config, PATH, then `~/.cargo/bin/clearhead-graphd`.
2. `clearhead.nvim/lua/clearhead/query.lua` (lines 5-63, 66-85) - asynchronously invokes `graphd --workspace <cwd> query <family> [name] --format ...`; captures output/error and decodes JSON.
3. `clearhead.nvim/lua/clearhead/view.lua` (lines 12-28, 30-64) - consumes index rows (`id`, `name`, `status`, source locator, optional due date) for quickfix and mutation-by-ID.
4. `clearhead.nvim/lua/clearhead/tree_view.lua` (lines 5-48) - consumes nested tree nodes (`id`, `kind`, `name`, `status`, `priority`, `children`).
5. `clearhead.nvim/README.md` (lines 10, 58, 127), `doc/clearhead.txt` (lines 53, 108, 144, 158-159, 711-725, 991-1025) - graphd is documented as a prerequisite and its tree/index/DOT contracts are public plugin behavior.
6. `clearhead.nvim/tests/living_loop_spec.lua` (lines 10-11) - end-to-end coverage becomes pending rather than failing when graphd is unavailable.

### Specifications/output contract

22. `specifications/schemas/index_query_result.schema.json` (lines 1-83) - pins ordered JSON array wire shape, canonical `urn:uuid` IDs, status enum, source locators, optional priority/parent/date fields, and rejects additional properties.
2. `specifications/CHANGELOG.md` (lines 7-11) - says query-output authority moved to graphd because it is the sole producer.
3. `specifications/explanations/data_workflows.md` (lines 8, 49-52) - documents CLI forwarding as a pure projection with identical stdout and status.
4. `specifications/ontology.md` (lines 66-111, 146-156) - normative RDF runtime/SPARQL conventions and warns ontology/query predicate drift produces successful but silently empty results.

### Core and other submodules

26. `clearhead-core/src/lib.rs` (lines 7-36), `src/config/loader.rs` (lines 1-6), `src/workspace/store/load.rs` (lines 595 onward) - Core deliberately supplies graph-neutral domain/workspace/config substrate consumed by graphd; hydrated recurrence lineage exists partly to preserve graph edges.
2. `clearhead-core/docs/ARCHITECTURE.md` (lines 1-14) - analytics tools are expected to read workspace files through shared Core behavior.
3. `clearhead-lsp/` - tracked-source search found no graphd invocation, environment variable, package, query, or CI dependency.
4. `ontology/` - tracked-source search found no graphd invocation, environment variable, package, or CI dependency; its SPARQL/ontology semantics remain an implementation dependency for any replacement.
5. `tree-sitter-actions/` - tracked-source search found no graphd consumer/dependency reference.

## Key Code

### CLI has two distinct hard dependencies

```rust
// clearhead-cli/src/graph_backend.rs:10-16
const GRAPHD_ENV: &str = "CLEARHEAD_GRAPHD";
pub fn graphd_command() -> Command {
    let executable = std::env::var_os(GRAPHD_ENV)
        .unwrap_or_else(|| "clearhead-graphd".into());
    Command::new(executable)
}
```

1. **Query facade:** inherited stdio and exact exit status (`commands/query.rs:40-55`).
2. **JSON-LD serializer:** sends serialized `DomainModel` bytes to `export-jsonld` stdin, requires successful exit and UTF-8 stdout (`graph_backend.rs:19-64`). This affects otherwise non-query CLI reads when `--format jsonld` is selected.

### Neovim invocation and output matrix

`clearhead.nvim/lua/clearhead/query.lua:17-23,66-85` builds:

- index: `clearhead-graphd --workspace <cwd> query index <name> --format jsonld`, expects decoded document and uses `@graph` when present.
- tree: `... query tree <name> --format json`, expects nested arrays/nodes.
- graph: `... query graph <name> --format dot`, expects raw DOT text.

The index consumer then relies on exact row identity/source fields to navigate and send `row.id` to CLI mutations (`view.lua:12-28`).

### Pinned schema is narrower than all live contracts

`specifications/schemas/index_query_result.schema.json:1-83` proves only index-family `--format json` rows. Neovim asks for index **JSON-LD**, CLI also consumes `export-jsonld`, and tree/DOT/raw/query-facade semantics live in graphd docs/tests rather than this shared schema. A replacement cannot claim compatibility from the shared schema test alone.

## Architecture

- Platform pins graphd as a gitlink, installs it as a user-facing binary, and treats its repository gate plus producer-schema conformance as part of the exact platform validation composition.
- Core owns workspace discovery, configuration, domain loading, and hydrated semantic fields. Graphd consumes Core and projects RDF/SPARQL/JSON-LD; it is not merely a daemon packaging layer.
- CLI invokes graphd out of process for both its public `query` facade and JSON-LD output on action/plan/charter reads. Query forwarding deliberately preserves graphd rendering, terminal detection, bytes, stderr, and exit behavior.
- Neovim bypasses CLI for reads. It directly composes graphd index/tree/graph families into quickfix, nested work-map, and Graphviz views, while using CLI separately for mutation.
- Specifications pin the index JSON row shape and ontology semantics. LSP, ontology, and parser have no direct process/build dependency, but ontology identifiers and Core model semantics constrain any replacement.

## Concrete migration risks

1. **Deleting only the gitlink breaks bootstrap and validation.** Update `.gitmodules`, staged gitlink, `scripts/startup`, `scripts/validate-pinned`, `.clearhead/config.json`, README repository list/text, and Cargo comments together.
2. **CLI will regress beyond `clearhead query`.** `action/plan/charter --format jsonld` depend on `export-jsonld`; a replacement must move serialization in-process or preserve the stdin DomainModel → UTF-8 JSON-LD process contract.
3. **Facade compatibility is byte/process sensitive.** Existing tests require unmodified stdout and exit code; inherited stdio also controls terminal-vs-pipe rendering. Capturing/re-rendering output is not equivalent.
4. **Mirrored command surface can drift.** CLI owns mirrored formats (`table,json,ndjson,jsonld,ids,turtle,dot`), query families/parameters, and fuzzy chain→canonical IRI adaptation. Retiring graphd requires either removing this public CLI surface or assigning a new owner.
5. **Neovim has three separate contracts.** Preserve JSON-LD `@graph` index framing plus row locators/IDs, nested JSON tree shape, and valid raw DOT. Replacing only index queries leaves tree/graph views broken.
6. **Binary discovery/config migration is user-visible.** Preserve or explicitly migrate `CLEARHEAD_GRAPHD`, `CLEARHEAD_NVIM_GRAPHD_BINARY_PATH`, setup key `nvim_graphd_binary_path`, PATH behavior, health checks, docs, and error strings.
7. **Current integration tests can hide absence.** CLI and Neovim end-to-end tests skip/pending when graphd is missing. Removal could look green unless tests are rewritten to require the replacement.
8. **Schema proof is incomplete.** Platform conformance covers graphd index JSON, not Neovim's index JSON-LD, tree JSON, DOT, raw/named query behavior, terminal rendering, or CLI export JSON-LD.
9. **Ontology drift can fail silently.** `specifications/ontology.md:146-156` explicitly notes changed CCO predicates can yield successful empty results; replacement queries need non-empty fixture smoke tests.
10. **Historical/docs contradictions need cleanup.** CLI README/UI say it does not proxy graphd while `commands/query.rs` does; migration should settle the intended ownership rather than mechanically rename references.
11. **Packaging independence changes.** Startup currently installs three binaries; CLI CI separately clones/builds graphd. If graph capability moves into CLI/Core, dependency-feature closure and the prior graphd no-Topiary/no-Tokio boundary need deliberate reassessment.
12. **Core semantic behavior must survive.** Recurrence hydration and source-location/canonical-ID semantics currently feed graph projection and mutation handoff; do not replace graph loading with a second workspace parser.

## Proving Commands

Run from `/home/dab/Products/platform` before removal to capture baseline, then against the replacement:

```sh
# Complete tracked consumer inventory (each submodule is a separate Git repo)
git grep -n -i -E 'clearhead[-_]graphd|CLEARHEAD_GRAPHD|graphd' -- ':!clearhead-graphd' ':!.clearhead/archive/**'
git submodule foreach --recursive 'git grep -n -i -E "clearhead[-_]graphd|CLEARHEAD_GRAPHD|graphd" -- . ":(exclude).clearhead/archive/**" || true'

# Pin/composition and all repository gates
scripts/validate-pinned

# CLI facade, ID handoff, and JSON-LD-related full tests
cargo build --manifest-path clearhead-graphd/Cargo.toml --locked
CLEARHEAD_GRAPHD="$PWD/clearhead-graphd/target/debug/clearhead-graphd" \
  cargo test --manifest-path clearhead-cli/Cargo.toml --locked

# Explicit producer contract
CLEARHEAD_SPEC_DIR="$PWD/specifications" \
  cargo test --manifest-path clearhead-graphd/Cargo.toml \
  --features spec-conformance --test spec_conformance

# Process-level byte/status equivalence baseline
ws="$PWD"
clearhead-graphd --workspace "$ws" query index default --format jsonld > /tmp/direct.out
clearhead --workspace "$ws" query index default --format jsonld > /tmp/facade.out
cmp /tmp/direct.out /tmp/facade.out

# Machine contracts used by clients
clearhead-graphd --workspace "$ws" query index default --format jsonld | jq -e '(."@graph" // .) | type == "array"'
clearhead-graphd --workspace "$ws" query tree work-map --format json | jq -e 'type == "array"'
clearhead-graphd --workspace "$ws" query graph dependencies --format dot | dot -Tsvg >/dev/null
clearhead-graphd --workspace "$ws" query index default --format ids | while IFS= read -r id; do
  printf '%s\n' "$id" | grep -Eq '^urn:uuid:[0-9a-f-]{36}$' || exit 1
done

# Neovim repository gate/living-loop (ensure binaries are on PATH so it does not mark pending)
PATH="$PWD/clearhead-cli/target/debug:$PWD/clearhead-graphd/target/debug:$PATH" \
  "$PWD/clearhead.nvim/.githooks/pre-push" </dev/null

# Verify retirement leaves no active references (exclude history/archive intentionally)
git grep -n -i -E 'clearhead[-_]graphd|CLEARHEAD_GRAPHD|graphd' -- ':!.clearhead/archive/**' || true
git submodule foreach --recursive 'git grep -n -i -E "clearhead[-_]graphd|CLEARHEAD_GRAPHD|graphd" -- . ":(exclude).clearhead/archive/**" || true'
```

## Start Here

Open `clearhead-cli/src/graph_backend.rs` first. It reveals the easily missed fact that graphd retirement affects not only query forwarding but also CLI JSON-LD reads. Then inspect `clearhead.nvim/lua/clearhead/query.lua` for the three direct client wire contracts before deciding where graph/RDF ownership moves.
