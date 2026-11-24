# In RStudio: set this folder as the working directory, then source this file.
source("install_packages.R")
shiny::runApp(".", host = "127.0.0.1", port = 3864, launch.browser = interactive())
