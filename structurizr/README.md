# ClearHead Structurizr workspace

[`workspace.dsl`](workspace.dsl) is the authoritative model of **structural
dependency and architectural awareness** in the current ClearHead platform.
Every relationship arrow means that the source knows about, invokes, implements,
or otherwise depends on the target. Response messages and bidirectional data
flow do not reverse those arrows.

The seven views use progressive disclosure:

1. System context
2. Runtime container dependencies
3. CLI composition
4. Clean Architecture layers inside Core
5. The decision/delivery boundary
6. The editor-independent language server
7. Authority and projection data boundaries

Runtime order is deliberately separate. See the
[Mermaid workflow diagrams](../docs/workflows.md) for editing, durable mutation,
calendar synchronization, and RDF publication sequences.

Color identifies Clean Architecture responsibility: blue elements are drivers,
grey elements are framework details, gold elements adapt representations,
orange elements adapt native interfaces, green elements contain application
policy, dark green is the domain, and purple elements are host-neutral ports.
Dashed borders indicate I/O or projected data, while a thick green store border
marks authoritative data.

The component model shows shared Core and filesystem-adapter code inside each
executable because they are linked libraries, not independently deployed
services. The detailed Core view uses the CLI as the reference composition; the
LSP view collapses that same library to keep the server boundary legible.

## Serve on a headless Tailscale node

The Compose service binds only to loopback; it is not exposed to the LAN or the
public internet. First authorize the deployment user to manage this node's
Tailscale Serve configuration (one-time host setup):

```sh
sudo tailscale set --operator="$USER"
```

Then run the launch script. It starts the container, waits for Structurizr, and
configures Tailscale Serve as the private HTTPS frontend:

```sh
structurizr/serve-tailscale
```

The command prints the tailnet URL, normally
`https://<machine>.<tailnet>.ts.net/`. Only clients permitted by the tailnet ACL
can reach it. This uses **Tailscale Serve**, not Funnel.

The node currently dedicates its root Tailscale Serve route to Structurizr. If
other applications later share this node, manage the Serve configuration
explicitly instead of resetting it globally.

To stop only the container:

```sh
docker compose -f structurizr/compose.yaml down
```

Tailscale retains its proxy configuration, so requests will fail closed while
the backend is stopped. Use `tailscale serve reset` only when you intend to
remove every Serve route configured on this node.

Set a different loopback port when necessary:

```sh
STRUCTURIZR_PORT=9090 structurizr/serve-tailscale
```

The image is pinned rather than using `latest`; update the image and validate
the workspace together when upgrading Structurizr.

## Run locally on a desktop

Use the local launcher when the browser and Structurizr are on the same machine:

```sh
structurizr/serve-local
```

It starts the container in the background, waits until it is ready, and prints
the browser URL (normally <http://localhost:8080/>). It does not require or
configure Tailscale. The loopback binding keeps Structurizr unavailable from
other machines on the LAN.

To use another local port:

```sh
STRUCTURIZR_PORT=9090 structurizr/serve-local
```

If Docker reports a socket permission error, add the desktop user to the Docker
group and then sign out and back in so the new group membership takes effect:

```sh
sudo usermod -aG docker "$USER"
```

## Validate the model

Use the same pinned container image:

```sh
docker compose -f structurizr/compose.yaml run --rm --no-deps \
  structurizr validate -workspace /usr/local/structurizr/workspace.dsl
```

Structurizr local may create `workspace.json` to hold UI state and manually
saved layout. It is intentionally ignored because the checked-in views use
`autoLayout`; `workspace.dsl` remains canonical.

## Updating the architecture

1. Change the model before changing individual views.
2. Read every Structurizr arrow as “source is aware of or depends on target.”
3. Put event order, responses, retries, and branching in Mermaid workflows.
4. Keep runtime architecture separate from repository or product-roadmap
   diagrams.
5. Model future components only after they exist; document planned seams as
   text instead.
6. Run validation and inspect the affected focused views before committing.
