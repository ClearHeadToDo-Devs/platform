# Context
This is a meta repository that contains the other projects as submodules that can be reviewed and edited from within one place

however, make no mistake these are all separate things and making sure the boundaries between them is clear will make all of this easier

This is my attempt at an "open, FAIR, realist, standard-first" approach to building a data platform that utilizes the powerful tools of:
- ontologies, in particular the prevalence of the Basic Formal Ontology (BFO) as a top-level ontology to ensure interoperability with other ontologies
    - as well as utilizing the Common Core Ontologies (CCO) to ensure that we are building on top of a solid foundation of well-established ontologies that have been built with interoperability in mind
        - in this way, our work is doing nothing but trying to make a domain-specific ontology as they advise, and because i was unable to find a CCO-enabled ontology that would fit this usecase. In an ideal world, some variation of this would exist already or this could serve as a common base, but for now, we are building out a platform to show this ontology has legs and can be used to do REAL work making REAL data and REAL tools

## Current Status (January 2025)

**Active Development:** V3 ontology with BFO/CCO alignment is the production path

- ✅ **V3 Ontology**: Complete BFO/CCO-aligned ontology (`ontology/actions-vocabulary.owl`)
- ✅ **V3 SHACL Shapes**: Comprehensive validation constraints (`ontology/actions-shapes-v3.ttl`)
- ✅ **Test Suite**: Full coverage with 14 passing tests
- 🚧 **JTD Generation**: Updating to use V3 SHACL (next step)
- 🚧 **Parser Ontology Extension**: Will extend V3 with file format concepts
- ⏳ **Grammar Generation**: Will generate from TypeScript types using type-sitter
- ⏳ **CLI Code Generation**: Will generate Rust structs from parser

**V2 Status:** Stable but superseded. V2 remains available in `ontology/v2/` for reference but new development uses V3.

See `ARCHITECTURE.md` for detailed technical architecture and `ontology/migrations/V2_TO_V3_MIGRATION.md` for migration guidance.

## Layout
Currently there are three projects that feed downstream from one another:
1. `ontology` which is the ontology for the clearhead platform and the highest level of abstraction as this combination of ontology and SHACL shapes allows us to create a nice format to work from
2. `tree-sitter-actions` that ontology is to be translated into a tree-sitter parser for the actions filetype we are developing that will allow actions to be written in readable plaintext while still giving the functionality that we want from data
3. `clearhead-cli`  both of these will inform the core cli written in rust and ensure that we are able to make a scriptable interface that is going to be available to the CLI users and enable them to work through the ATOMIC transactions on these underlying files
  1. one other note is that we are planning to support a TUI through this project as well so that cli users will have what they need
4. `clearhead-lsp` (future) an LSP server for our clearhead files that will support editor functionality such as completion, go to definition, and other functionality typcially associated with our data files
5. `clearhead.nvim` (future) a neovim plugin that will leverage everything else here so that we can make the workflow within neovim or any other editor for that matter easy since most of the functionality will be owned by these upstream tools
6. `clearhead.todo`(future) a webiste that will be used to manage local or server hosted tasks using a proper GUI

### Vision: Ontology-Driven Code Generation

The core principle is **extending ontologies** at each layer rather than maintaining separate configuration files. This gives maximum leverage from the semantic work.

#### Generation Pipeline

```
V3 Ontology + SHACL
       ↓
   [generates]
       ↓
   JTD Schemas
       ↓
   [generates]
       ↓
TypeScript Types
       ↓
   [extends V3 ontology with parser concepts]
       ↓
Parser Ontology (includes symbol mappings, syntax rules)
       ↓
   [generates grammar via type-sitter]
       ↓
Tree-Sitter Parser
       ↓
   [extends parser ontology with CLI concepts]
       ↓
CLI Ontology
       ↓
   [generates Rust structs from parser]
       ↓
Type-Safe CLI
```

#### Detailed Steps

1. **Start with V3 Ontology + SHACL**: BFO/CCO-aligned ontology defines semantic concepts (ActionPlan, ActionProcess) and validation constraints (priority 1-4, temporal consistency, etc.)

2. **Test with RDF Examples**: Example data validates against both ontology and SHACL shapes. These examples drive downstream generation, ensuring consistency.

3. **Generate JTD Schemas**: Use ontology + SHACL to generate [JSON Type Definition](https://jsontypedef.com/) schemas optimized for code generation (precise integer types, proper enums).

4. **Generate TypeScript Types**: Use [json-typedef-js](https://github.com/jsontypedef/json-typedef-js) to generate TypeScript interfaces from JTD.

5. **EXTEND Ontology for Parser**: Create parser-specific ontology that extends V3 with file format concepts:
   - Symbol mappings (`priority → "!"`)
   - Grammar rules (`choice`, `pattern`)
   - Line/file structure
   - **Key insight:** These become semantic annotations on existing properties, not separate config files

6. **Generate Grammar from Types**: Use [3p3r/type-sitter](https://github.com/3p3r/type-sitter) to generate tree-sitter `grammar.js` from TypeScript types. Grammar is generated, not hand-written!

7. **Test Parse Trees**: Generated example files test parser. Expected parse tree outputs are hand-written since automated generation would propagate bugs.

8. **EXTEND Ontology for CLI**: Parser ontology is extended again with CLI-specific concepts (commands, validation strategies, display formats).

9. **Generate Rust Structs**: Use [Jakobeha/type-sitter](https://github.com/Jakobeha/type-sitter) to generate type-safe Rust structs from the parser's AST nodes.

10. **CLI Implementation**: Hand-written business logic uses generated structs:
    - **Validation**: Convert to RDF, validate against SHACL shapes from step 1
    - **Export**: CRDT formats for collaboration
    - **Manipulation**: Type-safe file operations
    - **TUI**: Interactive terminal interface
    - **Server/Client**: Collaboration via CRDT sync
    - **Round-trip**: Text files → AST → RDF → SHACL validation ensures semantic correctness

#### Why This Approach?

- **Single Source of Truth**: Ontology drives everything
- **No Config Drift**: Symbols, rules, and types all come from ontology
- **Semantic Correctness**: Grammar validates syntax, SHACL validates semantics
- **Maximum Leverage**: One ontology change propagates through entire stack
- **Standards-Based**: BFO/CCO alignment ensures interoperability

#### Loose Coupling via Semantic Web

We follow semantic web principles for dependencies - tools are coupled through **data formats** and **validation rules**, not code dependencies.

**Deployment Model:**
- Ontologies/SHACL shapes published at public URLs (e.g., `https://vocab.clearhead.io/actions/v3`)
- Downstream projects fetch from URLs or fall back to bundled copies
- No assumption of monorepo structure

**Dependency Chain:**

1. **Ontology** (`ontology/`): Self-contained, publishes to web
   - Inputs: None
   - Outputs: OWL ontology + SHACL shapes at public URL

2. **Parser** (`tree-sitter-actions/`): Extends base ontology
   - Inputs: Fetches V3 ontology from URL
   - Outputs: Parser-extended ontology + generated grammar + npm package
   - Extends: Adds file format concepts (symbols, syntax rules)
   - May add parser-specific SHACL constraints while respecting base shapes

3. **CLI** (`clearhead-cli/`): Uses parser and extends ontology again
   - Inputs:
     - Parser npm package (for parsing)
     - Parser ontology from URL (for semantic understanding)
   - Outputs: CLI-extended ontology + executable
   - Extends: Adds CLI concepts (commands, display formats)
   - Validates: Uses SHACL shapes from base ontology for semantic correctness

This approach ensures **interoperability** - other tools can consume our ontology without depending on our code. 


