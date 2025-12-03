# Load required libraries
library(shiny)
library(shinydashboard)
library(tidyverse)
library(data.table)  # Required for fread
library(MycoTools)    # Ensure your package is installed and available

# Set maximum upload file size (e.g., 30 MB)
options(shiny.maxRequestSize = 30 * 1024^2)  # Set limit to 30 MB

# UI Definition
ui <- dashboardPage(
  skin = "purple",
  dashboardHeader(title = "MycoTools Shiny App"),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Data Upload", tabName = "data_upload", icon = icon("upload")),
      menuItem("Data Processing", tabName = "data_processing", icon = icon("cogs")),
      menuItem("Data Visualization", tabName = "data_visualization", icon = icon("chart-bar")),
      menuItem("Data Download", tabName = "data_download", icon = icon("download"))
    )
  ),
  dashboardBody(
    tabItems(
      tabItem(tabName = "data_upload",
              fluidRow(
                fileInput("file1", "Choose CSV File", accept = c(".csv")),
                selectInput("encoding", "Encoding",
                            choices = c("UTF-8", "ISO-8859-1", "Windows-1252")),
                textInput("sep", "Separator (default: ',', leave empty for default)", value = ","),
                textInput("dec", "Decimal point (default: '.', leave empty for default)", value = "."),
                checkboxInput("fill", "Fill in missing values (default: TRUE)", value = TRUE),
                textInput("na_strings", "NA Strings (default: '', leave empty for default)", value = ""),
                numericInput("skip_lines", "Number of lines to skip (default: 0)", value = 0, min = 0),
                actionButton("upload_btn", "Upload"),
                actionButton("refresh_btn", "Refresh Preview"),
                tableOutput("data_preview")
              )
      ),
      tabItem(tabName = "data_processing",
              fluidRow(
                checkboxGroupInput("functions", "Select Functions to Apply:",
                                   choices = c("define_variables_date",
                                               "define_variables_sensorID",
                                               "define_variables_temp",
                                               "define_variables_rhum",
                                               "define_variables_wood",
                                               "define_variables_ohm",
                                               "make_complete_date",
                                               "make_mycoindex_mold",
                                               "make_mycoindex_temp",
                                               "make_mycoindex_wood",
                                               "add_date_seasons")),

                # Dropdown input for define_variables_date
                selectInput("input_date", "Input Date Column", choices = NULL),
                # textInput("date_format", "Date Format", value = "ymd"),
                selectInput("date_format", "Date Format", choices = c("ymd", "ymd_hms", "ymd_hm")),

                # Dropdown input for define_variables_sensorID
                selectInput("input_sensor", "Input Sensor Column", choices = NULL),
                selectInput("input_port", "Input Port Column", choices = NULL),

                # Dropdown input for define_variables_temp
                selectInput("input_temp", "Input Temperature Column", choices = NULL),

                # Dropdown input for define_variables_rhum
                selectInput("input_rhum", "Input Humidity Column", choices = NULL),

                # Dropdown input for define_variables_wood
                selectInput("input_wood", "Input Wood Column", choices = NULL),

                # Dropdown input for define_variables_ohm
                selectInput("input_ohm", "Input Ohm Column", choices = NULL),

                # Dropdown input for make_complete_date
                selectInput("input_site_id", "Input Site ID Column", choices = NULL),
                # selectInput("input_sensor_id", "Input Sensor ID Column", choices = NULL),
                selectInput("timeframe", "Timeframe", choices = c("hour", "day", "week", "month")),

                # Dropdown input for make_mycoindex_mold
                selectInput("input_mold", "Input Mold Column", choices = NULL),
                numericInput("mold_low", "Mold Low Threshold", value = 75),
                numericInput("mold_mid", "Mold Mid Threshold", value = 85),
                numericInput("mold_high", "Mold High Threshold", value = 95),

                # Dropdown input for make_mycoindex_temp
                selectInput("input_temp_mold", "Input Temperature Column", choices = NULL),
                numericInput("temp_low", "Temp Low Threshold", value = 4),
                numericInput("temp_mid", "Temp Mid Threshold", value = 8),
                numericInput("temp_high", "Temp High Threshold", value = 14),
                numericInput("temp_max", "Temp Max Threshold", value = 35),

                # Dropdown input for make_mycoindex_wood
                selectInput("input_wood_mold", "Input Wood Column", choices = NULL),
                numericInput("wood_low", "Wood Low Threshold", value = 20),
                numericInput("wood_mid", "Wood Mid Threshold", value = 25),
                numericInput("wood_high", "Wood High Threshold", value = 30),
                numericInput("wood_max", "Wood Max Threshold", value = 100),

                actionButton("process_btn", "Process Data"),
                tableOutput("processed_data")
              )
      ),
      tabItem(tabName = "data_visualization",
              fluidRow(
                plotOutput("data_plot")
              )
      ),
      tabItem(tabName = "data_download",
              fluidRow(
                downloadButton("download_data", "Download Processed Data")
              )
      )
    )
  )
)

# Server logic
server <- function(input, output, session) {

  # Reactive value to store the uploaded data
  uploaded_data <- reactiveVal(NULL)

  read_file <- function() {
    req(input$file1)

    # Read the uploaded file using fread
    data <- data.table::fread(
      input$file1$datapath,
      encoding = input$encoding,
      sep = ifelse(input$sep != "", input$sep, ","),  # Default to ',' if empty
      dec = ifelse(input$dec != "", input$dec, "."),  # Default to '.' if empty
      fill = input$fill,
      na.strings = ifelse(input$na_strings != "", str_split(input$na_strings, ",")[[1]], ""),
      skip = input$skip_lines
    )

    return(data)
  }

  observeEvent(input$upload_btn, {
    uploaded_data(read_file())

    # Update the select inputs for the processing page based on uploaded data
    updateSelectInput(session, "input_date", "Input Date Column", choices = names(uploaded_data()))
    updateSelectInput(session, "input_sensor", "Input Sensor Column", choices = names(uploaded_data()))
    updateSelectInput(session, "input_temp", "Input Temperature Column", choices = names(uploaded_data()))
    updateSelectInput(session, "input_rhum", "Input Humidity Column", choices = names(uploaded_data()))
    updateSelectInput(session, "input_wood", "Input Wood Column", choices = names(uploaded_data()))
    updateSelectInput(session, "input_ohm", "Input Ohm Column", choices = names(uploaded_data()))
    updateSelectInput(session, "input_site_id", "Input Site ID Column", choices = names(uploaded_data()))
    updateSelectInput(session, "input_sensor_id", "Input Sensor ID Column", choices = names(uploaded_data()))
    updateSelectInput(session, "input_mold", "Input Mold Column", choices = names(uploaded_data()))
    updateSelectInput(session, "input_temp_mold", "Input Temperature Column", choices = names(uploaded_data()))
    updateSelectInput(session, "input_wood_mold", "Input Wood Column", choices = names(uploaded_data()))
  })

  observeEvent(input$refresh_btn, {
    uploaded_data(read_file())
  })

  output$data_preview <- renderTable({
    req(uploaded_data())
    uploaded_data() %>% head()  # Preview the first few rows
  })

  # Process data when button is clicked
  processed_data <- eventReactive(input$process_btn, {
    req(uploaded_data())

    data <- uploaded_data()

    # Apply selected processing functions
    if ("define_variables_date" %in% input$functions) {
      req(input$input_date, input$date_format)
      data <- MycoTools::define_variables_date(data,
                                               input_date = sym(input$input_date),
                                               date_format = input$date_format)
    }

    if ("define_variables_sensorID" %in% input$functions) {
      req(input$input_sensor, input$input_port)
      data <- MycoTools::define_variables_sensorID(data,
                                                   input_sensor = sym(input$input_sensor),
                                                   input_port = sym(input$input_port))
    }

    if ("define_variables_temp" %in% input$functions) {
      req(input$input_temp)
      data <- MycoTools::define_variables_temp(data,
                                               input_temp = sym(input$input_temp))
    }

    if ("define_variables_rhum" %in% input$functions) {
      req(input$input_rhum)
      data <- MycoTools::define_variables_rhum(data,
                                               input_rhum = sym(input$input_rhum))
    }

    if ("define_variables_wood" %in% input$functions) {
      req(input$input_wood)
      data <- MycoTools::define_variables_wood(data,
                                               input_wood = sym(input$input_wood))
    }

    if ("define_variables_ohm" %in% input$functions) {
      req(input$input_ohm)
      data <- MycoTools::define_variables_ohm(data,
                                              input_ohm = sym(input$input_ohm))
    }

    if ("make_complete_date" %in% input$functions) {
      req(input$input_date, input$input_site_id, input$input_sensor_id, input$timeframe)
      data <- MycoTools::make_complete_date(data = data,
                                            input_date = sym(input$input_date),
                                            input_site_id = sym(input$input_site_id),
                                            input_sensor_id = sym(input$input_sensor_id),
                                            timeframe = input$timeframe)
    }

    if ("make_mycoindex_mold" %in% input$functions) {
      req(input$input_mold)
      data <- MycoTools::make_mycoindex_mold(data = data,
                                             input_mold = sym(input$input_mold),
                                             mold_low = input$mold_low,
                                             mold_mid = input$mold_mid,
                                             mold_high = input$mold_high)
    }

    if ("make_mycoindex_temp" %in% input$functions) {
      req(input$input_temp_mold)
      data <- MycoTools::make_mycoindex_temp(data = data,
                                             input_temp = sym(input$input_temp_mold),
                                             temp_low = input$temp_low,
                                             temp_mid = input$temp_mid,
                                             temp_high = input$temp_high,
                                             temp_max = input$temp_max)
    }

    if ("make_mycoindex_wood" %in% input$functions) {
      req(input$input_wood_mold)
      data <- MycoTools::make_mycoindex_wood(data = data,
                                             input_wood = sym(input$input_wood_mold),
                                             wood_low = input$wood_low,
                                             wood_mid = input$wood_mid,
                                             wood_high = input$wood_high,
                                             wood_max = input$wood_max)
    }

    if ("add_date_seasons" %in% input$functions) {
      req(input$input_date)
      data <- MycoTools::add_date_seasons(data = data,
                                          input_date = sym(input$input_date))
    }

    return(data)
  })

  output$processed_data <- renderTable({
    req(processed_data())
    processed_data() %>% head()  # Preview the first few rows
  })

  # Plotting based on processed data
  output$data_plot <- renderPlot({
    req(processed_data())
    ggplot(processed_data(), aes(x = variable1, y = variable2)) +  # Replace `variable1` & `variable2`
      geom_point() +
      theme_minimal() +
      labs(title = "Data Visualization", x = "Variable 1", y = "Variable 2")
  })

  # Download handler for processed data
  output$download_data <- downloadHandler(
    filename = function() {
      paste("processed_data-", Sys.Date(), ".csv", sep = "")
    },
    content = function(file) {
      req(processed_data())
      write_csv(processed_data(), file)
    }
  )
}

# Run the application
shinyApp(ui = ui, server = server)
