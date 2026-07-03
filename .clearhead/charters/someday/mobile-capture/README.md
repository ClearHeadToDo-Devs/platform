---
alias: mobile-capture
state: New
description: Inbound capture from the phone without abandoning local-first — append-only inbox plus file sync, letting existing tools do the hard part
---

# Mobile Capture

Local-first files make mobile the hard problem. The CalDAV work cleverly
solves the **outbound** half — scheduled actions appear on the phone's
calendar through Radicale. But **inbound** capture (the thought at the
grocery store) has no path, and un-capturable systems leak trust: every
uncaptured thought is a small lesson that the system can't be relied on.
Capture is the killer feature of every task system that survives contact with
real life.

## The shape — leverage, don't build

No mobile app. The insight that keeps this cheap:

- **append-only `inbox.actions`** — capture only ever appends lines, which
  makes sync conflicts nearly moot; two appends merge trivially, no CRDT
  resurrection required
- **Syncthing** (or any file sync the user already runs) moves the file —
  "do one thing well" applied to the sync problem
- any plaintext editor or share-sheet-to-file tool on the phone is the
  capture UI; the relaxed parser (Decision 6) tolerates sloppy thumb-typed
  lines, and `normalize` cleans them up on the desktop side
- alternates worth a look if file sync proves fiddly: email-to-inbox, or a
  tiny self-hosted capture endpoint that appends

The CRDT machinery (Decision 19) stays parked — this charter is the evidence
either that append-only is enough (likely) or that real merge semantics have
their first genuine consumer (informative either way).

## Promotion trigger

Promote on the felt pain: the first week where lost mobile thoughts
noticeably erode trust in the inbox — or when the CalDAV outbound loop is
stable enough that inbound is the obvious next asymmetry to fix.

## First actions on promotion

1. spec the append-only inbox contract (what a capture line may omit;
   normalize's responsibilities) in the specifications repo
2. prove the Syncthing round-trip: phone append → desktop normalize → charter
   filing, one week of real use
3. document the recommended phone-side capture tools rather than building one
4. record what conflicts actually occurred — the CRDT bet's first real data
