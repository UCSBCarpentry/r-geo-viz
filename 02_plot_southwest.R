# Load utilities
source("utils.R")

# 1. Load Counties and filter for Oregon (STATEFP == "41")
log_msg("Loading and projecting counties...")
or_counties_3857 <- load_oregon_counties(crs_target = "EPSG:3857")

# Calculate Southwest Oregon quarter bounding box in EPSG:3857 (western half and southern half)
ext_3857 <- terra::ext(or_counties_3857)
mid_x <- (ext_3857[1] + ext_3857[2]) / 2
mid_y <- (ext_3857[3] + ext_3857[4]) / 2
sw_ext_3857 <- terra::ext(ext_3857[1], mid_x, ext_3857[3], mid_y)

# Convert Southwest bounding box to a SpatVector and project to EPSG:3857
# Using precomputed sw_ext_3857

# 2. Load Historic Fires (already EPSG:3857)
log_msg("Loading historic fires...")
fires_3857 <- load_historic_fires(crs_target = "EPSG:3857")

# 3. Load, downsample, and project rasters (more detail for southwest)
log_msg("Loading, downsampling, and projecting rasters...")
projected_rasters <- load_rasters(down_factor = 5, crs_target = "EPSG:3857")

# 4. Define plot extent based on Southwest Oregon (no padding)
xlims <- c(sw_ext_3857[1], sw_ext_3857[2])
ylims <- c(sw_ext_3857[3], sw_ext_3857[4])

# 5. Ensure output directory
ensure_output_dir("output")
output_path <- file.path("output", "02_oregon_southwest_composite_map.png")

# 6. Plotting
log_msg(paste("Plotting Southwest Oregon composite to:", output_path))
png(output_path, width = 2400, height = 1800, res = 200)

terra::plot(or_counties_3857, col = "gray95", border = "gray70", lwd = 1,
     xlim = xlims, ylim = ylims,
     main = "Southwest Oregon Historical Forest Maps, Counties, and Historic Fires\n(Produced by plot_southwest.R)",
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
log_msg("Southwest map completed successfully!")