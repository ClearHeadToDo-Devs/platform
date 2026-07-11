---
id: 019f485a-cf2c-77a2-9066-711bb02794a9
state: Active
---
# Leveraging Graph Structures to answer questions

one of the core desires of this project is to leverage the superior power of RDF, ontologies, and SPARQL to allow for declarative, graph-native data traversal.

however, the other virtue should be ease-of-use. SPARQL is obtuse, ontologies are academic, the average user doesnt want to go through a degree in ontology design and graph query tutorials in order to derive the next actions for their day.

Instead, we need to make a clean interface that will be able to LEVERAGE this underlying graph structure while still making it trivially easy to define or our clients and users and really leverage this to get queries that would be difficult-impossible in our normal understanding of data

## Views

The version of this will be a concept of views, which will leverage queries under the hood to get the data we need within the format we need.

with this, we are going to have a strong foundation where we are able to show the views that we need, within the context we need, without needing to teach people about the queries we are showing.

the beauty of this is that we can compose various views using the exact same underlying data with discipline structuring of our returns.


### Agenda View

one of the core views that is going to make a big differentiating factor for us is the agenda view which will help us get all actions that are:
- the first in the depedency chain
- are relevant to the current context
- are the lowest child of still-open parent actions
- is either due today, or is coming up in the next week
- is sorted by priority

this will be a core view that can be leveraged by either humans or agents to cut through everything and just get the relevant list of next steps that they can go about working without even caring

### Upcoming View

Another view that is related to the [calendar view](./calendar-view.md) is the upcoming view that would show actions that are coming up in the next days/weeks (configurable by the user) and would allow us to even see dependency chains so that users can start thinking about the relevant next steps

this is a great example of a view that can be leveraged when we are thinking in terms of dates

### Charter Graphs

Next, we have a view that leverages the tremendous ability to relate our work to other things.

one of the other core charters is the desire to integrate other data into our existing work with [graph models](./data-integration.md) by making it easy to quickly query everything related to a specific charter/tag even if the object is only related in another way

this is also leveraging the nature of graphs because charters can have parent charters and tags(context) can have parent context so this is still a full graph traversal even in a completely hermetically sealed situation

this will allow us to actually work though the structures
