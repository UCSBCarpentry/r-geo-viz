# Load utilities
source("utils.R")

# 1. Load Rasters first to get the native CRS
log_msg("Loading rasters...")
rasters <- load_rasters()
if (length(rasters) == 0) stop("No rasters found.")
native_crs <- terra::crs(rasters[[1]])

# 2. Load Counties and project to native CRS
log_msg("Loading and projecting counties to native CRS...")
or_counties_native <- load_oregon_counties(crs_target = native_crs)

# Calculate Southwest Oregon quarter bounding box in native CRS
ext_native <- terra::ext(or_counties_native)
mid_x <- (ext_native[1] + ext_native[2]) / 2
mid_y <- (ext_native[3] + ext_native[4]) / 2
sw_ext_native <- terra::ext(ext_native[1], mid_x, ext_native[3], mid_y)

# 3. Load Historic Fires, filter for 1900, and project to native CRS
log_msg("Loading and projecting historic fires (year 1900) to native CRS...")
fires_1900_native <- load_historic_fires(crs_target = native_crs, year = 1900)
log_msg(paste("Number of 1900 fires:", nrow(fires_1900_native)))

# 4. Define plot extent based on Southwest Oregon (no padding)
xlims <- c(sw_ext_native[1], sw_ext_native[2])
ylims <- c(sw_ext_native[3], sw_ext_native[4])

# 5. Ensure output directory
ensure_output_dir("output")
output_path <- file.path("output", "03_oregon_southwest_1900_map.jpg")

# 6. Plotting
log_msg(paste("Plotting Southwest Oregon 1900 composite to:", output_path))
jpeg(output_path, width = 2400, height = 1800, res = 200)

terra::plot(or_counties_native, col = "gray95", border = "gray70", lwd = 1,
     xlim = xlims, ylim = ylims,
     main = "Southwest Oregon Year 1900 Forest Fires & Historical Forest Maps\n(Produced by plot_southwest_1900.R)",
     mar = c(3, 3, 4, 3))

# Overlay rasters
for (name in names(rasters)) {
  log_msg(paste("Overlaying raster:", name))
  tryCatch({
    plotRGB(rasters[[name]], r = 1, g = 2, b = 3, add = TRUE)
  }, error = function(e) {
    log_msg(paste("Error plotting", name, ":", e$message))
  })
}

# County outlines
terra::plot(or_counties_native, col = NA, border = "black", lwd = 1.2, add = TRUE)

# Plot 1900 fires if any
if (nrow(fires_1900_native) > 0) {
  terra::plot(fires_1900_native, col = rgb(1, 0, 0, 0.4), border = "darkred", lwd = 1, add = TRUE)
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