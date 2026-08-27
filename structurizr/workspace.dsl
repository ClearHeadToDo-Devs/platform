workspace "ClearHead Platform" "Structural architecture and dependency awareness in the local-first ClearHead platform." {

    model {
        person = person "Person" "Captures, plans, queries, and completes intentions."
        agent = person "Software or LLM agent" "Uses plaintext and command contracts to participate in work." "Agent"

        neovim = softwareSystem "Neovim" "Hosts the first-party ClearHead plugin and supplies editor APIs." "External"
        lspClients = softwareSystem "Other LSP clients" "Editors and tools that consume the standard ClearHead language server independently of Neovim." "External"
        calendarSync = softwareSystem "Calendar sync tooling" "A filesystem-vdir sync adapter such as vdirsyncer." "External"
        caldav = softwareSystem "CalDAV ecosystem" "CalDAV servers and calendar/task clients." "External"
        rdfConsumers = softwareSystem "RDF consumers" "Independent SPARQL engines, graph stores, and data pipelines that consume ClearHead exports." "External"

        clearhead = softwareSystem "ClearHead" "Local-first intention management over an authoritative plaintext workspace." {
            nvimPlugin = container "clearhead.nvim" "Editor adapter that provides commands, views, syntax support, and save/mutate/reload orchestration." "Lua, Neovim plugin" "Driver"

            cli = container "clearhead" "Synchronous command adapter for terminal workflows, durable mutations, calendar reconciliation, RDF export, and optional SPARQL." "Rust CLI" "Driver" {
                group "Drivers" {
                    cliCommands = component "Command interface" "Adapts terminal commands and machine-readable requests to application operations." "Rust, clap" "Driver"
                    cliQuery = component "Query host" "Composes workspace loading, RDF publication, presentation, and optional one-shot SPARQL." "Rust, optional Oxigraph" "Driver,Optional"
                }

                group "Native interface adapters — clearhead-workspace-fs" {
                    cliGateway = component "Workspace gateway" "Composes native loading and delivery around Core's host-neutral contracts." "Rust" "Interface Adapter"
                    cliLoader = component "Mount and snapshot adapter" "Maps physical mounts and bytes to Core resource snapshots and revisions." "Rust" "Interface Adapter,IO"
                    cliDurability = component "Durability adapter" "Maps Core effects to locking, journaling, recovery, fsync, and atomic filesystem operations." "Rust" "Interface Adapter,IO"
                    cliCalendarDelivery = component "Calendar filesystem adapter" "Maps VTODO vdir resources to Core calendar observations and prepared effects." "Rust" "Interface Adapter,IO"
                }

                group "Application policy — clearhead_core" {
                    coreMutation = component "Mutation use cases" "Decides action, charter, archive, and transaction changes without performing I/O." "Pure Rust" "Application"
                    coreCalendarPolicy = component "Recurrence and reconciliation policy" "Decides occurrence projection, calendar reconciliation, and deviation changes." "Pure Rust, RFC 5545 semantics" "Application"
                    coreReference = component "Reference resolution" "Resolves UUID, prefix, alias, and path references across the domain model." "Pure Rust" "Application"
                }

                group "Entities — clearhead_core" {
                    coreDomain = component "Domain model" "Owns Objective, Charter, Plan, Action, lifecycle state, diff, filter, and update semantics." "Pure Rust" "Domain"
                }

                group "Boundary contracts — clearhead_core" {
                    coreEffects = component "Resource/effect port" "Defines logical locations, snapshots, revisions, prepared mutations, preconditions, and effect batches." "Pure Rust" "Port"
                    coreContracts = component "Host-neutral contracts" "Defines shared configuration semantics, selectors, transaction requests, and typed verb outcomes." "Pure Rust" "Port"
                }

                group "Pure representation adapters — clearhead_core" {
                    coreWorkspace = component "Workspace projection" "Assembles actions, charters, sidecars, manifests, templates, and archived facts into the domain model." "Pure Rust" "Representation Adapter"
                    coreActions = component "Actions language adapter" "Parses, lints, diffs, and formats the .actions representation." "Rust" "Representation Adapter"
                    coreIcalendar = component "iCalendar adapter" "Parses and renders VTODO resources around recurrence and reconciliation policy." "Pure Rust, RFC 5545" "Representation Adapter"
                    coreRdf = component "RDF publication adapter" "Projects the domain model to deterministic database-free quads and serializations." "Pure Rust, RDF" "Representation Adapter"
                }

                group "Framework details" {
                    actionsGrammar = component "tree-sitter-actions" "Pinned generated grammar used by the actions language adapter." "tree-sitter" "Framework"
                    formattingEngine = component "Topiary formatting engine" "Optional concrete formatter used to produce canonical .actions source." "Topiary" "Framework,Optional"
                }
            }

            lsp = container "clearhead-lsp" "Standard language server adapter over stdio; it serves any compatible client and does not depend on a particular editor or on the CLI." "Rust, Tokio, Tower LSP" "Driver" {
                lspProtocol = component "LSP protocol adapter" "Adapts standard JSON-RPC requests to editor analysis providers." "Rust, Tokio, Tower LSP" "Driver"
                lspProviders = component "Editor use-case adapter" "Owns open-document state and composes diagnostics, formatting, navigation, completion, and semantic-token behavior." "Rust" "Interface Adapter"
                lspFs = component "Workspace filesystem adapter" "Loads native workspace context required by providers." "clearhead-workspace-fs" "Interface Adapter,IO"
                lspCore = component "Domain and workspace policy" "The linked clearhead_core application and domain behavior." "clearhead_core" "Application"
                lspParser = component "Open-document syntax parser" "Maintains tolerant syntax trees for unsaved editor buffers." "tree-sitter-actions" "Framework"
            }

            workspaceFiles = container "Workspace files" "Authoritative human-readable charters, actions, sidecars, configuration, saved SPARQL, and UUID-addressed archived facts." "Markdown, .actions, JSON, SPARQL" "Data Store,Authority"
            plansVdir = container "Plans vdir" "Server-agnostic interoperability boundary for recurring Plan and standalone Action VTODO projections." "iCalendar VTODO files" "Data Store,Projection"
        }

        person -> nvimPlugin "Uses the editor experience"
        person -> cliCommands "Uses terminal workflows"
        agent -> cliCommands "Depends on command and machine-readable output contracts"
        agent -> workspaceFiles "Depends on the plaintext contract"

        nvimPlugin -> neovim "Depends on editor APIs"
        nvimPlugin -> lspProtocol "Depends on the standard LSP port" "LSP JSON-RPC over stdio"
        nvimPlugin -> cliCommands "Depends on the public command interface" "subprocess"
        nvimPlugin -> workspaceFiles "Depends on the editable plaintext representation"
        lspClients -> lspProtocol "Depend on the standard LSP port" "LSP JSON-RPC over stdio"

        calendarSync -> plansVdir "Depends on the standard filesystem vdir" "iCalendar VTODO"
        calendarSync -> caldav "Depends on the CalDAV protocol"
        rdfConsumers -> cliQuery "Depend on the RDF publication interface" "TriG, N-Quads, JSON-LD"

        cliCommands -> cliGateway "Uses native workspace operations"
        cliCommands -> cliQuery "Uses query and publication capabilities"
        cliCommands -> coreMutation "Invokes application use cases"
        cliCommands -> coreContracts "Depends on typed requests and outcomes"

        cliQuery -> cliLoader "Uses workspace snapshots"
        cliQuery -> coreRdf "Uses canonical RDF publication"

        cliGateway -> cliLoader "Uses native snapshot acquisition"
        cliGateway -> cliDurability "Uses native effect delivery"
        cliGateway -> cliCalendarDelivery "Uses calendar filesystem delivery"
        cliGateway -> coreMutation "Invokes mutation decisions"
        cliGateway -> coreEffects "Implements the resource/effect port"
        cliGateway -> coreContracts "Depends on host-neutral workspace contracts"

        cliLoader -> workspaceFiles "Reads physical workspace resources"
        cliLoader -> plansVdir "Reads physical calendar resources"
        cliLoader -> coreEffects "Produces snapshots and revisions defined by"
        cliLoader -> coreWorkspace "Uses pure workspace assembly"

        cliDurability -> workspaceFiles "Delivers filesystem effects"
        cliDurability -> plansVdir "Delivers calendar-file effects"
        cliDurability -> coreEffects "Implements effect delivery defined by"

        cliCalendarDelivery -> plansVdir "Reads and writes VTODO resources"
        cliCalendarDelivery -> coreIcalendar "Uses VTODO representation logic"
        cliCalendarDelivery -> coreCalendarPolicy "Invokes reconciliation policy"
        cliCalendarDelivery -> cliDurability "Uses durable effect delivery"

        coreMutation -> coreDomain "Depends on domain semantics"
        coreMutation -> coreEffects "Expresses decisions through the output port"
        coreMutation -> coreContracts "Depends on host-neutral requests"
        coreCalendarPolicy -> coreDomain "Depends on Plan and Action semantics"
        coreCalendarPolicy -> coreEffects "Expresses synchronization decisions through the output port"
        coreReference -> coreDomain "Depends on domain identities and relationships"

        coreWorkspace -> coreDomain "Produces the canonical in-memory model"
        coreWorkspace -> coreActions "Depends on the actions representation adapter"
        coreWorkspace -> coreIcalendar "Depends on the calendar representation adapter"
        coreWorkspace -> coreReference "Uses reference resolution"
        coreActions -> coreDomain "Maps plaintext to and from domain entities"
        coreActions -> actionsGrammar "Depends on the concrete grammar"
        coreActions -> formattingEngine "Optionally depends on the concrete formatter"
        coreIcalendar -> coreDomain "Maps VTODO resources to and from domain entities"
        coreIcalendar -> coreCalendarPolicy "Uses recurrence and reconciliation policy"
        coreRdf -> coreDomain "Depends only on the domain model"

        lspProtocol -> lspProviders "Invokes editor analysis operations"
        lspProviders -> lspCore "Depends on domain and workspace policy"
        lspProviders -> lspFs "Uses native workspace context"
        lspProviders -> lspParser "Uses tolerant open-document syntax trees"
        lspFs -> workspaceFiles "Reads native workspace resources"
        lspFs -> lspCore "Implements linked Core workspace contracts"
    }

    views {
        systemContext clearhead "01-SystemContext" "Who is aware of ClearHead, and which external capabilities ClearHead depends on." {
            include person agent clearhead neovim lspClients calendarSync caldav rdfConsumers
            autoLayout lr
        }

        container clearhead "02-RuntimeDependencies" "Runtime containers and durable stores; every arrow means the source knows about or depends on the target." {
            include person agent neovim lspClients nvimPlugin cli lsp workspaceFiles plansVdir calendarSync caldav rdfConsumers
            autoLayout lr
        }

        component cli "03-CliComposition" "How the CLI driver depends on native adapters, application policy, ports, and representations." {
            include cliCommands cliQuery cliGateway cliLoader cliDurability cliCalendarDelivery coreMutation coreCalendarPolicy coreEffects coreContracts coreWorkspace coreRdf workspaceFiles plansVdir
            autoLayout lr
        }

        component cli "04-CleanArchitecture" "Dependency awareness across framework details, representation adapters, application policy, ports, and domain entities." {
            include coreDomain coreMutation coreCalendarPolicy coreReference coreEffects coreContracts coreWorkspace coreActions coreIcalendar coreRdf actionsGrammar formattingEngine
            autoLayout lr
        }

        component cli "05-DecisionDeliveryBoundary" "The native adapters that implement Core's resource/effect port without being known by Core." {
            include cliGateway cliLoader cliDurability cliCalendarDelivery coreMutation coreCalendarPolicy coreEffects coreWorkspace coreIcalendar workspaceFiles plansVdir
            autoLayout lr
        }

        component lsp "06-LanguageServer" "The server depends on protocol, provider, filesystem, Core, and parser abstractions; clients depend on the server, never the reverse." {
            include nvimPlugin lspClients lspProtocol lspProviders lspFs lspCore lspParser workspaceFiles
            autoLayout lr
        }

        container clearhead "07-DataBoundaries" "Authority and projection stores with the independent tools that depend on their standard representations." {
            include agent nvimPlugin cli lsp workspaceFiles plansVdir calendarSync caldav rdfConsumers
            autoLayout lr
        }

        styles {
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Agent" {
                shape Robot
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "External" {
                background #6b7280
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #111827
            }
            element "Driver" {
                background #2563a6
                color #ffffff
            }
            element "Framework" {
                background #8b8f97
                color #ffffff
            }
            element "Interface Adapter" {
                background #e6a04b
                color #2f1b05
            }
            element "Representation Adapter" {
                background #d7b65d
                color #2f2608
            }
            element "Application" {
                background #67b279
                color #102a17
            }
            element "Domain" {
                background #2f855a
                color #ffffff
                shape Hexagon
            }
            element "Port" {
                background #8b5cf6
                color #ffffff
                shape Hexagon
            }
            element "IO" {
                border dashed
            }
            element "Optional" {
                stroke #7c3aed
                strokeWidth 3
            }
            element "Data Store" {
                shape Cylinder
                background #f2ca72
                color #2f2608
            }
            element "Authority" {
                stroke #166534
                strokeWidth 5
            }
            element "Projection" {
                border dashed
            }
            relationship "Relationship" {
                color #4b5563
                routing Orthogonal
            }
        }
    }

    !docs documentation

    configuration {
        scope softwaresystem
    }
}
