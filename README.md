# Context
This is a meta repository that contains the other projects as submodules that can be reviewed and edited from within one place

however, make no mistake these are all separate things and making sure the boundaries between them is clear will make all of this easier

## Layout
Currently there are three projects that feed downstream from one another:
1. `ontology` which is the ontology for the clearhead platform and the highest level of abstraction as this combination of ontology and SHACL shapes allows us to create a nice format to work from
2. `tree-sitter-actions` that ontology is to be translated into a tree-sitter parser for the actions filetype we are developing that will allow actions to be written in readable plaintext while still giving the functionality that we want from data
3. `clearhead-cli`  both of these will inform the core cli written in rust and ensure that we are able to make a scriptable interface that is going to be available to the CLI users and enable them to work through the ATOMIC transactions on these underlying files
  1. one other note is that we are planning to support a TUI through this project as well so that cli users will have what they need
4. `clearhead-lsp` (future) an LSP server for our clearhead files that will support editor functionality such as completion, go to definition, and other functionality typcially associated with our data files
5. `clearhead.nvim` (future) a neovim plugin that will leverage everything else here so that we can make the workflow within neovim or any other editor for that matter easy since most of the functionality will be owned by these upstream tools
6. `clearhead.todo`(future) a webiste that will be used to manage local or server hosted tasks using a proper GUI

# Vision
when i ponder how i want this to work i imagine the generation pipeline goes somethiing like this

ontology + SHACL -> JSON Schema + Syntax Mapping Rules -> Rust Structs -> text/data 

with that data being validated by the ontology and SHACL constraints we set at the beginning.

we can call this ontology-driven development or the ontological stack where we are using the ontology as the core engine of the work and generating our end points from this core of semantic meaning so that we can minimize drift between the different implementations while still letting them do their thing when necessary
