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

1. we start with the combination of the ontology and SHACL shapes that can be used to define these structures
2. The ontology repo also contains example RDF files that are tested against both the ontology and the SHACL shapes to ensure that they are valid examples of the concepts we want to represent. These are wonderful for downstream examples to be generated from the example data, keeping the pipeline consistent wherever possible
2. From there, we EXTEND the ontology in the parser to include concepts that are SPECIFIC to the action filetype such as the syntax for defining different properties and bringing in the concept of files and lines of text so that this new ontology will cover all the concepts we need to represent a file with lines of text to be read as actions
3. Next, we use the ontology and shapes to generate json typdef schemas compatible with generation tools to automatically generate structs based on the schema outlined
3. the typdefinition done, [json-typedef-js](https://github.com/jsontypedef/json-typedef-js) will be used to generate typscript types that will represent the various classes of our ontology in preparation for the parser
4. we use the typescript types to build a tree-sitter parser using [3p3r/type-sitter](https://github.com/3p3r/type-sitter) that will generate the grammar and therefore the parser for our action filetypes
5. while the normal file examples will be generate using the ontology examples, the outputted parse tree will be test by-hand to ensure that the structure looks like what we expect. plus, we cant really automate that testing since if we make a buggy change, we cant then generate the correct output to compare against
6. again, we are going to EXTEND the parser ontology so that we can now put the concepts that the CLI will need to interact with, creating a final ontology that leverages everything else to know its
7. next, we will use [Jakobeha/type-sitter](https://github.com/Jakobeha/type-sitter) in the rust CLI to generate equivalent rust structs that will be able to interact with the tree in a type-safe way purely from the parser
8. again, while we are going to use our examples to generate test cases, for the expected output we will need to hand-write the expected output
9. Finally, the cli will use these generate rust structs to implement functionality on top of the parsed files including:
    1. validation against the SHACL shapes defined in the ontology project
    2. Reading and exporting action file data to other formats as needed, in particular CRDT formats for collaboration
    3. manipulation of the files such as adding, removing, or modifying actions within them
    4. an interactive TUI that will allow users to work with the files in a more user-friendly way
    5. server functionality such as the ability to host the CRDT repository for collaboration
    6. and the opposite, a client mode that will allow users to connect to a server and work with the files collaboratively if they want to sync up in a local-first way
    7. notably, this is where we will go end-to-end from our intput (action text files) to our output (RDF files that conform to our highest ontology examples) so that we can ensure that the text files actually do create data that conforms to the SHACL shapes at the highest level
