// clearhead_core's components, included in each container that links the library.
// C4 draws a linked library's components inside every runtime that runs them; this file
// keeps one definition. Set CORE to the identifier prefix before including it.

group "Application policy — clearhead_core" {
    ${CORE}Mutation = component "Mutation use cases" "Decides action, charter, archive, and transaction changes without performing I/O." "Pure Rust" "Application"
    ${CORE}CalendarPolicy = component "Recurrence and reconciliation policy" "Decides occurrence projection, calendar reconciliation, and deviation changes." "Pure Rust, RFC 5545 semantics" "Application"
    ${CORE}Reference = component "Reference resolution" "Resolves UUIDs, prefixes, aliases and paths." "Pure Rust" "Application" {
        properties {
            "Detail" "Resolves UUID, prefix, alias, path and predecessor references across the domain model and workspace."
        }
    }
}

group "Entities — clearhead_core" {
    ${CORE}Domain = component "Domain model" "Objectives, charters, habits, actions and their states." "Pure Rust" "Domain" {
        properties {
            "Detail" "Owns Objective, Charter, Habit, Action, lifecycle state, written time bounds, Habit slot identity, diff, filter, and update semantics. Plans are projections of Habits and Action blocks."
        }
    }
}

group "Boundary contracts — clearhead_core" {
    ${CORE}Effects = component "Resource/effect port" "Defines logical locations, snapshots, revisions, prepared mutations, preconditions, and effect batches." "Pure Rust" "Port"
    ${CORE}Contracts = component "Host-neutral contracts" "Defines shared configuration semantics, selectors, transaction requests, and typed verb outcomes." "Pure Rust" "Port"
}

group "Pure representation adapters — clearhead_core" {
    ${CORE}Workspace = component "Workspace projection" "Assembles workspace files into the domain model." "Pure Rust" "Representation Adapter" {
        properties {
            "Detail" "Assembles actions, habits files, charters, objectives, sidecars, manifests, templates, and archived facts into the domain model; projects charters to charters.schema.json."
        }
    }
    ${CORE}Actions = component "Actions language adapter" "Parses, lints, diffs, merges and formats .actions." "Rust" "Representation Adapter" {
        properties {
            "Detail" "Parses, lints, diffs, merges by UUID, and formats the .actions representation."
        }
    }
    ${CORE}Icalendar = component "iCalendar adapter" "Parses and renders VTODO resources around recurrence and reconciliation policy." "Pure Rust, RFC 5545" "Representation Adapter"
    ${CORE}Rdf = component "RDF publication adapter" "Projects the domain model to the application graph (app: vocabulary) as deterministic database-free quads and serializations; publishes no undeclared charter id." "Pure Rust, RDF" "Representation Adapter"
}

group "Framework details" {
    ${CORE}ActionsGrammar = component "tree-sitter-actions" "The .actions grammar." "tree-sitter" "Framework" {
        properties {
            "Detail" "Pinned generated grammar used by the actions language adapter."
        }
    }
    ${CORE}FormattingEngine = component "Topiary formatting engine" "Optional concrete formatter used to produce canonical .actions source." "Topiary" "Framework,Optional"
    ${CORE}MarkdownParser = component "CommonMark parser" "The one Markdown parser for charter documents and action notes, so every reader agrees on headings, code and sections." "pulldown-cmark" "Framework"
}

${CORE}Mutation -> ${CORE}Domain "Depends on domain semantics" "" "Core internal"
${CORE}Mutation -> ${CORE}Effects "Expresses decisions through the output port" "" "Core internal"
${CORE}Mutation -> ${CORE}Contracts "Depends on host-neutral requests" "" "Core internal"
${CORE}CalendarPolicy -> ${CORE}Domain "Depends on Plan and Action semantics" "" "Core internal"
${CORE}CalendarPolicy -> ${CORE}Effects "Expresses synchronization decisions through the output port" "" "Core internal"
${CORE}Reference -> ${CORE}Domain "Depends on domain identities and relationships" "" "Core internal"
${CORE}Workspace -> ${CORE}Domain "Produces the canonical in-memory model" "" "Core internal"
${CORE}Workspace -> ${CORE}Actions "Depends on the actions representation adapter" "" "Core internal"
${CORE}Workspace -> ${CORE}Icalendar "Depends on the calendar representation adapter" "" "Core internal"
${CORE}Workspace -> ${CORE}Reference "Uses reference resolution" "" "Core internal"
${CORE}Workspace -> ${CORE}MarkdownParser "Reads charter structure through the shared parser" "" "Core internal"
${CORE}Actions -> ${CORE}MarkdownParser "Reads action-note structure through the shared parser" "" "Core internal"
${CORE}Actions -> ${CORE}Domain "Maps plaintext to and from domain entities" "" "Core internal"
${CORE}Actions -> ${CORE}ActionsGrammar "Depends on the concrete grammar" "" "Core internal"
${CORE}Actions -> ${CORE}FormattingEngine "Optionally depends on the concrete formatter" "" "Core internal"
${CORE}Icalendar -> ${CORE}Domain "Maps VTODO resources to and from domain entities" "" "Core internal"
${CORE}Icalendar -> ${CORE}CalendarPolicy "Uses recurrence and reconciliation policy" "" "Core internal"
${CORE}Rdf -> ${CORE}Domain "Depends only on the domain model" "" "Core internal"
