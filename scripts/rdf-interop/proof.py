#!/usr/bin/env python3
"""external-rdf-proof: prove ClearHead's RDF publication is engine-independent.

The `rdf-publication` charter's thesis is that ClearHead publishes *standard*
RDF and *standard* SPARQL — the query layer happens to embed Oxigraph, but the
data and the saved queries are supposed to run unchanged in any conformant
engine. A `cargo test` cannot prove that: it would be Oxigraph validating
Oxigraph. So this runs the real `clearhead` binary to export a committed
fixture workspace, loads the dataset into **rdflib** (a wholly independent,
pure-Python SPARQL implementation), and runs the CLI's own saved `.sparql`
files *unchanged*, asserting the representative facts survive the round trip.

It is wired into `scripts/validate-pinned`, not `cargo test`: the everyday Rust
loop stays engine-free, and only the platform composition gate pays for the
independent engine. Run it with rdflib from uv, naming the binary under test by
an absolute path (validate-pinned passes the one it built from the pinned
revisions):

    CLEARHEAD_BIN=$PWD/clearhead-core/target/debug/clearhead \
        uv run --with rdflib python scripts/rdf-interop/proof.py
"""

from __future__ import annotations

import os
import subprocess
import sys
import tempfile
from pathlib import Path

import rdflib  # pyright: ignore[reportMissingImports] -- supplied by uv

SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[1]
FIXTURE_DATA = SCRIPT_DIR / "fixture" / "data"
QUERIES = REPO_ROOT / "clearhead-core" / "crates" / "clearhead-cli" / "src" / "queries"

# The fixture's stable identity (see fixture/data/clearhead/workspace.json).
WS_ID = "00000000-0000-0000-0000-0000000000aa"
WS_GRAPH = f"urn:clearhead:workspace:{WS_ID}"

# Canonical identities the fixture pins, so a row id drives the CLI verbs.
ID_ALPHA = "urn:uuid:019f733d-4600-7000-8000-000000000001"
ID_STEP_TWO = "urn:uuid:019f733d-4600-7000-8000-000000000012"


def clearhead_binary() -> str:
    """The binary under test, named by CLEARHEAD_BIN. No PATH lookup: an
    installed `clearhead` was built from some other revision."""
    named = os.environ.get("CLEARHEAD_BIN")
    if not named or not Path(named).is_file():
        sys.exit("proof: set CLEARHEAD_BIN to the clearhead binary under test")
    return named


def export_dataset() -> str:
    """Run the real binary over the fixture, isolated from any real workspace."""
    with tempfile.TemporaryDirectory() as tmp:
        # A cwd with no `.clearhead` ancestor forces XDG resolution onto the
        # fixture alone; an empty config dir means no additional workspaces.
        env = {
            **os.environ,
            "XDG_DATA_HOME": str(FIXTURE_DATA),
            "XDG_CONFIG_HOME": str(Path(tmp) / "config"),
            "XDG_STATE_HOME": str(Path(tmp) / "state"),
        }
        result = subprocess.run(
            [clearhead_binary(), "export", "workspace", "--format", "trig"],
            cwd=tmp,
            env=env,
            capture_output=True,
            text=True,
        )
    if result.returncode != 0:
        sys.exit(f"proof: export failed:\n{result.stderr}")
    return result.stdout


def rows(dataset: rdflib.Dataset, name: str) -> list[dict[str, str]]:
    """Run a saved `.sparql` file unchanged; return rows as {var: lexical}."""
    query = (QUERIES / f"{name}.sparql").read_text()
    return [
        {str(var): str(val) for var, val in row.asdict().items()}
        for row in dataset.query(query)
    ]


def names(result: list[dict[str, str]]) -> set[str]:
    return {row["name"] for row in result}


class Proof:
    def __init__(self) -> None:
        self.failures: list[str] = []

    def check(self, ok: bool, description: str) -> None:
        mark = "ok  " if ok else "FAIL"
        print(f"  [{mark}] {description}")
        if not ok:
            self.failures.append(description)


def main() -> int:
    trig = export_dataset()
    ds = rdflib.Dataset(default_union=True)
    ds.parse(data=trig, format="trig")

    p = Proof()

    print("named-graph identity + canonical ids")
    populated = [str(g.identifier) for g in ds.graphs() if len(g)]
    p.check(populated == [WS_GRAPH], f"exactly one workspace graph == {WS_GRAPH}")
    subjects = {str(s) for s in ds.subjects()}
    p.check(ID_ALPHA in subjects, "Alpha task carries its canonical urn:uuid id")
    p.check(ID_STEP_TWO in subjects, "Step two carries its canonical urn:uuid id")

    print("proving queries run unchanged in rdflib")
    hi = rows(ds, "high-priority")
    p.check(names(hi) == {"Alpha task"}, "high-priority: only the prioritized action")
    p.check(any(r.get("priority") == "1" for r in hi), "high-priority: priority value travels")

    nxt = names(rows(ds, "index/unscheduled"))
    # Step two is blocked by open Step one, Done is complete, and Chain parent
    # is a container while its executable child remains open.
    p.check(
        nxt == {"Step one", "Alpha task"},
        "unscheduled: dependencies, completion, and containers are governed",
    )

    dep = rows(ds, "dependency-chain")
    p.check(
        dep == [{"name": "Step two", "depends_on": "Step one", "dep_state": "NotStarted"}],
        "dependency-chain: the successor edge survives",
    )

    p.check(rows(ds, "orphaned-actions") == [], "orphaned-actions: every action is charter-linked")

    # These execute cleanly in rdflib; their rows are fixture-incidental, so we
    # assert the deterministic counts to prove standard evaluation, not content.
    p.check(len(rows(ds, "open-actions")) == 4, "open-actions (backlog): 4 open actions")
    p.check(rows(ds, "completion-velocity") == [], "completion-velocity: runs (no dated completions)")

    print()
    if p.failures:
        print(f"external-rdf-proof: FAILED ({len(p.failures)} checks)")
        return 1
    print("external-rdf-proof: PASSED — publication is engine-independent")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
