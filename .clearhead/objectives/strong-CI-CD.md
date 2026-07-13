---
id: 019f583e-ae16-7d7c-8c94-3b2c72e09897
---
# CI CD for the Edge

While building each version of the cli etc is fine for my beefy desktop, edge computers like the phone and my laptop need to be able to download a new binary that will just work rather than needing a new build each time

Rust is amazing, but one of the features i dont love is the need for it to take so long on a build meaning that we should limit the build process to a build server and make sure that most users operate using a pre-built binary rather than forcing them to build something new each time
