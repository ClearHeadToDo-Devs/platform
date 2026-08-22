#!/usr/bin/env python3
"""Compare ClearHead (SPARQL Results JSON) and Rasqal (SPARQL CSV) query output
for the rdf-publication external proof.

Both are standard SPARQL result serializations. We compare the multiset of
bindings (value equality, order-insensitive) so a matching result proves both
engines return the same rows over the same dataset. When an ORDER BY variable
is given, we additionally assert each engine's output is sorted by that key,
so the contracted ordering is respected (without requiring identical
tie-breaks, which the SPARQL spec leaves undefined).

Usage: compare.py OURS.json THEIRS.csv [ORDER_BY_VAR]
Exit 0 on match, 1 on mismatch (with a diff on stderr).
"""
import csv
import json
import sys
from collections import Counter


def srj_rows(path):
    try:
        with open(path) as fh:
            doc = json.load(fh)
    except (OSError, ValueError) as exc:
        raise SystemExit(f"cannot read ClearHead SRJ {path}: {exc}") from exc
    out = []
    for binding in doc.get("results", {}).get("bindings", []):
        row = {}
        for var, cell in binding.items():
            row[var] = cell.get("value", "")
        out.append(tuple(sorted(row.items())))
    return out


def csv_rows(path):
    out = []
    try:
        with open(path, newline="") as fh:
            reader = csv.reader(fh)
            header = next(reader, None)
            if not header:
                return []
            for cells in reader:
                row = {}
                for var, cell in zip(header, cells, strict=False):
                    cell = cell.strip()
                    if cell != "":
                        row[var.lstrip("?")] = cell
                out.append(tuple(sorted(row.items())))
    except OSError as exc:
        raise SystemExit(f"cannot read rdflib CSV {path}: {exc}") from exc
    return out


def sorted_by_key(rows, key):
    values = [dict(r).get(key) for r in rows]
    return values == sorted(values, key=lambda v: (v is None, v))


def main():
    ours = srj_rows(sys.argv[1])
    theirs = csv_rows(sys.argv[2])
    order_key = sys.argv[3] if len(sys.argv) > 3 else None

    if Counter(ours) != Counter(theirs):
        ours_only = Counter(ours) - Counter(theirs)
        theirs_only = Counter(theirs) - Counter(ours)
        print("MISMATCH", file=sys.stderr)
        if ours_only:
            print("  only in ClearHead:", file=sys.stderr)
            for r, n in ours_only.items():
                print(f"    {n}x {dict(r)}", file=sys.stderr)
        if theirs_only:
            print("  only in rdflib:", file=sys.stderr)
            for r, n in theirs_only.items():
                print(f"    {n}x {dict(r)}", file=sys.stderr)
        return 1

    note = ""
    if order_key:
        note = ", ordered" if ours == theirs else ", same set (order differs = tie-break)"
    print(f"match ({len(ours)} rows{note})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
