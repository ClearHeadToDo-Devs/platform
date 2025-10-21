# Context
This is a higher order repo with several other repositories as git submodules

for a large intro please see [the README](./README.md) 

## Running components
all submodules have their own README files, please review before doing any work to ensure you have proper context

- ontology is a python project managed through `uv` and intended to generate json schemas from a combination of ontologies and SHACL shapes
- tree-sitter-actions is a javascript project under the `tree-sitter` banner and as such has its own flow around data generation
- clearhead-cli is a rust CLI that tries to use the first two projects to automically act on action files and translate the work without people needing to generate or download the parser themselves
