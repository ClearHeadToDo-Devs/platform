---
alias: caldav-integration
state: Active
description: CalDAV server and adapter layer for serving clearhead plan collections over the network
---

# CalDAV Integration

Radicale serves clearhead's plan collections as CalDAV calendars. An adapter
script bridges the two systems — it reads the clearhead workspace layout and
charter titles to generate the metadata Radicale needs, without embedding
Radicale-specific knowledge into clearhead itself.

## Boundary

- clearhead owns the data: `$XDG_DATA_HOME/clearhead/plans/<alias>/`
- the adapter derives CalDAV collection properties from charter titles and writes
  `.Radicale.props` as a generated artifact
- Radicale serves what the adapter produces, knowing nothing about clearhead

## Derivation

Collection displayname is resolved in order:
1. frontmatter `title:` in `charters/<alias>.md`
2. first `# Header` in charter content
3. humanized alias (`project-b` → `Project B`)

## Access

Accessible over Tailscale only. Auth via htpasswd/bcrypt. No SSL termination
needed — Tailscale handles transport encryption.
