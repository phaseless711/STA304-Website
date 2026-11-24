# Shared filters. E may extend this module without changing B/C module logic.
filtersUI <- function(id, data, chart_control = NULL) {
  ns <- shiny::NS(id)
  max_hours <- max(data$weekly_ai_hours, na.rm = TRUE)
  demos <- DEMOGRAPHIC_COLUMNS[DEMOGRAPHIC_COLUMNS %in% names(data)]
  shiny::tagList(
    shiny::h2("Explore the sample"),
    shiny::uiOutput(ns("scope")),
    shiny::tags$hr(),
    if (length(demos)) shiny::tagList(
      shiny::selectInput(ns("demographic"), "Demographic variable", choices = demos),
      shiny::uiOutput(ns("demographic_values"))
    ),
    shiny::selectInput(ns("tool"), "Primary AI tool",
      choices = c("All", sort(unique(data$tool))), selected = "All"),
    shiny::selectInput(ns("intention"), "Future tool choice",
      choices = c("All", "Stay", "Switch", "Not applicable")),
    shiny::sliderInput(ns("hours"), "Weekly AI use (hours)", min = 0,
      max = max_hours, value = c(0, max_hours), step = .5),
    shiny::checkboxInput(ns("keep_skipped"), "Include skipped usage questions", TRUE),
    chart_control,
    shiny::actionButton(ns("reset"), "Reset all filters", class = "reset-button")
  )
}

filtersServer <- function(id, data, with_reference = FALSE) {
  shiny::moduleServer(id, function(input, output, session) {
    demos <- DEMOGRAPHIC_COLUMNS[DEMOGRAPHIC_COLUMNS %in% names(data)]
    output$demographic_values <- shiny::renderUI({
      shiny::req(input$demographic)
      values <- sort(unique(as.character(data[[input$demographic]])))
      values <- values[!is.na(values) & nzchar(values)]
      shiny::selectInput(session$ns("demographic_value"), "Include respondents", c("All", values))
    })
    # Figure 1 retains the comparison denominator before selecting a tool.
    before_tool <- shiny::reactive({
      apply_view_filters(data, "All", input$intention, input$hours,
        input$keep_skipped, input$demographic, input$demographic_value)
    })
    filtered <- shiny::reactive(apply_view_filters(before_tool(), tool = input$tool))
    output$scope <- shiny::renderUI({
      shiny::div(class = "scope-counter", shiny::strong(nrow(filtered())),
        shiny::span(paste("of", nrow(data), "responses")))
    })
    shiny::observeEvent(input$reset, {
      shiny::updateSelectInput(session, "tool", selected = "All")
      shiny::updateSelectInput(session, "intention", selected = "All")
      shiny::updateSliderInput(session, "hours", value = c(0, max(data$weekly_ai_hours, na.rm = TRUE)))
      shiny::updateCheckboxInput(session, "keep_skipped", value = TRUE)
      if (length(demos)) shiny::updateSelectInput(session, "demographic_value", selected = "All")
    })
    if (with_reference) list(data = filtered, before_tool = before_tool) else filtered
  })
}
