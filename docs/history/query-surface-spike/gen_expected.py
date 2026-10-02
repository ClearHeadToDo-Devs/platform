"""Write the CCO expected graph for the spec's graph conformance fixture.

Not a reference implementation: it encodes the fixture's facts by hand and
only computes the helper IRIs, so the committed Turtle can be reviewed. Run
from the platform root and review the diff before committing:
    python3 docs/history/query-surface-spike/gen_expected.py \
        | sed 's#fixture (../ontology.md)#fixture (ontology.md at the repository root)#' \
        > specifications/examples/conformance/graph/expected.ttl
The spike's v5.ttl came from this script with two edits: the groceries
charter "active" instead of "new", and a +human context on the fence.
"""
import uuid

CTX_NS = uuid.UUID("0d8937ce-eb24-52d2-9532-39ea299f888b")
P = "01a0fb10-0000-7000-8000-"


def u(suffix):
    return P + suffix


def iri(x):
    return f"<urn:uuid:{x}>"


def helper(owner, role):
    return iri(uuid.uuid5(uuid.UUID(owner), role))


def ctx(slug):
    return iri(uuid.uuid5(CTX_NS, slug))


def lit(s):
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


out = []


def block(comment, *lines):
    out.append(f"# {comment}")
    out.extend(lines)
    out.append("")


def bearer(owner, role, prop, value, extra=""):
    return f"{helper(owner, role + '/value')} a cco:ont00000253 ; obo:BFO_0000101 {helper(owner, role)} ; {prop} {value}{extra} ."


def text(owner, role, s):
    return bearer(owner, role, "cco:ont00001765", lit(s))


def alias(owner, name):
    return [
        f"{helper(owner, 'alias')} a cco:ont00000003 ; cco:ont00001916 {iri(owner)} .",
        text(owner, "alias", name),
    ]


def state(owner, value):
    return [
        f"{helper(owner, 'state')} a cco:ont00000293 ; cco:ont00001868 {iri(owner)} .",
        text(owner, "state", value),
    ]


def condition(owner, role, describes=None, value=None):
    lines = [
        f"{helper(owner, role)} a cco:ont00000127 ; obo:BFO_0000178 {iri(owner)} , {helper(owner, role + '/condition')} .",
        f"{helper(owner, role + '/condition')} a cco:ont00000853"
        + (f" ; cco:ont00001982 {describes}" if describes else "") + " .",
    ]
    if value:
        prop, v = value
        lines.append(bearer(owner, role + "/condition", prop, v))
    return lines


def dt(s):
    return ("cco:ont00001767", f'"{s}"^^xsd:dateTime')


def date(s):
    return ("cco:ont00001771", f'"{s}"^^xsd:date')


def act(owner, status, when=None):
    extra = f" ; cco:ont00001767 \"{when}\"^^xsd:dateTime" if when else ""
    return [
        f"{helper(owner, 'act')} a cco:ont00000228 ; cco:ont00001920 {iri(owner)} .",
        f"{helper(owner, 'act/status')} a cco:ont00000203 ; cco:ont00001868 {helper(owner, 'act')} .",
        bearer(owner, "act/status", "cco:ont00001765", lit(status), extra),
    ]


def action(owner, label, *more):
    return [f"{iri(owner)} a obo:IAO_0000007 ; rdfs:label {lit(label)}{''.join(more)} ."]


eat, keep = u("0000000000b0"), u("0000000000b1")
home, groc = u("0000000000c0"), u("0000000000c1")
a = {k: u(f"0000000000{k}") for k in ("01", "02", "03", "04", "05", "06", "07", "08", "09", "0a", "10", "11", "12", "13")}

block("Objective: eat well (objectives/eat-well.md)",
      f"{iri(eat)} a cco:ont00000476 ; rdfs:label \"Eat well\" ;",
      '    dcterms:description "Meals at home most days, with food we like." ;',
      f"    obo:BFO_0000178 {iri(keep)} .",
      *alias(eat, "eat-well"))
block("Objective: keep food in the house, with one metric (objectives/keep-food.md)",
      f"{iri(keep)} a cco:ont00000476 ; rdfs:label \"Keep food in the house\" .",
      *alias(keep, "keep-food"),
      f"{helper(keep, 'metric/fridge-stocked')} a cco:ont00000853 ; cco:ont00001808 {iri(keep)} .",
      text(keep, "metric/fridge-stocked", "fridge stocked: milk, eggs and vegetables on hand"))
block("Charter: home, the root (charters/README.md)",
      f"{iri(home)} a cco:ont00000974 ; rdfs:label \"Run the household\" ;",
      '    dcterms:description "Everything that keeps the house going." ;',
      f"    obo:BFO_0000178 {iri(eat)} , {iri(groc)} ,",
      "        " + " , ".join(iri(a[k]) for k in ("01", "02", "03", "04", "05", "06", "08")) + " .",
      *alias(home, "home"), *state(home, "active"))
block("Charter: groceries (charters/groceries.md)",
      f"{iri(groc)} a cco:ont00000974 ; rdfs:label \"Groceries\" ;",
      f"    obo:BFO_0000178 {iri(keep)} , {iri(a['10'])} , {iri(a['13'])} .",
      *alias(groc, "groceries"), *state(groc, "new"))

o = a["01"]
block("[-] Call the plumber: every field",
      *action(o, "Call the plumber", ' ;\n    dcterms:description "The kitchen tap drips." ;\n    dcterms:created "2026-10-01T10:00:00"^^xsd:dateTime'),
      *alias(o, "plumber"),
      f"{helper(o, 'priority')} a cco:ont00000369 ; cco:ont00001811 {iri(o)} .",
      bearer(o, "priority", "cco:ont00001773", "2"),
      f"{helper(o, 'duration')} a cco:ont00001163 ; cco:ont00001808 {iri(o)} .",
      bearer(o, "duration", "cco:ont00001773", "15", " ; cco:ont00001863 cco:ont00001667"),
      *condition(o, "when/context/phone", describes=ctx("phone")),
      *condition(o, "when/scheduled", value=dt("2026-10-03T09:00:00")),
      *condition(o, "when/due", value=date("2026-10-04")),
      *act(o, "in progress"))
o = a["02"]
block("[x] Pay the water bill: completed, with its time",
      *action(o, "Pay the water bill"), *act(o, "completed", "2026-09-30T18:00:00"))
o = a["03"]
block("[_] Renew the magazine: cancelled, with its time",
      *action(o, "Renew the magazine"),
      f"{helper(o, 'cancelled')} a cco:ont00000293 ; cco:ont00001868 {iri(o)} .",
      bearer(o, "cancelled", "cco:ont00001765", lit("cancelled"), ' ; cco:ont00001767 "2026-09-28T08:30:00"^^xsd:dateTime'))
o = a["04"]
block("[=] Hear back from the landlord: blocked, waiting on something outside",
      *action(o, "Hear back from the landlord about the fence", ' ;\n    dcterms:description "Asked on Monday."'),
      *condition(o, "when/waiting", value=("cco:ont00001765", lit("waiting"))))
o = a["05"]
block("[ ] Fix the fence: not started (no act), a context and a predecessor",
      *action(o, "Fix the fence"),
      *condition(o, "when/context/home", describes=ctx("home")),
      *condition(o, f"when/after/{a['04']}", describes=iri(a["04"])))
o = a["06"]
block("[ ] Paint the shed: a predecessor its child inherits (in the application graph)",
      *action(o, "Paint the shed", f" ;\n    obo:BFO_0000178 {iri(a['07'])}"),
      *condition(o, f"when/after/{a['04']}", describes=iri(a["04"])))
block("Its child: nothing of its own; inheritance is not stated here",
      *action(a["07"], "Buy paint"))
o = a["08"]
block("[ ] Plan the party: a due date one child narrows and one inherits",
      *action(o, "Plan the party", f" ;\n    obo:BFO_0000178 {iri(a['09'])} , {iri(a['0a'])}"),
      *condition(o, "when/due", value=date("2026-10-04")))
block("Its children: an earlier due of its own, and none",
      *action(a["09"], "Send invites"),
      *condition(a["09"], "when/due", value=date("2026-10-03")),
      *action(a["0a"], "Bake the cake"))
o = a["10"]
block("[ ] Weekly shop ~: sequential parent; the marker itself is not emitted",
      *action(o, "Weekly shop", f" ;\n    obo:BFO_0000178 {iri(a['11'])} , {iri(a['12'])}"),
      *condition(o, "when/context/errands", describes=ctx("errands")))
block("Its children: the second waits on the first (sequential expansion)",
      *action(a["11"], "Write the list"),
      *action(a["12"], "Buy the food"),
      *condition(a["12"], f"when/after/{a['11']}", describes=iri(a["11"])))
o = a["13"]
block("[ ] Cook the soup: an explicit predecessor",
      *action(o, "Cook the soup"),
      *condition(o, f"when/after/{a['12']}", describes=iri(a["12"])))
block("Contexts: one node per slug, untyped; config's hierarchy as skos:broader",
      f"{ctx('phone')} rdfs:label \"phone\" .",
      f"{ctx('home')} rdfs:label \"home\" .",
      f"{ctx('errands')} rdfs:label \"errands\" ; skos:broader {ctx('out')} .",
      f"{ctx('out')} rdfs:label \"out\" .")

head = """# Expected graph for the graph conformance fixture (../ontology.md).
# The workspace in ./workspace projects to exactly these triples, in the
# workspace's named graph urn:clearhead:workspace:01a0fb10-0000-7000-8000-000000000000.
# Helper IRIs are UUIDv5 of owner id and role (Helper node IRIs).

@prefix cco: <https://www.commoncoreontologies.org/> .
@prefix obo: <http://purl.obolibrary.org/obo/> .
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .
@prefix dcterms: <http://purl.org/dc/terms/> .
@prefix skos: <http://www.w3.org/2004/02/skos/core#> .

"""
print(head + "\n".join(out).rstrip() + "\n", end="")
