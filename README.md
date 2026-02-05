# The ClearHead Platform
This is my attempt to create a free, open personal data platform that is:
- local-first, relying on local storage and computation where possible 
- human-centric, which is why the source of truth is the actions format that will remain human-readable and editable
- FAIR data: meaning this data is Findable, Accessible, Interoperable, and Reusable
- Ontologically grounded, meaning that data is structured according to well-defined ontologies to ensure semantic clarity and interoperability

## Context
This is my attempt at a higher-order repository, or in other words, a repository meant to maintain other repositories.

As the clearhead platform grows, I find myself wanting to separate out orthogonal concerns into their own repositories. 

On the one hand, these are different tools with their own toolschains and lifecycles. On the other hand, as a platform, they are deeply coupled and a change in one repository often cascades into changes in other repositories.

### Working with Submodules
Git submodules are notoriously tricky to work with, so we have laid out documentation in [Submodules](./SUBMODULES.md) to help you get started. including:
- Day-to-day workflows
- Cloning the repository
- Updating submodules

### Tracking Decisions
we maintain the [DECISIONS.md](./DECISIONS.md) file to track important architectural and design decisions made throughout the development of the platform. This helps provide context and reasoning behind certain choices, making it easier for contributors to understand the project's evolution.


## The Chain
The ClearHead platform can be seen as more or less abstract products that work together for a common goal:
- [Specifications](./specifications): The source of truth for the platform, written in human-readable formats like markdown. This covers guidance on evertying from the file format, to file and naming conventions, to example files and data schemas
  - all downstream dependencies rely on this repository, but usually not directly, we vendor examples so that downstream repositories can be more self-contained, and where possible the products may simply conform to the specifications without needing to reference them directly
- [Ontology](./ontology): The ontologies that provide the semantic backbone for the platform, ensuring that data is structured and interpreted consistently across different tools and repositories
  - Aligned with the CCO ontology, which itself is a BFO-aligned ontology format.
  - Creates the semantic backbone that enables interoperability and data integration across the platform
  - tools like the CLI use it to do semantic reasoning and validation on the data ingested 
- [Action File Parser](./tree-sitter-actions/) a parser for the action file format, built using tree-sitter
  - used by the CLI and other tools to parse and validate action files
- [Core Library](./clearhead-core/) the main rust library that provides the core functionality of the platform in such a way that can be leveraged by other downstream tools
  - currently, only supporting the CLI but the boundary has been established in such a way that the other downstream tools can leverage it as well
- [CLI](./clearhead-cli/) the CLI and server implementation of many of the specifications outlined
  - handles much of the file ingestion, formatting, and linting required to translate strings in files into data that can be queried
  - uses the ontology to do semantic reasoning and validation on the data ingested
  - parses everything with the above tree-sitter parser
  - also serves as an LSP server so that linting and validation can be done in editors
- [Neovim App](./clearhead-nvim/) a neovim plugin that uses the CLI as a backend to provide in-editor support for the action file format
  - provides syntax highlighting, linting, and validation for action files within neovim
  - leverages the CLI's LSP server capabilities to offer real-time feedback and assistance while editing action files
  - also leverages the tree-sitter parser for accurate syntax parsing, folding, and highlighting

