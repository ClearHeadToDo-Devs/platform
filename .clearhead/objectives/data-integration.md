# Data Integration through data rather than API

Another core virtue i desire to structure is how this platform can serve as a root for other existing applications and how we can leverage the connections from this graph into other graphs in such a way that we are able to integrate apps that never though about each other

## External data protocol

This is where the value of the ontology is core, by leveraging the BFO as a core ontology, as long as the graphs we need are related to the core ontology we use as our Top level ontology (TLO) we can always integrate directly by type

but there is more, when one ponders actions they are often related to other things completely outside of the regular domain.

for example, exercise goals may be associated with set data or calorie intake, or sleep data, and we want to be able to pull that information in without making specific integration points on the two sides.

at the data level, RDF already handles this it is trivially easy to make connections between two objects even if they arent related. 

but there are many technical hurdles that must be overcome before they can be related within a single graph

### the how

this will be done through an importer and exporter that will allow data to be integrated into the graph even if it does not natively come into the ontology that we have. this beautifully handles the structure we are hoping for where the ontology represents the open world principles that allow new information to be input

## visualizing graph data properly

the part that i still havent cracked is how to make viewing, editing, and traversing this data not just possible with the power of declarative data languages like SPARQL or how to visualize a single line in DOT but to ponder deeply how to move us into a graph-centric understanding of our work and open the doors to leveraging various forms of input, data, and prose that will allow us to leverage all of our existing knowledge within a single environment
