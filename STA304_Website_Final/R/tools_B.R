# B: teammate Figure1_Shiny.R, adapted to the shared site layout and filters.
toolsUI <- function(id, survey) {
  ns <- shiny::NS(id)
  purposes <- sort(unique(survey$purpose[survey$is_ai_user & !is.na(survey$purpose)]))
  shiny::tagList(
    section_header("02 / TOOLS & TASKS", "AI Tool Use by Academic Purpose",
      "Compare tool choices across the academic tasks reported by AI users."),
    shiny::div(class = "panel",
      shiny::div(class = "control-grid figure-controls",
        shiny::selectInput(ns("purpose"), "Academic purpose", c("All purposes" = "all", purposes)),
        shiny::radioButtons(ns("measure"), "Display values",
          c("Percentage" = "percent", "Count" = "count"), inline = TRUE)),
      shiny::div(class = "chart-topline", shiny::h3("Figure 1. AI Tool Use by Academic Purpose"),
        shiny::uiOutput(ns("sample"))),
      shiny::plotOutput(ns("chart"), height = "420px"),
      shiny::p(class = "figure-note", "\"Other AI\" includes DeepSeek and Yuanbao."),
      shiny::uiOutput(ns("denominator_note")),
      shiny::div(class = "interpretation", shiny::span(class = "results-label", "Results"),
        shiny::textOutput(ns("reading"))),
      shiny::checkboxInput(ns("show_table"), "Show the numbers behind this chart", FALSE),
      shiny::conditionalPanel("input.show_table", ns = ns,
        shiny::tableOutput(ns("summary_table")),
        shiny::downloadButton(ns("download"), "Download this summary", class = "secondary-button"))
    )
  )
}

purpose_tool_summary <- function(selected, reference, purpose = "") {
  eligible <- function(d) {
    d <- d[d$is_ai_user & !is.na(d$purpose), , drop = FALSE]
    if (nzchar(purpose) && purpose != "all") d <- d[d$purpose == purpose, , drop = FALSE]
    d
  }
  selected <- eligible(selected)
  reference <- eligible(reference)
  sizes <- table(reference$purpose)
  groups <- c("ChatGPT", "Claude", "Gemini", "Other AI")
  group <- ifelse(selected$tool %in% groups[1:3], selected$tool, "Other AI")
  shown_groups <- groups[groups %in% group]
  grid <- as.data.frame(table(
    Purpose = factor(selected$purpose, levels = rev(names(sizes))),
    Tool = factor(group, levels = shown_groups)), responseName = "Count")
  grid$Denominator <- as.integer(sizes[as.character(grid$Purpose)])
  grid$Percentage <- if (nrow(grid)) 100 * grid$Count / grid$Denominator else numeric(0)
  list(rows = grid, selected = nrow(selected), reference = nrow(reference))
}

toolsServer <- function(id, data, before_tool = data, palette = function() FIGURE_PALETTES$Navy) {
  shiny::moduleServer(id, function(input, output, session) {
    summary <- shiny::reactive(purpose_tool_summary(data(), before_tool(),
      if (is.null(input$purpose)) "" else input$purpose))
    output$denominator_note <- shiny::renderUI({
      s <- summary()
      if (identical(input$measure, "percent") && s$selected > 0 &&
          s$selected < s$reference) {
        shiny::p(class = "figure-note", "Percentages are relative to all tools within each purpose.")
      }
    })
    output$sample <- shiny::renderUI(shiny::span(class = "sample-badge",
      sprintf("n = %d eligible AI users", summary()$selected)))
    output$chart <- shiny::renderPlot({
      result <- summary()
      shiny::validate(shiny::need(result$selected > 0,
        if (only_non_users(data())) {
          "The selected respondents reported no AI use. The survey skips the academic-purpose question for this group."
        } else {
          "No eligible AI users match these filters. Try changing the tool or academic purpose."
        }))
      shiny::req(input$measure)
      d <- result$rows
      percent <- input$measure == "percent"
      d$Value <- if (percent) d$Percentage else d$Count
      tool_colours <- palette()[c("ChatGPT", "Claude", "Gemini", "Other AI")]
      ggplot2::ggplot(d, ggplot2::aes(Value, Purpose, fill = Tool)) +
        ggplot2::geom_col(orientation = "y", width = .65,
          position = ggplot2::position_stack(reverse = TRUE)) +
        ggplot2::scale_fill_manual(values = tool_colours) +
        ggplot2::scale_x_continuous(
          breaks = if (percent) seq(0, 100, 25) else ggplot2::waiver(),
          labels = if (percent) function(x) paste0(x, "%") else ggplot2::waiver(),
          expand = ggplot2::expansion(mult = c(0, .04))) +
        ggplot2::coord_cartesian(xlim = if (percent) c(0, 100) else NULL) +
        ggplot2::labs(x = if (percent) "Share of AI users within each purpose" else "Number of students",
          y = "Primary academic purpose") +
        chart_theme()
    }, res = 110, bg = "white")
    output$reading <- shiny::renderText({
      s <- summary()
      if (!s$selected) return("No eligible AI users match these filters.")
      by_tool <- tapply(s$rows$Count, s$rows$Tool, sum)
      leaders <- names(by_tool)[by_tool == max(by_tool)]
      if (length(by_tool) == 1L && s$selected < s$reference) {
        intro <- sprintf("The selected tool group accounts for %d of %d eligible AI users across the academic purposes shown (%.1f%%).",
          s$selected, s$reference, 100 * s$selected / s$reference)
      } else if (length(leaders) == 1L) {
        intro <- sprintf("Among the %d eligible AI users shown, %s is the most common tool group, used by %d respondents (%.1f%%).",
          s$selected, leaders, max(by_tool), 100 * max(by_tool) / s$selected)
      } else {
        intro <- sprintf("Among the %d eligible AI users shown, %s are tied as the most common tool groups, with %d respondents each (%.1f%% each).",
          s$selected, paste(leaders, collapse = " and "), max(by_tool), 100 * max(by_tool) / s$selected)
      }
      detail <- NULL
      if (length(leaders) == 1L) {
        rows <- s$rows[as.character(s$rows$Tool) == leaders, , drop = FALSE]
        high <- rows[which.max(rows$Percentage), , drop = FALSE]
        low <- rows[which.min(rows$Percentage), , drop = FALSE]
        if (nrow(rows) == 1L) {
          detail <- sprintf("For %s, this group accounts for %d of %d AI users (%.1f%%).",
            tolower(as.character(high$Purpose)), high$Count, high$Denominator, high$Percentage)
        } else if (high$Percentage > low$Percentage) {
          detail <- sprintf("Its share is highest for %s (%.1f%%; %d of %d respondents) and lowest for %s (%.1f%%; %d of %d respondents).",
            tolower(as.character(high$Purpose)), high$Percentage, high$Count, high$Denominator,
            tolower(as.character(low$Purpose)), low$Percentage, low$Count, low$Denominator)
        } else {
          detail <- sprintf("Its share is %.1f%% within each academic purpose shown.", high$Percentage)
        }
      }
      paste(c(intro, detail), collapse = " ")
    })
    readable_summary <- shiny::reactive({
      d <- summary()$rows
      data.frame("Academic purpose" = as.character(d$Purpose), "Tool shown" = as.character(d$Tool),
        Count = d$Count, "Eligible AI users before tool filter" = d$Denominator,
        "Percentage (%)" = round(d$Percentage, 1), check.names = FALSE)
    })
    output$summary_table <- shiny::renderTable(readable_summary(), striped = TRUE, spacing = "m", digits = 1)
    output$download <- shiny::downloadHandler(filename = function() "STA304-tool-by-purpose.csv",
      content = function(file) write.csv(readable_summary(), file, row.names = FALSE))
  })
}
