---
id: 019fcb4a-6036-7dc6-a89f-404d8ad1013b
---
# Introducing Property Testing

One of the ideas that was brought up to me as a way to introduce more control
into the process is property testing. in particular, the ability to define
intention behind the code rather than simply a blunt test

this has a few potential benefits:

- reduce the amount of standard tests that can be replaced with a property-based
test suite
- build some generators with a strategy so that we are able to define really
strong generators for our work and define the work as we go by letting the
generator grow with the domain model and workspace models
-
