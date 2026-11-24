# Shared data definitions. All modules use the same eligible respondents.
read_survey <- function(path) {
  d <- read.csv(path, na.strings = c("", "NA", "N/A"),
                stringsAsFactors = FALSE, check.names = FALSE)
  required <- c("primary_tool", "weekly_ai_hours", "academic_purpose", "intend_switch")
  stopifnot(all(required %in% names(d)))
  # The distributed CSV already excludes the ID; this is a second safeguard.
  d <- d[, !tolower(names(d)) %in% c("studentid", "student_id"), drop = FALSE]
  d$weekly_ai_hours <- as.numeric(d$weekly_ai_hours)
  d$intend_switch <- as.numeric(d$intend_switch)
  stopifnot(all(is.na(d$weekly_ai_hours) | (is.finite(d$weekly_ai_hours) & d$weekly_ai_hours >= 0)))
  stopifnot(all(is.na(d$intend_switch) | d$intend_switch %in% c(0, 1)))
  d$is_ai_user <- !is.na(d$primary_tool) & d$primary_tool != "I do not use AI."
  d$tool <- ifelse(d$is_ai_user, d$primary_tool, "No AI use")
  d$switch_group <- ifelse(!d$is_ai_user | is.na(d$intend_switch), "Not applicable",
                            ifelse(d$intend_switch == 1, "Switch", "Stay"))
  purpose_labels <- c(
    "Brainstorming & Idea Generation" = "Brainstorming",
    "Exam preparation and last-minute revision" = "Exam preparation",
    "Summarizing Readings & Lecture Slides" = "Summarizing readings & slides",
    "Writing & Debugging Code (e.g., R, Python, SQL)" = "Coding & debugging",
    "Writing & Editing Essays or Reports" = "Writing & editing"
  )
  d$purpose <- unname(purpose_labels[d$academic_purpose])
  d
}

eligible_users <- function(d) {
  d[d$is_ai_user & !is.na(d$weekly_ai_hours) &
      !is.na(d$intend_switch) & !is.na(d$academic_purpose), , drop = FALSE]
}

only_non_users <- function(d) {
  nrow(d) > 0 && all(!d$is_ai_user & !is.na(d$primary_tool))
}

apply_view_filters <- function(d, tool = "All", intention = "All", hours = NULL,
                               keep_skipped = TRUE, demographic = NULL,
                               demographic_value = "All") {
  keep <- rep(TRUE, nrow(d))
  if (!is.null(tool) && tool != "All") keep <- keep & d$tool == tool
  if (!is.null(intention) && intention != "All") keep <- keep & d$switch_group == intention
  if (!is.null(hours)) {
    within <- !is.na(d$weekly_ai_hours) & d$weekly_ai_hours >= hours[1] & d$weekly_ai_hours <= hours[2]
    keep <- keep & (within | (isTRUE(keep_skipped) & is.na(d$weekly_ai_hours)))
  }
  if (!is.null(demographic) && demographic %in% names(d) &&
      !is.null(demographic_value) && demographic_value != "All") {
    keep <- keep & !is.na(d[[demographic]]) & as.character(d[[demographic]]) == demographic_value
  }
  d[which(keep), , drop = FALSE]
}

pct <- function(x, n, digits = 1) {
  if (!is.finite(n) || n == 0) return("\u2014")
  paste0(formatC(100 * x / n, format = "f", digits = digits), "%")
}

fmt_p <- function(p) {
  if (!is.finite(p)) return("Not available")
  if (p < .0001) return("< 0.0001")
  formatC(p, format = "f", digits = 4)
}

wrap_label <- function(x, width = 30) {
  vapply(x, function(s) paste(strwrap(s, width = width), collapse = "\n"), character(1))
}

chart_theme <- function() {
  ggplot2::theme_minimal(base_size = 13, base_family = "Arial") +
    ggplot2::theme(
      axis.text = ggplot2::element_text(colour = "#485B73"),
      panel.grid.major.y = ggplot2::element_blank(),
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major.x = ggplot2::element_line(colour = "#E5EDF6"),
      plot.title = ggplot2::element_text(face = "bold", colour = "#172840", size = 15),
      plot.subtitle = ggplot2::element_text(colour = "#53667D", margin = ggplot2::margin(b = 18)),
      legend.title = ggplot2::element_blank(), legend.position = "bottom",
      plot.margin = ggplot2::margin(12, 25, 12, 8)
    )
}

section_header <- function(kicker, title, description = NULL) {
  shiny::div(class = "section-heading",
    shiny::h1(title))
}

metric_card <- function(label, value, detail, accent = FALSE) {
  shiny::div(class = paste("metric-card", if (accent) "metric-accent" else ""),
    shiny::div(class = "metric-label", label), shiny::div(class = "metric-value", value),
    shiny::div(class = "metric-detail", detail))
}

category_summary <- function(d, variable = "primary_tool") {
  empty <- data.frame(label = character(), n = integer(), denominator = integer(), share = numeric())
  if (!nrow(d)) return(empty)
  if (variable == "benefits") {
    labels <- c(benefit_time = "Saving time", benefit_understanding = "Understanding concepts",
                benefit_grades = "Improved grades", benefit_coding = "Coding skills",
                benefit_anxiety = "Less learning anxiety")
    a <- d[d$is_ai_user, , drop = FALSE]
    out <- do.call(rbind, lapply(names(labels), function(v) {
      if (!v %in% names(a)) return(NULL)
      valid <- a[[v]] %in% c(0, 1)
      data.frame(label = unname(labels[v]), n = sum(a[[v]][valid] == 1), denominator = sum(valid))
    }))
    if (is.null(out)) return(empty)
  } else {
    if (variable == "primary_tool") values <- d$tool
    if (variable == "academic_purpose") values <- d$purpose[d$is_ai_user]
    if (variable == "tool_choice_reason") values <- d$tool_choice_reason[d$is_ai_user]
    values <- values[!is.na(values) & nzchar(values)]
    if (!length(values)) return(empty)
    tab <- table(values)
    out <- data.frame(label = names(tab), n = as.integer(tab), denominator = length(values))
  }
  out <- out[out$denominator > 0, , drop = FALSE]
  out$share <- out$n / out$denominator
  out[order(-out$n, out$label), , drop = FALSE]
}

make_category_plot <- function(summary, measure = "percent", palette = "Navy", axis_max = NULL, colour = NULL) {
  stopifnot(nrow(summary) > 0)
  s <- summary
  s$label <- factor(s$label, levels = rev(s$label))
  s$value <- if (measure == "percent") 100 * s$share else s$n
  s$mark <- if (measure == "percent") sprintf("%.1f%%", s$value) else as.character(s$n)
  if (is.null(axis_max)) axis_max <- if (measure == "percent") 100 else max(s$n) * 1.15
  ggplot2::ggplot(s, ggplot2::aes(value, label)) +
    ggplot2::geom_col(fill = if (is.null(colour)) PALETTES[[palette]][1] else colour, width = .54) +
    ggplot2::geom_text(ggplot2::aes(label = mark), hjust = -.18, size = 4, family = "Arial", colour = "#17345A") +
    ggplot2::scale_y_discrete(labels = function(x) wrap_label(x, 31)) +
    ggplot2::scale_x_continuous(expand = ggplot2::expansion(mult = c(0, .08))) +
    ggplot2::coord_cartesian(xlim = c(0, axis_max), clip = "on") +
    ggplot2::labs(x = if (measure == "percent") "Share of eligible respondents (%)" else "Respondents", y = NULL) +
    chart_theme()
}
