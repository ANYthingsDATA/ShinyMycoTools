# Handoff: MycoTools Data Platform — Visual Redesign

## Overview

This package contains a high-fidelity HTML prototype of the **MycoTools Data Platform** — a Shiny app built by ANYthings for Mycoteam. The prototype demonstrates the target visual design for the app's four tabs (Upload, Configure, Dashboard, Download), including all interactive states, chart styles, and the MYCOindex risk heatmap.

## About the Design Files

The files in this bundle (`MycoTools Dashboard.html` and `charts.jsx`) are **design references created in HTML/React** — prototypes showing intended look and behaviour. They are not production code to ship directly.

Your task is to **recreate these designs inside the existing `app.R` Shiny codebase**, using `bslib`, `DT`, `plotly`, and inline CSS/HTML helpers that are already present in that file. Do not port the app to a different framework.

The source Shiny file is `app.R` (provided separately). Cross-reference every section below against that file.

## Fidelity

**High-fidelity.** The prototype uses final colours, typography, spacing, and interactions. Recreate as closely as Shiny/bslib allows. Where Plotly or bslib impose limits, apply the palette and typography as closely as possible and note any deltas in a comment.

---

## Design Tokens

### Brand colours

| Token | Hex | Usage in app.R |
|---|---|---|
| `BRAND_PRIMARY` (Mycoteam Teal) | `#57A19F` | Navbar bg, primary buttons, focus rings |
| `BRAND_SECONDARY` (Yellow-Green) | `#C9CC64` | Accents (sparingly) |
| `BRAND_BLACK` | `#1A1A1A` | Headings, active nav stripe, top accent bar |
| `BRAND_SIGNAL` (Signal Red) | `#E03C31` | Alerts, high-risk counts, danger states |
| `BRAND_BLUE` (System Blue) | `#0B3D91` | Links, column references, Plotly primary series |
| `BRAND_DARK_GREY` | `#333333` | Body text |
| `BRAND_MID_GREY` | `#767676` | Captions, section labels |
| `BRAND_LIGHT_GREY` | `#D9D9D9` | Borders, table gridlines, card borders |
| `BRAND_NEAR_WHITE` | `#F5F5F5` | Page background, alternate table rows |
| `BRAND_OFF_WHITE` | `#FAFAFA` | Card backgrounds (slide surfaces) |

### Data visualisation palette (NYCTA-inspired)

Used for sensor series colours in Plotly charts, in order:

| Sensor slot | Colour | Hex |
|---|---|---|
| 1 (S-01 / first sensor) | System Blue | `#0B3D91` |
| 2 (S-02 / second sensor) | Signal Red | `#E03C31` |
| 3 (S-03 / third sensor) | Transit Green | `#00933C` |
| 4+ | Line Orange | `#FF6319` |
| 5+ | Line Purple | `#6E267B` |

### MYCOindex risk colour scale

Used in the Plotly heatmap (`colorscale` parameter) and any risk badges:

```r
MIX_COLORSCALE <- list(
  list(0,    "#2E7D32"),   # No risk — dark green
  list(0.25, "#81C784"),   # Low — light green
  list(0.5,  "#FDD835"),   # Moderate — yellow
  list(1,    "#C62828")    # High — deep red
)
```

For cells with `NA` / no data, use `#E8F5E9` (near-white green).

### Typography

```r
base_font    = font_google("Inter")
heading_font = font_google("Inter", wght = "700")
code_font    = font_google("JetBrains Mono")
font_scale   = 0.9
```

- Section labels (e.g. "IMPORT FILE", "SENSORS"): 9px, `font-weight: 700`, `text-transform: uppercase`, `letter-spacing: 0.08em`, colour `#767676`
- Card headers / sub-tab labels: 11–12px, `font-weight: 700`, colour `#1A1A1A`
- Table headers: `font-weight: 700`, background `#F5F5F5`
- Monospace values (stats, column names): `JetBrains Mono`, 10–11px

### Spacing

- Card padding: `14px 16px`
- Grid gap between cards: `12–16px`
- Page padding: `16px`
- Sidebar width: `240px` (Dashboard tab), `260px` (bslib sidebar)

### Borders & Radii

- **All border-radius: 0** — this is a hard rule of the ANYthings/NASA aesthetic. Override bslib's default rounded corners everywhere.
- Card border: `1px solid #D9D9D9`
- No drop shadows
- Active sidebar nav item: `3px solid #1A1A1A` left border, `background: #F5F5F5`

---

## Screens & Views

### Global chrome

**Top accent stripe** — 3px solid `#1A1A1A` bar above the navbar. Add via:
```r
tags$div(style = "height: 3px; background: #1A1A1A; position: sticky; top: 0; z-index: 9999;")
```

**Navbar** (`page_navbar` / `bs_theme`)
- Background: `#57A19F`
- Text: `#FFFFFF`
- Active tab: white background, teal text (`#57A19F`), no rounded corners
- Disabled tabs (before data is available): `opacity: 0.4`, `pointer-events: none` — use `shinyjs` or server-side `shinyjs::disable()` / conditional `nav_panel` visibility

**Footer**
- `border-top: 1px solid #D9D9D9`
- Background: `#FFFFFF`
- Left: "MYCOTEAM" — 9px, `font-weight: 700`, `letter-spacing: 0.05em`, `#1A1A1A`
- Right: "Built by ANYthings · MycoTools v1.0" — 9px, `#767676`
- Far right: row/col count in `JetBrains Mono` 9px

---

### Tab 1 — Upload

**Layout:** `layout_columns(col_widths = c(4, 8))`

**Left card — Import File**
- File input with dashed border drop zone: `border: 1.5px dashed #D9D9D9; background: #F5F5F5; padding: 18px 12px; text-align: center`
- Delimiter, skip, sheet selects: standard `selectInput` / `numericInput` with bslib styling
- "Import" button: `btn-primary` (teal), full width
- Horizontal rule, then "Load demo dataset" secondary button (black bg, white text)
- Success state: green alert `background: #E8F5E9; border: 1px solid #A5D6A7; color: #2E7D32` with ✓ prefix

**Right card — Raw Preview**
- `verbatimTextOutput` styled with `JetBrains Mono` 10px, `line-height: 1.6`
- On successful import: row of badges below the preview
  - Filled badge (teal bg): row count
  - Outlined badges (`#F5F5F5` bg, `#D9D9D9` border): column count, sensor count, date range

**Badge CSS:**
```css
.badge-outline {
  font-size: 9px; font-weight: 700; padding: 2px 7px;
  text-transform: uppercase; letter-spacing: 0.05em;
  background: #F5F5F5; color: #333333;
  border: 1px solid #D9D9D9; border-radius: 0;
}
```

---

### Tab 2 — Configure

**Layout:** `layout_columns(col_widths = c(4, 8))`

**Left — Config panels** (`navset_card_tab`)

Sub-tabs: Columns, Dates, MYCOindex, Extras

*Columns sub-tab:*
- Section sub-labels: `h6` with `text-transform: uppercase; font-size: 9px; font-weight: 700; color: #767676; letter-spacing: 0.08em`
- All `selectInput` controls: full width, border-radius 0

*MYCOindex sub-tab:*
- Threshold inputs in a 3-column grid (`fluidRow` + `column(4, ...)`)
- Group label `tags$b(...)` before each threshold group
- `hr()` separators between groups

**Right card — Run Processing**
- "Run Processing" button: `btn-primary`, full width, teal
- Animated progress bar (while `withProgress` is running): inject a CSS animation via `shinyjs::runjs` or use bslib's built-in progress
  - Style: `height: 4px; background: #D9D9D9; overflow: hidden` container, sliding teal fill
- Success alert: `background: #E8F5E9; border: 1px solid #A5D6A7` with row × col count
- Output preview `DTOutput`: `table-sm`, no border-radius, striped with `#FAFAFA`

---

### Tab 3 — Dashboard

**Layout:** `layout_sidebar(sidebar = sidebar(width = 240, ...))`

#### Sidebar

- Background: `#FFFFFF`, `border-right: 1px solid #D9D9D9`
- Section labels (same style as above — uppercase, 9px, `#767676`)
- Sensor checkboxes: `checkboxGroupInput`, 11px, gap between items
- Select/Deselect all: `actionLink` styled as 9px teal / grey text, no underline
- Date range: `dateRangeInput`, full width
- "Reset to full range": `actionLink`, 9px, `#767676`
- Variable selects: `selectInput`, full width, bottom `margin: 4px`

#### Stat tiles row

Four tiles in `layout_columns(col_widths = c(3, 3, 3, 3))`. Each tile:
```
Card border: 1px solid #D9D9D9, bg: #FFFFFF, padding: 14px 16px
Label: 9px, 700, uppercase, letter-spacing 0.07em, #767676, margin-bottom: 6px
Value: 26px, 700, letter-spacing -0.02em, line-height: 1
  — default colour: #1A1A1A
  — alert colour (high risk / peak RH ≥ 85): #E03C31
Unit: 11px, #555555, inline after value
Sub-label: 9px, #767676, margin-top: 4px
```

Tiles: Observations (n rows), Mean RH (%), Peak RH (% — red if ≥ 85), High-risk periods (MIx_mold ≥ 0.5 — red if > 0).

Implement as `value_box()` (bslib ≥ 0.5) with custom CSS overrides, or as `card()` with inline HTML.

#### Dashboard sub-tabs (`navset_card_tab`)

Active tab button style:
```css
.nav-tabs .nav-link.active {
  background: #1A1A1A !important;
  color: #FFFFFF !important;
  border-color: #1A1A1A !important;
  border-radius: 0 !important;
  font-weight: 700;
}
.nav-tabs .nav-link {
  border-radius: 0 !important;
  font-size: 11px;
  color: #555555;
}
```

**Time Series sub-tab (`plotlyOutput`)**

Apply to all time-series Plotly charts:
```r
layout(
  paper_bgcolor = "rgba(0,0,0,0)",
  plot_bgcolor  = "rgba(0,0,0,0)",
  font = list(family = "Inter, Helvetica Neue, Arial", size = 10, color = "#555555"),
  xaxis = list(
    showgrid = TRUE, gridcolor = "#D9D9D9", gridwidth = 0.5,
    zeroline = FALSE, linecolor = "#333333", linewidth = 1,
    tickfont = list(family = "JetBrains Mono", size = 9)
  ),
  yaxis = list(
    showgrid = TRUE, gridcolor = "#D9D9D9", gridwidth = 0.5,
    zeroline = FALSE, linecolor = "#333333", linewidth = 1,
    tickfont = list(family = "JetBrains Mono", size = 9)
  ),
  hovermode = "x unified",
  legend = list(orientation = "h", y = -0.18, font = list(size = 9))
)
```

Sensor line colours: use `NYCTA_PALETTE` (see Data Viz Palette above) cycling by sensor index.

Line width: `1.75`. No markers by default (`mode = "lines"`).

**Summary sub-tab (`DTOutput`)**

```r
datatable(...,
  options = list(scrollX = TRUE, pageLength = 25, dom = "tip"),
  rownames = FALSE,
  class = "table-sm"
) %>%
  formatStyle("highRisk",
    color = styleInterval(0, c("#555555", "#E03C31")),
    fontWeight = styleInterval(0, c("normal", "bold"))
  )
```

Header background: `#F5F5F5`. Alt rows: `#FAFAFA`. All cells: `font-family: JetBrains Mono` for numeric columns.

**Distributions sub-tab**

Two-column `layout_columns(col_widths = c(6, 6))`:
- Left: `plotlyOutput("plot_hist_primary")` — fill colour = first NYCTA palette colour for selected variable; `opacity = 0.85`; bar outlines white, 0.5px
- Right: `plotlyOutput("plot_hist_mix")` — grouped/overlaid bars per MYCOindex, colours: Mold=`#0B3D91`, Temp=`#FF6319`, Wood=`#00933C`; `opacity = 0.85`; `barmode = "overlay"`

Apply same Plotly layout settings as Time Series.

**Heatmap sub-tab**

```r
plot_ly(..., type = "heatmap",
  colorscale = MIX_COLORSCALE,   # defined above
  zmin = 0, zmax = 1,
  xgap = 0.5, ygap = 0.5         # thin gaps between cells
) %>%
layout(
  xaxis = list(title = "", tickfont = list(family = "Inter", size = 9)),
  yaxis = list(title = "", autorange = "reversed",
               tickfont = list(family = "Inter", size = 10)),
  paper_bgcolor = "rgba(0,0,0,0)",
  plot_bgcolor  = "rgba(0,0,0,0)",
  font = list(family = "Inter")
)
```

Add a text annotation below the chart explaining the risk scale (replicates the legend in the prototype):
`"0 = No risk · 0.25 = Low · 0.5 = Moderate · 1.0 = High/Critical"`  — 9px, `#767676`.

---

### Tab 4 — Download

**Layout:** `layout_columns(col_widths = c(4, 8))`

**Left card — Export**
- Format `selectInput`, filename `textInput`
- `downloadButton`: `btn-primary`, full width, margin-top 8px
- File summary block below button: `background: #F5F5F5; border: 1px solid #D9D9D9; padding: 8px 10px; font-size: 10px`

**Right card — Column Reference**
- Standard `tags$table` (not DT)
- Column name cells: `font-family: JetBrains Mono; color: #0B3D91`
- Type cells: `font-family: JetBrains Mono; color: #555555`
- Alternating row background: `#FAFAFA` / `#FFFFFF`
- Border: `0.5px solid #D9D9D9` on row bottoms only — no outer border

---

## Global CSS overrides

Add the following to the `app_theme` or inject via `tags$style(HTML(...))` in the UI:

```css
/* Remove all border-radius (NASA aesthetic) */
.card, .nav-tabs .nav-link, .btn, select, input, .form-control,
.dataTables_wrapper, .shiny-notification { border-radius: 0 !important; }

/* Section labels */
.section-label {
  font-size: 9px; font-weight: 700; color: #767676;
  text-transform: uppercase; letter-spacing: 0.08em; margin-bottom: 6px;
}

/* Sidebar nav items */
.sidebar-nav-item { padding: 9px 16px; font-size: 12px; border-left: 3px solid transparent; }
.sidebar-nav-item.active {
  background: #F5F5F5; border-left-color: #1A1A1A;
  font-weight: 700; color: #1A1A1A;
}

/* DT tables */
table.dataTable thead th { background: #F5F5F5 !important; font-weight: 700; }
table.dataTable tbody tr:nth-child(even) td { background: #FAFAFA; }
table.dataTable td, table.dataTable th { border-bottom: 0.5px solid #D9D9D9 !important; }

/* bslib card headers */
.card-header { font-size: 11px; font-weight: 700; background: #FFFFFF; border-bottom: 1px solid #D9D9D9; }

/* Scrollbars */
::-webkit-scrollbar { width: 5px; height: 5px; }
::-webkit-scrollbar-track { background: #F5F5F5; }
::-webkit-scrollbar-thumb { background: #D9D9D9; }
```

Inject in `app.R` UI section:
```r
tags$head(tags$style(HTML("
  /* paste CSS above here */
")))
```

---

## Interactions & Behaviour

| Trigger | Behaviour |
|---|---|
| File imported successfully | Show green success alert; enable Configure tab |
| "Run Processing" clicked | Show animated progress bar (4 steps); on completion show green alert + auto-navigate to Dashboard tab using `updateNavbarPage(session, inputId = ..., selected = "tab_dashboard")` |
| Sensor checkbox toggled | All dashboard charts re-render reactively (already implemented via `dash_data()`) |
| Date range changed | All charts re-render via `dash_data()` |
| "Reset to full range" clicked | Reset `dateRangeInput` to full data range |
| Heatmap cell hovered | Plotly native tooltip: `hovertemplate = "<b>%{x|%Y-%m-%d}</b><br>Sensor: %{y}<br>{label}: %{z:.2f}<extra></extra>"` |
| Time series hovered | `hovermode = "x unified"` with `JetBrains Mono` tooltip font |

---

## Assets

| Asset | Source | Usage |
|---|---|---|
| `mycoteam_logo.png` | Client-supplied (place in `www/`) | Navbar left; replace `tags$strong("MycoTools")` |
| `any_logo_white_back_v3.png` | ANYthings brand assets (place in `www/`) | Footer right, 20px height |
| `square_any_logo_white_back_v3.png` | ANYthings brand assets | Favicon / `<link rel="icon">` |

The `app.R` already contains TODO comments marking exactly where to drop these images.

---

## Files in this package

| File | Purpose |
|---|---|
| `README.md` | This document — primary implementation spec |
| `MycoTools Dashboard.html` | Full interactive HTML prototype — open in browser to see all tabs, charts, and interactions |
| `charts.jsx` | SVG chart component source used in the prototype — reference for axis styles, colour application, and tooltip format; do **not** ship this file |

---

## Priority order for implementation

1. Apply `bs_theme()` token changes (colours, fonts, border-radius: 0)
2. Inject global CSS overrides
3. Restyle navbar, footer, top stripe
4. Stat tile row in Dashboard
5. Plotly chart colour/layout updates (palette, grid, fonts)
6. DT table styling
7. Upload tab success states
8. Progress bar animation on Configure tab
9. Logo swaps (requires client assets)
