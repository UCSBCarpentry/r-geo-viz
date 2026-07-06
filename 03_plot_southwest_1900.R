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

# 2. Load Historic Fires, filter for 1900
log_msg("Loading and filtering historic fires (year 1900)...")
fires_1900_3857 <- load_historic_fires(crs_target = "EPSG:3857", year = 1900)
log_msg(paste("Number of 1900 fires:", nrow(fires_1900_3857)))

# 3. Load, downsample, and project rasters (detail for southwest)
log_msg("Loading, downsampling, and projecting rasters...")
projected_rasters <- load_rasters(down_factor = 5, crs_target = "EPSG:3857")

# 4. Define plot extent based on Southwest Oregon (no padding)
xlims <- c(sw_ext_3857[1], sw_ext_3857[2])
ylims <- c(sw_ext_3857[3], sw_ext_3857[4])

# 5. Ensure output directory
ensure_output_dir("output")
output_path <- file.path("output", "03_oregon_southwest_1900_map.png")

# 6. Plotting
log_msg(paste("Plotting Southwest Oregon 1900 composite to:", output_path))
png(output_path, width = 2400, height = 1800, res = 200)

terra::plot(or_counties_3857, col = "gray95", border = "gray70", lwd = 1,
     xlim = xlims, ylim = ylims,
     main = "Southwest Oregon Year 1900 Forest Fires & Historical Forest Maps\n(Produced by plot_southwest_1900.R)",
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

# Plot 1900 fires if any
if (nrow(fires_1900_3857) > 0) {
  terra::plot(fires_1900_3857, col = rgb(1, 0, 0, 0.4), border = "darkred", lwd = 1, add = TRUE)
} else {
  log_msg("No fires found for 1900 in the dataset.")
}

# Legend
legend("bottomleft", legend = c("County Boundaries", "1900 Forest Fires"),
       col = c("black", "darkred"), lty = 1, lwd = c(1.2, 1),
       fill = c(NA, rgb(1, 0, 0, 0.4)), border = c("black", "darkred"),
       bg = "white", cex = 0.8)

dev.off()
log_msg("Southwest 1900 map completed successfully!")