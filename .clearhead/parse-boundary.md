---
alias: parse_boundary
---
# Parse Boundary and Mutation Safety

The parser currently has two behaviors (strict failure and recoverable parse), but command-level handling is inconsistent. This creates unsafe edges where partial recovery can silently become destructive file rewrites.

This charter defines a single parse boundary contract for the platform: syntax errors are systemic and block mutation; lint remains advisory for valid parses. It also defines observability hooks so parse health is measurable over time rather than inferred from incidents.
