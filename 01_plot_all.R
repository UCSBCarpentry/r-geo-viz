# Load utilities
source("utils.R")

# 1. Load Counties and filter for Oregon (STATEFP == "41")
log_msg("Loading and projecting counties...")
or_counties_3857 <- load_oregon_counties(crs_target = "EPSG:3857")

# 2. Load Historic Fires (already EPSG:3857)
log_msg("Loading historic fires...")
fires_3857 <- load_historic_fires(crs_target = "EPSG:3857")

# 3. Load, downsample, and project rasters
log_msg("Loading, downsampling, and projecting rasters...")
projected_rasters <- load_rasters(down_factor = 10, crs_target = "EPSG:3857")

# 4. Define plot extent based on Oregon counties (no padding)
ext_3857 <- terra::ext(or_counties_3857)
xlims <- c(ext_3857[1], ext_3857[2])
ylims <- c(ext_3857[3], ext_3857[4])

# 5. Ensure output directory
ensure_output_dir("output")
output_path <- file.path("output", "01_oregon_composite_map.png")

# 6. Plotting to high-resolution large image
log_msg(paste("Plotting composite to:", output_path))
png(output_path, width = 2400, height = 1800, res = 200)

# Base plot of Oregon counties to set coordinate system
terra::plot(or_counties_3857, col = "gray95", border = "gray70", lwd = 1,
     main = "Oregon Historical Forest Maps, Counties, and Historic Fires\n(Produced by plot_all.R)",
     mar = c(3, 3, 4, 3))

# Overlay rasters
for (name in names(projected_rasters)) {
  log_msg(paste("Overlaying raster:", name))
  tryCatch({
    plotRGB(projected_rasters[[name]], r = 1, g = 2, b = 3, add = TRUE)
  }, error = function(e) {
    log_msg(paste("Error plotting", name, ":", e$message))
  })
}

# County outlines
terra::plot(or_counties_3857, col = NA, border = "black", lwd = 1.2, add = TRUE)

# Historic fires
terra::plot(fires_3857, col = rgb(1, 0, 0, 0.3), border = "darkred", lwd = 0.5, add = TRUE)

# Legend
legend("bottomleft", legend = c("County Boundaries", "Historic Fires (pre-2000)"),
       col = c("black", "darkred"), lty = 1, lwd = c(1.2, 1),
       fill = c(NA, rgb(1, 0, 0, 0.3)), border = c("black", "darkred"),
       bg = "white", cex = 0.8)

dev.off()
log_msg("Map completed successfully!")