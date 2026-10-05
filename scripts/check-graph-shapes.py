"""Check the specification's graph shapes against its conformance fixture.

Two suites: the CCO graph (graph.shapes.ttl, expected.ttl, invalid/, warning/)
and the application graph (app.shapes.ttl, expected-app.ttl, invalid-app/).

- Each expected graph conforms to its shapes, with no results at all.
- Each invalid graph fails on exactly the shape its `# expect:` line names.
- Each warning graph yields only warnings, from the shape it names.
- The CCO expected graph, merged with the ontology, reasons consistent under
  HermiT and passes the ontology's own verify rules (ROBOT).
- The mapping (specifications/ontology/mapping/*.rq) of the application
  expected graph is isomorphic to the CCO one, and every application term in
  the app shapes is read by the mapping or listed in ontology/unmapped.ttl.

Run: uv run --with pyshacl==0.40.1 python scripts/check-graph-shapes.py
"""

import pathlib
import subprocess
import sys
import tempfile

from pyshacl import validate
import re

from rdflib import Graph, Namespace, URIRef
from rdflib.compare import graph_diff, to_isomorphic
from rdflib.namespace import RDF

SH = Namespace("http://www.w3.org/ns/shacl#")

root = pathlib.Path(__file__).resolve().parent.parent
fixture = root / "specifications/examples/conformance/graph"
schemas = root / "specifications/schemas"
ontology = root / "specifications/ontology"

# (name, shapes, their namespace, expected graph, invalid dir, warning dir)
SUITES = [
    ("cco", schemas / "graph.shapes.ttl", "https://clearhead.us/specifications/graph-shapes#",
     fixture / "expected.ttl", fixture / "invalid", fixture / "warning"),
    ("app", schemas / "app.shapes.ttl", "https://clearhead.us/specifications/app-shapes#",
     fixture / "expected-app.ttl", fixture / "invalid-app", fixture / "warning-app"),
]


def named_shape(shapes, source):
    """The named node shape a result came from (property shapes are anonymous)."""
    if isinstance(source, URIRef):
        return str(source)
    owner = next(shapes.subjects(SH.property, source), None)
    return str(owner) if owner is not None else str(source)


def results(shapes, namespace, path):
    """(severity, named shape) for every result of validating one graph."""
    _, report, _ = validate(Graph().parse(path), shacl_graph=shapes, advanced=True)
    return {
        (str(report.value(r, SH.resultSeverity)).rsplit("#", 1)[-1],
         named_shape(shapes, report.value(r, SH.sourceShape)).removeprefix(namespace))
        for r in report.subjects(RDF.type, SH.ValidationResult)
    }


def expected_shape(path):
    for line in path.read_text().splitlines():
        if line.startswith("# expect: "):
            return line.removeprefix("# expect: ").strip()
    sys.exit(f"{path}: no '# expect:' line")


failures = []
counts = []

for name, shapes_path, namespace, expected, invalid, warning in SUITES:
    shapes = Graph().parse(shapes_path)
    found = results(shapes, namespace, expected)
    if found:
        failures.append(f"{expected.name}: {sorted(found)}")
    for path in sorted(invalid.glob("*.ttl")):
        want = expected_shape(path)
        found = results(shapes, namespace, path)
        if found != {("Violation", want)}:
            failures.append(f"{invalid.name}/{path.name}: wanted only a violation of {want}, got {sorted(found)}")
    for path in sorted(warning.glob("*.ttl")):
        want = expected_shape(path)
        found = results(shapes, namespace, path)
        if found != {("Warning", want)}:
            failures.append(f"{warning.name}/{path.name}: wanted only a warning from {want}, got {sorted(found)}")
    counts.append(f"{name}: {len(list(invalid.glob('*.ttl')))} invalid")

with tempfile.TemporaryDirectory() as tmp:
    merged = pathlib.Path(tmp) / "merged.owl"
    robot = ["robot", "--catalog", str(ontology / "catalog-v001.xml")]
    steps = {
        "merge": robot + ["merge", "--input", str(ontology / "clearhead.ttl"),
                          "--input", str(fixture / "expected.ttl"), "--output", str(merged)],
        "reason": ["robot", "reason", "--reasoner", "HermiT", "--input", str(merged),
                   "--output", str(pathlib.Path(tmp) / "reasoned.owl")],
        "verify": ["robot", "verify", "--input", str(merged), "--output-dir", tmp, "--queries",
                   *map(str, sorted((ontology / "verify").glob("*.rq")))],
    }
    for name, step in steps.items():
        run = subprocess.run(step, capture_output=True, text=True)
        if run.returncode != 0:
            failures.append(f"robot {name}: {(run.stdout + run.stderr).strip()[-600:]}")
            break

mapping_dir = root / "specifications/ontology/mapping"
queries = sorted(mapping_dir.glob("*.rq"))
app_graph = Graph().parse(fixture / "expected-app.ttl")
mapped = Graph()
for query in queries:
    for triple in app_graph.query(query.read_text()):
        mapped.add(triple)
want, got = to_isomorphic(Graph().parse(fixture / "expected.ttl")), to_isomorphic(mapped)
if want != got:
    _, missing, extra = graph_diff(want, got)
    failures.append(f"mapping: {len(missing)} triples of expected.ttl missing, {len(extra)} extra")

APP = "https://clearhead.us/vocab/app/v1#"
local = lambda text: set(re.findall(r"\bapp:([A-Za-z]+)", text))
terms = local((schemas / "app.shapes.ttl").read_text())
used = set().union(*(local(q.read_text()) for q in queries))
exempt = {str(s).removeprefix(APP) for s in Graph().parse(mapping_dir.parent / "unmapped.ttl").subjects()}
if terms - used - exempt:
    failures.append(f"terms with no meaning (map them or list them in unmapped.ttl): {sorted(terms - used - exempt)}")
if used & exempt:
    failures.append(f"terms both mapped and listed as unmapped: {sorted(used & exempt)}")

if failures:
    print("graph shapes > FAILED", *failures, sep="\n  ", file=sys.stderr)
    sys.exit(1)
print("graph shapes > both expected graphs conform, the CCO one reasons consistent and is the "
      f"mapping of the application one ({len(queries)} queries, every term mapped or listed); "
      f"invalid graphs fail on their shapes ({', '.join(counts)})")
