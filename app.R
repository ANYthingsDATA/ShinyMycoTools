# app.R — Posit Connect Cloud entrypoint (thin launcher)
# -----------------------------------------------------------------------------
# The MycoTools data platform — the full Shiny UI *and* all data processing —
# now lives inside the MycoTools package (inst/shiny/, launched interactively
# via MycoTools::run_app()).
#
# This repository is only the Connect Cloud deployment shell: it pins the
# MycoTools version (installed from GitHub — see manifest.json / renv.lock)
# and serves the bundled app object below.
#
#   Local dev : MycoTools::run_app()
#   Deploy    : Connect Cloud sources this file and serves the returned app.
#
# Do not re-introduce app or processing code here — change it in the
# MycoTools package, push a tagged release, then bump the pin (see CLAUDE.md).
# -----------------------------------------------------------------------------

library(MycoTools)

shiny::shinyAppDir(
  system.file("shiny", package = "MycoTools")
)
