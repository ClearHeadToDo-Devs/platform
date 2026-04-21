# Architectural Decisions

**Last Updated:** February 14th 2026
**Status:** Living Document

This document records key architectural decisions made for the Clearhead Platform. Each decision includes context, rationale, alternatives considered, and trade-offs.

---
## Decision 21: `ics` as the plan format

ive been working through the idea of decoupling the various aspects of planning and i realized that we should try to pawn off the when to the tool that does this the best, the calendar and to make the role of the actions format more distinction without needing to encapsute a bunch of rrule logic

this means plans will now be represented as `ics` files which can easily be created within any standard calendar application and which other applications can easily read and edit as well.

this means that the actions format will be losing support for rrule syntax as they will now take the place of the planned act domain object and will be the thing that gets automatically generated when reading these ics files.

this makes both systems simpler while also being more able to differentiate the role of each piece and also makes it so that we can leverage existing tools for working with calendar data rather than needing to build our own syntax for it.

planned acts will still utilize the uuid v5 but will now use the calendar id as the namespace rather than the way we had it before where the ttl had the link which makes this much easier to control

this means that the ttl will now be used for nothing but the central archive which is where it excels as a data format

### Template support
while normally we will support the calendar event itself becoming an action, in order to make this easier we will also support the idea of having template files in the `templates` directory of the workspace that can be leveraged to create complex process chains in a recurring manner based on the calendar events 

In addition, the templates can then be used for other usecases like starting a charter off with a known set of planned acts and customizing them from there to make things easier to understand
## Decision 20: Provisional project local scope

After much considerations, im undoing decision 5, the user-level storage only decision, and instead going with a provisional project local scope.

now, the problems were still there i dont think i plan to do a recursive search of the filesystem, but instead, we can have a simple mechanism for designating a project local scope where we look for a `.clearhead` or `next.actions` file in the project root directory (we will have to do a check if we are in a project directory)

we will also have a config option to designate whether people want to have the cli and other pieces be dynamic or if we want to look at a single workspace every time

### What changed?

Decision 19 opened the design space allot more to allow for project-scoped work now that we are going to be able to designate everything through git.

allot of work has gone into making this process git-friendly so we want to make sure that we can leverage that where necessary

besides, it could be argued that people would want their plans related to a project to be deeply coupled to the project itself and not just floating around in a user-level workspace, so this allows for that use case while still allowing for the individual use case as well

Another thing people will be able to do is designate a config option for adding additional workspaces in the CLI so that if people DO want to navigate and add everything to a single query, they can but we will default to one workspace at a time

#### Considerations

Now, this also means we are going to have different RDF graphs for each workspace without extra work and maybe we consider a format where we can look at different graphs but that isnt the end of the world honestly and again it might be helpful for people to have many smaller graphs with the ability to aggregate them later with a strong query engine rather than forcing people to put everything in one place

still, this allows git to be a first-class citizen and opens the possibility of managing a project entirely within the repo which i honestly think is table stakes for what we are building here since this is meant to be something developer friendly is tremendously important that we meet people where they are rather than building for a customer im not sure exists
## Decision 19: CRDT Sync as Feature not Root

After reflecting, we are going to add an update to decision 2.

In the older format, we were using the CRDT as the main root because i wanted this to be the core way we had several devices speak. However, I really want to support the use case of someone just editing the files by hand and using the CLI locally before the structure of the CRDT is fully added.

This does a few things:

- Simplifies the CLI and LSP server implementation so they are unconcerned with the CRDT layer.
- The CRDT will operate on the on-disk files as a secondary source of truth when enabled, but the files should be able to live on their own
- the CRDT server will need to be able to read the workspace files but that seems fine overall and it makes things easier to structure our work

So we are going to take some work of simplifying the CLI and LSP to make that experience really tight, with plans for the sync server to be something that we do in JS later 
## Decision 18: RDF Store

In line with the work outlined below on the CRDT layer, we will also be decoupling the RDF store from the core hotpath.

Before, we were kinda keeping this all in sync, but now, instead we will do something where CLI commands using queries will just load the current state into oxigraph from the files themselves, assuming that if there are changes from the CRDT, they have already been projected to the workspace, so that we can answer questions.

We will largely avoid RDF queries in the LSP since it must be really used carefully to avoid perfomance issues and if we do have something running then we want to be careful
## Decision 17: WorkspaceStore Trait

### Context
The LSP/sync server decoupling decision (below) raises a question: where does workspace management live? Currently, loading/saving domain objects (plans, charters) and discovering workspace contents is spread across both clearhead-core (crdt.rs has `Workspace`, `CrdtStorage`, `ActionRepository` with `std::fs` calls) and clearhead-cli (workspace.rs for file/charter discovery, its own crdt.rs for XDG resolution and schema migration).

Both the CLI and the future sync server need these operations. A database or mobile app would need them too — but shouldn't be forced into filesystem assumptions.

### Decision
Define a `WorkspaceStore` trait in clearhead-core that abstracts "load/save domain objects by key." The trait covers:
- Listing objectives in the workspace
- Loading/saving `DomainModel` for an objective
- Loading/saving `Charter` for an objective
- Discovering all charters in the workspace

Storage backends implement this trait:
- **Filesystem** (`.actions` + `.md` files) — behind an optional feature flag in core
- **Database** (SQLite, etc.) — consumers implement as needed
- **In-memory** — always available, ships with core for testing

The CRDT sync layer sits *above* this trait. A sync server uses a `WorkspaceStore` to project CRDT state outward, but the store has no knowledge of CRDTs or synchronization. When the LSP is connected, it controls projection timing (gating). When no editor is running, the sync server projects through the store directly.

### Rationale
- **Multiple consumers:** CLI, LSP, sync server all need workspace operations
- **Multiple backends:** Filesystem is one option, not the only one
- **Testability:** `InMemoryStore` eliminates temp directory gymnastics in tests
- **Clean CRDT boundary:** Store doesn't know about sync, CRDT doesn't know about storage format

### Alternatives Considered
1. **Pure path mapping in core:** Core returns paths, consumers do I/O
   - Rejected: Dishonest about the abstraction — it's not "give me paths," it's "load/save domain objects"
2. **Separate `clearhead-workspace` crate:** Shared crate for filesystem operations
   - Rejected: Extra crate when a feature flag in core achieves the same thing
3. **Keep workspace logic in CLI only:** Sync server imports CLI as library
   - Rejected: CLI has interactive/display concerns that don't belong in a sync daemon

### Implementation
- `clearhead-core/src/store.rs` — trait definition, `ObjectiveRef`, `DiscoveredCharter`, `InMemoryStore`
- Phase 2 (future): `FsWorkspaceStore` behind `fs` feature flag
- Phase 3 (future): CLI refactored to use trait instead of direct filesystem calls

## Decision 16: Decoupling LSP from CRDT Sync
Ive been building up the work and i realize now that having the LSP server directly manipulate the CRDT document is causing some issues around the fact that we want to be able to have the LSP server be a more general tool for working with the DSL files rather than being tightly coupled to the CRDT syncing and merging.

Instead, the future sync server that will be handling automerge will also be the primary tool responsible for manipulating the CRDT documents based on requests for changes it recieves

Instead, the LSP will just check a UNIX domain socket to see if the sync server is running, if so, it pushes changes to the sync server after its modifiications, and recieves edits over that same socket.

If not, if moves on as it normally would, just modifying the file and letting the formatter and linter do their thing without worrying about the CRDT document at all. this way those who dont want to leverage the CRDT syncing can still use the LSP server for the other features without needing to worry about the syncing piece at all.
##  Decision 15: Semantic Patch + Projection Gating for Multi-Device Sync

**Date:** February 2026  

### Context
ClearHead is local-first and editor-centric. Multi-device sync introduces a failure mode where remote updates can cause confusing or "funky" merges if we treat the DSL file as the merge surface or if we rewrite projections while a user is actively editing.

The sync architecture already establishes the CRDT as the source of truth and the DSL as a projection. This decision clarifies *how* we bridge editor saves, CRDT updates, and multi-device synchronization without relying on text merge semantics.

### Decision
1. **Semantic changes are represented as patches over stable domain identifiers.**
   - The fundamental unit of change is a domain-level patch (e.g., "set priority", "rename", "add context tag"), addressed by stable UUIDs.
   - These patches are applied to the CRDT, not to DSL text.

2. **Sync merges occur at the CRDT layer; DSL merges are avoided.**
   - Devices synchronize CRDT state (plans + processes) using CRDT merge semantics.
   - The DSL remains a deterministic, regenerable projection.

3. **Projection writes are gated by user intent ("safe moments").**
   - Remote CRDT updates may be received at any time.
   - Rewriting projected DSL files is treated as an intentional operation (e.g., on-save, manual apply, or when the editor is known to be clean), to avoid altering a user's active editing context.

4. **Observability records semantic history; it is not a sync mechanism.**
   - Telemetry captures the semantic meaning of changes (patch summaries, sync sessions, conflict classifications) to explain behavior.
   - Cross-device state sharing remains solely a CRDT concern.

### Rationale
- **Editor respect:** Avoids rewriting files "under the user's feet".
- **Merge stability:** UUID-addressed patches reduce dependence on fragile text diffs and ordering.
- **Local-first consistency:** Each device can remain fully functional offline; sync is incremental.
- **Debuggability:** Observability bridges the gap between CRDT operational history and human-meaningful change history.

### Alternatives Considered
1. **Sync the DSL files directly (file-level replication):**
   - Rejected: turns sync into text-merge conflict management and defeats projection architecture.

2. **Always project on every CRDT change (continuous projection):**
   - Rejected: causes unsolicited file rewrites and increases editor friction.

3. **Use observability events as the replication mechanism (semantic event sourcing):**
   - Rejected: duplicates CRDT coordination with another ordering/deduplication system.

### Trade-offs
**Pros:**
- Stable merges (domain patches over UUIDs)
- Predictable editor experience (projection gating)
- Easier sync debugging (semantic telemetry)
- Keeps sync concerns in CRDT layer

**Cons:**
- Requires defining a patch vocabulary (domain operations)
- Requires tracking a "base" view for clean patch derivation from saved text
- Some remote updates will not be visible until the next intentional apply

### Specification Implications (High Level)
- Sync spec should explicitly describe *semantic patching* and *projection gating* as core strategies for multi-device stability.
- Observability spec should include events that explain patch derivation/application and sync sessions, while remaining non-authoritative.

## Decision 14: Archiving Actions
In order to support the archival of plans (actions) and their planned acts, we are going to implement a simple mechanism for archiving actions.

The core mechanism is described in [the process specification](./specifications/process.md) but the key points are:
- we have <charter>.archive.actions files that live alongside the main action plan files
- when an action is archived, it is moved from the main action plan file to the archive
- archived actions are read-only and cannot be modified
- archived actions can be unarchived back to the main action plan file
- the CLI will support commands for archiving and unarchiving actions
- the LSP server will support commands for archiving and unarchiving actions automatically as a part of the generation workflow

this is separate from the logging mechanism which simply logs what happened, instead, we are focused here on what the final state of the action and its planned acts are for the sake of continued analysis

open questions are whether or not we should allow the export of data to other formats or even supporting a retention period mechanism where stuff gets automatically removed from the archive after a certain period of time to ensure the archive doesnt grow indefinitely but these are things we can explore later

For now, this is another piece of functionality that will be something a user can turn on or off depending on preference but i think this will be important for making it so people dont need to manage the movement of closed actions manually
## Decision 13: Splitting the CLI from Core
The core functionality of the platform has been growing for awhile and with the latest additions to the LSP we are going to split the clearhead cli from the core platform functionality.

This will enable the two to grow independently and is already yielding benefits around readability and proper boundary definition.

Implementors are free to either integrate with the cli or to build their own tools on top of the core platform functionality as a core library, or even at a data level if the intergration needs to be really loose.
## Decision 12: Reworking the Ontology and CLI
After allot of pondering, im very happy to say the v4 of the ontology is prepared and ready to go.

I realized that CCO offers the mass majority of what we need for the entire thing to work and I really like the idea of our core entities:
- Objectives (akin to projects in other frameworks)
- Plans (the templates for what we call actions)
- Planned Act (the execution of a plan, what we call action processes)
  - Every plan has atleast one planned act, but recurring plans can have many planned acts

we have everything we need to represent the domain, now to make it cleaner, we are going to make some changes to the CLI and the way we represent things in the data structures to better align with the ontology.

In this way, we arent using the ontology generatively we are just going to make it so that the ontology is driving the design of the CLI

The parser will still be the same as those are about the syntax that we use to represent the data 

Core will cover:
- Core structures that represent the domain objects
- Conversions to and from the various formats
  - DSL
  - TTL
  - Table
  - JSON
- CRDT syncing and merging
- Formatting and Linting Logic
- SPARQL querying

Leaving the CLI to cover:
- Command Line Parsing
- Layered Configuration Management
- File System Interactions
- Network Calls
- LSP Server implementation (this is the part with the runtime)
## Decision 11: Oxigraph as Query Layer
After doing allot of research on the various options for a query engine, I have decided to give [Oxigraph](https://github.com/oxigraph/oxigraph?tab=readme-ov-file) a try as the core query engine for the platform.

This is for a few reasons:
- As we can see from the [Ontology](./ontology/README.md) we have put in allot of work to make sure we have strong ontological underpinnings from the BFO/CCO alignment so having a strong RDF query engine is important to make sure we can leverage SPARQL queries to do reasoning over the data.
- Oxigraph is written in Rust which makes it a great fit for our existing Rust codebase especially since it tries to be a fully compliant SPARQL 1.1 engine.
- It has support for persistent storage which means we can use it as a cache layer for the data we have.

Although, its important to note what this is NOT:

The oxigraph will NOT be the persistence layer, this and syncing will still be handled by the automerge CRDT document with the intermediate representation still serving as the hub for moving data between the various formats.

The DSL is still going to be the primary human interface we are NOT replacing the actions file format with RDF.

What this DOES do however is supercharge our ability to do complex queries over the data and to do reasoning over the data in a way that is performant and scalable. 

This is amazing for:
- Linting: Through SHACL shapes and ontology reasoning we can do much more complex linting of the data
- Reporting: we can now do complex queries over the data and even over time
- Integration: with the ontology entities being first-class citizens rather than just being implicit in the data structures we can now more easily integrate with other systems that also use RDF and ontologies. 


### Changes

We want to go over what breaking changes this will entail:
- Removing the sql queries. we dont want to maintain multiple query engines so we will be removing the existing sql queries and replacing them with SPARQL queries and oxigraph as the query engine.
- Alignment between Structs and Ontology Domain Objects. Now, this is where we are ALIGNING the structs more closely with the ontology domain objects so that we can have a lossless mapping between the two. This means that we will need to make sure that the structs are designed in a way that they can be easily converted to and from data that conforms to our ontology and this will be REPRESENTED in the structs themselves, which makes the introduction to oxigraph much more seamless.

 ### Sync Implications

By keeping all data (plans AND processes) in the CRDT, we mainain a single sync mechanism. 
  Oxigraph is rebuilt locally from the CRDT/IR, so we don't need to solve RDF sync. This eliminates events.db as a separate store 
  - ActionProcesses now live in the CRDT alongisde ActionPlans.
  Flow:
  - CRDT → IR → Oxigraph (query cache)
  - CRDT → IR → DSL (human interface)

  Sync happens at CRDT layer only

## Decision 10: Expanding Reference Styles
In order to make the reference styles more flexible we are going to expand the existing reference styles to include some new ones:

- Short UUID: The first 8 characters of the UUID can be used as a short "good enough" reference for actions, good for when we want to be sure but ALSO keep the id short enough to be human friendly.
- Alias: We want to add syntax to define shorthands for actions so that we can have things like "get project documentation done" to "documentation" this way, the alias will still be the same and easier to read _even if we change the name or description_
- Defining sequential action plans: to make it easier to have multiple actions that are inherently sequential, we will support a syntax for designating a set of actions as being sequentially dependent on one another. this will make it easier to have things like "step 1", "step 2", "step 3" without needing to have complex dependencies defined.

By default, we want to still assume that actions are independent unless otherwise specified but this will make it easier to have more complex workflows defined in the action plan DSL and where we want to simply use the order to denote dependencies rather than needing to have complex dependency graphs defined.
## Decision 9: Action Plan Hierarchies
Another hierarchy we have specced out in the file format but have yet to represent in the data is the idea that one action plan can have child action plans.

we will need some sort of syntax to represent this so that we can have two subprojects with the name "cli" that are different things.

this will make some things easier like having a project for "work" and a project for "personal" and being able to have actions that are scoped to those projects.

This means we need a way to denote child projects within the file format as well as the data structures because as we have noted its important that we actually have a _lossless_ representation of the file format in the data structures so that we can roundtrip without losing information.
## Decision 8 Tag Hierarchies
One feature i want to support is the idea of tag subtypes. the idea being that some contexts are of a precise type of another context.

These can be defined within a single config option in the core config file and will only be a list of values, with the ability to put certain tags under others. 

This allows one to make one tag implicitly include other tags. for example:
Grocery store is a subtype of driving
so if I tag something as grocery store it will also be tagged as driving.

neovim is a subset of terminal so if I tag something as neovim it will also be tagged as terminal which itself will be a subset of computer so tagging something as neovim will also tag it as computer
## Decision 7: Decreasing Formatter Responsibility
After reflecting on the role of the formatter in the overall architecture, I have decided to reduce its responsibilities significantly.

In particular, a core design philosphy is that we dont really care about whitespace in the action plan dsl.

To this end, we are removing much of the responsibility of formatting, moving to topiary within the tree sitter parser, and making it so that the cli just runs topiary through the formatter rather than trying to do its own thing.

this will primarily be used on "on save" actions in the LSP server to ensure that the document is in a normalized state but we wont be worrying about things like indentation levels or other whitespace issues.

the "indent" queries in the treesitter parser will be used to ensure that children are indented properly but beyond that we wont be worrying about it.

this makes it so that formatting is primarily handled by the parser, while the cli owns linting which happens AFTER parsing .
## Decision 6: Relaxed Parser, Strict Linter
In tree-sitter, it is less reliable and more brittle to do error reporting from the tree itself. 

Instead, we want to have a relatively relaxed parser that can parse most things into a tree structure, and then have the linter be the place where we do the strict checking of the document to ensure that it is valid.

this was brought to my attention when i realized that we were getting invalid trees from small issues like tags with no content and instead of making people figure out why the tree isnt valid i would rather say thats a valid tree but you have a linter error that says "tags must have content" or something like that.

This goes along with modern tools like typescript where the parser is very relaxed and the typechecker is where the strictness comes in.
## Decision 5: User-Level Storage Only (Superceded by 20)
After working through the architecture problems for a few weeks ive decided that the best path forward is to focus on keeping actions in the user-stored directories and to forget about doing the file-search for other projects that just so happen to have action plans in them.

This is because the complexity of doing this is high including:
- Recursively searching directories can be really bad for performance
- It becomes strange to know when we want "everything" and when we want just the user-level stuff
- Syncing and conflicts become a nightmare when you have multiple projects with different action plans
- we dont want to lock projects into having to have action plans if they dont want them

This, along with our core usecase of individual intentions keeps our vision clean, and more able to actually implement the core features that we want to implement to make the _individual_ experience great rather than trying to be everything to everyone.


## Decision 4: Recurrence Instances.
To avoid the problem of needing to check the instances for an action we are only going to track the most upcoming few instances of a recurring action maybe like 3 months but we can configure this but i dont want this to be something where we are constantly scanning the list whenever an action is changed to ensure that the structure is still there right for the rrule so if someone changes shit we just work through that rather than doing some stupid bullshit
## Decision 3: Discipline Around the Linter
After reviewing the existing implementation, i realized that we need to be really carefuly and disciplined about what the linter checks and what it cant check and how to works in the larger system.

while the linter is wonderful for helping with immediate diagnostics, there is a fine line between helpful and annoying.

In particular, we want it to be configurable and especially where we are providing diagnostics rather than error reporting we want to make that clear so here we have:
- Errors: Literally invalid syntax that prevents parsing
  - this is where the actual parser errors and tips around them go
- Warnings: Valid trees, but there is something wrong with the document that will block lots of functionality
  - best exampled is the UUID missing from an action. Technically valid, but will block syncing and other features
- Info: Process improvements
  - We cover the process in the process specification but its important to remember things like making sure an action has a completed date when its closed or that an open action has a due date before today that is a process issue rather than a syntax issue

  The fact this matches the LSP diagnostic levels is intentional so that we can leverage the LSP features fully and so that we can have a consistent experience across editors.

By contrast, the formatter tries to go with a more gofmt approach of just fixing everything it can including:
- adding whitespace for children
- putting properties in a specific order
- normalizing line endings

Again, the lsp leverages this to provide "on save" formatting that makes sure everything is in the right place but is mediated through the server rather than asking each editor to do its own thing.

These tools make the processing and working with the DSL, even with the below CRDT changes possible as the tooling will ensure synced documents are of valid state
## Decision 2: CRDT is New Source of Truth (superceeded by 19)
As i have grappled with several architectures i realize that the primary way that we move forward is by leveraging the CRDT data structures as the shared source of truth for the application state.

This changes things significantly because the filetype is now a projected view FROM the CRDT and is not the primary source of truth anymore.

However, the DSL remains a core view and i want to make sure the work is put in to make the act of updating the state of the automerge document from a text editor is as seamless as possible.

We will do this by leveraging the LSP as the intermediary that has things like "on save" actions that will actually be able to do the heavy lifting of getting the CRDT document, comparing current state to the text editor state, and then applying the necessary changes to the CRDT document.

This is going to leverage the linter and formatter so nothing is going to really change but the order is going to be done a bit differently.

Now, we are still going to leverage events for our historical analysis but the database will also likely be more of something that is used to track what has been done rather than actually used to persist present state and work through the issues around that.

This will still require the sqlite for local state on the recurrance level, and the CRDT document will be the source of truth for the action plan as a whole.

With this, automerge repo, and the LSP server we will have the vision of having something that can be edited from a normal text editor as redily as it is handled in the webapp or mobile app.

This also makes the cli more impactful as now our CRUD operations will be directly manipulating the CRDT document rather than trying to parse and reserialize the text file.

but what DOESNT change is that the struct is the hub that moves data from one format to another. For example, both the events.db AND the reader DB will still go from the cmdb doc -> struct -> sqlite rather than trying to pull the data from the text file directly.

In this way, we arent changing the overall architecture but rather changing the source of truth and how we interact with it.

### Semantic Event Logging
One of the other approaches that i was working on was a small event sourcing piece that created semantic events for the domain language that made it easier to make the current state.

However, with the CRDT as the source of truth, this becomes less necessary as the CRDT document itself is the source of truth and we can always derive events from it if needed.

By contrast, the events db is more for analytics, aggregating data on the same computer, while also being used to aggregate the data acrossed multiple devices via duckdb in any one of the nodes so that we are able to also ask questions about these actions acrossed multiple dimmensions

what this DB DOES own however is the recurrence problem and tracking atleast the most upcoming recurring action instance so that when we edit the template file in the DSL we will keep it closed while still noting that in our events db we have the upcoming instance that is open and have closed/cancelled an instance

## ... When the sync server is running
to simplify the architecture, this is true for the sync server, which will only watch the structure of the work, and update the files as needed, but for users that dont want to use the sync server, they should be able to edit the structure such that they can work through the introductions

so while CRDT WILL own the sync story, it will not own the local edit story, or more precisely, will not be NECESSARY for functioning of the core workspace model so that users can still edit the files
## Decision 1: Loosly couple the ontology and move forward
Instead of relying on generation as before, we are instead using the ontology like any other piece where the cli will leverage it by translating the work into data and then running the validation shapes.

We will NOT be generating code from the ontology directly, but rather using it as a source of truth for semantic validation and reasoning.

In addition, we have been doing a deeper focus on aligning around the CLI and making the editor extensions a first-class citizen


**Version:** 1.0
**Authors:** Clearhead Platform Team
