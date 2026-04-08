# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Running the App

```r
shiny::runApp("app.R")
```

Or open `app.R` in RStudio and click **Run App**.

## Dependency Management

Uses `renv`. The `.Rprofile` activates it automatically.

```r
renv::restore()    # restore packages from lockfile
renv::snapshot()   # after adding new packages
```

Key packages: `shiny`, `bslib`, `DT`, `plotly`, `dplyr`, `tidyr`, `lubridate`, `readr`, `readxl`, `writexl`, `rlang`, `parsedate`, `tools`.

## Architecture

`app.R` is the single-file Shiny application. It sources all processing functions from `R/` at startup and builds a 4-tab `bslib` navbar app:

| Tab | Purpose |
|-----|---------|
| **Upload** | File import via `import_data()` — auto-detects CSV delimiter/decimal, reads Excel |
| **Configure** | Column mapping → date completion → MYCOindex thresholds → optional season variables |
| **Dashboard** | Interactive plotly visualisations filtered by date range and sensor |
| **Download** | Export processed data as CSV, CSV2, or Excel |

State is held in `reactiveValues(raw_data, processed_data)` and passed between tabs.

## Processing Pipeline (server-side)

Steps execute sequentially when **Run Processing** is clicked:

1. `define_variables_date()` / `define_variables_datetime()` → `gen_date`, `gen_datetime`, `gen_time`
2. `define_variables_sensorID()` → `gen_sensorID`
3. `define_variables_temp/rhum/wood/ohm()` → `gen_temp`, `gen_rhum`, `gen_wood`, `gen_ohm`
4. `make_complete_date()` → generates a date spine (group_vars + date column only), then **left-joined** back to the full data to fill missing rows with `NA`
5. `make_mycoindex_mold/temp/wood()` → `MIx_mold`, `MIx_temp`, `MIx_wood` (values: 0, 0.25/0.2, 0.5/0.4, 1)
6. `add_date_seasons()` → `gen_season`, `gen_year_season`, `gen_isoweek`, `gen_isoyear`, month columns

**Important:** all `define_variables_*` and `make_*` functions use tidy evaluation (`{{ }}`). In Shiny, dynamic column names are passed with `!!sym(input$col_name)`. Where the column must be a bare name inside `rlang::inject()`, use `rlang::sym("col_name")`.

## R/ Functions

| File | Exports |
|------|---------|
| `import_dataset.R` | `import_data()` — CSV/Excel reader |
| `define_variables.R` | `define_variables_datetime()`, `define_variables_date()`, `define_variables_sensorID()`, `define_variables_temp/rhum/wood/ohm()` |
| `add_variables.R` | `add_date_seasons()` |
| `make_complete_date.R` | `make_complete_date()` — returns date spine only (not full data) |
| `make_mycoindex_mold/temp/wood.R` | respective index functions |
| `make_rolling.R` | **Not sourced** — references `make_rolling_time_mean()` which is defined in the private MycoTools package, not in this repo |

## Branding

Colours are placeholders at the top of `app.R`:

```r
BRAND_PRIMARY   <- "#1B5E20"   # TODO: replace with ANYthings/Mycoteam primary
BRAND_SECONDARY <- "#2E7D32"   # TODO: replace with brand secondary
```

The `app_theme` `bs_theme()` call and `MIX_COLORSCALE` (heatmap colour ramp) may also need updating.

## Posit Connect Cloud Deployment

Deploy with `rsconnect::deployApp()` or the RStudio push-button. The `renv.lock` pins all package versions. For the private MycoTools package, functions are sourced directly from `R/` so no package installation is required on the server.
