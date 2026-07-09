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

# 3. Load Historic Fires and project to native CRS
log_msg("Loading and projecting historic fires to native CRS...")
fires_native <- load_historic_fires(crs_target = native_crs)

# 4. Define plot extent based on Southwest Oregon (no padding)
xlims <- c(sw_ext_native[1], sw_ext_native[2])
ylims <- c(sw_ext_native[3], sw_ext_native[4])

# 5. Ensure output directory
ensure_output_dir("output")
output_path <- file.path("output", "02_oregon_southwest_composite_map_v2.1.jpg")

# 6. Plotting
log_msg(paste("Plotting Southwest Oregon composite to:", output_path))
jpeg(output_path, width = 2400, height = 1800, res = 200)

terra::plot(or_counties_native, col = "gray95", border = "gray70", lwd = 1,
     xlim = xlims, ylim = ylims,
     main = "Southwest Oregon Historical Forest Maps, Counties, and Historic Fires\n[AI-Generated Analysis & Visualization - Version 2.1]",
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

# Historic fires
terra::plot(fires_native, col = rgb(1, 0, 0, 0.3), border = "darkred", lwd = 0.5, add = TRUE)

# Legend
legend("bottomleft", legend = c("County Boundaries", "Historic Fires (pre-2000)", "Note: AI-generated Map (v2.1)"),
       col = c("black", "darkred", "blue"), lty = c(1, 1, 3), lwd = c(1.2, 1, 1),
       fill = c(NA, rgb(1, 0, 0, 0.3), NA), border = c("black", "darkred", NA),
       bg = "white", cex = 0.8)

dev.off()
log_msg("Southwest map completed successfully!")