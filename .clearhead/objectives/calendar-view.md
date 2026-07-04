# Leveraging the calendar as a useful view
one of the core usecases is the ability to review, alter, and update our calendar with our upcoming actions and making that something that we want to structure our actions in such a way that we are able to understand our larger structure within the context of our finite time.

## where the calendar sits

now, not all actions are calendar events especially when we consider how VTODO is represented when there is no date "A "VTODO" calendar component without the "DTSTART" and "DUE" (or "DURATION") properties specifies a to-do that will be associated with each successive calendar date, until it is completed."

this shows clearly that we do NOT want this to be our default.

instead, VTODO represents actions that have either a do date or a due date. they represent "hard rocks" in our schedule that helps us understand what we need to do throughout our day or to know where the big deadlines in life loom.

## what it does NOT cover

this does NOT cover the structure of actions that lack any sort of start or due date, as these represent actions that should be completed whenever possible and therefore will live outside of the calendar entirely

the understanding is that our calendar integration will cover actions that are going to be calendar-related

## VTODO, NOT VEVENT

the ultimate vision is that VTODO items are orthogonal to the VEVENT calendar objects. this mirrors our semantic understanding as this represents events that have no completion state associated with them (birthdays for example)

dates have many uses, sometimes they are markers for us, sometimes they are just work that we want to structure

## the nature of the integration

this integration should be light, we will assume people are using the vdir format and making sure that we are able to have a bidirectional sync so that changes to vtodo objects are reflected in the actions list and vice-versa if we complete an upcoming or previous VTODO action, that should be represented within the calendar event

this will primarily be done by affecting the plan file which is in the form of a V* format while also allowing us to read those.

the beauty is by simply configuring them to be in the same  folder as a CALDAV folder, we can have natural bisync without building a specific format for it.

# what does success look like?
The calendar becomes a first-class interface for date-related actions and it becomes easy to edit and update structures in the calendar and have that move gracefully into the workspace and vice versa
