"""Run each query three ways and compare answers: v4 today, raw V5, V5 view.

Run with any Python that has rdflib, e.g. from the platform root:
    uv run --with rdflib python docs/history/query-surface-spike/run.py
The v4 queries are read live from the CLI and this workspace, so once they
move to the application vocabulary this script records history, not a test.
"""
import pathlib

import rdflib

HERE = pathlib.Path(__file__).parent
ROOT = HERE.parents[2]  # the platform repository
CLI = ROOT / "clearhead-core/crates/clearhead-cli/src/queries"
V4 = {
    "for-human": ROOT / ".clearhead/queries/for-human.sparql",
    "unscheduled": CLI / "index/unscheduled.sparql",
    "agenda": CLI / "index/agenda.sparql",
}
STATUS = {"NotStarted": "not started", "InProgress": "in progress", "Blocked": "blocked"}

v4 = rdflib.Dataset(default_union=True)
v4.parse(HERE / "v4.trig", format="trig")
v5 = rdflib.Graph().parse(HERE / "v5.ttl")
view = rdflib.Graph()
for triple in v5.query((HERE / "view/view.rq").read_text()):
    view.add(triple)


def lines(text):
    return sum(
        1 for line in text.splitlines()
        if line.strip() and not line.strip().startswith(("#", "PREFIX"))
    )


def answers(graph, text):
    return sorted((str(row.name), STATUS.get(str(row.status), str(row.status))) for row in graph.query(text))


print(f"view: {len(view)} triples from {len(v5)} V5 triples; view.rq is {lines((HERE / 'view/view.rq').read_text())} lines\n")
for name, path in V4.items():
    v4_text = path.read_text().replace("?END_OF_TODAY", '"2026-10-04T23:59:59-07:00"^^xsd:dateTime')
    raw_text = (HERE / f"raw/{name}.rq").read_text()
    view_text = (HERE / f"view/{name}.rq").read_text()
    a, b, c = answers(v4, v4_text), answers(v5, raw_text), answers(view, view_text)
    same = "same answers" if a == b == c else "DIFFERENT"
    print(f"{name}: v4 {lines(v4_text)} lines, raw {lines(raw_text)}, view {lines(view_text)} -> {same}")
    print(f"  v4   {a}\n  raw  {b}\n  view {c}")
