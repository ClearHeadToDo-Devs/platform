// clearhead_core's components, included in each container that links the library.
// C4 draws a linked library's components inside every runtime that runs them; this file
// keeps one definition. Set CORE to the identifier prefix before including it.

group "Application policy — clearhead_core" {
    ${CORE}Mutation = component "Mutation use cases" "Decides action, charter, archive, and transaction changes without performing I/O." "Pure Rust" "Application"
    ${CORE}CalendarPolicy = component "Recurrence and reconciliation policy" "Decides occurrence projection, calendar reconciliation, and deviation changes." "Pure Rust, RFC 5545 semantics" "Application"
    ${CORE}Reference = component "Reference resolution" "Resolves UUID, prefix, alias, path and predecessor references across the domain model and workspace." "Pure Rust" "Application"
}

group "Entities — clearhead_core" {
    ${CORE}Domain = component "Domain model" "Owns Objective, Charter, Habit, Action, lifecycle state, written time bounds, Habit slot identity, diff, filter, and update semantics. Plans are projections of Habits and Action blocks." "Pure Rust" "Domain"
}

group "Boundary contracts — clearhead_core" {
    ${CORE}Effects = component "Resource/effect port" "Defines logical locations, snapshots, revisions, prepared mutations, preconditions, and effect batches." "Pure Rust" "Port"
    ${CORE}Contracts = component "Host-neutral contracts" "Defines shared configuration semantics, selectors, transaction requests, and typed verb outcomes." "Pure Rust" "Port"
}

group "Pure representation adapters — clearhead_core" {
    ${CORE}Workspace = component "Workspace projection" "Assembles actions, habits files, charters, objectives, sidecars, manifests, templates, and archived facts into the domain model; projects charters to charters.schema.json." "Pure Rust" "Representation Adapter"
    ${CORE}Actions = component "Actions language adapter" "Parses, lints, diffs, merges by UUID, and formats the .actions representation." "Rust" "Representation Adapter"
    ${CORE}Icalendar = component "iCalendar adapter" "Parses and renders VTODO resources around recurrence and reconciliation policy." "Pure Rust, RFC 5545" "Representation Adapter"
    ${CORE}Rdf = component "RDF publication adapter" "Projects the domain model to the application graph (app: vocabulary) as deterministic database-free quads and serializations; publishes no undeclared charter id." "Pure Rust, RDF" "Representation Adapter"
}

group "Framework details" {
    ${CORE}ActionsGrammar = component "tree-sitter-actions" "Pinned generated grammar used by the actions language adapter." "tree-sitter" "Framework"
    ${CORE}FormattingEngine = component "Topiary formatting engine" "Optional concrete formatter used to produce canonical .actions source." "Topiary" "Framework,Optional"
    ${CORE}MarkdownParser = component "CommonMark parser" "The one Markdown parser for charter documents and action notes, so every reader agrees on headings, code and sections." "pulldown-cmark" "Framework"
}

${CORE}Mutation -> ${CORE}Domain "Depends on domain semantics"
${CORE}Mutation -> ${CORE}Effects "Expresses decisions through the output port"
${CORE}Mutation -> ${CORE}Contracts "Depends on host-neutral requests"
${CORE}CalendarPolicy -> ${CORE}Domain "Depends on Plan and Action semantics"
${CORE}CalendarPolicy -> ${CORE}Effects "Expresses synchronization decisions through the output port"
${CORE}Reference -> ${CORE}Domain "Depends on domain identities and relationships"
${CORE}Workspace -> ${CORE}Domain "Produces the canonical in-memory model"
${CORE}Workspace -> ${CORE}Actions "Depends on the actions representation adapter"
${CORE}Workspace -> ${CORE}Icalendar "Depends on the calendar representation adapter"
${CORE}Workspace -> ${CORE}Reference "Uses reference resolution"
${CORE}Workspace -> ${CORE}MarkdownParser "Reads charter structure through the shared parser"
${CORE}Actions -> ${CORE}MarkdownParser "Reads action-note structure through the shared parser"
${CORE}Actions -> ${CORE}Domain "Maps plaintext to and from domain entities"
${CORE}Actions -> ${CORE}ActionsGrammar "Depends on the concrete grammar"
${CORE}Actions -> ${CORE}FormattingEngine "Optionally depends on the concrete formatter"
${CORE}Icalendar -> ${CORE}Domain "Maps VTODO resources to and from domain entities"
${CORE}Icalendar -> ${CORE}CalendarPolicy "Uses recurrence and reconciliation policy"
${CORE}Rdf -> ${CORE}Domain "Depends only on the domain model"
