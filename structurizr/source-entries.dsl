// Optional reading entry points for first-party architectural components.
// These are starts, not exhaustive ownership maps.

// CLI composition and native delivery
!element cliCommands {
    url "https://github.com/ClearHeadToDo-Devs/clearhead-core/tree/main/crates/clearhead-cli/src/cli"
}

!element cliQuery {
    url "https://github.com/ClearHeadToDo-Devs/clearhead-core/tree/main/crates/clearhead-cli/src/query"
}

!element cliGateway {
    url "https://github.com/ClearHeadToDo-Devs/clearhead-core/blob/main/crates/clearhead-cli/src/filesystem/mod.rs"
}

!element cliLoader {
    url "https://github.com/ClearHeadToDo-Devs/clearhead-core/blob/main/crates/clearhead-cli/src/filesystem/mounts.rs"
}

!element cliDurability {
    url "https://github.com/ClearHeadToDo-Devs/clearhead-core/blob/main/crates/clearhead-cli/src/filesystem/durability.rs"
}

!element cliCalendarDelivery {
    url "https://github.com/ClearHeadToDo-Devs/clearhead-core/blob/main/crates/clearhead-cli/src/filesystem/calendar.rs"
}

// Core internals
!element coreMutation {
    url "https://github.com/ClearHeadToDo-Devs/clearhead-core/tree/main/crates/clearhead-core/src/workspace"
}

!element coreCalendarPolicy {
    url "https://github.com/ClearHeadToDo-Devs/clearhead-core/blob/main/crates/clearhead-core/src/workspace/calendar/reconcile.rs"
}

!element coreReference {
    url "https://github.com/ClearHeadToDo-Devs/clearhead-core/blob/main/crates/clearhead-core/src/reference.rs"
}

!element coreDomain {
    url "https://github.com/ClearHeadToDo-Devs/clearhead-core/tree/main/crates/clearhead-core/src/domain"
}

!element coreEffects {
    url "https://github.com/ClearHeadToDo-Devs/clearhead-core/blob/main/crates/clearhead-core/src/workspace/resource.rs"
}

!element coreContracts {
    url "https://github.com/ClearHeadToDo-Devs/clearhead-core/blob/main/crates/clearhead-core/src/lib.rs"
}

!element coreWorkspace {
    url "https://github.com/ClearHeadToDo-Devs/clearhead-core/tree/main/crates/clearhead-core/src/workspace/store"
}

!element coreActions {
    url "https://github.com/ClearHeadToDo-Devs/clearhead-core/tree/main/crates/clearhead-core/src/workspace/actions"
}

!element coreIcalendar {
    url "https://github.com/ClearHeadToDo-Devs/clearhead-core/blob/main/crates/clearhead-core/src/workspace/calendar/ics.rs"
}

!element coreRdf {
    url "https://github.com/ClearHeadToDo-Devs/clearhead-core/tree/main/crates/clearhead-core/src/rdf"
}

!element actionsGrammar {
    url "https://github.com/ClearHeadToDo-Devs/tree-sitter-actions"
}

// Language server composition
!element lspProtocol {
    url "https://github.com/ClearHeadToDo-Devs/clearhead-core/blob/main/crates/clearhead-cli/src/lsp/handlers.rs"
}

!element lspProviders {
    url "https://github.com/ClearHeadToDo-Devs/clearhead-core/blob/main/crates/clearhead-cli/src/lsp/providers.rs"
}

!element lspFs {
    url "https://github.com/ClearHeadToDo-Devs/clearhead-core/blob/main/crates/clearhead-cli/src/filesystem/mounts.rs"
}

!element lspCore {
    url "https://github.com/ClearHeadToDo-Devs/clearhead-core/blob/main/crates/clearhead-core/src/lib.rs"
}

!element lspParser {
    url "https://github.com/ClearHeadToDo-Devs/tree-sitter-actions"
}
