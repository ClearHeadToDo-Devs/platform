"""Check the specification's graph shapes against its conformance fixture.

- The expected graph conforms to the shapes, with no results at all.
- Each graph in invalid/ fails on exactly the shape its `# expect:` line names.
- Each graph in warning/ yields only warnings, from the shape it names.
- The expected graph, merged with the ontology, reasons consistent under
  HermiT and passes the ontology's own verify rules (ROBOT).

Run: uv run --with pyshacl==0.40.1 python scripts/check-graph-shapes.py
"""

import pathlib
import subprocess
import sys
import tempfile

from pyshacl import validate
from rdflib import Graph, Namespace, URIRef
from rdflib.namespace import RDF

SH = Namespace("http://www.w3.org/ns/shacl#")
SHAPE = "https://clearhead.us/specifications/graph-shapes#"

root = pathlib.Path(__file__).resolve().parent.parent
fixture = root / "specifications/examples/conformance/graph"
shapes = Graph().parse(root / "specifications/schemas/graph.shapes.ttl")
ontology = root / "ontology/v5"


def named_shape(source):
    """The named node shape a result came from (property shapes are anonymous)."""
    if isinstance(source, URIRef):
        return str(source)
    owner = next(shapes.subjects(SH.property, source), None)
    return str(owner) if owner is not None else str(source)


def results(path):
    """(severity, named shape) for every result of validating one graph."""
    _, report, _ = validate(Graph().parse(path), shacl_graph=shapes, advanced=True)
    return {
        (str(report.value(r, SH.resultSeverity)).rsplit("#", 1)[-1],
         named_shape(report.value(r, SH.sourceShape)).removeprefix(SHAPE))
        for r in report.subjects(RDF.type, SH.ValidationResult)
    }


def expected_shape(path):
    for line in path.read_text().splitlines():
        if line.startswith("# expect: "):
            return line.removeprefix("# expect: ").strip()
    sys.exit(f"{path}: no '# expect:' line")


failures = []

found = results(fixture / "expected.ttl")
if found:
    failures.append(f"expected.ttl: {sorted(found)}")

for path in sorted((fixture / "invalid").glob("*.ttl")):
    want = expected_shape(path)
    found = results(path)
    if found != {("Violation", want)}:
        failures.append(f"invalid/{path.name}: wanted only a violation of {want}, got {sorted(found)}")

for path in sorted((fixture / "warning").glob("*.ttl")):
    want = expected_shape(path)
    found = results(path)
    if found != {("Warning", want)}:
        failures.append(f"warning/{path.name}: wanted only a warning from {want}, got {sorted(found)}")

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

if failures:
    print("graph shapes > FAILED", *failures, sep="\n  ", file=sys.stderr)
    sys.exit(1)
print("graph shapes > expected conforms and reasons consistent; "
      f"{len(list((fixture / 'invalid').glob('*.ttl')))} invalid graphs fail on their shapes")
