"""Check the draft application vocabulary against today's answers.

The spec fixture's expected-app.ttl answers the query-surface spike's three
queries in app: terms on both engines. The oracle is the shipping v4 CLI, run
on a scratch copy of the fixture workspace. Both sides get the spike's two
changes: groceries Active, the fence tagged +human.

    uv run --with pyoxigraph --with rdflib python docs/history/app-vocabulary-check/run.py
"""

import json
import shutil
import subprocess
import tempfile
from pathlib import Path

import pyoxigraph
import rdflib

HERE = Path(__file__).parent
ROOT = HERE.parents[2]
FIXTURE = ROOT / "specifications/examples/conformance/graph/expected-app.ttl"
WORKSPACE = FIXTURE.parent / "workspace"
V4_QUERIES = {
    "for-human": ROOT / ".clearhead/queries/for-human.sparql",
    "unscheduled": ROOT / "clearhead-core/crates/clearhead-cli/src/queries/index/unscheduled.sparql",
    "agenda": ROOT / "clearhead-core/crates/clearhead-cli/src/queries/index/agenda.sparql",
}
SPIKE_CHANGES = """
PREFIX app: <https://clearhead.us/vocab/app/v1#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
DELETE DATA { <urn:uuid:01a0fb10-0000-7000-8000-0000000000c1> app:state app:New } ;
INSERT DATA {
  <urn:uuid:01a0fb10-0000-7000-8000-0000000000c1> app:state app:Active .
  <urn:uuid:01a0fb10-0000-7000-8000-000000000005> app:context <urn:example:human> .
  <urn:example:human> a app:Context ; rdfs:label "human" .
}
"""
# Where v4 disagrees with the spec, the spec wins: v4's agenda reads only an
# action's own dates, but action_file_format.md says queries use the effective
# window, so a child inherits its parent's due date.
V4_MISSES = {"agenda": [("Bake the cake", "not started")]}
STATE = {"NotStarted": "not started", "InProgress": "in progress", "Blocked": "blocked"}


def lines(text):
    return sum(1 for ln in text.splitlines() if ln.strip() and not ln.strip().startswith(("#", "PREFIX")))


def label(value):
    return STATE.get(str(value).rsplit("#", 1)[-1], str(value))


def oxigraph_answers(data, query):
    store = pyoxigraph.Store()
    store.load(data, pyoxigraph.RdfFormat.TURTLE)
    store.update(SPIKE_CHANGES)
    return sorted((str(s["name"].value), label(s["state"].value)) for s in store.query(query))


def rdflib_answers(data, query):
    graph = rdflib.Graph().parse(data=data, format="turtle")
    graph.update(SPIKE_CHANGES)
    return sorted((str(r["name"]), label(r["state"])) for r in graph.query(query))


def v4_answers(workspace, query):
    """Ask the installed clearhead CLI, which still emits v4."""
    out = subprocess.run(
        ["clearhead", "query", "raw", "--workspace", "graph-fixture", "--format", "json", query],
        cwd=workspace, capture_output=True, text=True, check=True,
    ).stdout
    rows = json.loads(out)["results"]["bindings"]
    return sorted((r["name"]["value"], label(r["status"]["value"])) for r in rows)


def spike_workspace(scratch):
    """Copy the fixture workspace and apply the spike's two changes to its files."""
    root = Path(shutil.copytree(WORKSPACE, Path(scratch) / "workspace"))
    charters = root / ".clearhead/charters"
    md = charters / "groceries.md"
    md.write_text(md.read_text().replace("state: New", "state: Active"))
    actions = charters / "next.actions"
    actions.write_text(actions.read_text().replace("Fix the fence +home", "Fix the fence +home,human"))
    return root


def main():
    data = FIXTURE.read_text()
    scratch = tempfile.mkdtemp()
    workspace = spike_workspace(scratch)
    for name, path in V4_QUERIES.items():
        v4_text = path.read_text().replace("?END_OF_TODAY", '"2026-10-04T23:59:59Z"^^xsd:dateTime')
        want = sorted(v4_answers(workspace, v4_text) + V4_MISSES.get(name, []))
        app_text = (HERE / f"app/{name}.rq").read_text()
        for engine, run in (("oxigraph", oxigraph_answers), ("rdflib", rdflib_answers)):
            got = run(data, app_text)
            verdict = ("same as v4" + (" + its known misses" if name in V4_MISSES else "")) if got == want else f"DIFFERENT\n    v4  {want}\n    app {got}"
            print(f"{name:12} {engine:8} v4 {lines(v4_text):2} lines, app {lines(app_text):2}  {verdict}")


if __name__ == "__main__":
    main()
