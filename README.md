# ShinyMycoTools

A Shiny web application for processing and visualising indoor climate and moisture sensor data. Built for [Mycoteam](https://mycoteam.no) by [ANYthings](https://anythings.no).

## What it does

ShinyMycoTools takes raw logger data from indoor climate sensors and produces a standardised, analysis-ready dataset with computed risk indices. The workflow is:

1. **Upload** — import CSV, CSV2 (semicolon-delimited), TXT, or Excel files from any logger brand. Preview raw file content before importing to verify delimiter and encoding.
2. **Configure** — map raw column names to standard variables, optionally complete missing timestamps to a regular time series, compute MYCOindex risk scores, and add calendar variables.
3. **Dashboard** — explore the processed data interactively: time series, distributions, summary statistics, and a MYCOindex heatmap. Filter by date range and sensor. Rename sensors with custom labels.
4. **Download** — export the processed dataset as CSV, CSV2, or Excel with a custom filename.

## MYCOindex

The MYCOindex is a risk scoring system for mold, temperature, and wood moisture conditions. Each index produces values of 0, 0.25/0.2, 0.5/0.4, or 1, where 1 indicates conditions most favorable for mold growth. Thresholds are configurable in the Configure tab.

| Index | Input column | Output |
|-------|-------------|--------|
| MYCOindex Mold | Relative humidity | `MIx_mold` |
| MYCOindex Temp | Temperature | `MIx_temp` |
| MYCOindex Wood | Wood moisture | `MIx_wood` |

## Getting started

### Prerequisites

- R ≥ 4.1
- RStudio (recommended)

### Install dependencies

This project uses [`renv`](https://rstudio.github.io/renv/) for reproducible package management.

```r
renv::restore()
```

If you don't have a `renv.lock` yet (fresh clone):

```r
renv::snapshot()
```

### Run the app

```r
shiny::runApp("app.R")
```

Or open `app.R` in RStudio and click **Run App**.

## Supported file formats

| Format | Notes |
|--------|-------|
| CSV (`,`) | Auto-detected delimiter |
| CSV2 (`;`) | Auto-detected or manually selected |
| TSV (`\t`) | Auto-detected or manually selected |
| Excel (`.xlsx`, `.xls`) | Sheet selection supported |

Encoding is assumed UTF-8. Skip lines and comment prefixes (e.g. `#`) are configurable before importing.

## Generated columns

After processing, the following standardised columns are added:

| Column | Type | Description |
|--------|------|-------------|
| `gen_datetime` | POSIXct | Standardised datetime |
| `gen_date` | Date | Date component |
| `gen_time` | chr | Time as HH:MM:SS |
| `gen_sensorID` | chr | Sensor identifier |
| `gen_temp` | dbl | Temperature (°C) |
| `gen_rhum` | dbl | Relative humidity (%) |
| `gen_wood` | dbl | Wood moisture (%) |
| `gen_ohm` | dbl | Ohm (raw resistance) |
| `MIx_mold` | dbl | MYCOindex — mold risk |
| `MIx_temp` | dbl | MYCOindex — temperature risk |
| `MIx_wood` | dbl | MYCOindex — wood moisture risk |
| `gen_season` | chr | Season (Winter/Spring/Summer/Fall) |
| `gen_year_season` | chr | Year + season (e.g. "2024, Winter") |
| `gen_isoweek` | int | ISO 8601 week number |
| `gen_isoyear` | int | ISO year |
| `gen_date_month_num` | int | Month (1–12) |
| `gen_date_month_lab` | chr | Month label (Jan–Dec) |

## Project structure

```
app.R                      # Single-file Shiny application
R/
  import_dataset.R         # import_data() — CSV/Excel reader
  define_variables.R       # Column standardisation functions
  add_variables.R          # add_date_seasons()
  make_complete_date.R     # make_complete_date() — date spine generator
  make_mycoindex_mold.R    # make_mycoindex_mold()
  make_mycoindex_temp.R    # make_mycoindex_temp()
  make_mycoindex_wood.R    # make_mycoindex_wood()
  make_rolling.R           # (not sourced — requires private MycoTools package)
www/                       # Static assets (logos)
renv/                      # renv environment
manifest.json              # Posit Connect Cloud deployment manifest
```

## Deployment

The app is deployed on [Posit Connect Cloud](https://connect.posit.cloud) via GitHub integration. On every push, Connect pulls from the `master` branch and installs dependencies from `manifest.json`.

To regenerate the manifest after adding packages:

```r
rsconnect::writeManifest()
```

Then commit and push `manifest.json`.

## Built by

[ANYthings](https://anythings.no) — data science and epidemiological consulting by Anders Benteson Nygaard.
