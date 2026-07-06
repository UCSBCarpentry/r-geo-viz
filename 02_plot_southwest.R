library(terra)

# 1. Load Counties and filter for Oregon (STATEFP == "41")
print("Loading and projecting counties...")
counties <- vect("data/tl_2023_us_county.shp")
or_counties <- counties[counties$STATEFP == "41", ]

# Calculate Southwest Oregon quarter bounding box in lon/lat (EPSG:4269)
ext_lonlat <- ext(or_counties)
mid_x <- (ext_lonlat[1] + ext_lonlat[2]) / 2
mid_y <- (ext_lonlat[3] + ext_lonlat[4]) / 2
sw_box_lonlat <- ext(ext_lonlat[1], mid_x, ext_lonlat[3], mid_y)

# Convert Southwest bounding box to a SpatVector and project to EPSG:3857
sw_poly_lonlat <- as.polygons(sw_box_lonlat, crs = "EPSG:4269")
sw_poly_3857 <- project(sw_poly_lonlat, "EPSG:3857")
sw_ext_3857 <- ext(sw_poly_3857)

# Project Oregon counties to EPSG:3857
or_counties_3857 <- project(or_counties, "EPSG:3857")

# 2. Load Historic Fires (already EPSG:3857)
print("Loading historic fires...")
fires_3857 <- vect("data/Historic_OR_Fires/Historic_Fires_(pre_2000).shp")

# 3. Load, downsample, and project rasters
print("Loading, downsampling, and projecting rasters...")
raster_files <- list.files("data/forest_maps", pattern = "\\.jpg$", full.names = TRUE)

projected_rasters <- list()
for (rf in raster_files) {
  print(paste("Processing raster:", basename(rf)))
  r <- rast(rf)
  
  # Downsample by a factor of 5 for more zoomed-in detail in the southwest quarter
  r_sub <- aggregate(r, fact = 5)
  
  # Project to EPSG:3857
  r_proj <- project(r_sub, "EPSG:3857")
  
  projected_rasters[[basename(rf)]] <- r_proj
}

# 4. Define plot extent based on Southwest Oregon (no padding)
xlims <- c(sw_ext_3857[1], sw_ext_3857[2])
ylims <- c(sw_ext_3857[3], sw_ext_3857[4])

# 5. Create output directory if it doesn't exist
output_dir <- "output"
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)
output_path <- file.path(output_dir, "02_oregon_southwest_composite_map.png")

# 6. Plotting to high-resolution large image
print(paste("Plotting Southwest Oregon composite to:", output_path))
png(output_path, width = 2400, height = 1800, res = 200)

# Start with empty plot of Oregon counties filtered to the southwest viewport to establish coordinates
plot(or_counties_3857, col = "gray95", border = "gray70", lwd = 1,
     xlim = xlims, ylim = ylims,
      main = "Southwest Oregon Historical Forest Maps, Counties, and Historic Fires\n(Produced by plot_southwest.R)",
     mar = c(3, 3, 4, 3))

# Plot each raster using plotRGB with add=TRUE
for (name in names(projected_rasters)) {
  print(paste("Overlaying raster:", name))
  tryCatch({
    plotRGB(projected_rasters[[name]], r = 1, g = 2, b = 3, add = TRUE)
  }, error = function(e) {
    print(paste("Error plotting", name, ":", e$message))
  })
}

# Plot Oregon counties outlines on top of the rasters
plot(or_counties_3857, col = NA, border = "black", lwd = 1.2, add = TRUE)

# Plot historic fires on top of everything
plot(fires_3857, col = rgb(1, 0, 0, 0.3), border = "darkred", lwd = 0.5, add = TRUE)

# Add a simple map legend
legend("bottomleft", legend = c("County Boundaries", "Historic Fires (pre-2000)"),
       col = c("black", "darkred"), lty = 1, lwd = c(1.2, 1),
       fill = c(NA, rgb(1, 0, 0, 0.3)), border = c("black", "darkred"),
       bg = "white", cex = 0.8)

dev.off()
print("Southwest map completed successfully!")
