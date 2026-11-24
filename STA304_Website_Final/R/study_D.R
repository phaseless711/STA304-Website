# D module: findings and limitations for the shared survey website.
studyUI <- function(id) {
  ns <- shiny::NS(id)
  shiny::div(id = ns("page"), class = "study-page",
    section_header("04 / THE STUDY", "Summary of Findings"),
    shiny::div(class = "study-intro",
      shiny::div(class = "panel", shiny::h3("Survey Overview"),
        shiny::p("This survey explores generative AI use among STA304H5 students, including their primary tools, academic purposes, weekly usage hours, perceived benefits, and intentions to switch tools."),
        shiny::p("It includes 112 voluntary responses, of which 110 are from AI users. Participants were recruited through Piazza posts and in-person invitations, so the findings describe a self-selected sample and may not represent all STA304H5 students.")),
      shiny::div(class = "panel", shiny::h3("Survey Analysis"),
        shiny::p("We used descriptive statistics to summarize AI tool preferences, academic purposes, weekly usage hours, and switching intentions."),
        shiny::p("A chi-square test examined the association between primary AI tool and academic purpose, while quadratic logistic regression assessed the relationship between weekly usage hours and the intention to switch tools."))),
    shiny::div(class = "panel", shiny::h3("Summary statistics"),
      shiny::p("Weekly AI use for coursework (hours), overall and by switching intention, in the current selection."),
      shiny::div(class = "study-table", shiny::tableOutput(ns("hours_table"))),
      shiny::uiOutput(ns("hours_reading"))),
    shiny::div(class = "panel",
      shiny::h3("Statistical Findings"),
      shiny::uiOutput(ns("sample")),
      shiny::uiOutput(ns("results"))),
    shiny::div(class = "panel caveat-panel", shiny::h3("Study Limitations"),
      shiny::p("The voluntary, non-probability sample may be affected by self-selection bias and may not represent all STA304H5 students. Usage hours, perceived benefits, and switching intentions were self-reported and may differ from actual behaviour or outcomes."),
      shiny::p("Sparse tool-by-purpose counts and influential observations limit the strength of the statistical evidence. The quadratic model was selected during exploratory analysis, so its p-values do not account for model-selection uncertainty. Repeated subgroup testing may also increase the risk of false-positive findings. These observational results describe associations and cannot establish causation."))
  )
}

study_hours_summary <- function(d) {
  d <- d[d$is_ai_user & is.finite(d$weekly_ai_hours), , drop = FALSE]
  groups <- list("All AI users" = d$weekly_ai_hours,
    Stay = d$weekly_ai_hours[d$intend_switch %in% 0],
    Switch = d$weekly_ai_hours[d$intend_switch %in% 1])
  do.call(rbind, lapply(names(groups), function(g) {
    x <- groups[[g]]
    data.frame(Variable = "Weekly AI use (hours)", Group = g, N = length(x),
      Mean = if (length(x)) mean(x) else NA_real_,
      Median = if (length(x)) stats::median(x) else NA_real_,
      SD = if (length(x) > 1L) stats::sd(x) else NA_real_,
      IQR = if (length(x)) stats::IQR(x) else NA_real_, check.names = FALSE)
  }))
}

# Preserve the existing analysis sample, formula, seed and simulation count.
compute_study <- function(d, centre) {
  a <- eligible_users(d)
  out <- list(n = nrow(a), chi = NULL, logistic = NULL,
    chi_note = NULL, logistic_note = NULL)
  if (!nrow(a)) {
    out$chi_note <- out$logistic_note <- "Not reported: no complete AI-user responses in this selection."
    return(out)
  }

  tab <- table(a$primary_tool, a$academic_purpose)
  if (nrow(tab) < 2L || ncol(tab) < 2L) {
    out$chi_note <- "Not reported: the test requires at least two AI tools and two academic purposes."
  } else {
    # Restore RNG state so this calculation does not affect other modules.
    had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
    if (had_seed) old_seed <- get(".Random.seed", envir = .GlobalEnv)
    on.exit({
      if (had_seed) assign(".Random.seed", old_seed, envir = .GlobalEnv)
      else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE))
        rm(".Random.seed", envir = .GlobalEnv)
    }, add = TRUE)
    set.seed(304)
    out["chi"] <- list(tryCatch(stats::chisq.test(tab, simulate.p.value = TRUE, B = 100000),
      error = function(e) NULL))
    if (is.null(out$chi) || !is.finite(out$chi$p.value)) {
      out["chi"] <- list(NULL)
      out$chi_note <- "Not reported: the simulated test could not be computed for this selection."
    }
  }

  counts <- table(factor(a$intend_switch, levels = c(0, 1)))
  # Conservative display safeguards, not universal sample-size assumptions.
  if (nrow(a) < 20L || any(counts < 5L) || length(unique(a$weekly_ai_hours)) < 3L) {
    out$logistic_note <- "Not reported: this app requires 20 complete responses, five Stay and five Switch responses, and three distinct hour values to display the model."
    return(out)
  }
  if (length(centre) != 1L || !is.finite(centre)) {
    out$logistic_note <- "Not reported: the full-sample hours-centering value is unavailable."
    return(out)
  }
  a$hours_centered <- a$weekly_ai_hours - centre
  out["logistic"] <- list(tryCatch({
    warned <- FALSE
    fitted <- withCallingHandlers({
      null <- stats::glm(intend_switch ~ 1, data = a, family = stats::binomial())
      model <- stats::glm(intend_switch ~ hours_centered + I(hours_centered^2),
        data = a, family = stats::binomial())
      list(null = null, model = model)
    }, warning = function(w) { warned <<- TRUE; invokeRestart("muffleWarning") })
    model <- fitted$model
    if (warned || !model$converged || model$rank < 3L ||
        any(!is.finite(stats::coef(summary(model)))) ||
        any(stats::fitted(model) < 1e-8 | stats::fitted(model) > 1 - 1e-8)) {
      NULL
    } else {
      comparison <- stats::anova(fitted$null, model, test = "Chisq")
      p <- comparison$`Pr(>Chi)`[2]
      if (!is.finite(p)) NULL else list(p = p, statistic = comparison$Deviance[2],
        df = comparison$Df[2], n = nrow(a))
    }
  }, error = function(e) NULL))
  if (is.null(out$logistic))
    out$logistic_note <- "Not reported: model fitting failed or showed instability in this selection; this is not a nonsignificant result."
  out
}

studyServer <- function(id, data, centre) {
  shiny::moduleServer(id, function(input, output, session) {
    results <- shiny::reactive(compute_study(data(), centre))
    output$hours_table <- shiny::renderTable({
      study_hours_summary(data())
    }, digits = 2, na = "\u2014", rownames = FALSE, striped = TRUE,
      bordered = FALSE, spacing = "s")
    output$hours_reading <- shiny::renderUI({
      d <- data()
      d <- d[d$is_ai_user & is.finite(d$weekly_ai_hours), , drop = FALSE]
      if (!nrow(d)) return(shiny::p("No valid weekly-hour responses are available in this selection."))
      x <- d$weekly_ai_hours
      if (length(x) == 1L) {
        return(shiny::p(sprintf("The respondent reported %.2f hours of weekly AI use for coursework.", x)))
      }
      q <- stats::quantile(x, c(.25, .75), names = FALSE)
      fmt <- function(v) if (length(v) == 1L && is.finite(v)) sprintf("%.2f", v) else "not available"
      overall <- shiny::p(shiny::HTML(sprintf(
        "Among the %d AI users, average weekly AI use for coursework was <strong>%s hours</strong>, with a median of <strong>%s hours</strong>, a standard deviation of <strong>%s hours</strong>, and an IQR of <strong>%s hours</strong>. The middle 50%% of responses ranged from <strong>%s to %s hours</strong>, indicating variation in how much time students spent using AI.",
        length(x), fmt(mean(x)), fmt(stats::median(x)), fmt(stats::sd(x)), fmt(stats::IQR(x)), fmt(q[1]), fmt(q[2]))))
      pairs <- d[d$intend_switch %in% c(0, 1), , drop = FALSE]
      comparison <- NULL
      if (all(c(0, 1) %in% pairs$intend_switch)) {
        stay <- pairs$weekly_ai_hours[pairs$intend_switch == 0]
        switch <- pairs$weekly_ai_hours[pairs$intend_switch == 1]
        relation <- function(a, b) if (a > b) "higher" else if (a < b) "lower" else "the same"
        lead <- sprintf(
          "Students planning to stay with their current tool reported %s average usage than those planning to switch (<strong>%s versus %s hours</strong>), but a %s median (<strong>%s versus %s hours</strong>).",
          relation(mean(stay), mean(switch)), fmt(mean(stay)), fmt(mean(switch)),
          relation(stats::median(stay), stats::median(switch)), fmt(stats::median(stay)), fmt(stats::median(switch)))
        # Avoid a contrast when the filtered groups follow a different pattern.
        if (!(mean(stay) > mean(switch) && stats::median(stay) < stats::median(switch))) {
          lead <- sprintf(
            "Students planning to stay with their current tool reported average usage of <strong>%s hours</strong> and a median of <strong>%s hours</strong>, compared with <strong>%s</strong> and <strong>%s hours</strong>, respectively, for those planning to switch.",
            fmt(mean(stay)), fmt(stats::median(stay)), fmt(mean(switch)), fmt(stats::median(switch)))
        }
        spread <- sprintf("Usage variability was SD = <strong>%s</strong> in the Stay group and SD = <strong>%s</strong> in the Switch group.",
          fmt(stats::sd(stay)), fmt(stats::sd(switch)))
        if (length(stay) > 1L && length(switch) > 1L &&
            mean(stay) > mean(switch) && stats::median(stay) < stats::median(switch) &&
            stats::sd(stay) > stats::sd(switch)) {
          spread <- sprintf("Usage also varied more in the Stay group (SD = <strong>%s</strong>) than in the Switch group (SD = <strong>%s</strong>), suggesting that some higher-use respondents raised the Stay group's average.",
            fmt(stats::sd(stay)), fmt(stats::sd(switch)))
        }
        comparison <- shiny::p(shiny::HTML(paste(lead, spread,
          "These descriptive differences alone do not establish a statistically significant relationship between usage hours and switching intention.")))
      }
      shiny::tagList(overall, comparison)
    })
    output$sample <- shiny::renderUI(shiny::p(
      sprintf("The following results are based on %d AI users with complete responses and update with the sidebar filters.", results()$n)))
    output$results <- shiny::renderUI({
      r <- results()
      p_label <- function(p) if (p < .0001) "p < 0.0001" else paste0("p = ", fmt_p(p))
      chi <- if (is.null(r$chi)) shiny::p(r$chi_note) else {
        significant <- r$chi$p.value < .05
        shiny::tagList(
          shiny::p(sprintf(
            "The chi-square test %s a statistically significant association between students' primary AI tool and their main academic purpose (\u03c7\u00b2 = %.3f, Monte Carlo %s).",
            if (significant) "found" else "did not find",
            as.numeric(r$chi$statistic), p_label(r$chi$p.value))),
          shiny::p(if (significant)
            "Tool choice and academic purpose were associated in this selection, but the test does not establish a causal relationship."
            else if (as.numeric(r$chi$statistic) > 1e-10)
              "Although tool preferences varied across purposes in the sample, the evidence was insufficient to conclude that tool choice and academic purpose were associated."
            else "The evidence was insufficient to conclude that tool choice and academic purpose were associated; this does not prove independence."))
      }
      logistic <- if (is.null(r$logistic)) shiny::p(r$logistic_note) else {
        significant <- r$logistic$p < .05
        shiny::tagList(
          shiny::p(sprintf(
            "The quadratic logistic regression model %s statistical significance at the 5%% level (likelihood-ratio \u03c7\u00b2 = %.3f, df = %d, %s).",
            if (significant) "reached" else "did not reach", r$logistic$statistic,
            as.integer(r$logistic$df), p_label(r$logistic$p))),
          shiny::p(if (significant)
            "Weekly usage hours provided exploratory evidence of an association with switching intention in this selection. This does not establish causation; the result should be interpreted cautiously because the model was selected during exploratory analysis."
            else "The sample provided insufficient evidence of an association between weekly AI usage hours and switching intention. This does not establish that no relationship exists; the result should be interpreted cautiously because the model was selected during exploratory analysis."))
      }
      shiny::div(class = "study-grid test-grid",
        shiny::div(class = "test-block", shiny::h4("AI Tool and Academic Purpose"),
          if (!is.null(r$chi)) shiny::div(class = "test-value", p_label(r$chi$p.value)), chi),
        shiny::div(class = "test-block", shiny::h4("Weekly Usage and Switching Intention"),
          if (!is.null(r$logistic)) shiny::div(class = "test-value", p_label(r$logistic$p)), logistic))
    })
    results
  })
}
