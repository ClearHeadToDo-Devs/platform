# Clearhead Platform Architecture

**The Definitive Guide to Ontology-Driven Development**

> **TL;DR**: This platform uses OWL ontologies and SHACL constraints as the single source of semantic truth. SHACL shapes drive automatic generation of JSON Schemas, grammar rules, and type definitions, while implementations provide the behavior. This creates a "small waist" architecture where semantic changes flow automatically through all layers.

## Table of Contents

1. [Introduction: Ontology-Driven Development](#introduction-ontology-driven-development)
2. [The Layer Model](#the-layer-model)
3. [SHACL as the Data Flow Hub](#shacl-as-the-data-flow-hub)
4. [Generation vs Hand-Written Boundaries](#generation-vs-hand-written-boundaries)
5. [The Role of Reasoners](#the-role-of-reasoners)
6. [Concrete Example: Priority Property Flow](#concrete-example-priority-property-flow)
7. [Practical Workflows](#practical-workflows)
8. [Repository Guide](#repository-guide)
9. [Current State & Next Steps](#current-state--next-steps)
10. [Decision Rationales](#decision-rationales)

---

## Introduction: Ontology-Driven Development

### Philosophy

The Clearhead platform is built on **ontology-driven development** - using formal semantic definitions (OWL ontologies) combined with data constraints (SHACL shapes) as the **single source of truth** for all downstream implementations.

This approach provides:

- **Semantic Consistency**: All tools share the same understanding of domain concepts
- **Automatic Propagation**: Changes to the ontology flow to all implementations
- **Minimal Coordination**: New tools can be added without modifying existing ones
- **Clear Boundaries**: Separation between semantic truth and implementation details

### The "Small Waist" Architecture

Like the internet protocol stack, we use a thin, stable interface layer (the ontology + SHACL shapes) that connects many different implementations:

```
┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│  Web GUI     │  │  Mobile App  │  │  TUI         │  │  Plugins     │
└──────┬───────┘  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘
       │                 │                 │                 │
       └─────────────────┴─────────────────┴─────────────────┘
                                │
                    ┌───────────▼────────────┐
                    │   Clearhead CLI        │
                    │   (Rust)               │
                    └───────────┬────────────┘
                                │
                    ┌───────────▼────────────┐
                    │   Tree-Sitter Parser   │
                    │   (JavaScript)         │
                    └───────────┬────────────┘
                                │
         ┌──────────────────────┴──────────────────────┐
         │                                             │
    ┌────▼────────┐         ┌───────────────────┐     │
    │ JSON Schema │         │  Syntax Mapping   │     │
    │ (Generated) │         │  (Bridge Layer)   │     │
    └────┬────────┘         └────┬──────────────┘     │
         │                       │                     │
         └───────────┬───────────┘                     │
                     │                                 │
        ┌────────────▼───────────┐    ┌───────────────▼─────────┐
        │  SHACL Shapes          │    │  OWL Ontology           │
        │  (Constraints)         │    │  (Semantic Definitions) │
        │  actions-shapes.ttl    │    │  actions-vocabulary.ttl │
        └────────────────────────┘    └─────────────────────────┘
                     │
                     │
                THE "SMALL WAIST"
           (Minimal, Stable Interface)
```

**Key Insight**: The ontology and SHACL shapes are the only files that need to be manually edited for semantic changes. Everything else is either generated or informed by these foundational files.

---

## The Layer Model

The architecture consists of six distinct layers, each with specific responsibilities:

### Layer 1: OWL Ontology (Semantic Definitions)

**Files**: `ontology/actions-vocabulary.ttl`

**Purpose**: Defines what CAN exist in the domain

**Responsibilities**:
- Class hierarchy (Action, RootAction, ChildAction, LeafAction)
- Property definitions (name, priority, context, etc.)
- Domain and range constraints
- Disjointness declarations (RootAction ⊓ LeafAction = ∅)
- Schema.org alignment via `rdfs:subPropertyOf`
- Functional property declarations

**Validated By**: OWL Reasoners (HermiT, Pellet)

**Example**:
```turtle
actions:Action a owl:Class ;
    rdfs:subClassOf schema:Action ;
    rdfs:label "Action" ;
    rdfs:comment "A task or action to be completed" .

actions:priority a owl:DatatypeProperty ;
    rdfs:subPropertyOf schema:propertyID ;
    rdfs:domain actions:Action ;
    rdfs:range xsd:integer ;
    rdfs:comment "Priority level using Eisenhower Matrix (1=urgent+important, 4=neither)" .
```

### Layer 2: SHACL Shapes (Data Constraints)

**Files**: `ontology/actions-shapes.ttl`

**Purpose**: Defines what MUST exist for valid data

**Responsibilities**:
- Required fields (`sh:minCount 1`)
- Value constraints (ranges, patterns, formats)
- Cardinality restrictions
- Business rules (e.g., doDateTime < dueDateTime)
- Temporal validation
- UUID format patterns

**Validated By**: SHACL Validators (pySHACL)

**Example**:
```turtle
actions:ActionPriorityConstraint a sh:PropertyShape ;
    sh:path actions:priority ;
    sh:datatype xsd:integer ;
    sh:minInclusive 1 ;
    sh:maxInclusive 4 ;
    sh:message "Priority must be between 1 (highest) and 4 (lowest)" .

actions:ActionNameConstraint a sh:PropertyShape ;
    sh:path schema:name ;
    sh:minCount 1 ;
    sh:maxCount 1 ;
    sh:datatype xsd:string ;
    sh:message "Action must have exactly one name" .
```

**THIS IS THE HUB**: SHACL shapes drive all downstream generation!

### Layer 3: JSON Schema (Implementation Contract)

**Files**: `ontology/schemas/*.schema.json`

**Purpose**: Provides implementation-agnostic validation schemas

**Generated From**: OWL Ontology + SHACL Shapes

**Generation Command**: `uv run invoke generate-schemas`

**Responsibilities**:
- Type definitions (string, integer, boolean, etc.)
- Validation rules (min/max, patterns, required fields)
- Documentation (descriptions from ontology)
- Cross-language compatibility

**Example** (generated):
```json
{
  "type": "object",
  "title": "Action",
  "required": ["name", "priority", "state"],
  "properties": {
    "priority": {
      "type": "integer",
      "minimum": 1,
      "maximum": 4,
      "description": "Priority level using Eisenhower Matrix"
    },
    "name": {
      "type": "string",
      "description": "The name or title of the action"
    }
  }
}
```

**Used By**:
- Tree-sitter syntax mapping
- Rust struct generation
- API documentation
- Database schema generation
- TypeScript type generation

### Layer 4: Syntax Mapping (Semantic → Syntactic Bridge)

**Files**: `tree-sitter-actions/src/syntax_mapping.js`

**Purpose**: Maps semantic properties to file format syntax

**Informed By**: JSON Schema (which came from SHACL)

**Responsibilities**:
- Symbol assignments (priority → `!`, context → `+`)
- Grammar rule hints (choice vs pattern vs integer)
- Value mappings (minimum/maximum → choice values)
- Format examples

**Example**:
```javascript
{
    property: "priority",
    symbol: "!",
    rule: "choice",
    values: [1, 2, 3, 4],  // From JSON Schema min/max
    context: "any_level",
    example: "!2"
}
```

**Generates**:
- `.actions` file examples from JSON data
- Grammar rule suggestions for tree-sitter
- Test inputs for parser

### Layer 5: Implementations (Parsers & Tools)

#### Tree-Sitter Parser

**Repository**: `tree-sitter-actions/`

**Purpose**: Parse `.actions` text files into Abstract Syntax Trees

**Responsibilities**:
- Grammar definition (`grammar.js`)
- Syntax validation (correct structure)
- Parse tree generation
- Syntax highlighting queries
- Parser corpus tests

**Example Grammar** (hand-written, informed by syntax mapping):
```javascript
module.exports = grammar({
  name: 'actions',
  rules: {
    action: $ => seq(
      $.checkbox,
      $.name,
      repeat(choice(
        $.priority,    // Hand-written: seq('!', choice('1','2','3','4'))
        $.context,     // Hand-written: seq('+', /@[a-z]+/)
        // ... other properties
      ))
    ),
    priority: $ => seq('!', choice('1', '2', '3', '4'))
  }
});
```

**What's Generated**:
- ✅ Example `.actions` files from JSON examples
- ✅ Test input strings

**What's Hand-Written**:
- ✋ `grammar.js` (informed by syntax mapping)
- ✋ Parser corpus tests (expected parse trees)
- ✋ Syntax highlighting queries

#### Clearhead CLI

**Repository**: `clearhead-cli/`

**Purpose**: Validate, manipulate, and manage `.actions` files

**Responsibilities**:
- File parsing (using tree-sitter)
- Semantic validation (using SHACL)
- Business logic (complete, schedule, query)
- File I/O operations
- TUI interface

**Example Struct** (generated):
```rust
// Generated from JSON Schema
#[derive(Debug, Serialize, Deserialize)]
pub struct Action {
    pub name: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub priority: Option<u8>,  // From schema "type": "integer"
    #[serde(skip_serializing_if = "Option::is_none")]
    pub context: Option<String>,
    // ... other fields from schema
}
```

**Example Implementation** (hand-written):
```rust
impl Action {
    /// Parse an actions file using tree-sitter
    pub fn from_file(path: &Path) -> Result<Vec<Action>> {
        // Hand-written parsing logic
    }

    /// Validate against SHACL constraints
    pub fn validate(&self) -> ValidationResult {
        // Calls pySHACL or similar
    }

    /// Mark action as completed
    pub fn complete(&mut self) -> Result<()> {
        self.state = "completed".into();
        self.completed_date_time = Some(Utc::now());
        self.validate()?;
        Ok(())
    }
}
```

**What's Generated**:
- ✅ Struct field definitions
- ✅ Field types and optionality
- ✅ Serde annotations

**What's Hand-Written**:
- ✋ `impl` blocks with methods
- ✋ Business logic
- ✋ Tests
- ✋ Error handling
- ✋ File I/O

### Layer 6: Runtime Validation

**Purpose**: Ensure data quality at runtime

**Flow**:
```
User creates: [ ] Task !5 +@office
       │
       ├─► Tree-sitter parses
       │   ✓ Syntax valid (grammar accepts it)
       │
       ├─► Convert to Rust struct
       │   Action { priority: Some(5), context: Some("@office"), ... }
       │   ✓ Type safe
       │
       └─► SHACL Validation
           ✗ FAIL: "Priority must be between 1 and 4"
           User sees error message
```

**Key Point**: Syntactic validation (tree-sitter) catches structure errors, semantic validation (SHACL) catches constraint violations.

---

## SHACL as the Data Flow Hub

SHACL shapes are the **central driver** of the entire architecture. Every constraint flows through SHACL:

```
                    ┌──────────────────────────┐
                    │   OWL Ontology           │
                    │   (Defines properties)   │
                    └───────────┬──────────────┘
                                │
                                ↓
                    ┌──────────────────────────┐
                    │   SHACL Shapes           │
                    │   *** THE HUB ***        │
                    │                          │
                    │  • sh:minInclusive 1     │
                    │  • sh:maxInclusive 4     │
                    │  • sh:pattern "^@.*"     │
                    │  • sh:minCount 1         │
                    │  • sh:datatype xsd:int   │
                    └────────────┬─────────────┘
                                 │
          ┌──────────────────────┼──────────────────────┐
          │                      │                      │
          ▼                      ▼                      ▼
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│  JSON Schema    │  │ Syntax Mapping  │  │ Runtime         │
│                 │  │                 │  │ Validation      │
│ "minimum": 1    │  │ values: [1,2,3,4│  │ validate()      │
│ "maximum": 4    │  │ symbol: "!"     │  │ -> pySHACL      │
└────────┬────────┘  └────────┬────────┘  └─────────────────┘
         │                    │
         ▼                    ▼
┌─────────────────┐  ┌─────────────────┐
│ Rust Types      │  │ Grammar Rules   │
│                 │  │                 │
│ Option<u8>      │  │ choice('1',...) │
└─────────────────┘  └─────────────────┘
```

**Flow Example**: Adding a constraint

1. **Designer adds to SHACL**: `sh:minInclusive 1 ; sh:maxInclusive 4`
2. **Schema Generator reads**: Creates `"minimum": 1, "maximum": 4` in JSON Schema
3. **Syntax Mapping reads**: Generates `values: [1, 2, 3, 4]` for grammar
4. **Grammar uses**: `choice('1', '2', '3', '4')`
5. **Type Generator reads**: Creates `Option<u8>` with range check
6. **Runtime Validator uses**: Original SHACL shapes for validation

**One change, six updates, zero manual coordination!**

---

## Generation vs Hand-Written Boundaries

Understanding what to generate versus what to hand-write is crucial for maintaining the architecture:

### Tree-Sitter Parser

| Component | Generate or Hand-Write | Source | Rationale |
|-----------|------------------------|--------|-----------|
| `.actions` example files | ✅ Generate | JSON examples + syntax mapping | Ensures consistency between formats |
| Test input strings | ✅ Generate | JSON examples + syntax mapping | Automatic coverage of all properties |
| `grammar.js` | ✋ Hand-write | Informed by syntax mapping | Tree-sitter DSL requires expertise |
| Corpus tests (parse trees) | ✋ Hand-write | Generated inputs as basis | Parse tree structure is implementation detail |
| Syntax highlighting queries | ✋ Hand-write | Grammar structure | Editor-specific patterns |

**Why not generate grammar.js?**
- Tree-sitter's grammar DSL requires careful optimization
- Error recovery rules are implementation-specific
- Performance tuning needs human judgment
- BUT syntax mapping provides the constraints to implement

### Rust CLI

| Component | Generate or Hand-Write | Source | Rationale |
|-----------|------------------------|--------|-----------|
| Struct field definitions | ✅ Generate | JSON Schema | Direct 1:1 mapping |
| Field types (`u8`, `String`, etc.) | ✅ Generate | JSON Schema types | Mechanical conversion |
| Serde annotations | ✅ Generate | JSON Schema structure | Standard patterns |
| `impl` blocks with methods | ✋ Hand-write | Business requirements | Domain-specific logic |
| Business logic (`complete()`, `schedule()`) | ✋ Hand-write | Application needs | Not in ontology |
| Tests | ✋ Hand-write | Use cases | Test business behavior |
| Error handling | ✋ Hand-write | UX requirements | User-facing messages |
| File I/O | ✋ Hand-write | Platform needs | Implementation detail |

**Why not generate impl blocks?**
- Business logic is application-specific, not semantic
- Error messages need human-crafted UX
- Optimization strategies vary by use case
- BUT structs ensure type safety from schema

### Summary Table

| Layer | Generated Artifacts | Hand-Written Artifacts | Bridge |
|-------|---------------------|------------------------|--------|
| **OWL** | None (source of truth) | All ontology definitions | N/A |
| **SHACL** | None (source of truth) | All constraint shapes | N/A |
| **JSON Schema** | Entire schema files | None | Generator script |
| **Syntax Mapping** | None (manually curated) | All mappings | Reads JSON Schema |
| **Tree-Sitter** | Example files | Grammar, corpus tests | Syntax mapping |
| **Rust CLI** | Struct definitions | Impl blocks, tests, logic | Schema → codegen |

**Golden Rule**: Generate **data structures**, hand-write **behavior**.

---

## The Role of Reasoners

OWL reasoners and SHACL validators serve different but complementary purposes:

### OWL Reasoners (HermiT, Pellet, Owlready2)

**When**: Design time (during ontology development)

**Purpose**: Validate logical consistency of the ontology itself

**Checks**:
- ✅ Class satisfiability (no impossible classes)
- ✅ Disjointness violations (RootAction ⊓ LeafAction = ∅)
- ✅ Property domain/range correctness
- ✅ Functional property consistency
- ✅ Ontology coherence

**Example Test**:
```python
def test_root_and_leaf_are_disjoint():
    """Reasoner catches if action is both root and leaf"""
    action = URIRef("http://example.org/action1")

    # Declare as both (should fail)
    g.add((action, RDF.type, actions.RootAction))
    g.add((action, RDF.type, actions.LeafAction))

    result = run_reasoner(g)
    assert not result.is_consistent  # Reasoner detects contradiction
```

**Command**: `uv run pytest tests/test_owl_reasoning.py`

**Files Tested**: `actions-vocabulary.ttl` (the ontology)

### SHACL Validators (pySHACL)

**When**: Design time (testing examples) AND runtime (validating user data)

**Purpose**: Validate data instances against constraints

**Checks**:
- ✅ Required fields present
- ✅ Value ranges satisfied (priority 1-4)
- ✅ Pattern compliance (UUID format, context pattern)
- ✅ Cardinality constraints (min/max occurrences)
- ✅ Business rules (doDateTime < dueDateTime)

**Example Test**:
```python
def test_priority_out_of_range():
    """SHACL catches invalid priority value"""
    data = {
        "@type": "actions:Action",
        "name": "Test",
        "priority": 5  # Invalid!
    }

    result = validate_shacl(data, shapes_graph)
    assert not result.conforms
    assert "Priority must be between 1 and 4" in result.results_text
```

**Command**: `uv run pytest tests/test_shacl_validation.py`

**Files Tested**: `actions-shapes.ttl` (the constraints) against example data

### Two-Layer Testing Strategy

```
┌─────────────────────────────────────────────────────┐
│ Layer 1: OWL Reasoning (Ontology Tests)            │
│ ────────────────────────────────────────────────────│
│ $ uv run pytest tests/test_owl_reasoning.py         │
│                                                     │
│ Tests:                                              │
│ • Is the ontology logically consistent?            │
│ • Are disjoint classes properly separated?         │
│ • Do properties have correct domains/ranges?       │
│ • Are functional properties correctly declared?    │
│                                                     │
│ Tool: HermiT/Pellet reasoner via Owlready2         │
│ Input: actions-vocabulary.ttl                      │
│ Output: Consistency report                         │
└─────────────────────────────────────────────────────┘
                         │
                         ↓ Ontology is consistent
                         │
┌─────────────────────────────────────────────────────┐
│ Layer 2: SHACL Validation (Data Tests)             │
│ ────────────────────────────────────────────────────│
│ $ uv run pytest tests/test_shacl_validation.py      │
│                                                     │
│ Tests:                                              │
│ • Does this data satisfy constraints?              │
│ • Are required fields present?                     │
│ • Do values fall within allowed ranges?            │
│ • Do patterns match (UUID, context, etc.)?         │
│                                                     │
│ Tool: pySHACL validator                            │
│ Input: actions-shapes.ttl + example data           │
│ Output: Validation report with violations          │
└─────────────────────────────────────────────────────┘
```

**When to Use Each**:

| Scenario | Use OWL Reasoner | Use SHACL Validator |
|----------|------------------|---------------------|
| Designing ontology classes | ✅ Yes | ❌ No |
| Adding new properties | ✅ Yes | ❌ No |
| Defining constraints | ❌ No | ✅ Yes |
| Testing example data | ❌ No | ✅ Yes |
| Runtime data validation | ❌ No | ✅ Yes |
| Checking disjointness | ✅ Yes | ❌ No |
| Validating value ranges | ❌ No | ✅ Yes |

### Optional: Runtime Inference

Advanced use case: Use reasoners at runtime to infer facts

```rust
impl Action {
    pub fn infer_properties(&mut self) -> Result<()> {
        // Convert to RDF
        let mut graph = self.to_rdf()?;

        // Run reasoner
        let reasoner = OwlReasoner::new();
        reasoner.infer(&mut graph)?;

        // Extract inferred facts
        // e.g., "If has_child_action count = 0, then is LeafAction"
        if graph.contains((self.uri, RDF.type, actions.LeafAction)) {
            self.inferred_leaf = true;
        }

        Ok(())
    }
}
```

**Note**: This is optional and typically not needed for basic validation. SHACL handles most runtime needs.

---

## Concrete Example: Priority Property Flow

Let's trace the `priority` property through every layer to see how changes propagate:

### Step 1: Designer's Intent

> "Actions should have a priority from 1 (most urgent/important) to 4 (least urgent/important) based on the Eisenhower Matrix."

### Step 2: OWL Ontology Definition

**File**: `ontology/actions-vocabulary.ttl`

```turtle
actions:priority a owl:DatatypeProperty ;
    rdfs:subPropertyOf schema:propertyID ;
    rdfs:domain actions:Action ;
    rdfs:range xsd:integer ;
    rdfs:label "Priority" ;
    rdfs:comment "Priority level using Eisenhower Matrix (1=urgent+important, 4=neither)" .
```

**What it says**: "Actions CAN have a priority property, and if they do, it's an integer."

### Step 3: SHACL Constraint Definition

**File**: `ontology/actions-shapes.ttl`

```turtle
actions:ActionPriorityConstraint a sh:PropertyShape ;
    sh:path actions:priority ;
    sh:datatype xsd:integer ;
    sh:minInclusive 1 ;
    sh:maxInclusive 4 ;
    sh:message "Priority must be between 1 (highest) and 4 (lowest)" .
```

**What it says**: "Priority MUST be between 1 and 4 if present."

### Step 4: JSON Schema Generation

**Command**: `uv run invoke generate-schemas`

**Generated File**: `ontology/schemas/action.schema.json`

```json
{
  "properties": {
    "priority": {
      "type": "integer",
      "minimum": 1,
      "maximum": 4,
      "description": "Priority level using Eisenhower Matrix (1=urgent+important, 4=neither)"
    }
  }
}
```

**Translation**: `sh:minInclusive 1` → `"minimum": 1`, `sh:maxInclusive 4` → `"maximum": 4`

### Step 5: Syntax Mapping

**File**: `tree-sitter-actions/src/syntax_mapping.js`

```javascript
{
    property: "priority",
    symbol: "!",
    rule: "choice",
    values: [1, 2, 3, 4],  // Derived from JSON Schema min/max
    context: "any_level",
    example: "!2"
}
```

**Decision**: Use `!` symbol, generate explicit choices from the range.

### Step 6: Example Generation

**Command**: `node json_to_actions_converter.js`

**Input**: `ontology/examples/valid_action.json`
```json
{
  "name": "Review quarterly reports",
  "priority": 2
}
```

**Generated Output**: `tree-sitter-actions/examples/valid_action.actions`
```
[ ] Review quarterly reports !2
```

### Step 7: Tree-Sitter Grammar (Hand-Written)

**File**: `tree-sitter-actions/grammar.js`

```javascript
// Hand-written, informed by syntax mapping
module.exports = grammar({
  name: 'actions',
  rules: {
    // ...
    priority: $ => seq(
      '!',
      choice('1', '2', '3', '4')  // From syntax mapping values
    ),
    // ...
  }
});
```

**Why hand-written?**: Tree-sitter requires optimization, error recovery, performance tuning.

### Step 8: Parser Corpus Test (Hand-Written)

**File**: `tree-sitter-actions/test/corpus/properties.txt`

```
================
priority property
================
[ ] Task !2

---

(action_list
  (root_action
    (checkbox)
    (name)
    (priority
      (priority_symbol)
      (priority_value))))
```

**Why hand-written?**: Parse tree structure is an implementation detail, not semantic.

### Step 9: Rust Struct Generation

**Command**: `cargo build` (runs `build.rs`)

**Generated File**: `clearhead-cli/src/generated.rs`

```rust
// GENERATED FILE - DO NOT EDIT
#[derive(Debug, Serialize, Deserialize)]
pub struct Action {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub priority: Option<u8>,  // From JSON Schema "type": "integer", "minimum": 1
    // ... other fields
}
```

**Translation**: `"type": "integer"` with `"maximum": 4` → `Option<u8>`

### Step 10: Rust Implementation (Hand-Written)

**File**: `clearhead-cli/src/models/action.rs`

```rust
impl Action {
    /// Validate priority is in valid range
    pub fn validate_priority(&self) -> Result<(), ValidationError> {
        if let Some(p) = self.priority {
            if p < 1 || p > 4 {
                return Err(ValidationError::InvalidPriority(p));
            }
        }
        Ok(())
    }

    /// Check if this is a high-priority action
    pub fn is_urgent(&self) -> bool {
        self.priority.map_or(false, |p| p == 1)
    }
}

#[cfg(test)]
mod tests {
    #[test]
    fn test_priority_out_of_range() {
        let action = Action {
            name: "Test".into(),
            priority: Some(5),  // Invalid!
            ..Default::default()
        };
        assert!(action.validate_priority().is_err());
    }
}
```

**Why hand-written?**: Business logic (`is_urgent()`) and validation logic are application-specific.

### Step 11: Runtime Flow

```
User creates file:
[ ] Important task !5

        ↓

Tree-sitter parses:
✗ FAIL: Grammar only accepts '1', '2', '3', or '4'
Error: Unexpected character '5' after '!'

        OR (if grammar was permissive)

Tree-sitter parses:
✓ Success: (action (priority "5"))

        ↓

Convert to Rust:
Action { priority: Some(5), ... }

        ↓

SHACL Validation:
let rdf = action.to_rdf();
let result = validate_shacl(&rdf, shapes_graph);

✗ FAIL: ValidationError
Message: "Priority must be between 1 (highest) and 4 (lowest)"
Constraint: sh:minInclusive 1, sh:maxInclusive 4
```

### The Complete Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│ Designer: "Priority should be 1-4"                          │
└────────────────────────┬────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────┐
│ OWL: actions:priority rdfs:range xsd:integer                │
└────────────────────────┬────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────┐
│ SHACL: sh:minInclusive 1 ; sh:maxInclusive 4                │
│ *** THIS IS THE SOURCE OF CONSTRAINT ***                    │
└────────────────────────┬────────────────────────────────────┘
                         │
        ┌────────────────┼────────────────┐
        ↓                ↓                ↓
┌─────────────┐  ┌──────────────┐  ┌─────────────────┐
│ JSON Schema │  │Syntax Mapping│  │Runtime Validator│
│ min:1,max:4 │  │values:[1..4] │  │Uses SHACL direct│
└──────┬──────┘  └──────┬───────┘  └─────────────────┘
       ↓                ↓
┌─────────────┐  ┌──────────────┐
│ Rust        │  │ Tree-sitter  │
│ Option<u8>  │  │ choice(1..4) │
└─────────────┘  └──────────────┘
```

**One constraint definition, six artifacts, complete consistency!**

---

## Practical Workflows

### Workflow 1: Adding a New Property

Let's add an **"energy level"** property (low/medium/high) to actions.

#### Step 1: Update OWL Ontology

**File**: `ontology/actions-vocabulary.ttl`

```turtle
actions:energyLevel a owl:DatatypeProperty ;
    rdfs:subPropertyOf schema:property ;
    rdfs:domain actions:Action ;
    rdfs:range xsd:string ;
    rdfs:label "Energy Level" ;
    rdfs:comment "Required energy level to complete this action" .
```

#### Step 2: Add SHACL Constraint

**File**: `ontology/actions-shapes.ttl`

```turtle
actions:ActionEnergyLevelConstraint a sh:PropertyShape ;
    sh:path actions:energyLevel ;
    sh:datatype xsd:string ;
    sh:in ("low" "medium" "high") ;
    sh:message "Energy level must be one of: low, medium, high" .
```

#### Step 3: Add Example Data

**File**: `ontology/examples/energy_example.json`

```json
{
  "name": "Deep work session",
  "priority": 1,
  "state": "active",
  "energyLevel": "high"
}
```

#### Step 4: Test Ontology

```bash
cd ontology
uv run pytest tests/test_shacl_validation.py
```

Should pass with new example.

#### Step 5: Generate JSON Schema

```bash
cd ontology
uv run invoke generate-schemas
```

Check `schemas/action.schema.json`:
```json
{
  "properties": {
    "energyLevel": {
      "type": "string",
      "enum": ["low", "medium", "high"],
      "description": "Required energy level to complete this action"
    }
  }
}
```

#### Step 6: Update Syntax Mapping

**File**: `tree-sitter-actions/src/syntax_mapping.js`

```javascript
{
    property: "energyLevel",
    symbol: "E",
    rule: "choice",
    values: ["low", "medium", "high"],
    context: "any_level",
    example: "Ehigh"
}
```

#### Step 7: Generate Example

```bash
cd tree-sitter-actions
node src/json_to_actions_converter.js

# Output:
# [ ] Deep work session !1 Ehigh
```

#### Step 8: Update Grammar

**File**: `tree-sitter-actions/grammar.js`

```javascript
energy_level: $ => seq(
  'E',
  choice('low', 'medium', 'high')
),
```

#### Step 9: Add Parser Test

**File**: `tree-sitter-actions/test/corpus/properties.txt`

```
================
energy level property
================
[ ] Deep work Ehigh

---

(action
  (name)
  (energy_level
    (energy_symbol)
    (energy_value)))
```

#### Step 10: Build Parser

```bash
cd tree-sitter-actions
npm install
npm run build
npm test
```

#### Step 11: Regenerate Rust Structs

```bash
cd clearhead-cli
cargo clean
cargo build

# Check generated.rs for:
# pub energy_level: Option<String>,
```

#### Step 12: Add Business Logic

**File**: `clearhead-cli/src/models/action.rs`

```rust
impl Action {
    /// Check if action requires high energy
    pub fn requires_high_energy(&self) -> bool {
        self.energy_level.as_deref() == Some("high")
    }

    /// Get recommended time of day based on energy
    pub fn recommended_time(&self) -> &str {
        match self.energy_level.as_deref() {
            Some("high") => "morning",
            Some("medium") => "afternoon",
            Some("low") => "evening",
            _ => "anytime"
        }
    }
}

#[test]
fn test_energy_validation() {
    let action = Action {
        name: "Test".into(),
        energy_level: Some("invalid".into()),
        ..Default::default()
    };
    assert!(action.validate().is_err());
}
```

#### Step 13: Test End-to-End

```bash
# In clearhead-cli
cargo test

# Test file:
echo "[ ] Deep work Einvalid" > test.actions
cargo run -- validate test.actions

# Should fail: "Energy level must be one of: low, medium, high"
```

#### Summary

**Manual Steps**: 4 (OWL, SHACL, syntax mapping, grammar)
**Generated Steps**: 3 (JSON Schema, examples, Rust struct)
**Implementation Steps**: 3 (parser test, business logic, tests)

**Total Time**: ~30 minutes for a new property with full integration!

### Workflow 2: Modifying a Constraint

Let's change priority from 1-4 to 1-5.

#### Step 1: Update SHACL Only

**File**: `ontology/actions-shapes.ttl`

```turtle
actions:ActionPriorityConstraint a sh:PropertyShape ;
    sh:path actions:priority ;
    sh:datatype xsd:integer ;
    sh:minInclusive 1 ;
    sh:maxInclusive 5 ;  # Changed from 4 to 5
    sh:message "Priority must be between 1 (highest) and 5 (lowest)" .
```

#### Step 2: Regenerate JSON Schema

```bash
cd ontology
uv run invoke generate-schemas

# Check schemas/action.schema.json:
# "maximum": 5  ← Changed
```

#### Step 3: Update Syntax Mapping

**File**: `tree-sitter-actions/src/syntax_mapping.js`

```javascript
values: [1, 2, 3, 4, 5],  // Added 5
```

#### Step 4: Update Grammar

**File**: `tree-sitter-actions/grammar.js`

```javascript
priority: $ => seq('!', choice('1', '2', '3', '4', '5')),  // Added '5'
```

#### Step 5: Rebuild Everything

```bash
# Parser
cd tree-sitter-actions
npm run build
npm test

# CLI
cd clearhead-cli
cargo clean && cargo build
cargo test
```

**Done!** One constraint change propagated through 4 layers in ~5 minutes.

### Workflow 3: Testing Changes Across Layers

```bash
# Layer 1: Ontology consistency
cd ontology
uv run pytest tests/test_owl_reasoning.py

# Layer 2: SHACL validation
uv run pytest tests/test_shacl_validation.py

# Layer 3: Schema generation
uv run invoke generate-schemas
uv run invoke test-examples

# Layer 4: Parser
cd ../tree-sitter-actions
npm test

# Layer 5: CLI
cd ../clearhead-cli
cargo test

# Layer 6: Integration
cargo run -- validate ../ontology/examples/*.actions
```

---

## Repository Guide

### `/` (Meta Repository)

**Purpose**: Container for all submodules

**Key Files**:
- `README.md` - Project overview
- `ARCHITECTURE.md` - This file (THE definitive guide)
- `CLAUDE.md` - AI assistant context
- `.gitmodules` - Submodule definitions

**Commands**:
```bash
git submodule update --init --recursive  # Initialize all submodules
git submodule update --remote            # Update all to latest
```

### `ontology/`

**Purpose**: Semantic foundation (OWL + SHACL)

**Key Files**:
- `actions-vocabulary.ttl` - OWL ontology (THE source of truth)
- `actions-shapes.ttl` - SHACL constraints (drives generation)
- `schemas/` - Generated JSON Schemas
- `examples/` - Test data
- `tests/` - OWL reasoning + SHACL validation tests

**Commands**:
```bash
uv run pytest                    # Run all tests
uv run invoke generate-schemas   # Generate JSON Schemas
uv run invoke validate           # Validate ontology syntax
uv run invoke full-pipeline      # Complete workflow
```

**What to Edit**:
- ✅ `actions-vocabulary.ttl` - Add classes, properties
- ✅ `actions-shapes.ttl` - Add/modify constraints
- ✅ `examples/*.json` - Add test cases
- ❌ `schemas/` - Never edit (generated)

### `tree-sitter-actions/`

**Purpose**: Parser for `.actions` file format

**Key Files**:
- `grammar.js` - Tree-sitter grammar (hand-written)
- `src/syntax_mapping.js` - Semantic → syntactic bridge
- `test/corpus/` - Parser tests
- `examples/` - Generated example files

**Commands**:
```bash
npm install                              # Install dependencies
npm run build                            # Build parser
npm test                                 # Run corpus tests
node src/json_to_actions_converter.js    # Generate examples
```

**What to Edit**:
- ✅ `grammar.js` - Refine parsing rules
- ✅ `src/syntax_mapping.js` - Map new properties
- ✅ `test/corpus/` - Add parser tests
- ❌ `examples/` - Generated from ontology

### `clearhead-cli/`

**Purpose**: CLI tool for managing `.actions` files

**Key Files**:
- `build.rs` - Code generation at compile time
- `src/generated.rs` - Generated structs
- `src/models/` - Hand-written implementations
- `src/main.rs` - CLI entry point

**Commands**:
```bash
cargo build                        # Build (runs codegen)
cargo test                         # Run tests
cargo run -- validate <file>       # Validate file
cargo run -- list --priority 1     # Query actions
```

**What to Edit**:
- ✅ `src/models/` - Business logic
- ✅ `src/commands/` - CLI commands
- ✅ `tests/` - Integration tests
- ❌ `src/generated.rs` - Generated structs

### Future Repositories

- `clearhead-lsp/` - Language Server Protocol implementation
- `clearhead.nvim/` - Neovim plugin
- `clearhead.todo/` - Web GUI

---

## Current State & Next Steps

### What's Working Now ✅

Based on our discussion and existing code:

1. **Ontology Layer**:
   - ✅ OWL ontology with Schema.org alignment
   - ✅ SHACL shapes with comprehensive constraints
   - ✅ OWL reasoning tests
   - ✅ SHACL validation tests

2. **Generation Layer**:
   - ✅ JSON Schema generation from OWL + SHACL
   - ✅ Syntax mapping system
   - ✅ Example file generation

3. **Tree-Sitter**:
   - ✅ Grammar for basic actions
   - ✅ Syntax mapping configuration
   - ✅ Example generation from JSON

4. **Rust CLI**:
   - ✅ Basic project structure
   - ⚠️ Struct generation (needs implementation)
   - ⚠️ Tree-sitter integration (needs implementation)

### Gaps Identified 🔍

From our conversation, here are the missing pieces:

1. **Tree-Sitter**:
   - ❌ Missing symbols in grammar (`+`, `$`, `I`, `C`, `U`)
   - ❌ Advanced recurrence patterns
   - ⚠️ Parser corpus tests (need expansion)

2. **Rust CLI**:
   - ❌ Automated struct generation from JSON Schema
   - ❌ Tree-sitter integration for parsing
   - ❌ SHACL validation via pySHACL
   - ❌ Core commands (validate, list, add, complete)
   - ❌ Round-trip testing (.actions → struct → validate)

3. **Documentation**:
   - ✅ This architecture document (now complete!)
   - ⚠️ User guides (needed)
   - ⚠️ API documentation (needed)

### Immediate Next Steps (Priority Order)

#### Phase 1: Complete Tree-Sitter Parser (1-2 weeks)

1. **Add missing symbols to grammar**
   - Implement `+` (context)
   - Implement `$` (description)
   - Implement `I`, `C`, `U` (status symbols)

2. **Expand corpus tests**
   - Cover all 20 properties
   - Test error recovery
   - Test nested actions

3. **Validate against generated examples**
   - Parse all examples from ontology
   - Ensure 100% success rate

**Acceptance Criteria**: All generated `.actions` examples parse correctly with full test coverage.

#### Phase 2: Rust CLI Foundation (2-3 weeks)

1. **Implement struct generation**
   - Read JSON Schema
   - Generate Rust struct definitions
   - Include Serde annotations
   - Wire into `build.rs`

2. **Integrate tree-sitter**
   - Parse `.actions` files
   - Convert AST to Rust structs
   - Handle parse errors gracefully

3. **Add SHACL validation**
   - Call pySHACL via subprocess or FFI
   - Parse validation reports
   - Display user-friendly errors

4. **Implement core commands**
   - `validate <file>` - Parse + validate
   - `list` - Display actions with filtering
   - `add <name>` - Create new action

**Acceptance Criteria**: Can parse, validate, and manipulate `.actions` files end-to-end.

#### Phase 3: Testing & Documentation (1 week)

1. **Integration tests**
   - Round-trip tests (file → parse → struct → validate → file)
   - Property coverage tests
   - Error handling tests

2. **User documentation**
   - Getting started guide
   - File format specification
   - CLI command reference

3. **Developer documentation**
   - Contributing guide
   - Testing guide
   - Release process

**Acceptance Criteria**: New developers can understand and contribute to the project.

#### Phase 4: Advanced Features (3-4 weeks)

1. **TUI interface**
   - Interactive action management
   - Keyboard navigation
   - Filtering and search

2. **Advanced operations**
   - Bulk operations
   - Query language
   - Action templates

3. **Performance optimization**
   - Large file handling
   - Incremental parsing
   - Caching

**Acceptance Criteria**: Production-ready for real-world use.

### Long-Term Vision 🚀

1. **LSP Server** (clearhead-lsp)
   - Real-time validation
   - Autocomplete
   - Go to definition
   - Hover documentation

2. **Editor Plugins**
   - Neovim plugin (clearhead.nvim)
   - VS Code extension
   - Syntax highlighting packages

3. **Web Interface** (clearhead.todo)
   - Browser-based task management
   - Real-time sync
   - Mobile-responsive

4. **Ecosystem Growth**
   - Database connectors
   - API server
   - Mobile apps
   - Third-party integrations

---

## Decision Rationales

### Why OWL + SHACL instead of JSON Schema alone?

**Decision**: Use W3C standards (OWL + SHACL) as foundation, generate JSON Schema.

**Alternatives Considered**:
- Option A: JSON Schema as source of truth
- Option B: Custom DSL for constraints
- Option C: OWL + SHACL (chosen)

**Rationale**:
1. **Semantic Richness**: OWL provides inheritance, disjointness, reasoning
2. **Standards Compliance**: W3C standards ensure interoperability
3. **Tooling**: Existing tools (Protégé, reasoners, validators)
4. **Future-Proof**: Can generate many formats from one source
5. **Schema.org Alignment**: Natural extension of existing vocabularies

**Trade-off**: Steeper learning curve, but long-term benefits outweigh initial complexity.

### Why Generate Structs but Hand-Write Methods?

**Decision**: Generate data structures, hand-write behavior.

**Alternatives Considered**:
- Option A: Hand-write everything (too much duplication)
- Option B: Generate everything (loses flexibility)
- Option C: Generate structs, hand-write methods (chosen)

**Rationale**:
1. **Consistency**: Structs must match schema exactly → generate
2. **Flexibility**: Business logic varies by use case → hand-write
3. **Maintainability**: Schema changes auto-update structs
4. **Optimization**: Hand-written code can be optimized per use case

**Trade-off**: Requires discipline to not edit generated files, but clear separation of concerns is worth it.

### Why Tree-Sitter instead of Custom Parser?

**Decision**: Use tree-sitter for parsing.

**Alternatives Considered**:
- Option A: Custom recursive descent parser
- Option B: Parser combinator library (nom, pest)
- Option C: Tree-sitter (chosen)

**Rationale**:
1. **Error Recovery**: Tree-sitter handles partial/invalid input gracefully
2. **Incremental Parsing**: Efficient re-parsing of edited files
3. **Editor Integration**: Syntax highlighting, code navigation built-in
4. **Language Bindings**: Works from JavaScript, Rust, Python, etc.
5. **Ecosystem**: Supports LSP, formatters, linters

**Trade-off**: Learning tree-sitter's DSL, but ecosystem benefits are substantial.

### Why Not Generate Grammar from SHACL?

**Decision**: Syntax mapping informs grammar, but grammar is hand-written.

**Alternatives Considered**:
- Option A: Fully generate grammar.js from SHACL (too rigid)
- Option B: Hand-write grammar with no guidance (drift risk)
- Option C: Syntax mapping informs, human refines (chosen)

**Rationale**:
1. **Performance**: Hand-tuned grammars parse faster
2. **Error Recovery**: Humans write better error handling
3. **Readability**: Generated grammars are often cryptic
4. **Flexibility**: File format can diverge slightly from data model

**Trade-off**: Manual updates needed, but syntax mapping provides clear guidance.

### Why Submodules instead of Monorepo?

**Decision**: Separate repositories connected via git submodules.

**Alternatives Considered**:
- Option A: Monorepo with workspace (Cargo workspace, npm workspaces)
- Option B: Separate repos with package dependencies
- Option C: Separate repos with submodules (chosen)

**Rationale**:
1. **Clear Boundaries**: Each component has its own repository
2. **Independent Releases**: Tree-sitter can release without CLI changes
3. **Different Languages**: Python, JavaScript, Rust have different tooling
4. **Optional Checkout**: Users can clone just what they need

**Trade-off**: Submodule management complexity, but clear boundaries worth it.

---

## Conclusion

This architecture provides a **scalable, maintainable approach** to building a complete language toolchain from semantic foundations.

**Key Principles**:

1. **SHACL is the Hub**: All constraints flow through SHACL shapes
2. **Generate Data, Hand-Write Behavior**: Clear separation of concerns
3. **Small Waist Design**: Minimal, stable interface between layers
4. **Reasoners for Design, SHACL for Runtime**: Two-layer validation
5. **Syntax Mapping as Bridge**: Connects semantic and syntactic worlds

**Benefits Realized**:

- ✅ Single source of truth (ontology + SHACL)
- ✅ Automatic constraint propagation
- ✅ Clear generation boundaries
- ✅ Minimal manual coordination
- ✅ Scalable to new implementations

**The Vision**:

Edit the ontology once, see changes flow automatically through JSON Schemas, grammar rules, type definitions, and runtime validators. Add new tools without modifying existing ones. Maintain semantic consistency across all implementations.

**This is ontology-driven development.**

---

## Additional Resources

### Internal Documentation

- **[ONTOLOGY.md](./ontology/ONTOLOGY.md)** - Detailed semantic definitions
- **[SCHEMA_GENERATION.md](./ontology/docs/SCHEMA_GENERATION.md)** - JSON Schema generation
- **[TOOLCHAIN_ARCHITECTURE_PLAN.md](./ontology/docs/TOOLCHAIN_ARCHITECTURE_PLAN.md)** - Build pipeline
- **[SYNTAX_MAPPING.md](./tree-sitter-actions/docs/SYNTAX_MAPPING.md)** - Parser bridge layer
- **[CLAUDE.md](./CLAUDE.md)** - AI assistant context

### External Standards

- **[OWL 2 Specification](https://www.w3.org/TR/owl2-overview/)** - Web Ontology Language
- **[SHACL Specification](https://www.w3.org/TR/shacl/)** - Shapes Constraint Language
- **[Schema.org](https://schema.org/)** - Structured data vocabulary
- **[Tree-Sitter](https://tree-sitter.github.io/)** - Parser generation system
- **[JSON Schema](https://json-schema.org/)** - Schema definition standard

### Tools

- **[Protégé](https://protege.stanford.edu/)** - Ontology editor
- **[pySHACL](https://github.com/RDFLib/pySHACL)** - SHACL validation
- **[Owlready2](https://owlready2.readthedocs.io/)** - OWL reasoning
- **[Tree-sitter CLI](https://github.com/tree-sitter/tree-sitter/tree/master/cli)** - Parser development

---

**Version**: 1.0
**Last Updated**: 2025-01-19
**Authors**: Clearhead Platform Team
**Status**: Living Document

**Questions or suggestions?** Open an issue in the platform repository.
