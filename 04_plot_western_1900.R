# Load utilities
source("utils.R")

# 1. Load the 2 westernmost rasters and prepare cropped version in native coordinates
log_msg("Loading and cropping the 2 westernmost rasters...")
r1_path <- "data/forest_maps/Plate_CXXVI.jpg"
r2_path <- "data/forest_maps/Plate_CXXVII.jpg"

r1 <- terra::rast(r1_path)
r2 <- terra::rast(r2_path)

# Crop the northern map (Plate_CXXVII.jpg) in half first to remove the northern half
ext_r2 <- terra::ext(r2)
mid_y <- (ext_r2[3] + ext_r2[4]) / 2
south_half_ext <- terra::ext(ext_r2[1], ext_r2[2], ext_r2[3], mid_y)
r2_cropped <- terra::crop(r2, south_half_ext)

# Now crop both by 200 pixels AND an additional 10% of the extent on each edge to remove collars
ext1 <- terra::ext(r1)
w1 <- ext1[2] - ext1[1]
h1 <- ext1[4] - ext1[3]
r1_cropped <- terra::crop(r1, terra::ext(ext1[1] + 200 + 0.1*w1, ext1[2] - 200 - 0.1*w1,
                                          ext1[3] + 200 + 0.1*h1, ext1[4] - 200 - 0.1*h1))

ext2c <- terra::ext(r2_cropped)
w2 <- ext2c[2] - ext2c[1]
h2 <- ext2c[4] - ext2c[3]
r2_cropped_final <- terra::crop(r2_cropped, terra::ext(ext2c[1] + 200 + 0.1*w2, ext2c[2] - 200 - 0.1*w2,
                                                     ext2c[3] + 200 + 0.1*h2, ext2c[4] - 200 - 0.1*h2))

# Recalculate native CRS from cropped r1
native_crs <- terra::crs(r1_cropped)

# 2. Load Counties, filter for Oregon, and project to the native Polyconic CRS of the rasters
log_msg("Loading and projecting counties to native CRS...")
or_counties_native <- load_oregon_counties(crs_target = native_crs)

# 3. Load Historic Fires, filter for 1900, and project to the native Polyconic CRS of the rasters
log_msg("Loading, filtering, and projecting historic fires (year 1900) to native CRS...")
fires_1900_native <- load_historic_fires(crs_target = native_crs, year = 1900)

# ----------------------------------------------------
# A. Standard Resolution Map (downsampled by 5, native CRS)
# ----------------------------------------------------
log_msg("Preparing Standard Resolution Rasters (downsampled by 5)...")
# Downsample cropped native rasters directly without any reprojection/resampling
r1_sub_std <- terra::aggregate(r1_cropped, fact = 5)
r2_sub_std <- terra::aggregate(r2_cropped_final, fact = 5)

# Calculate combined extent of the two rasters in native coordinates
ext1_std <- terra::ext(r1_sub_std)
ext2_std <- terra::ext(r2_sub_std)
combined_ext_std <- terra::ext(
  min(ext1_std[1], ext2_std[1]),
  max(ext1_std[2], ext2_std[2]),
  min(ext1_std[3], ext2_std[3]),
  max(ext1_std[4], ext2_std[4])
)

xlims_std <- c(combined_ext_std[1], combined_ext_std[2])
ylims_std <- c(combined_ext_std[3], combined_ext_std[4])

ensure_output_dir("output")
output_path_std <- "output/04_oregon_western_1900_map.png"
log_msg(paste("Plotting Standard Resolution to:", output_path_std))

png(output_path_std, width = 2000, height = 1800, res = 200)

# Base plot with county background in native Polyconic coordinates
terra::plot(or_counties_native, col = "gray95", border = "gray70", lwd = 1,
     xlim = xlims_std, ylim = ylims_std,
     main = "Western Oregon Year 1900 Forest Fires (Plates CXXVI & CXXVII-South)\n(Produced by plot_western_1900.R)",
     mar = c(3, 3, 4, 3))

# Overlay the two rasters: northern map first, then southern map on top (no reprojection!)
plotRGB(r2_sub_std, r = 1, g = 2, b = 3, add = TRUE)
plotRGB(r1_sub_std, r = 1, g = 2, b = 3, add = TRUE)

# Redraw county boundaries on top
terra::plot(or_counties_native, col = NA, border = "black", lwd = 1.2, add = TRUE)

# Overlay 1900 fires if any
if (nrow(fires_1900_native) > 0) {
  terra::plot(fires_1900_native, col = rgb(1, 0, 0, 0.4), border = "darkred", lwd = 1, add = TRUE)
}

# Legend
legend("bottomleft", legend = c("County Boundaries", "1900 Forest Fires"),
       col = c("black", "darkred"), lty = 1, lwd = c(1.2, 1),
       fill = c(NA, rgb(1, 0, 0, 0.4)), border = c("black", "darkred"),
       bg = "white", cex = 0.8)

dev.off()

# ----------------------------------------------------
# B. High Resolution Map (original untouched native rasters!)
# ----------------------------------------------------
log_msg("Preparing High Resolution Rasters (Original Untouched Scanned Map)...")
# Use the cropped native rasters directly without reprojection or resampling!
r1_hr <- r1_cropped
r2_hr <- r2_cropped

# Calculate combined extent of the two rasters in native coordinates
ext1_hr <- terra::ext(r1_hr)
ext2_hr <- terra::ext(r2_hr)
combined_ext_hr <- terra::ext(
  min(ext1_hr[1], ext2_hr[1]),
  max(ext1_hr[2], ext2_hr[2]),
  min(ext1_hr[3], ext2_hr[3]),
  max(ext1_hr[4], ext2_hr[4])
)

xlims_hr <- c(combined_ext_hr[1], combined_ext_hr[2])
ylims_hr <- c(combined_ext_hr[3], combined_ext_hr[4])

output_path_hr <- "output/04_oregon_western_1900_map_highres.png"
log_msg(paste("Plotting High Resolution (Original Untouched Scanned Map) to:", output_path_hr))

png(output_path_hr, width = 8000, height = 7200, res = 200)

# Scale line widths and text size (4x scaled up) for the giant map canvas
terra::plot(or_counties_native, col = "gray95", border = "gray70", lwd = 4,
     xlim = xlims_hr, ylim = ylims_hr,
     main = "Western Oregon Year 1900 Forest Fires (Plates CXXVI & CXXVII-South) - High Res\n(Produced by plot_western_1900.R)",
     mar = c(3, 3, 4, 3), cex.main = 4)

# Overlay the two untouched rasters 
plotRGB(r2_hr, r = 1, g = 2, b = 3, add = TRUE)
plotRGB(r1_hr, r = 1, g = 2, b = 3, add = TRUE)

# Redraw county boundaries on top with scaled line width (4.8)
terra::plot(or_counties_native, col = NA, border = "black", lwd = 4.8, add = TRUE)

# Overlay 1900 fires with scaled line width (4)
if (nrow(fires_1900_native) > 0) {
  terra::plot(fires_1900_native, col = rgb(1, 0, 0, 0.4), border = "darkred", lwd = 4, add = TRUE)
}

# Add legend with scaled text size (cex = 3.2)
legend("bottomleft", legend = c("County Boundaries", "1900 Forest Fires"),
       col = c("black", "darkred"), lty = 1, lwd = c(4.8, 4),
       fill = c(NA, rgb(1, 0, 0, 0.4)), border = c("black", "darkred"),
       bg = "white", cex = 3.2)

dev.off()

log_msg("Both maps completed successfully!")


