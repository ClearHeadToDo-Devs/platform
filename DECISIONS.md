# Architectural Decisions

**Last Updated:** January 2025
**Status:** Living Document

This document records key architectural decisions made for the Clearhead Platform. Each decision includes context, rationale, alternatives considered, and trade-offs.

---
## Decision 2: Loosly couple the ontology and move forward
Instead of relying on generation as before, we are instead using the ontology like any other piece where the cli will leverage it by translating the work into data and then running the validation shapes.

We will NOT be generating code from the ontology directly, but rather using it as a source of truth for semantic validation and reasoning.

In addition, we have been doing a deeper focus on aligning around the CLI and making the editor extensions a first-class citizen

## Decision 1: V3 Ontology with BFO/CCO Alignment

**Date:** October 2024
**Status:** ✅ Implemented

### Context
Need to choose between continuing with V2 (Schema.org-based) or migrating to V3 (BFO/CCO-aligned).

### Decision
Use V3 ontology with BFO 2.0 and CCO alignment as the production path. V2 is archived but stable.

### Rationale
- **Rigorous upper ontology:** BFO provides continuant/occurrent distinction
- **Proven patterns:** CCO DirectiveInformationContentEntity for plans
- **Interoperability:** 450+ ontologies use BFO
- **Plan vs Process:** Enables recurring actions (one plan → multiple executions)
- **Scientific credibility:** BFO is ISO standard

### Alternatives Considered
1. **Continue with V2 (Schema.org):** Simpler but less rigorous
2. **Custom ontology:** Reinventing the wheel
3. **SKOS only:** Too lightweight for our needs

### Trade-offs
- ✅ **Pro:** Formal semantics, interoperability, extensibility
- ❌ **Con:** Steeper learning curve, more complex
- **Verdict:** Scientific rigor worth the complexity

### Implementation
- `ontology/actions-vocabulary.owl` - V3 ontology (production)
- `ontology/v2/` - V2 archived for reference
- Migration guide: `ontology/migrations/V2_TO_V3_MIGRATION.md`

---

## Decision 2: Ontology Extension Over Configuration Files

**Date:** January 2025
**Status:** ✅ Decided, 🚧 Implementing

### Context
Need way to map semantic properties to file format syntax (e.g., `priority → "!"`).

### Decision
EXTEND ontologies at each layer rather than maintaining separate config files like `syntax_mapping.json`.

### Rationale
- **Single source of truth:** Ontology contains semantic AND syntactic information
- **No drift:** Can't get out of sync if it's all in one place
- **Reasoning:** Can use ontology reasoners over parser rules
- **Documentation:** Generate docs from same source
- **Maximum leverage:** One change propagates everywhere

### Alternatives Considered
1. **Separate syntax_mapping.json:** (Previous approach) Drift risk, duplication
2. **Code-based mapping:** Hard to maintain, no reasoning
3. **Database config:** Adds complexity, not semantic

### Trade-offs
- ✅ **Pro:** Consistency, reasoning, generation potential
- ❌ **Con:** Requires ontology expertise
- **Verdict:** Architectural purity wins

### Implementation
```turtle
# Parser ontology extends V3
@prefix parser: <https://vocab.clearhead.io/parser#> .

actions:hasPriority
    parser:symbol "!" ;
    parser:grammarRule "choice" ;
    parser:validValues (1 2 3 4) .
```

Three-layer approach:
- Layer 1: V3 base ontology (semantic)
- Layer 2: Parser ontology (adds syntax mappings)
- Layer 3: CLI ontology (adds command concepts)

---

## Decision 3: JTD for Code Generation (Not JSON Schema)

**Date:** October 2024
**Status:** ✅ Decided, 🚧 Implementing

### Context
Need schema format for generating TypeScript types and Rust structs.

### Decision
Use JSON Type Definition (JTD) as primary schema format. JSON Schema is optional for API documentation.

### Rationale
- **Precise types:** `uint8` not generic `integer`
- **Type-safe enums:** Not string unions
- **Designed for codegen:** Official generators for Rust/TypeScript/Go/Python
- **Cleaner output:** Less boilerplate in generated code
- **Simpler schemas:** Easier to maintain

### Alternatives Considered
1. **JSON Schema only:** Good for validation, poor for codegen
2. **Protobuf:** Binary format, doesn't align with ontology
3. **GraphQL Schema:** Too API-specific
4. **Manual type definitions:** Violates ontology-driven principle

### Trade-offs
- ✅ **Pro:** Better codegen, precise types, clean output
- ❌ **Con:** Smaller ecosystem than JSON Schema
- **Verdict:** Code quality matters more than ecosystem size

### Implementation
```bash
# Generate JTD from V3 + SHACL
uv run python scripts/generate_jtd.py

# Generate TypeScript
jtd-codegen actionplan.jtd.json --typescript-out src/types/

# Generate Rust (indirectly via parser)
type-sitter --rust --parser tree-sitter-actions
```

See: `ontology/SCHEMA_GENERATION_DECISION.md` for detailed comparison.

---

## Decision 4: Generate Grammar (Don't Hand-Write)

**Date:** January 2025
**Status:** ✅ Decided, ⏳ Not Started

### Context
Tree-sitter requires `grammar.js` file. Should it be hand-written or generated?

### Decision
GENERATE grammar.js from TypeScript types using type-sitter. Do not hand-write.

### Rationale
- **Consistency:** Guaranteed match with semantic model
- **Automation:** Changes propagate automatically
- **Maintenance:** Less manual work
- **Type safety:** Types drive both parsing and code generation
- **Single source:** Ontology → JTD → TypeScript → Grammar

### Alternatives Considered
1. **Hand-write grammar:** (Previous approach) Manual sync, drift risk
2. **Generate from ontology directly:** No good tools exist
3. **Hybrid (generate + hand-tune):** Complexity, unclear ownership

### Trade-offs
- ✅ **Pro:** Automation, consistency, maintainability
- ❌ **Con:** Less fine-grained control, dependency on type-sitter
- **Verdict:** Automation and consistency win

### Implementation
```bash
# TypeScript types from JTD
jtd-codegen *.jtd.json --typescript-out src/types/

# Grammar from TypeScript
type-sitter generate \
  --input src/types/ \
  --ontology parser-ontology.ttl \
  --output grammar.js
```

---

## Decision 5: SHACL for Runtime Validation

**Date:** October 2024
**Status:** ✅ Implemented

### Context
Need runtime validation of action data beyond type checking.

### Decision
Use SHACL shapes for semantic validation. Convert Rust structs to RDF, validate with pySHACL.

### Rationale
- **Rich constraints:** SPARQL rules for complex logic (temporal, hierarchical)
- **Standard format:** W3C SHACL specification
- **Semantic correctness:** Validates meaning, not just syntax
- **Existing shapes:** Leverage V3 SHACL shapes (456 lines already written)
- **User-friendly messages:** `sh:message` provides clear errors

### Alternatives Considered
1. **Generate Rust validators from SHACL:** Faster but requires custom codegen
2. **JSON Schema validation:** Too limited for complex rules
3. **Custom validation code:** Reinventing SHACL
4. **Skip validation:** Dangerous

### Trade-offs
- ✅ **Pro:** Expressiveness, standards compliance, reuse SHACL work
- ❌ **Con:** Performance (RDF conversion overhead)
- **Verdict:** Correctness matters more than performance initially

### Implementation
```rust
impl Action {
    pub fn validate(&self) -> Result<ValidationReport> {
        let rdf = self.to_rdf()?;
        let shapes = fetch_shapes("https://vocab.clearhead.io/v3/shapes")?;
        pyshacl::validate(rdf, shapes)
    }
}
```

**Future optimization:** Generate Rust validators from SHACL for performance.

---

## Decision 6: Three-Layer Ontology Architecture

**Date:** January 2025
**Status:** ✅ Decided, 🚧 Implementing

### Context
Need way to add domain-specific concepts without polluting base ontology.

### Decision
Use three extending ontology layers:
1. **Base V3:** Semantic concepts (ActionPlan, ActionProcess)
2. **Parser Ontology:** File format concepts (symbols, grammar rules)
3. **CLI Ontology:** Command concepts (operations, display formats)

### Rationale
- **Separation of concerns:** Each layer has clear responsibility
- **Extensibility:** Add layers without modifying base
- **Reusability:** Tools can import at appropriate level
- **Standards compliance:** Base ontology remains clean

### Alternatives Considered
1. **Monolithic ontology:** Everything in one file (bloated, mixed concerns)
2. **Module system:** Complex dependency management
3. **Separate vocabularies:** No inheritance, duplication

### Trade-offs
- ✅ **Pro:** Clear boundaries, extensibility, reusability
- ❌ **Con:** Three files to maintain (but automated)
- **Verdict:** Architectural cleanliness worth it

### Implementation
```
V3 Base (ontology/)
   ↓ owl:imports + extends
Parser (tree-sitter-actions/parser-ontology.ttl)
   ↓ owl:imports + extends
CLI (clearhead-cli/cli-ontology.ttl)
```

---

## Decision 7: Rust CLI Uses Parser-Generated Structs

**Date:** January 2025
**Status:** ✅ Decided, ⏳ Not Started

### Context
How should Rust CLI get its data structures?

### Decision
Generate Rust structs from parser AST nodes using type-sitter (Jakobeha variant). Do NOT generate directly from JTD.

### Rationale
- **Parser alignment:** Structs match AST structure exactly
- **Type safety:** Guaranteed valid parse tree → struct conversion
- **Single flow:** Parser defines structure, CLI consumes it
- **No redundancy:** Don't generate same structs twice

### Alternatives Considered
1. **Generate from JTD directly:** Duplicate struct definitions
2. **Hand-write structs:** Manual sync, drift risk
3. **Generate from JSON Schema:** Wrong tool for the job

### Trade-offs
- ✅ **Pro:** Single source (parser), type safety, no duplication
- ❌ **Con:** Dependent on parser being ready
- **Verdict:** Proper dependency chain

### Implementation
```bash
# In clearhead-cli/build.rs or separate script
type-sitter --rust \
  --parser ../tree-sitter-actions \
  --output src/generated/
```

Then hand-write impl blocks in `src/models/`.

---

## Summary of Key Decisions

| Decision | Status | Impact |
|----------|--------|--------|
| V3 BFO/CCO ontology | ✅ Done | Foundation for everything |
| Ontology extension | ✅ Decided | Eliminates config files |
| JTD for codegen | ✅ Decided | Better type generation |
| Generate grammar | ✅ Decided | Automation wins |
| SHACL validation | ✅ Done | Semantic correctness |
| Three-layer ontology | ✅ Decided | Clean architecture |
| Parser → Rust structs | ✅ Decided | Proper flow |

---

## Principles Underlying All Decisions

1. **Single Source of Truth:** Ontology drives everything
2. **Generate Structure, Hand-Write Behavior:** Clear boundary
3. **Standards First:** Use W3C, BFO, CCO when possible
4. **Automation Over Manual:** Generate rather than hand-maintain
5. **Semantic Correctness:** Types + SHACL validation
6. **Maximum Leverage:** One change propagates through stack

---

## Related Documentation

- [README.md](./README.md) - Vision and pipeline
- [ARCHITECTURE.md](./ARCHITECTURE.md) - Technical architecture
- [ontology/BFO_CCO_ALIGNMENT.md](./ontology/BFO_CCO_ALIGNMENT.md) - V3 rationale
- [ontology/SCHEMA_GENERATION_DECISION.md](./ontology/SCHEMA_GENERATION_DECISION.md) - JTD vs JSON Schema

---

**When to Update This Document:**
- Major architectural decisions
- Changes to generation pipeline
- Trade-off reconsiderations
- Lessons learned from implementation

**Version:** 1.0
**Authors:** Clearhead Platform Team
