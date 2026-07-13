---
id: 019f5841-1012-7fa2-9d9d-57dec5d906c7
objectives: [calendar-view, data-integration]
---
# VTODO Bidirectional sync 
While the VEVENT is fine for integration, the true next-steps for us will be about building out the VTODO integration such that we can manage scheduled actions entirely from the calendar view exactly where they were always destined to be.

while we got the sync mechanism down for a single column we have a few functionality and non-functional goals for this charter

## Bidrectional sync
the first goal is that both layers can both read and edit. changes in actions should flow to the calendar, changes in the events should flow to actions

this includes:
- start date
- due date
- state 
- title
- description

we will use most of the integration points that already exist like:
- templates
- syncing fields via sidecar

still, we are going to need to go another level of strong to get it all working properly and we are going to want to be doing the most cononacle version of this so that we are able to do this right rather than just this event structure we have

## caldav-compatible

the HOW should come down to integrations with the caldav implementations, and not even that, since we largely conform to the vdir format we should be able to get this all setup by just changing the plan path of our workspace but doing it right will take some thought
