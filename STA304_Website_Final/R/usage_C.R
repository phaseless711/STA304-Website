# C: teammate app.R histogram, adapted to the shared site layout and filters.
usageUI <- function(id, survey) {
  ns <- shiny::NS(id)
  max_hours <- max(survey$weekly_ai_hours, na.rm = TRUE)
  shiny::tagList(
    section_header("03 / TIME & FUTURE CHOICES", "Weekly AI Usage Hours",
      "Explore how reported hours are distributed overall or among students who plan to stay or switch."),
    shiny::div(class = "panel",
      shiny::div(class = "control-grid figure-controls",
        shiny::radioButtons(ns("scale"), "Y-axis scale",
          c("Number of students" = "count", "Density" = "density"), inline = TRUE)),
      shiny::div(class = "chart-topline", shiny::h3("Figure 2. Distribution of Weekly AI Usage Hours"),
        shiny::uiOutput(ns("sample"))),
      shiny::plotOutput(ns("chart"), height = "410px"),
      shiny::div(class = "control-grid two",
        shiny::sliderInput(ns("binwidth"), "Histogram bin width (hours)",
          min = .5, max = 10, value = 2, step = .5),
        shiny::sliderInput(ns("xlim"), "X-axis limits (hours)", min = 0,
          max = max_hours, value = c(0, max_hours), step = 1),
        shiny::checkboxInput(ns("custom_y"), "Set Y-axis limits manually", FALSE),
        shiny::div(
          shiny::conditionalPanel("input.custom_y && input.scale === 'count'", ns = ns,
            shiny::sliderInput(ns("ymax_count"), "Y-axis maximum",
              min = 1, max = max(30, nrow(survey)), value = 30, step = 1, ticks = FALSE)),
          shiny::conditionalPanel("input.custom_y && input.scale === 'density'", ns = ns,
            shiny::sliderInput(ns("ymax_density"), "Y-axis maximum",
              min = .01, max = 2, value = 1, step = .01, ticks = FALSE)))),
      shiny::div(class = "interpretation", shiny::span(class = "results-label", "Results"),
        shiny::textOutput(ns("reading")))
    )
  )
}

usageServer <- function(id, data, palette = function() FIGURE_PALETTES$Navy) {
  shiny::moduleServer(id, function(input, output, session) {
    plot_data <- shiny::reactive({
      d <- data()
      d[d$is_ai_user & is.finite(d$weekly_ai_hours) & d$intend_switch %in% c(0, 1), , drop = FALSE]
    })
    output$sample <- shiny::renderUI(shiny::span(class = "sample-badge",
      sprintf("n = %d respondents", nrow(plot_data()))))
    output$chart <- shiny::renderPlot({
      d <- plot_data()
      shiny::validate(shiny::need(nrow(d) > 0,
        if (only_non_users(data())) {
          "The selected respondents reported no AI use. The survey skips the weekly usage and future tool choice questions for this group."
        } else {
          "No eligible responses match these filters."
        }))
      shiny::req(input$binwidth, input$xlim, input$scale)
      shiny::validate(shiny::need(diff(input$xlim) > 0, "Choose a nonzero X-axis range."))
      density <- input$scale == "density"
      y_limit <- NULL
      if (isTRUE(input$custom_y)) {
        ymax <- if (density) input$ymax_density else input$ymax_count
        shiny::req(is.finite(ymax), ymax > 0)
        y_limit <- c(0, ymax)
      }
      ggplot2::ggplot(d, ggplot2::aes(x = weekly_ai_hours)) +
        ggplot2::geom_histogram(
          mapping = if (density) ggplot2::aes(y = ggplot2::after_stat(density)) else NULL,
          binwidth = input$binwidth, boundary = 0,
          fill = palette()[["histogram"]], colour = "white", linewidth = .35) +
        ggplot2::coord_cartesian(xlim = input$xlim,
          ylim = y_limit, expand = c(top = is.null(y_limit), bottom = is.null(y_limit))) +
        ggplot2::labs(x = "Weekly AI usage (hours)", y = if (density) "Density" else "Number of students") +
        chart_theme() + ggplot2::theme(panel.grid.major.y = ggplot2::element_line(colour = "#E5EDF6"))
    }, res = 110, bg = "white")
    output$reading <- shiny::renderText({
      d <- plot_data()
      if (!nrow(d)) return("No eligible responses match these filters.")
      sprintf("Among the %d respondents shown, average weekly AI use was %.2f hours and the median was %.2f hours.",
        nrow(d), mean(d$weekly_ai_hours), median(d$weekly_ai_hours))
    })
  })
}
