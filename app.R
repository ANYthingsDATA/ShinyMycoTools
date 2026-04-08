# app.R ─────────────────────────────────────────────────────────────────────
# MycoTools Data Platform
# Built by ANYthings for Mycoteam
# ─────────────────────────────────────────────────────────────────────────────

library(shiny)
library(bslib)
library(DT)
library(plotly)
library(dplyr)
library(tidyr)
library(lubridate)
library(readr)
library(readxl)
library(writexl)
library(rlang)
library(parsedate)
library(tools)

# Source MycoTools functions (make_rolling.R excluded: depends on unexported helper)
source("R/import_dataset.R")
source("R/define_variables.R")
source("R/add_variables.R")
source("R/make_complete_date.R")
source("R/make_mycoindex_mold.R")
source("R/make_mycoindex_temp.R")
source("R/make_mycoindex_wood.R")

options(shiny.maxRequestSize = 100 * 1024^2)

# ── THEME ─────────────────────────────────────────────────────────────────────
# ANYthings brand system — see brand identity docs for full spec
BRAND_BLACK     <- "#1A1A1A"   # ANYthings Black — headings, navbar
BRAND_SIGNAL    <- "#E03C31"   # Signal Red — key callouts, alerts (use sparingly)
BRAND_BLUE      <- "#0B3D91"   # System Blue — links, secondary emphasis
BRAND_DARK_GREY <- "#333333"   # Body text, secondary headings
BRAND_MID_GREY  <- "#767676"   # Captions, metadata, muted text
BRAND_LIGHT_GREY <- "#D9D9D9"  # Rules, borders, table gridlines
BRAND_NEAR_WHITE <- "#F5F5F5"  # Alternate row backgrounds, subtle fills

app_theme <- bs_theme(
  version   = 5,
  primary   = BRAND_BLACK,
  secondary = BRAND_DARK_GREY,
  danger    = BRAND_SIGNAL,
  info      = BRAND_BLUE,
  bg        = "#FFFFFF",
  fg        = BRAND_DARK_GREY,
  "navbar-bg"    = BRAND_BLACK,
  "navbar-color" = "#FFFFFF",
  "border-color" = BRAND_LIGHT_GREY,
  "card-border-color" = BRAND_LIGHT_GREY,
  base_font    = font_google("Inter"),
  heading_font = font_google("Inter", wght = "700"),
  code_font    = font_google("JetBrains Mono"),
  font_scale   = 0.9
)

# ── CONSTANTS ─────────────────────────────────────────────────────────────────
MEASURE_COLS <- c(
  "Temperature (°C)"      = "gen_temp",
  "Relative Humidity (%)" = "gen_rhum",
  "Wood Moisture (%)"     = "gen_wood",
  "Ohm"                   = "gen_ohm"
)

MIX_COLS <- c(
  "MYCOindex — Mold" = "MIx_mold",
  "MYCOindex — Temp" = "MIx_temp",
  "MYCOindex — Wood" = "MIx_wood"
)

ALL_GEN_COLS <- c(MEASURE_COLS, MIX_COLS)

# Colour scale for MYCOindex heatmap: white → yellow → orange → red
MIX_COLORSCALE <- list(
  list(0,   "#F9FBE7"),
  list(0.01, "#F9A825"),
  list(0.5, "#E65100"),
  list(1,   "#B71C1C")
)

# ── HELPERS ───────────────────────────────────────────────────────────────────
empty_plotly <- function(msg = "No data to display") {
  plot_ly() %>%
    layout(
      title  = list(text = msg, x = 0.5, font = list(color = "#999", size = 13)),
      xaxis  = list(visible = FALSE),
      yaxis  = list(visible = FALSE),
      paper_bgcolor = "rgba(0,0,0,0)",
      plot_bgcolor  = "rgba(0,0,0,0)"
    )
}

col_label <- function(col_id, lookup = ALL_GEN_COLS) {
  nm <- names(lookup)[lookup == col_id]
  if (length(nm)) nm[[1]] else col_id
}

# ── UI ────────────────────────────────────────────────────────────────────────
ui <- page_navbar(
  # TODO: replace tags$strong("MycoTools") with:
  #   tags$span(
  #     tags$img(src = "mycoteam_logo.png", height = "28px", alt = "Mycoteam",
  #              style = "vertical-align: middle; margin-right: 8px;"),
  #     tags$span("MycoTools", style = "color: #FFFFFF; font-weight: 700;")
  #   )
  # Logo files go in www/ — Shiny serves that folder as the static root.
  # Use any_logo_white_back_v3.png (horizontal) for the footer.
  # Use square_any_logo_white_back_v3.png for the favicon / app icon.
  title   = tags$strong("MycoTools", style = "color: #FFFFFF; letter-spacing: -0.3px;"),
  theme   = app_theme,
  inverse = TRUE,
  footer  = div(
    class = "d-flex align-items-center justify-content-between px-3 py-2",
    style = paste0("border-top: 1px solid ", BRAND_LIGHT_GREY, ";",
                   "background: #FFFFFF;"),
    # Primary brand — Mycoteam logo (left / dominant)
    # TODO: replace with: tags$img(src = "mycoteam_logo.png", height = "28px", alt = "Mycoteam")
    tags$span(
      style = paste0("font-weight: 700; font-size: 1rem; color: ", BRAND_BLACK, ";"),
      "Mycoteam"
    ),
    # Secondary brand — ANYthings (right, smaller)
    # TODO: replace with: tags$img(src = "any_logo_white_back_v3.png", height = "20px", alt = "ANYthings")
    tags$span(
      class = "small",
      style = paste0("color: ", BRAND_MID_GREY, ";"),
      "Built by ANYthings"
    )
  ),

  # ══════════════════════════════════════════════════════════════════
  # TAB 1 — UPLOAD
  # ══════════════════════════════════════════════════════════════════
  nav_panel(
    title = tagList(icon("upload"), " Upload"),
    value = "tab_upload",

    layout_columns(
      col_widths = c(4, 8),

      # ── Import controls ──
      card(
        card_header(icon("file-import", class = "me-1"), "Import File"),
        card_body(
          fileInput("file_upload", NULL,
                    accept      = c(".csv", ".txt", ".xlsx", ".xls"),
                    buttonLabel = "Browse…",
                    placeholder = "CSV / Excel / TXT"),

          hr(),
          selectInput("import_delim", "Delimiter",
                      choices  = c("Auto-detect" = "auto",
                                   "Comma  (,)"  = ",",
                                   "Semicolon (;)" = ";",
                                   "Tab  (\\t)"  = "\t"),
                      selected = "auto", width = "100%"),
          numericInput("import_skip",    "Skip lines at top", value = 0, min = 0),
          textInput("import_comment",    "Comment prefix",    value = "",
                    placeholder = "e.g.  #  — leave empty to disable"),
          numericInput("import_sheet",   "Excel sheet",       value = 1, min = 1),
          hr(),
          actionButton("btn_import", "Import",
                       icon  = icon("file-import"),
                       class = "btn-primary w-100")
        )
      ),

      # ── Preview ──
      navset_card_tab(
        nav_panel(
          title = tagList(icon("file-lines", class = "me-1"), " Raw file"),
          card_body(
            uiOutput("raw_hint_ui"),
            verbatimTextOutput("raw_preview")
          )
        ),
        nav_panel(
          title = tagList(
            icon("table", class = "me-1"), " Imported data",
            span(class = "ms-2", uiOutput("upload_badge_ui", inline = TRUE))
          ),
          card_body(
            uiOutput("upload_hint_ui"),
            DTOutput("tbl_preview")
          )
        )
      )
    )
  ),

  # ══════════════════════════════════════════════════════════════════
  # TAB 2 — CONFIGURE & PROCESS
  # ══════════════════════════════════════════════════════════════════
  nav_panel(
    title = tagList(icon("sliders"), " Configure"),
    value = "tab_configure",

    layout_columns(
      col_widths = c(4, 8),

      # ── Left: configuration panels ──
      navset_card_tab(

        # ── Columns ──
        nav_panel(
          title = tagList(icon("columns"), " Columns"),
          p(class = "text-muted small mt-1 mb-3",
            "Map raw column names to the standard variables used downstream."),

          h6(class = "text-uppercase text-muted small mb-1", "Date / Time"),
          selectInput("map_date", "Date column *",
                      choices = c("— select after import —" = ""), width = "100%"),
          selectInput("map_time", "Time column (if separate from date)",
                      choices = c("None" = ""), width = "100%"),
          selectInput("map_timezone", "Timezone",
                      choices  = c("UTC", "Europe/Oslo", "Europe/Stockholm",
                                   "Europe/Copenhagen", "Europe/Berlin", "Europe/London"),
                      selected = "Europe/Oslo", width = "100%"),

          h6(class = "text-uppercase text-muted small mb-1 mt-3", "Sensor"),
          selectInput("map_sensor", "Sensor ID column",
                      choices = c("None" = ""), width = "100%"),
          selectInput("map_port", "Port column (appended to sensor ID)",
                      choices = c("None" = ""), width = "100%"),

          h6(class = "text-uppercase text-muted small mb-1 mt-3", "Measurements"),
          selectInput("map_temp", "Temperature",       choices = c("None" = ""), width = "100%"),
          selectInput("map_rhum", "Relative Humidity", choices = c("None" = ""), width = "100%"),
          selectInput("map_wood", "Wood Moisture",     choices = c("None" = ""), width = "100%"),
          selectInput("map_ohm",  "Ohm",               choices = c("None" = ""), width = "100%")
        ),

        # ── Date completion ──
        nav_panel(
          title = tagList(icon("calendar-check"), " Dates"),
          p(class = "text-muted small mt-1 mb-3",
            "Fill missing timestamps to create a regular time series."),

          checkboxInput("do_complete", "Complete missing dates", value = FALSE),

          conditionalPanel(
            "input.do_complete == true",
            selectInput("map_site_id", "Site ID column (optional grouping)",
                        choices = c("None" = ""), width = "100%"),
            selectInput("complete_timeframe", "Resolution",
                        choices  = c("Hourly" = "hour", "Daily" = "day",
                                     "Weekly" = "week", "Monthly" = "month"),
                        selected = "day", width = "100%"),
            div(class = "alert alert-warning small py-2 mt-2",
                icon("triangle-exclamation", class = "me-1"),
                "Resolution must match your data's actual sampling interval.")
          )
        ),

        # ── MYCOindex ──
        nav_panel(
          title = tagList(icon("virus"), " MYCOindex"),
          p(class = "text-muted small mt-1 mb-2",
            "Select which indexes to compute and adjust thresholds if needed."),

          checkboxGroupInput("do_indexes", NULL,
                             choices  = c("Mold (from RH)"  = "mold",
                                          "Temperature"     = "temp",
                                          "Wood Moisture"   = "wood"),
                             selected = c("mold", "temp", "wood")),

          hr(),
          tags$b("Mold — Relative Humidity (%)"),
          fluidRow(
            column(4, numericInput("mold_low",  "Low",  75, width = "100%")),
            column(4, numericInput("mold_mid",  "Mid",  85, width = "100%")),
            column(4, numericInput("mold_high", "High", 95, width = "100%"))
          ),
          hr(),
          tags$b("Temperature (°C)"),
          fluidRow(
            column(3, numericInput("temp_low",  "Low",   4, width = "100%")),
            column(3, numericInput("temp_mid",  "Mid",   8, width = "100%")),
            column(3, numericInput("temp_high", "High", 14, width = "100%")),
            column(3, numericInput("temp_max",  "Max",  35, width = "100%"))
          ),
          hr(),
          tags$b("Wood Moisture (%)"),
          fluidRow(
            column(3, numericInput("wood_low",  "Low",   20, width = "100%")),
            column(3, numericInput("wood_mid",  "Mid",   25, width = "100%")),
            column(3, numericInput("wood_high", "High",  30, width = "100%")),
            column(3, numericInput("wood_max",  "Max",  100, width = "100%"))
          )
        ),

        # ── Extras ──
        nav_panel(
          title = tagList(icon("plus-circle"), " Extras"),
          checkboxInput("do_seasons", "Add season & calendar variables", value = TRUE),
          tags$ul(class = "text-muted small mt-2",
            tags$li(code("gen_season"), " — Winter / Spring / Summer / Fall"),
            tags$li(code("gen_year_season"), " — e.g. '2024, Winter'"),
            tags$li(code("gen_isoweek"), " / ", code("gen_isoyear"),
                    " — ISO 8601 week"),
            tags$li(code("gen_date_month_num"), " / ",
                    code("gen_date_month_lab"))
          )
        )
      ),

      # ── Right: run + output ──
      card(
        card_header(icon("gears", class = "me-1"), "Run Processing"),
        card_body(
          uiOutput("process_prereq_ui"),
          actionButton("btn_process", "Run Processing",
                       icon  = icon("gears"),
                       class = "btn-primary w-100"),
          br(), br(),
          uiOutput("process_status_ui"),
          hr(),
          h6(class = "fw-bold", "Output Preview (first 200 rows)"),
          DTOutput("tbl_processed")
        )
      )
    )
  ),

  # ══════════════════════════════════════════════════════════════════
  # TAB 3 — DASHBOARD
  # ══════════════════════════════════════════════════════════════════
  nav_panel(
    title = tagList(icon("chart-line"), " Dashboard"),
    value = "tab_dashboard",

    layout_sidebar(
      sidebar = sidebar(
        width = 260,
        title = "Filters",
        open  = TRUE,

        # Sensor checkboxes — populated dynamically
        uiOutput("dash_sensor_ui"),

        hr(),

        # Date range — populated dynamically
        uiOutput("dash_daterange_ui"),

        hr(),

        # Variable selectors — updated via observe() when data is ready
        selectInput("dash_primary_var", "Primary variable",
                    choices = character(0), width = "100%"),

        checkboxGroupInput("dash_mix_overlay", "Overlay MYCOindex",
                           choices  = MIX_COLS,
                           selected = character(0)),

        hr(),

        selectInput("heatmap_index", "Heatmap: MYCOindex",
                    choices = MIX_COLS, selected = "MIx_mold", width = "100%")
      ),

      uiOutput("dashboard_main_ui")
    )
  ),

  # ══════════════════════════════════════════════════════════════════
  # TAB 4 — DOWNLOAD
  # ══════════════════════════════════════════════════════════════════
  nav_panel(
    title = tagList(icon("download"), " Download"),
    value = "tab_download",

    layout_columns(
      col_widths = c(4, 8),

      card(
        card_header(icon("file-export", class = "me-1"), "Export"),
        card_body(
          uiOutput("dl_prereq_ui"),
          selectInput("dl_format", "Format",
                      choices = c("CSV (comma)"       = "csv",
                                  "CSV2 (semicolon)"  = "csv2",
                                  "Excel (.xlsx)"     = "xlsx"),
                      width = "100%"),
          downloadButton("btn_download", "Download Processed Data",
                         class = "btn-primary w-100 mt-2")
        )
      ),

      card(
        card_header(icon("book", class = "me-1"), "Generated Column Reference"),
        card_body(
          tags$table(
            class = "table table-sm table-striped",
            tags$thead(tags$tr(
              tags$th("Column"), tags$th("Type"), tags$th("Description")
            )),
            tags$tbody(
              tags$tr(tags$td(code("gen_datetime")),    tags$td("POSIXct"), tags$td("Standardised datetime")),
              tags$tr(tags$td(code("gen_date")),        tags$td("Date"),    tags$td("Date component")),
              tags$tr(tags$td(code("gen_time")),        tags$td("chr"),     tags$td("Time HH:MM:SS")),
              tags$tr(tags$td(code("gen_sensorID")),    tags$td("chr"),     tags$td("Sensor identifier")),
              tags$tr(tags$td(code("gen_temp")),        tags$td("dbl"),     tags$td("Temperature (°C)")),
              tags$tr(tags$td(code("gen_rhum")),        tags$td("dbl"),     tags$td("Relative humidity (%)")),
              tags$tr(tags$td(code("gen_wood")),        tags$td("dbl"),     tags$td("Wood moisture (%)")),
              tags$tr(tags$td(code("gen_ohm")),         tags$td("dbl"),     tags$td("Ohm value")),
              tags$tr(tags$td(code("MIx_mold")),        tags$td("dbl"),     tags$td("Mold index (0 / 0.25 / 0.5 / 1)")),
              tags$tr(tags$td(code("MIx_temp")),        tags$td("dbl"),     tags$td("Temperature index (0 / 0.2 / 0.4 / 1)")),
              tags$tr(tags$td(code("MIx_wood")),        tags$td("dbl"),     tags$td("Wood index (0 / 0.25 / 0.5 / 1)")),
              tags$tr(tags$td(code("gen_season")),      tags$td("chr"),     tags$td("Winter / Spring / Summer / Fall")),
              tags$tr(tags$td(code("gen_year_season")), tags$td("chr"),     tags$td("e.g. '2024, Winter'")),
              tags$tr(tags$td(code("gen_isoweek")),     tags$td("int"),     tags$td("ISO 8601 week number")),
              tags$tr(tags$td(code("gen_isoyear")),     tags$td("int"),     tags$td("ISO year"))
            )
          )
        )
      )
    )
  ),

  nav_spacer(),
  nav_item(tags$span(class = "navbar-text small opacity-75",
                     "ANYthings for Mycoteam"))
)


# ── SERVER ────────────────────────────────────────────────────────────────────
server <- function(input, output, session) {

  rv <- reactiveValues(
    raw_data       = NULL,
    processed_data = NULL
  )

  # ════════════════════════════════════════════════════════════════
  # UPLOAD
  # ════════════════════════════════════════════════════════════════

  output$raw_hint_ui <- renderUI({
    if (is.null(input$file_upload)) {
      div(class = "alert alert-info",
          icon("circle-info", class = "me-1"),
          "Select a file to preview its raw content.")
    }
  })

  output$raw_preview <- renderText({
    req(input$file_upload)
    lines <- tryCatch(
      readLines(input$file_upload$datapath, n = 100, warn = FALSE, encoding = "UTF-8"),
      error = function(e) paste("Could not read file:", conditionMessage(e))
    )
    paste(lines, collapse = "\n")
  })

  output$upload_hint_ui <- renderUI({
    if (is.null(rv$raw_data)) {
      div(class = "alert alert-info",
          icon("circle-info", class = "me-1"),
          "Select a file and click ", tags$strong("Import"), " to load your data.")
    }
  })

  observeEvent(input$btn_import, {
    req(input$file_upload)

    tryCatch({
      comment_arg <- trimws(input$import_comment)
      comment_arg <- if (nzchar(comment_arg)) comment_arg else NULL

      data <- import_data(
        path    = input$file_upload$datapath,
        sheet   = as.integer(input$import_sheet),
        delim   = input$import_delim,
        skip    = as.integer(input$import_skip),
        comment = comment_arg
      )

      rv$raw_data       <- data
      rv$processed_data <- NULL

      # Populate column selectors on Configure tab
      col_choices <- c("None" = "", setNames(names(data), names(data)))
      for (id in c("map_date", "map_time", "map_sensor", "map_port",
                   "map_temp", "map_rhum", "map_wood", "map_ohm", "map_site_id")) {
        updateSelectInput(session, id, choices = col_choices)
      }

      # Auto-detect date column
      date_guess <- grep("date|time|datum|dato|timestamp",
                         names(data), ignore.case = TRUE, value = TRUE)[1]
      if (!is.na(date_guess)) {
        updateSelectInput(session, "map_date", selected = date_guess)
      }

      showNotification(
        sprintf("Imported %s rows × %s columns",
                format(nrow(data), big.mark = ","), ncol(data)),
        type = "message"
      )

    }, error = function(e) {
      showNotification(paste("Import error:", conditionMessage(e)),
                       type = "error", duration = 15)
    })
  })

  output$upload_badge_ui <- renderUI({
    req(rv$raw_data)
    tags$span(class = "badge bg-success",
              icon("check", class = "me-1"),
              sprintf("%s rows · %s cols",
                      format(nrow(rv$raw_data), big.mark = ","),
                      ncol(rv$raw_data)))
  })

  output$tbl_preview <- renderDT({
    req(rv$raw_data)
    datatable(head(rv$raw_data, 200),
              options  = list(scrollX = TRUE, pageLength = 10, dom = "tip"),
              rownames = FALSE,
              class    = "table-sm table-striped")
  })


  # ════════════════════════════════════════════════════════════════
  # PROCESS
  # ════════════════════════════════════════════════════════════════

  output$process_prereq_ui <- renderUI({
    if (is.null(rv$raw_data)) {
      div(class = "alert alert-warning mb-2",
          icon("triangle-exclamation", class = "me-1"),
          "Upload data first (Upload tab).")
    } else if (!nzchar(input$map_date)) {
      div(class = "alert alert-warning mb-2",
          icon("triangle-exclamation", class = "me-1"),
          "Select a date column in the Columns tab.")
    }
  })

  observeEvent(input$btn_process, {
    req(rv$raw_data, nzchar(input$map_date))

    withProgress(message = "Processing data…", value = 0, {
      tryCatch({
        data <- rv$raw_data

        # ── 1. Date / time ──────────────────────────────────────────
        incProgress(0.10, detail = "Parsing dates…")

        if (nzchar(input$map_time)) {
          data <- define_variables_datetime(
            data,
            input_date = !!sym(input$map_date),
            input_time = !!sym(input$map_time),
            tz = input$map_timezone
          )
        } else {
          data <- define_variables_date(
            data,
            input_date = !!sym(input$map_date),
            tz = input$map_timezone
          )
        }

        # ── 2. Sensor ID ────────────────────────────────────────────
        if (nzchar(input$map_sensor)) {
          if (nzchar(input$map_port)) {
            data <- define_variables_sensorID(
              data,
              input_sensor = !!sym(input$map_sensor),
              input_port   = !!sym(input$map_port)
            )
          } else {
            data <- define_variables_sensorID(
              data,
              input_sensor = !!sym(input$map_sensor)
            )
          }
        }

        # ── 3. Measurement columns ──────────────────────────────────
        if (nzchar(input$map_temp))
          data <- define_variables_temp(data, input_temp = !!sym(input$map_temp))
        if (nzchar(input$map_rhum))
          data <- define_variables_rhum(data, input_rhum = !!sym(input$map_rhum))
        if (nzchar(input$map_wood))
          data <- define_variables_wood(data, input_wood = !!sym(input$map_wood))
        if (nzchar(input$map_ohm))
          data <- define_variables_ohm(data, input_ohm  = !!sym(input$map_ohm))

        # ── 4. Date completion ──────────────────────────────────────
        incProgress(0.35, detail = "Completing date sequence…")

        if (isTRUE(input$do_complete)) {
          tf         <- input$complete_timeframe
          # Use gen_datetime for hourly resolution, gen_date otherwise
          date_col   <- if (tf == "hour") "gen_datetime" else "gen_date"
          site_col   <- if (nzchar(input$map_site_id)) input$map_site_id else NULL
          has_sensor <- "gen_sensorID" %in% names(data)

          if (date_col %in% names(data)) {
            date_spine <- make_complete_date(
              data,
              input_date      = date_col,
              input_site_id   = site_col,
              input_sensor_id = if (has_sensor) "gen_sensorID" else NULL,
              timeframe       = tf
            )

            # make_complete_date returns date spine only; join back full data
            date_spine <- date_spine %>% select(-any_of(c("min_date", "max_date")))
            join_keys  <- intersect(names(date_spine), names(data))
            data       <- left_join(date_spine, data, by = join_keys)
          }
        }

        # ── 5. MYCOindex ────────────────────────────────────────────
        incProgress(0.60, detail = "Computing MYCOindexes…")

        if ("mold" %in% input$do_indexes && "gen_rhum" %in% names(data)) {
          data <- make_mycoindex_mold(
            data, input_mold = gen_rhum,
            mold_low  = input$mold_low,
            mold_mid  = input$mold_mid,
            mold_high = input$mold_high
          )
        }
        if ("temp" %in% input$do_indexes && "gen_temp" %in% names(data)) {
          data <- make_mycoindex_temp(
            data, input_temp = gen_temp,
            temp_low  = input$temp_low,
            temp_mid  = input$temp_mid,
            temp_high = input$temp_high,
            temp_max  = input$temp_max
          )
        }
        if ("wood" %in% input$do_indexes && "gen_wood" %in% names(data)) {
          data <- make_mycoindex_wood(
            data, input_wood = gen_wood,
            wood_low  = input$wood_low,
            wood_mid  = input$wood_mid,
            wood_high = input$wood_high,
            wood_max  = input$wood_max
          )
        }

        # ── 6. Seasons ──────────────────────────────────────────────
        incProgress(0.85, detail = "Adding calendar variables…")

        if (isTRUE(input$do_seasons) && "gen_datetime" %in% names(data)) {
          data <- add_date_seasons(data)
        }

        rv$processed_data <- data
        incProgress(1, detail = "Complete.")

        showNotification(
          sprintf("Done — %s rows × %s columns",
                  format(nrow(data), big.mark = ","), ncol(data)),
          type = "message"
        )

      }, error = function(e) {
        showNotification(paste("Error:", conditionMessage(e)),
                         type = "error", duration = 20)
      })
    })
  })

  output$process_status_ui <- renderUI({
    req(rv$processed_data)
    d <- rv$processed_data
    div(class = "alert alert-success py-2",
        icon("circle-check", class = "me-1"),
        sprintf("Processed: %s rows × %s columns",
                format(nrow(d), big.mark = ","), ncol(d)))
  })

  output$tbl_processed <- renderDT({
    req(rv$processed_data)
    datatable(head(rv$processed_data, 200),
              options  = list(scrollX = TRUE, pageLength = 10, dom = "tip"),
              rownames = FALSE,
              class    = "table-sm")
  })


  # ════════════════════════════════════════════════════════════════
  # DASHBOARD — sidebar filters
  # ════════════════════════════════════════════════════════════════

  # Update static variable-selector inputs once processed data exists
  observe({
    req(rv$processed_data)
    d <- rv$processed_data

    prim_avail <- MEASURE_COLS[MEASURE_COLS %in% names(d)]
    if (length(prim_avail)) {
      sel <- if ("gen_rhum" %in% prim_avail) "gen_rhum" else prim_avail[[1]]
      updateSelectInput(session, "dash_primary_var", choices = prim_avail, selected = sel)
    }

    mix_avail <- MIX_COLS[MIX_COLS %in% names(d)]
    if (length(mix_avail)) {
      updateCheckboxGroupInput(session, "dash_mix_overlay",
                               choices = mix_avail, selected = character(0))
      updateSelectInput(session, "heatmap_index",
                        choices = mix_avail, selected = mix_avail[[1]])
    }
  })

  # Dynamic sensor checkboxes (rendered when data is available)
  output$dash_sensor_ui <- renderUI({
    req(rv$processed_data)
    d <- rv$processed_data
    if (!"gen_sensorID" %in% names(d)) return(NULL)

    sensors <- sort(unique(as.character(d$gen_sensorID[!is.na(d$gen_sensorID)])))
    if (!length(sensors)) return(NULL)

    tagList(
      checkboxGroupInput("dash_sensors", "Sensors",
                         choices  = sensors,
                         selected = sensors,
                         width    = "100%"),
      actionLink("dash_select_all",   "Select all",   class = "small me-2"),
      actionLink("dash_deselect_all", "Deselect all", class = "small")
    )
  })

  observeEvent(input$dash_select_all, {
    req(rv$processed_data)
    if ("gen_sensorID" %in% names(rv$processed_data)) {
      sensors <- sort(unique(as.character(rv$processed_data$gen_sensorID)))
      updateCheckboxGroupInput(session, "dash_sensors", selected = sensors)
    }
  })
  observeEvent(input$dash_deselect_all, {
    updateCheckboxGroupInput(session, "dash_sensors", selected = character(0))
  })

  # Dynamic date range
  output$dash_daterange_ui <- renderUI({
    req(rv$processed_data)
    d <- rv$processed_data
    if (!"gen_date" %in% names(d)) return(NULL)

    rng <- range(d$gen_date, na.rm = TRUE)
    tagList(
      dateRangeInput("dash_dates", "Date range",
                     start = rng[1], end = rng[2],
                     min = rng[1], max = rng[2], width = "100%"),
      actionLink("dash_reset_dates", "Reset to full range",
                 class = "small text-muted")
    )
  })

  observeEvent(input$dash_reset_dates, {
    req(rv$processed_data)
    if ("gen_date" %in% names(rv$processed_data)) {
      rng <- range(rv$processed_data$gen_date, na.rm = TRUE)
      updateDateRangeInput(session, "dash_dates", start = rng[1], end = rng[2])
    }
  })

  # ── Filtered data ──
  dash_data <- reactive({
    req(rv$processed_data)
    d <- rv$processed_data

    if ("gen_date" %in% names(d) && !is.null(input$dash_dates)) {
      d <- filter(d, !is.na(gen_date),
                  gen_date >= input$dash_dates[1],
                  gen_date <= input$dash_dates[2])
    }
    if ("gen_sensorID" %in% names(d) && length(input$dash_sensors) > 0) {
      d <- filter(d, gen_sensorID %in% input$dash_sensors)
    }
    d
  })

  # ── Dashboard placeholder / tabs ──
  output$dashboard_main_ui <- renderUI({
    if (is.null(rv$processed_data)) {
      div(class = "alert alert-info m-3",
          icon("circle-info", class = "me-1"),
          "Process your data first (Configure tab) to enable the dashboard.")
    } else {
      navset_card_tab(
        nav_panel(
          title = tagList(icon("chart-line"), " Time Series"),
          plotlyOutput("plot_timeseries", height = "460px")
        ),
        nav_panel(
          title = tagList(icon("table"), " Summary"),
          DTOutput("tbl_summary")
        ),
        nav_panel(
          title = tagList(icon("chart-bar"), " Distributions"),
          layout_columns(
            col_widths = c(6, 6),
            plotlyOutput("plot_hist_primary", height = "380px"),
            plotlyOutput("plot_hist_mix",     height = "380px")
          )
        ),
        nav_panel(
          title = tagList(icon("border-all"), " Heatmap"),
          plotlyOutput("plot_heatmap", height = "500px")
        )
      )
    }
  })


  # ════════════════════════════════════════════════════════════════
  # DASHBOARD — plots
  # ════════════════════════════════════════════════════════════════

  # ── Time series ──────────────────────────────────────────────────
  output$plot_timeseries <- renderPlotly({
    req(dash_data())
    d <- dash_data()

    x_col   <- if ("gen_datetime" %in% names(d)) "gen_datetime" else "gen_date"
    y_var   <- input$dash_primary_var
    overlay <- input$dash_mix_overlay
    vars    <- unique(c(y_var, overlay))
    vars    <- vars[vars %in% names(d)]

    if (!length(vars) || !x_col %in% names(d))
      return(empty_plotly("Select a variable in the sidebar"))

    has_sensor <- "gen_sensorID" %in% names(d)
    p <- plot_ly()

    for (var in vars) {
      lbl <- col_label(var)

      if (has_sensor) {
        for (snsr in sort(unique(as.character(d$gen_sensorID)))) {
          dd <- filter(d, gen_sensorID == snsr) %>% arrange(.data[[x_col]])
          p  <- add_trace(p,
            x    = dd[[x_col]], y = dd[[var]],
            type = "scatter", mode = "lines",
            name = paste0(snsr, " — ", lbl),
            hovertemplate = paste0(
              "%{x}<br>", lbl, ": %{y:.3f}<extra>", snsr, "</extra>")
          )
        }
      } else {
        dd <- arrange(d, .data[[x_col]])
        p  <- add_trace(p,
          x = dd[[x_col]], y = dd[[var]],
          type = "scatter", mode = "lines", name = lbl
        )
      }
    }

    p %>% layout(
      xaxis     = list(title = ""),
      yaxis     = list(title = "Value"),
      hovermode = "x unified",
      legend    = list(orientation = "h", y = -0.18),
      margin    = list(b = 90)
    )
  })

  # ── Summary table ─────────────────────────────────────────────────
  output$tbl_summary <- renderDT({
    req(dash_data())
    d <- dash_data()

    num_cols <- intersect(
      c("gen_temp", "gen_rhum", "gen_wood", "gen_ohm",
        "MIx_mold", "MIx_temp", "MIx_wood"),
      names(d)
    )

    if (!length(num_cols))
      return(datatable(data.frame(Note = "No processed numeric columns.")))

    grp_cols <- intersect(c("gen_sensorID"), names(d))

    smry <- if (length(grp_cols)) {
      d %>%
        group_by(across(all_of(grp_cols))) %>%
        summarise(
          across(all_of(num_cols),
                 list(Mean = ~ round(mean(.x, na.rm = TRUE), 2),
                      SD   = ~ round(sd(.x,   na.rm = TRUE), 2),
                      Min  = ~ round(min(.x,   na.rm = TRUE), 2),
                      Max  = ~ round(max(.x,   na.rm = TRUE), 2),
                      N    = ~ sum(!is.na(.x))),
                 .names = "{.col}_{.fn}"),
          .groups = "drop"
        )
    } else {
      d %>%
        summarise(
          across(all_of(num_cols),
                 list(Mean = ~ round(mean(.x, na.rm = TRUE), 2),
                      SD   = ~ round(sd(.x,   na.rm = TRUE), 2),
                      Min  = ~ round(min(.x,   na.rm = TRUE), 2),
                      Max  = ~ round(max(.x,   na.rm = TRUE), 2),
                      N    = ~ sum(!is.na(.x))),
                 .names = "{.col}_{.fn}")
        )
    }

    datatable(smry,
              options  = list(scrollX = TRUE, pageLength = 25),
              rownames = FALSE,
              class    = "table-sm table-striped")
  })

  # ── Histogram — primary variable ──────────────────────────────────
  output$plot_hist_primary <- renderPlotly({
    req(dash_data())
    d   <- dash_data()
    var <- input$dash_primary_var

    if (!var %in% names(d)) return(empty_plotly())

    lbl <- col_label(var)

    if ("gen_sensorID" %in% names(d) &&
        length(unique(na.omit(d$gen_sensorID))) > 1) {
      plot_ly(d, x = ~.data[[var]],
              color = ~as.character(gen_sensorID),
              type = "histogram", nbinsx = 40, opacity = 0.75) %>%
        layout(
          barmode = "overlay",
          xaxis   = list(title = lbl),
          yaxis   = list(title = "Count"),
          title   = list(text = paste("Distribution:", lbl), x = 0),
          legend  = list(orientation = "h", y = -0.2)
        )
    } else {
      plot_ly(d, x = ~.data[[var]], type = "histogram", nbinsx = 40,
              marker = list(color = BRAND_PRIMARY,
                            line  = list(color = "#fff", width = 0.5))) %>%
        layout(
          xaxis = list(title = lbl),
          yaxis = list(title = "Count"),
          title = list(text = paste("Distribution:", lbl), x = 0)
        )
    }
  })

  # ── Histogram — MYCOindex ──────────────────────────────────────────
  output$plot_hist_mix <- renderPlotly({
    req(dash_data())
    d     <- dash_data()
    avail <- intersect(unname(MIX_COLS), names(d))

    if (!length(avail)) return(empty_plotly("No MYCOindex columns available"))

    pal <- c("#43A047", "#FB8C00", "#E53935")
    p   <- plot_ly()

    for (i in seq_along(avail)) {
      p <- add_trace(p,
        x       = d[[avail[i]]],
        type    = "histogram",
        name    = col_label(avail[i]),
        opacity = 0.75,
        nbinsx  = 10,
        marker  = list(color = pal[i])
      )
    }

    p %>% layout(
      barmode = "overlay",
      xaxis   = list(title = "MYCOindex (0–1)", range = c(-0.05, 1.1)),
      yaxis   = list(title = "Count"),
      title   = list(text = "MYCOindex Distributions", x = 0),
      legend  = list(orientation = "h", y = -0.2)
    )
  })

  # ── Heatmap ────────────────────────────────────────────────────────
  output$plot_heatmap <- renderPlotly({
    req(dash_data())
    d   <- dash_data()
    idx <- input$heatmap_index

    if (is.null(idx) || !idx %in% names(d))
      return(empty_plotly("Select a MYCOindex that has been computed"))

    lbl      <- col_label(idx)
    has_date <- "gen_date"     %in% names(d)
    has_snsr <- "gen_sensorID" %in% names(d)

    if (!has_date) return(empty_plotly("Date column not available"))

    if (has_snsr) {
      heat_df <- d %>%
        filter(!is.na(gen_date)) %>%
        mutate(sensor = as.character(gen_sensorID)) %>%
        group_by(date = gen_date, sensor) %>%
        summarise(value = mean(.data[[idx]], na.rm = TRUE), .groups = "drop")

      wide   <- pivot_wider(heat_df, names_from = sensor, values_from = value)
      x_vals <- wide$date
      y_vals <- setdiff(names(wide), "date")
      z_mat  <- as.matrix(wide[, y_vals, drop = FALSE])

      plot_ly(
        x = x_vals, y = y_vals, z = t(z_mat),
        type       = "heatmap",
        colorscale = MIX_COLORSCALE,
        zmin = 0, zmax = 1,
        colorbar   = list(title     = list(text = lbl),
                          tickvals  = c(0, 0.25, 0.5, 1)),
        hovertemplate = paste0(
          "<b>%{x|%Y-%m-%d}</b><br>Sensor: %{y}<br>", lbl, ": %{z:.2f}<extra></extra>")
      ) %>% layout(
        xaxis = list(title = ""),
        yaxis = list(title = "Sensor", autorange = "reversed"),
        title = list(text = paste("Daily mean:", lbl), x = 0)
      )

    } else {
      # No sensor column: area chart of daily mean
      trend <- d %>%
        filter(!is.na(gen_date)) %>%
        group_by(date = gen_date) %>%
        summarise(value = mean(.data[[idx]], na.rm = TRUE), .groups = "drop") %>%
        arrange(date)

      plot_ly(trend, x = ~date, y = ~value,
              type = "scatter", mode = "lines",
              fill = "tozeroy",
              fillcolor = "rgba(27,94,32,0.15)",
              line = list(color = BRAND_PRIMARY),
              hovertemplate = "<b>%{x|%Y-%m-%d}</b><br>Value: %{y:.2f}<extra></extra>") %>%
        layout(
          xaxis = list(title = ""),
          yaxis = list(title = lbl, range = c(0, 1.05)),
          title = list(text = paste("Daily mean:", lbl), x = 0)
        )
    }
  })


  # ════════════════════════════════════════════════════════════════
  # DOWNLOAD
  # ════════════════════════════════════════════════════════════════

  output$dl_prereq_ui <- renderUI({
    if (is.null(rv$processed_data)) {
      div(class = "alert alert-warning mb-2",
          icon("triangle-exclamation", class = "me-1"),
          "Process data first (Configure tab).")
    }
  })

  output$btn_download <- downloadHandler(
    filename = function() {
      ext <- switch(input$dl_format, "xlsx" = ".xlsx", ".csv")
      paste0("mycotools_", Sys.Date(), ext)
    },
    content = function(file) {
      req(rv$processed_data)
      d <- rv$processed_data
      switch(input$dl_format,
        "xlsx" = writexl::write_xlsx(d, file),
        "csv2" = readr::write_csv2(d, file),
                 readr::write_csv(d, file)
      )
    }
  )
}

shinyApp(ui = ui, server = server)
