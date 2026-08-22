#!/usr/bin/env python3
"""Run one SPARQL query against the exported dataset with rdflib (an
independent SPARQL 1.1 implementation) and emit SPARQL CSV results.

TriG is loaded into a Dataset with ``default_union = True`` — the ClearHead
evaluator's union-default-graph convention (specifications/ontology.md) — so
queries written without an explicit GRAPH clause match across every workspace
named graph, exactly as they do in the in-process evaluator. Turtle is loaded
into a single Graph (its graph-only contract).
"""
import sys

import rdflib


def main():
    data_path, data_fmt, query_path, out_path = sys.argv[1:5]
    try:
        store = rdflib.Dataset() if data_fmt == "trig" else rdflib.Graph()
        store.parse(data_path, format=data_fmt)
        if isinstance(store, rdflib.Dataset):
            store.default_union = True
        with open(query_path) as fh:
            query = fh.read()
        payload = store.query(query).serialize(format="csv")
    except (OSError, RuntimeError) as exc:
        raise SystemExit(f"rdflib query failed: {exc}") from exc
    if isinstance(payload, bytes):
        payload = payload.decode()
    try:
        with open(out_path, "w") as fh:
            fh.write(payload)
    except OSError as exc:
        raise SystemExit(f"cannot write {out_path}: {exc}") from exc


if __name__ == "__main__":
    main()
