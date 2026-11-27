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

// Core internals, once for each container that links Core
!var CORE core
!include core-source-entries.dsl
!var CORE lspCore
!include core-source-entries.dsl

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
