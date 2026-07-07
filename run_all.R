# Master driver script for the r-geo-viz project
# Executes all plotting and detection scripts in sequence, handling errors gracefully.

source("utils.R")

scripts <- list(
  "01_plot_all.R",
  "02_plot_southwest.R",
  "03_plot_southwest_1900.R",
  "04_plot_western_1900.R",
  "05_detect_burnt.R",
  "06_frap_overlay.R"
)

for (scr in scripts) {
  log_msg(paste("Running", scr))
  tryCatch({
    source(scr, local = TRUE)
    log_msg(paste("Finished", scr))
  }, error = function(e) {
    log_msg(paste("Error in", scr, ":", e$message))
  })
}
