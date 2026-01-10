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

### Finding Next-Steps
THE core functionality of the platform is the `actions` file format, as such, next steps will be kept within the conancal `next.actions` file in the root of the repository. Unless otherwise specified, these next steps are intended to be worked on as our project goals.

In addition, each submodule may have its own next steps and issues tracked within their respective repositories. From a data standpoint, this exemplifies a key principle of the platform: decentralization. Each tool or component can evolve independently while still contributing to the overall ecosystem.

each `next.actions` file should be kept up-to-date with the current priorities and tasks for that specific repository.

Please review the file format specification for guidance on how to write the file, and the cli guidance on how you can leverage tooling to make the file more managable for example, DONT generate UUIDs by hand, DO use the `normalize` subcommand to add them automatically for you!

In particular, we want to prioritize high priority actions over low priority ones where possible and when there are not blockers to that work but it is often needed to make some technical work changes before we can implement large swaths of features.

The goal is quality over quantity, so ample documentation, testing, and careful thought should go into each action before it is marked as done.

In particular, the concept of orthogonality should be kept in mind, meaning that changes should be made at the appropriate level of the platform to avoid unnecessary coupling and complexity.

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
- [CLI](./clearhead-cli/) the CLI and server implementation of many of the specifications outlined
  - handles much of the file ingestion, formatting, and linting required to translate strings in files into data that can be queried
  - uses the ontology to do semantic reasoning and validation on the data ingested
  - parses everything with the above tree-sitter parser
  - also serves as an LSP server so that linting and validation can be done in editors
- [Neovim App](./clearhead-nvim/) a neovim plugin that uses the CLI as a backend to provide in-editor support for the action file format
  - provides syntax highlighting, linting, and validation for action files within neovim
  - leverages the CLI's LSP server capabilities to offer real-time feedback and assistance while editing action files
  - also leverages the tree-sitter parser for accurate syntax parsing, folding, and highlighting

