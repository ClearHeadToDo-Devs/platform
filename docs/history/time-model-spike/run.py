"""Time-model spike: which application-graph shape answers time questions plainly and correctly?

One table of awkward bounds, emitted in each candidate shape, queried on both engines
we rely on (Oxigraph, as the CLI links it; rdflib, as the external proof runs), and
checked against hand-computed answers.

    uv run --with pyoxigraph --with rdflib python docs/history/time-model-spike/run.py
"""

import re
from datetime import date, datetime, time, timedelta
from pathlib import Path
from zoneinfo import ZoneInfo

import pyoxigraph
import rdflib

HERE = Path(__file__).parent
ZONE = ZoneInfo("America/Los_Angeles")  # the viewer's zone; "now" is 2026-10-05T14:30 there

# id: (DSL timing as written, expected membership in agenda / overdue / fits-in-30)
FIXTURE = {
    "A": (":2026-10-05", {"agenda"}),
    "B": (":2026-10-04", {"agenda", "overdue"}),
    "C": (":2026-10-05T12:00", {"agenda", "overdue"}),
    "D": (":2026-10-05T20:00Z", {"agenda", "overdue"}),  # 13:00 local
    "E": (":2026-10-05T23:00+09:00", {"agenda", "overdue"}),  # 07:00 local
    "X": (":2026-10-06T01:00Z", {"agenda"}),  # 18:00 local, today though written as the 6th
    "F": ("@2026-10-06", set()),
    "G": ("@2026-10-05T15:00 |30", {"agenda"}),  # later today, not startable yet
    "H": ("@2026-10-05 :2026-10-05 |20", {"agenda", "fits"}),
    "I": ("|45", set()),
    "J": ("|15", {"fits"}),
    "K": ("@2026-10-05T14:00-04:00 |30", {"agenda", "fits"}),  # 11:00 local
    "Y": ("@2026-10-05T16:00+02:00 |10", {"agenda", "fits"}),  # 07:00 local, written "16:00"
    "M": ("@2026-10-05T09:00 |30 (occurrence of a recurring VTODO)", {"agenda", "fits"}),
}

APP = "https://clearhead.us/vocab/app/v1#"
XSD = "http://www.w3.org/2001/XMLSchema#"


def parse_timing(text):
    """Split '@x :y |n' into (start, due, minutes) as written; a trailing (note) is ignored."""
    start = due = minutes = None
    for token in text.split("(")[0].split():
        if token.startswith("@"):
            start = token[1:]
        elif token.startswith(":"):
            due = token[1:]
        elif token.startswith("|"):
            minutes = int(token[1:])
    return start, due, minutes


def written_literal(value):
    """As written: xsd:date for a date, else xsd:dateTime, floating or with its offset.
    The only change is adding the seconds xsd:dateTime requires."""
    if "T" not in value:
        return f'"{value}"^^<{XSD}date>'
    return f'"{re.sub(r"T(\d\d:\d\d)(?!:)", r"T\1:00", value)}"^^<{XSD}dateTime>'


def instant(value, end_of_day):
    """The comparable instant a bound means (Decision 47), resolved in the viewer's zone."""
    if "T" not in value:
        day = date.fromisoformat(value) + timedelta(days=1 if end_of_day else 0)
        return datetime.combine(day, time(), ZONE)
    parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
    return parsed if parsed.tzinfo else parsed.replace(tzinfo=ZONE)


def emit(shape):
    lines = [f"@prefix app: <{APP}> ."]
    for action_id, (timing, _) in FIXTURE.items():
        start, due, minutes = parse_timing(timing)
        subject = f"<urn:example:{action_id}>"
        lines.append(f'{subject} a app:Action ; app:name "{action_id}" ; app:status "not started" .')
        if minutes:
            lines.append(f"{subject} app:minutes {minutes} .")
        for prop, value, end_of_day in (("start", start, False), ("due", due, True)):
            if value is None:
                continue
            lines.append(f"{subject} app:{prop} {written_literal(value)} .")
            if shape == "s2":
                at = instant(value, end_of_day).isoformat()
                lines.append(f'{subject} app:{ {"start": "notBefore", "due": "lateFrom"}[prop] } "{at}"^^<{XSD}dateTime> .')
    return "\n".join(lines) + "\n"


def run_oxigraph(data, query):
    store = pyoxigraph.Store()
    store.load(data.encode(), pyoxigraph.RdfFormat.TURTLE)
    return {str(solution["name"].value) for solution in store.query(query)}


def run_rdflib(data, query):
    graph = rdflib.Graph().parse(data=data, format="turtle")
    return {str(row["name"]) for row in graph.query(query)}


def main():
    expected = {
        question: {i for i, (_, tags) in FIXTURE.items() if question in tags}
        for question in ("agenda", "overdue", "fits")
    }
    for shape in ("s1", "s2"):
        data = emit(shape)
        (HERE / f"{shape}.ttl").write_text(data)
        for question, want in expected.items():
            path = HERE / shape / f"{question}.rq"
            query = path.read_text()
            lines = sum(1 for ln in query.splitlines() if ln.strip() and not ln.lstrip().startswith(("#", "PREFIX")))
            for engine, run in (("oxigraph", run_oxigraph), ("rdflib", run_rdflib)):
                try:
                    got = run(data, query)
                except Exception as error:  # an engine refusing is a finding, not a crash
                    print(f"{shape} {question:8} {engine:8} ERROR {error}")
                    continue
                verdict = "ok" if got == want else f"WRONG missing={sorted(want - got)} extra={sorted(got - want)}"
                print(f"{shape} {question:8} {engine:8} {lines:2} lines  {verdict}")


if __name__ == "__main__":
    main()
