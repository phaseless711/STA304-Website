# A owns the site-wide title, navigation and visual identity.
PROJECT <- list(
  title = "STA304 Student AI Use Survey",
  subtitle = "Generative AI preferences and habits among STA304H5 students",
  team = "Null Hypothesis",
  term = "Fall 2026",
  data_file = file.path("data", "survey.csv")
)

# E can enable demographic filters after genuine data are supplied.
# Named entries use a readable label and an existing CSV column, for example:
# DEMOGRAPHIC_COLUMNS <- c("Year of study" = "year_of_study")
# Do not invent values or derive demographics from the course-specific ID.
DEMOGRAPHIC_COLUMNS <- character(0)

PALETTES <- list(
  Navy = c("#1B3B67", "#7F9FC6", "#284F83", "#AFC6E1", "#436898", "#D5E1EF"),
  Orange = c("#D76B27", "#EBA46B", "#B94D15", "#F3C398", "#8F532F", "#D7CBC1"),
  Forest = c("#225D50", "#9ABDA2", "#D1AD66", "#547975", "#B7C6A0", "#B7BDB9"),
  Ocean = c("#285D87", "#8FBAD2", "#D8AC63", "#648F9A", "#B0CBD1", "#B9BEC4"),
  `Colour-blind friendly` = c("#0072B2", "#E69F00", "#009E73", "#CC79A7", "#56B4E9", "#999999")
)

# The stacked chart uses the tool colours. The histogram shows one distribution.
FIGURE_PALETTES <- list(
  Navy = c("ChatGPT" = "#1B3B67", "Claude" = "#4C84B8", "Gemini" = "#91B8D8",
    "Other AI" = "#D6E5F2", histogram = "#284F83"),
  Grayscale = c("ChatGPT" = "#333333", "Claude" = "#666666", "Gemini" = "#999999",
    "Other AI" = "#CCCCCC", histogram = "#555555"),
  Pastel = c("ChatGPT" = "#A8DADC", "Claude" = "#F4A7A8", "Gemini" = "#CDB4DB",
    "Other AI" = "#FFD6A5", histogram = "#7C99BB")
)
