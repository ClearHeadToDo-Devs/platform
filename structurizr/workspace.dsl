workspace "ClearHead Platform" "Structural architecture and dependency awareness in the local-first ClearHead platform." {

    model {
        person = person "Person" "Captures, plans, queries, and completes intentions."
        agent = person "Software or LLM agent" "Uses plaintext and command contracts to participate in work." "Agent"

        neovim = softwareSystem "Neovim" "Hosts the first-party ClearHead plugin and supplies editor APIs." "External"
        lspClients = softwareSystem "Other LSP clients" "Editors that use the language server without Neovim." "External" {
            properties {
                "Detail" "Editors and tools that consume the standard ClearHead language server independently of Neovim."
            }
        }
        calendarSync = softwareSystem "Calendar sync tooling" "A filesystem-vdir sync adapter such as vdirsyncer." "External"
        caldav = softwareSystem "CalDAV ecosystem" "CalDAV servers and calendar/task clients." "External"
        rdfConsumers = softwareSystem "RDF consumers" "Independent SPARQL engines, graph stores, and data pipelines that consume ClearHead exports." "External"
        git = softwareSystem "Git" "Version control for a workspace; configured to merge .actions files through ClearHead's merge driver." "External"

        clearhead = softwareSystem "ClearHead" "Local-first intention management over an authoritative plaintext workspace." {
            nvimPlugin = container "clearhead.nvim" "Commands, views and save orchestration inside Neovim." "Lua, Neovim plugin" "Driver" {
                properties {
                    "Detail" "Editor adapter that provides the :Clearhead command tree, <Plug> mappings, query, notes and command-output views, syntax support, and save/mutate/reload orchestration."
                }
            }

            cli = container "clearhead" "Synchronous command binary from clearhead-cli; composes its cli and query frontends with the shared filesystem adapter and pure Core." "Rust, clearhead-cli crate" "Driver" {
                group "Drivers" {
                    cliCommands = component "Command interface" "Adapts terminal commands and machine-readable requests to application operations." "Rust, clap" "Driver"
                    cliQuery = component "Query host" "Composes workspace loading, RDF publication, presentation, and optional one-shot SPARQL." "Rust, optional Oxigraph" "Driver,Optional"
                }

                group "Native interface adapters — clearhead-cli/filesystem" {
                    cliGateway = component "Workspace gateway" "Composes native loading and delivery around Core's host-neutral contracts." "Rust" "Interface Adapter"
                    cliLoader = component "Mount and snapshot adapter" "Maps physical mounts and bytes to Core resource snapshots and revisions." "Rust" "Interface Adapter,IO"
                    cliDurability = component "Durability adapter" "Maps Core effects to precondition checks, additive delivery, fsync, and atomic single-file writes; interrupted batches remain recoverable without a journal." "Rust" "Interface Adapter,IO"
                    cliCalendarDelivery = component "Calendar filesystem adapter" "Maps VTODO vdir resources to Core calendar observations and prepared effects." "Rust" "Interface Adapter,IO"
                }

                !var CORE core
                !include core.dsl
            }

            lsp = container "clearhead-lsp" "Separate stdio binary from clearhead-cli; shares the crate's filesystem adapter and Core dependency but does not call the CLI frontend or depend on an editor." "Rust, clearhead-cli crate, Tokio, Tower LSP" "Driver" {
                lspProtocol = component "LSP protocol adapter" "Turns LSP requests into editor operations." "Rust, Tokio, Tower LSP" "Driver" {
                    properties {
                        "Detail" "Adapts standard JSON-RPC requests to editor analysis providers."
                    }
                }
                lspProviders = component "Editor use-case adapter" "Holds open documents; computes diagnostics and edits." "Rust" "Interface Adapter" {
                    properties {
                        "Detail" "Owns open-document state and composes diagnostics, formatting, navigation, completion, and semantic-token behavior."
                    }
                }
                lspFs = component "Shared filesystem adapter" "Finds and loads the workspace; stamps sidecars." "Rust, clearhead-cli/filesystem" "Interface Adapter,IO" {
                    properties {
                        "Detail" "Loads native workspace context, and stamps sidecars on save, through the clearhead-cli crate's filesystem module, shared with the command binary."
                    }
                }

                !var CORE lspCore
                !include core.dsl
            }

            workspaceFiles = container "Workspace files" "The plaintext workspace: the source of truth." "Markdown, .actions, JSON, SPARQL" "Data Store,Authority" {

                properties {

                    "Detail" "Authoritative human-readable charters, objectives, actions, habits files, sidecars with notes, configuration, saved SPARQL, and UUID-addressed archived facts."

                }

            }
            plansVdir = container "Plans vdir" "Server-agnostic interoperability boundary for VTODO projections: a recurring Plan projects a Habit, a one-off Plan an Action's @ block." "iCalendar VTODO files" "Data Store,Projection"
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
        git -> cliCommands "Invokes the .actions merge driver" "clearhead merge-actions %O %A %B"

        cliCommands -> cliGateway "Uses native workspace operations"
        cliCommands -> cliQuery "Uses query and publication capabilities"
        cliCommands -> coreMutation "Invokes application use cases"
        cliCommands -> coreContracts "Depends on typed requests and outcomes"
        cliCommands -> coreActions "Invokes the semantic .actions merge"

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



        lspProtocol -> lspProviders "Delegates analysis to"
        lspProtocol -> lspCoreActions "Diffs and formats with"
        lspProtocol -> lspCoreReference "Resolves definitions with"
        lspProtocol -> lspFs "Loads the workspace and stamps sidecars with"
        lspProviders -> lspCoreActions "Parses and lints with"
        lspProviders -> lspCoreWorkspace "Checks workspace rules with"
        lspProviders -> lspFs "Finds the workspace with"
        lspProviders -> lspCoreActionsGrammar "Parses unsaved buffers with"
        lspFs -> workspaceFiles "Reads; writes sidecars"
        lspFs -> lspCoreWorkspace "Assembles the model with"

        !include source-entries.dsl
    }

    views {
        systemContext clearhead "01-SystemContext" "Who is aware of ClearHead, and which external capabilities ClearHead depends on." {
            include person agent clearhead neovim lspClients calendarSync caldav rdfConsumers git
            autoLayout lr 450 300
        }

        container clearhead "02-RuntimeDependencies" "Runtime containers and durable stores; every arrow means the source knows about or depends on the target." {
            include person agent neovim lspClients nvimPlugin cli lsp workspaceFiles plansVdir calendarSync caldav rdfConsumers git
            autoLayout lr 450 300
        }

        component cli "03-CliComposition" "How the CLI driver depends on native adapters, application policy, ports, and representations." {
            include git cliCommands cliQuery cliGateway cliLoader cliDurability cliCalendarDelivery coreMutation coreCalendarPolicy coreEffects coreContracts coreWorkspace coreActions coreRdf workspaceFiles plansVdir
            autoLayout lr 450 300
        }

        component cli "04-CleanArchitecture" "Dependency awareness across framework details, representation adapters, application policy, ports, and domain entities." {
            include coreDomain coreMutation coreCalendarPolicy coreReference coreEffects coreContracts coreWorkspace coreActions coreIcalendar coreRdf coreActionsGrammar coreFormattingEngine coreMarkdownParser
            autoLayout lr 450 300
        }

        component cli "05-DecisionDeliveryBoundary" "The native adapters that implement Core's resource/effect port without being known by Core." {
            include cliGateway cliLoader cliDurability cliCalendarDelivery coreMutation coreCalendarPolicy coreEffects coreWorkspace coreIcalendar workspaceFiles plansVdir
            autoLayout lr 450 300
        }

        component lsp "06-LanguageServer" "The server and the parts of the linked Core it calls; clients depend on the server, never the reverse." {
            include nvimPlugin lspClients lspProtocol lspProviders lspFs lspCoreActions lspCoreWorkspace lspCoreReference lspCoreActionsGrammar workspaceFiles
            exclude "relationship.tag==Core internal"
            exclude "nvimPlugin -> workspaceFiles"
            autoLayout lr 450 300
        }

        container clearhead "07-DataBoundaries" "Authority and projection stores with the independent tools that depend on their standard representations." {
            include agent nvimPlugin cli lsp workspaceFiles plansVdir calendarSync caldav rdfConsumers
            autoLayout lr 450 300
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
                routing Direct
            }
        }
    }

    !docs documentation

    configuration {
        scope softwaresystem
    }
}
