# E: rerun after changing package dependencies, data or application files.
if (!requireNamespace("rsconnect", quietly = TRUE)) {
  install.packages("rsconnect", repos = "https://cloud.r-project.org")
}
options(repos = c(CRAN = "https://cloud.r-project.org"))
rsconnect::writeManifest(
  appDir = ".", appPrimaryDoc = "app.R",
  appFiles = c("app.R", list.files("R", full.names = TRUE),
    list.files("www", full.names = TRUE), "data/survey.csv")
)
