# Clearhead Platform Architecture (V3)

**Status:** Active Development
**Last Updated:** January 2025
**Version:** 3.0

> **TL;DR**: V3 ontology (BFO/CCO-aligned) + SHACL shapes are the single source of truth. Ontologies are EXTENDED at each layer (parser, CLI) to add domain-specific concepts. JTD schemas enable code generation. SHACL provides runtime validation. Everything generates from ontology - no separate config files.

---

## Table of Contents

1. [Core Principles](#core-principles)
2. [The Three-Layer Ontology Architecture](#the-three-layer-ontology-architecture)
3. [Generation Pipeline](#generation-pipeline)
4. [SHACL as Validation Hub](#shacl-as-validation-hub)
5. [Current Implementation Status](#current-implementation-status)
6. [Key Architectural Decisions](#key-architectural-decisions)

---

## Core Principles

### 1. Ontology Extension Over Configuration Files

**Problem:** Separate config files (syntax_mapping.json) drift from ontology.

**Solution:** Extend the ontology itself with domain-specific annotations.

```turtle
# Bad: Separate syntax_mapping.json
{
  "priority": {
    "symbol": "!",
    "values": [1, 2, 3, 4]
  }
}

# Good: Ontology extension
@prefix parser: <https://vocab.clearhead.io/parser#> .

actions:hasPriority
    parser:symbol "!" ;
    parser:grammarRule "choice" ;
    parser:validValues (1 2 3 4) .
```

**Benefits:**
- Single source of truth
- Semantic consistency
- Can reason over parser rules
- Generate both grammar AND documentation

### 2. SHACL Drives Everything

All constraints flow through SHACL shapes:

```
OWL Ontology          SHACL Shapes
(what CAN exist)  →  (what MUST exist)
                           ↓
                    ┌──────┴──────┐
                    ↓             ↓
                JTD Schema    Runtime
                (codegen)    Validation
```

**Why SHACL?**
- Rich constraint language (SPARQL rules)
- Standard W3C format
- Runtime validation of RDF data
- Semantic, not just syntactic

### 3. JTD for Code Generation

**NOT using JSON Schema** for our use case.

**Why JTD?**
- Precise integer types (`uint8` not `integer`)
- Clean enums (type-safe, not strings)
- Designed for codegen
- Official generators for Rust/TypeScript

**JSON Schema remains available** for API documentation if needed, but JTD is primary.

### 4. Grammar Generation, Not Hand-Writing

**Original approach:** Hand-write grammar.js, hand-maintain tests
**Current approach:** Generate grammar from TypeScript types using type-sitter

```
V3 Ontology + SHACL
       ↓
   JTD Schemas
       ↓
TypeScript Types
       ↓
   [type-sitter]
       ↓
  grammar.js  (GENERATED!)
```

**Trade-off:** Less manual control, but guaranteed consistency with types.

---

## The Three-Layer Ontology Architecture

Instead of one monolithic ontology, we have **three extending layers**:

```
┌─────────────────────────────────────────────┐
│ Layer 1: V3 Base Ontology                   │
│ Location: ontology/actions-vocabulary.owl   │
│                                             │
│ • Semantic concepts (ActionPlan, Process)  │
│ • BFO/CCO alignment                        │
│ • Core properties (hasPriority, hasState) │
│ • SHACL validation shapes                  │
│                                             │
│ Published: https://vocab.clearhead.io/v3   │
└──────────────────┬──────────────────────────┘
                   │ owl:imports + extends
                   ↓
┌─────────────────────────────────────────────┐
│ Layer 2: Parser Ontology                    │
│ Location: tree-sitter-actions/parser.owl    │
│                                             │
│ • File format concepts (Line, File)        │
│ • Symbol mappings (priority → "!")        │
│ • Grammar rules (choice, pattern)          │
│ • Syntax constraints                       │
│                                             │
│ Published: vocab.clearhead.io/parser       │
└──────────────────┬──────────────────────────┘
                   │ owl:imports + extends
                   ↓
┌─────────────────────────────────────────────┐
│ Layer 3: CLI Ontology                       │
│ Location: clearhead-cli/cli.owl             │
│                                             │
│ • Command concepts (Validate, List)        │
│ • Display formats (Terminal, TUI)         │
│ • Operation metadata                       │
└─────────────────────────────────────────────┘
```

**Key Insight:** Each layer adds concepts without modifying the base. Tools can import at any level.

---

## Generation Pipeline

### Full Flow

```
┌─────────────────────────────────────────┐
│ 1. V3 Ontology + SHACL                  │
│                                         │
│ - actions-vocabulary.owl                │
│ - actions-shapes-v3.ttl                 │
│ - RDF examples (tested)                 │
└───────────────┬─────────────────────────┘
                ↓
┌─────────────────────────────────────────┐
│ 2. JTD Generation                       │
│                                         │
│ uv run python generate_jtd.py           │
│                                         │
│ Reads: OWL + SHACL                      │
│ Outputs: schemas/jtd/*.jtd.json         │
│ - Precise types (uint8, uint16)        │
│ - Required from sh:minCount             │
│ - Enums from sh:in                      │
└───────────────┬─────────────────────────┘
                ↓
┌─────────────────────────────────────────┐
│ 3. TypeScript Type Generation           │
│                                         │
│ jtd-codegen *.jtd.json \                │
│   --typescript-out src/types/           │
│                                         │
│ Generates: ActionPlan, ActionProcess    │
│ interfaces with proper types            │
└───────────────┬─────────────────────────┘
                ↓
┌─────────────────────────────────────────┐
│ 4. Parser Ontology Extension            │
│                                         │
│ Hand-create: parser.owl                 │
│ Extends V3 with:                        │
│   actions:hasPriority parser:symbol "!" │
│                                         │
│ This ontology contains the mapping!     │
└───────────────┬─────────────────────────┘
                ↓
┌─────────────────────────────────────────┐
│ 5. Grammar Generation                   │
│                                         │
│ type-sitter generate \                  │
│   --input src/types/ \                  │
│   --ontology parser.owl \               │
│   --output grammar.js                   │
│                                         │
│ Grammar.js is GENERATED!                │
└───────────────┬─────────────────────────┘
                ↓
┌─────────────────────────────────────────┐
│ 6. Tree-Sitter Parser                   │
│                                         │
│ npm run build                           │
│                                         │
│ Generates: C parser + node bindings     │
│ Parses: .actions files → AST            │
└───────────────┬─────────────────────────┘
                ↓
┌─────────────────────────────────────────┐
│ 7. Rust Struct Generation               │
│                                         │
│ type-sitter --rust \                    │
│   --parser tree-sitter-actions \        │
│   --output src/generated/               │
│                                         │
│ Generates: Rust structs from AST nodes  │
└───────────────┬─────────────────────────┘
                ↓
┌─────────────────────────────────────────┐
│ 8. CLI Implementation                   │
│                                         │
│ Hand-written:                           │
│ - Business logic (complete, schedule)   │
│ - File I/O                              │
│ - TUI                                   │
│                                         │
│ Uses generated structs for type safety  │
└───────────────┬─────────────────────────┘
                ↓
┌─────────────────────────────────────────┐
│ 9. Runtime Validation                   │
│                                         │
│ impl Action {                           │
│   fn validate(&self) -> Result<()> {    │
│     let rdf = self.to_rdf();           │
│     pyshacl_validate(rdf, shapes)       │
│   }                                     │
│ }                                       │
│                                         │
│ Validates against original SHACL shapes │
└─────────────────────────────────────────┘
```

### What's Generated vs Hand-Written

| Artifact | Generated | Hand-Written | Why |
|----------|-----------|--------------|-----|
| **OWL Ontology** | ❌ | ✅ | Semantic definitions are human knowledge |
| **SHACL Shapes** | ❌ | ✅ | Business rules are human decisions |
| **JTD Schemas** | ✅ | ❌ | Mechanical transformation from OWL+SHACL |
| **TypeScript Types** | ✅ | ❌ | Generated by jtd-codegen |
| **Parser Ontology** | ❌ | ✅ | Mapping decisions require human judgment |
| **grammar.js** | ✅ | ❌ | Generated by type-sitter from types |
| **Parser Tests** | ⚠️ | ✅ | Input files generated, expected output hand-written |
| **Rust Structs** | ✅ | ❌ | Generated by type-sitter from parser |
| **Rust Impl Blocks** | ❌ | ✅ | Business logic is application-specific |

**Golden Rule:** Generate **structure**, hand-write **behavior**.

---

## SHACL as Validation Hub

SHACL shapes drive three things:

### 1. Code Generation (via JTD)

```turtle
# SHACL
actions:hasPriority
    sh:datatype xsd:integer ;
    sh:minInclusive 1 ;
    sh:maxInclusive 4 ;
    sh:minCount 1 .

          ↓

# JTD
{
  "properties": {
    "priority": { "type": "uint8" }  # Required + right-sized type
  }
}

          ↓

# Rust
pub struct ActionPlan {
    pub priority: u8,  # Not Option<u8>, not i64!
}
```

### 2. Documentation

SHACL `sh:message` provides user-facing error messages:

```turtle
sh:message "Priority must be between 1 (urgent+important) and 4 (neither)" ;
```

Becomes CLI error:
```
❌ Validation failed: Priority must be between 1 (urgent+important) and 4 (neither)
   Found: 5 in action "Complete report"
```

### 3. Runtime Validation

```rust
impl Action {
    pub fn validate(&self) -> Result<ValidationReport> {
        // Convert Rust struct to RDF
        let rdf_graph = self.to_rdf()?;

        // Load SHACL shapes from ontology URL
        let shapes = fetch_shapes("https://vocab.clearhead.io/v3/shapes")?;

        // Validate
        let report = pyshacl::validate(rdf_graph, shapes)?;

        if !report.conforms {
            return Err(ValidationError::ShaclViolation(report));
        }

        Ok(report)
    }
}
```

**Why convert to RDF?** SHACL validates semantic correctness, not just types. Complex rules like "completed date must be after do date" require SPARQL.

---

## Current Implementation Status

### ✅ Complete

- **V3 Ontology**: BFO/CCO-aligned, production-ready
- **V3 SHACL Shapes**: Comprehensive constraints (456 lines)
- **Test Suite**: 14 tests, all passing
- **RDF Examples**: Valid and invalid test data
- **Documentation**: This file, README.md, decision records

### 🚧 In Progress

- **JTD Generation**: Script exists, needs update to read V3 SHACL for required/optional
- **Parser Ontology**: Needs creation (will extend V3 with file format concepts)

### ⏳ Not Started

- **TypeScript Type Generation**: Waiting on JTD schemas
- **Grammar Generation**: Waiting on TypeScript types + parser ontology
- **Rust Struct Generation**: Waiting on parser
- **CLI Implementation**: Waiting on Rust structs

### Timeline

- **Phase 1 (Complete)**: V3 Ontology + SHACL - 2 weeks ✅
- **Phase 2 (Current)**: JTD + Parser Ontology - 2-3 weeks 🚧
- **Phase 3**: Grammar Generation - 1-2 weeks
- **Phase 4**: CLI Implementation - 3-4 weeks

**Total to working CLI:** ~8-10 weeks from start

---

## Key Architectural Decisions

### Decision 1: V3 (BFO/CCO) Over V2 (Schema.org)

**Rationale:**
- BFO provides rigorous upper ontology (continuant/occurrent distinction)
- CCO gives proven patterns (DirectiveInformationContentEntity)
- Plan vs Process separation enables recurring actions
- 450+ ontologies use BFO - interoperability

**Trade-off:** More complex, but scientifically rigorous

### Decision 2: Ontology Extension Over Config Files

**Rationale:**
- Single source of truth
- Can reason over syntax rules
- Generate grammar AND documentation
- No drift between ontology and implementation

**Trade-off:** Requires ontology expertise, but worth it

### Decision 3: JTD Over JSON Schema

**Rationale:**
- Precise types (uint8 not integer)
- Type-safe enums
- Designed for codegen
- Cleaner generated code

**Trade-off:** Smaller ecosystem, but better output quality

### Decision 4: Generate Grammar Over Hand-Write

**Rationale:**
- Guaranteed consistency with types
- Automatic updates when ontology changes
- Less manual maintenance

**Trade-off:** Less fine-grained control, but automation wins

### Decision 5: SHACL for Runtime Validation

**Rationale:**
- Complex constraints (temporal, hierarchical)
- SPARQL expressiveness
- Standard format
- Validates semantic correctness, not just syntax

**Trade-off:** Performance (convert to RDF), but correctness matters more

---

## Related Documentation

- **[README.md](./README.md)** - Project overview and vision
- **[ontology/CLAUDE.md](./ontology/CLAUDE.md)** - Ontology development guide
- **[ontology/BFO_CCO_ALIGNMENT.md](./ontology/BFO_CCO_ALIGNMENT.md)** - V3 architecture rationale
- **[ontology/SCHEMA_GENERATION_DECISION.md](./ontology/SCHEMA_GENERATION_DECISION.md)** - JTD vs JSON Schema
- **[ontology/migrations/V2_TO_V3_MIGRATION.md](./ontology/migrations/V2_TO_V3_MIGRATION.md)** - Migration guide

---

## Conclusion

This architecture provides:

1. **Single Source of Truth**: V3 ontology + SHACL shapes
2. **Maximum Leverage**: One change propagates through stack
3. **Semantic Correctness**: Types + SHACL validation
4. **Standards-Based**: BFO/CCO/W3C compliance
5. **Maintainability**: Generate structure, hand-write behavior

**The key insight:** Extend ontologies, don't create config files. This is ontology-driven development taken seriously.

---

**Version:** 3.0
**Status:** Living Document
**Authors:** Clearhead Platform Team
**Last Updated:** January 2025
