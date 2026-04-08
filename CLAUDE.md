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

**Important — tidy evaluation:**
- `define_variables_*` and `make_mycoindex_*` use `{{ }}` inside `dplyr::mutate()`. In Shiny, pass dynamic column names as `!!sym(input$col_name)` — R's lazy evaluation means the bare name is captured by `{{ }}` before dplyr resolves it in the data mask.
- `make_complete_date()` accepts **plain character column names** (not symbols). Pass strings directly: `input_date = "gen_date"`, `input_sensor_id = "gen_sensorID"`. No `rlang::inject()` needed.
- Never use `{{ }}` outside a data-masked verb (`mutate`, `filter`, `summarise`, etc.) — bare column references outside those contexts cause "object not found" errors.

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

This is an ANYthings client deliverable — full ANYthings branding applies.

### Colors

Defined as constants at the top of `app.R`. Use these values:

**Mycoteam brand (primary UI)**

| Role | Name | Hex |
|------|------|-----|
| Primary — navbar, buttons, active | Mycoteam Teal | `#57A19F` |
| Accent — highlights, badges | Mycoteam Yellow-Green | `#C9CC64` |

**ANYthings system palette**

| Role | Name | Hex |
|------|------|-----|
| Headings | ANYthings Black | `#1A1A1A` |
| Background | White | `#FFFFFF` |
| Alerts (sparingly) | Signal Red | `#E03C31` |
| Links / data viz | System Blue | `#0B3D91` |
| Body text | Dark Grey | `#333333` |
| Captions / muted | Medium Grey | `#767676` |
| Borders / rules | Light Grey | `#D9D9D9` |
| Alt row backgrounds | Near White | `#F5F5F5` |

Signal Red is for errors and alerts only — not decorative. The MYCOindex heatmap uses a functional risk scale (white → yellow → orange → red) — do not replace with brand colors.

### Typography

Web/Shiny font stack:
- **Sans-serif (UI):** Inter (Google Fonts) — headings, labels, body
- **Monospace (code/data):** JetBrains Mono — inline code, verbatim output

Load Inter via `bslib::bs_theme(base_font = bslib::font_google("Inter"))`.

### Shiny / bslib

- Layout: `bslib::page_navbar()` with `card()`-based content — already in use
- White card backgrounds, minimal borders, generous padding
- Tables: `DT::datatable()` with light grey header (`#F5F5F5`), thin `#D9D9D9` gridlines
- No gradients, drop shadows, or decorative color fills

### Logo

Files go in `www/`. Two variants:

| File | Use |
|------|-----|
| `any_logo_white_back_v3.png` | Horizontal — navbar, header |
| `square_any_logo_white_back_v3.png` | Square — favicon, app icon |

Always use the PNG files directly — never re-render, crop, recolor, or add effects. Use the horizontal variant in the navbar. For dark backgrounds use the logo as-is (white container form — do not invert).

## Posit Connect Cloud Deployment

Deploy with `rsconnect::deployApp()` or the RStudio push-button. The `renv.lock` pins all package versions. For the private MycoTools package, functions are sourced directly from `R/` so no package installation is required on the server.
