# Master driver script for the r-geo-viz project
# Executes all plotting and detection scripts in sequence, handling errors gracefully.

source("utils.R")

scripts <- list(
  "01_plot_all.R",
  "02_plot_southwest.R",
  "03_plot_southwest_1900.R",
  "04_plot_western_1900.R",
  "05_california_composite.R",
  "06_detect_burnt.R",
  "07_frap_overlay.R"
)

for (scr in scripts) {
  log_msg(paste("Running [AI-Driven Workflow Task]:", scr))
  tryCatch({
    source(scr, local = TRUE)
    log_msg(paste("Finished [AI-Driven Workflow Task]:", scr))
  }, error = function(e) {
    log_msg(paste("Error in AI task", scr, ":", e$message))
  })
}
