# A: application shell, shared visual identity, and module integration.
library(shiny)
library(bslib)
library(ggplot2)
library(DT)

for (file in c("config.R", "helpers.R", "filters_E.R", "tools_B.R", "usage_C.R", "study_D.R")) {
  source(file.path("R", file), local = TRUE)
}
survey <- read_survey(PROJECT$data_file)
full_users <- eligible_users(survey)
centre <- mean(full_users$weekly_ai_hours)

ui <- fluidPage(
  theme = bs_theme(version = 5, bg = "#FFFFFF", fg = "#172840", primary = "#17345A",
    base_font = "Arial", heading_font = "Arial", border_radius = "12px"),
  tags$head(
    tags$title(PROJECT$title),
    tags$meta(name = "viewport", content = "width=device-width, initial-scale=1"),
    tags$link(rel = "stylesheet", type = "text/css", href = "styles.css"),
    tags$link(rel = "icon", type = "image/svg+xml", href = "favicon.svg")),
  div(class = "site-shell",
    tags$aside(class = "global-sidebar", `aria-label` = "Shared survey filters and chart settings",
      filtersUI("filters", survey, chart_control = conditionalPanel(
        "input.main_nav === 'overview' || input.main_nav === 'tools' || input.main_nav === 'usage'",
        selectInput("figure_palette", "Chart palette (all three charts)", names(FIGURE_PALETTES))))),
    tags$main(class = "main-content",
      tabsetPanel(id = "main_nav", type = "tabs", selected = "overview",
        tabPanel("Survey Overview", value = "overview",
          section_header("01 / OVERVIEW", "AI Use Among STA304H5 Students",
            "Explore which AI tools STA304H5 respondents use most for coursework."),
          div(class = "panel",
            div(class = "chart-topline", h3("Primary AI Tools")),
            plotOutput("overview_chart", height = "420px"),
            div(class = "interpretation", span(class = "results-label", "Results"),
              textOutput("overview_reading")))),
        tabPanel("AI Tools and Academic Tasks", value = "tools", toolsUI("tools", survey)),
        tabPanel("Weekly AI Use", value = "usage", usageUI("usage", survey)),
        tabPanel("Findings", value = "study", studyUI("study")),
        tabPanel("Survey Data", value = "data",
          section_header("05 / DATA EXPLORER", "Survey Responses",
            "Search and sort the responses in your current view. Course-specific student IDs are excluded."),
          div(class = "panel", uiOutput("data_scope"), DTOutput("responses")))
      ))
  )
)

server <- function(input, output, session) {
  filters <- filtersServer("filters", survey, with_reference = TRUE)
  filtered_data <- filters$data
  figure_palette <- reactive({
    req(input$figure_palette)
    FIGURE_PALETTES[[input$figure_palette]]
  })
  toolsServer("tools", filtered_data, before_tool = filters$before_tool, palette = figure_palette)
  usageServer("usage", filtered_data, palette = figure_palette)
  studyServer("study", filtered_data, centre)
  overview_summary <- reactive(category_summary(filtered_data(), "primary_tool"))
  output$overview_chart <- renderPlot({
    s <- overview_summary()
    validate(need(nrow(s) > 0, "No responses in this view. Reset the filters to start again."))
    make_category_plot(s, "percent", "Navy", 100, colour = figure_palette()[["histogram"]]) +
      labs(x = "Share of respondents (%)")
  }, res = 110, bg = "white")
  output$overview_reading <- renderText({
    s <- overview_summary()
    req(nrow(s) > 0)
    leaders <- s$label[s$n == s$n[1]]
    share <- pct(s$n[1], s$denominator[1])
    if (length(leaders) == 1) {
      sprintf("The most common response in this view is %s (%d of %d respondents, %s).",
        leaders, s$n[1], s$denominator[1], share)
    } else {
      sprintf("The most common responses in this view are %s. Each accounts for %d of %d responses (%s).",
        paste(leaders, collapse = ", "), s$n[1], s$denominator[1], share)
    }
  })
  output$data_scope <- renderUI(div(class = "chart-topline", h3("Survey Responses"),
    span(class = "sample-badge", paste(nrow(filtered_data()), "responses in this view"))))
  output$responses <- renderDT({
    d <- filtered_data()
    shown <- data.frame(`Primary AI tool` = d$tool, `Weekly use (hours)` = d$weekly_ai_hours,
      `Main academic purpose` = d$purpose, `Future tool choice` = d$switch_group,
      `Reports saving time` = ifelse(is.na(d$benefit_time), NA, ifelse(d$benefit_time == 1, "Yes", "No")),
      check.names = FALSE)
    datatable(shown, rownames = FALSE, filter = "top", selection = "none",
      options = list(pageLength = 8, lengthMenu = c(8, 15, 30), scrollX = TRUE,
        language = list(search = "Search responses:", emptyTable = "No responses match these filters."),
        columnDefs = list(list(targets = "_all", defaultContent = "Not applicable"))))
  }, server = TRUE)
}

shinyApp(ui, server)
