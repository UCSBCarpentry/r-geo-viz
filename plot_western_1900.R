library(terra)

# 1. Load the 2 westernmost rasters and prepare cropped version in native coordinates
print("Loading and cropping the 2 westernmost rasters...")
r1_path <- "/home/coder/forest_types_r/data/forest_maps/Plate_CXXVI.jpg"
r2_path <- "/home/coder/forest_types_r/data/forest_maps/Plate_CXXVII.jpg"

r1 <- rast(r1_path)
r2 <- rast(r2_path)

# Extract native CRS from the rasters (Polyconic, centered at lon_0=-124.15)
native_crs <- crs(r1)

# Crop the northern map (Plate_CXXVII.jpg) in half to remove the northern half in native coordinates
ext_r2 <- ext(r2)
mid_y <- (ext_r2[3] + ext_r2[4]) / 2
south_half_ext <- ext(ext_r2[1], ext_r2[2], ext_r2[3], mid_y)
r2_cropped <- crop(r2, south_half_ext)

# 2. Load Counties, filter for Oregon, and project to the native Polyconic CRS of the rasters
print("Loading and projecting counties to native CRS...")
counties <- vect("/home/coder/forest_types_r/data/tl_2023_us_county.shp")
or_counties_native <- project(counties[counties$STATEFP == "41", ], native_crs)

# 3. Load Historic Fires, filter for 1900, and project to the native Polyconic CRS of the rasters
print("Loading, filtering, and projecting historic fires (year 1900) to native CRS...")
fires_3857 <- vect("/home/coder/forest_types_r/data/Historic_OR_Fires/Historic_Fires_(pre_2000).shp")
fires_1900_3857 <- fires_3857[fires_3857$FIRE_YEAR == "1900" & !is.na(fires_3857$FIRE_YEAR), ]
fires_1900_native <- project(fires_1900_3857, native_crs)


# ----------------------------------------------------
# A. Standard Resolution Map (downsampled by 5, native CRS)
# ----------------------------------------------------
print("Preparing Standard Resolution Rasters (downsampled by 5)...")
# We downsample native rasters directly without any reprojection/resampling
r1_sub_std <- aggregate(r1, fact = 5)
r2_sub_std <- aggregate(r2_cropped, fact = 5)

# Calculate combined extent of the two rasters in native coordinates
ext1_std <- ext(r1_sub_std)
ext2_std <- ext(r2_sub_std)
combined_ext_std <- ext(
  min(ext1_std[1], ext2_std[1]),
  max(ext1_std[2], ext2_std[2]),
  min(ext1_std[3], ext2_std[3]),
  max(ext1_std[4], ext2_std[4])
)

# Pad the extent slightly (e.g. by 10 km) for better layout margins
pad <- 10000
xlims_std <- c(combined_ext_std[1] - pad, combined_ext_std[2] + pad)
ylims_std <- c(combined_ext_std[3] - pad, combined_ext_std[4] + pad)

output_path_std <- "/home/coder/forest_types_r/output/oregon_western_1900_map.png"
print(paste("Plotting Standard Resolution to:", output_path_std))

png(output_path_std, width = 2000, height = 1800, res = 200)

# Establish coordinate system with county backgrounds in native Polyconic coordinates
plot(or_counties_native, col = "gray95", border = "gray70", lwd = 1,
     xlim = xlims_std, ylim = ylims_std,
     main = "Western Oregon Year 1900 Forest Fires (Plates CXXVI & CXXVII-South)",
     mar = c(3, 3, 4, 3))

# Overlay the two rasters: northern map first, then southern map on top (no reprojection!)
plotRGB(r2_sub_std, r = 1, g = 2, b = 3, add = TRUE)
plotRGB(r1_sub_std, r = 1, g = 2, b = 3, add = TRUE)

# Redraw county boundaries on top
plot(or_counties_native, col = NA, border = "black", lwd = 1.2, add = TRUE)

# Overlay 1900 fires
if (nrow(fires_1900_native) > 0) {
  plot(fires_1900_native, col = rgb(1, 0, 0, 0.4), border = "darkred", lwd = 1, add = TRUE)
}

# Add legend
legend("bottomleft", legend = c("County Boundaries", "1900 Forest Fires"),
       col = c("black", "darkred"), lty = 1, lwd = c(1.2, 1),
       fill = c(NA, rgb(1, 0, 0, 0.4)), border = c("black", "darkred"),
       bg = "white", cex = 0.8)

dev.off()


# ----------------------------------------------------
# B. High Resolution Map (original untouched native rasters!)
# ----------------------------------------------------
print("Preparing High Resolution Rasters (Original Untouched Scanned Map)...")
# We use the original r1 and r2_cropped directly without reprojection or resampling!
r1_hr <- r1
r2_hr <- r2_cropped

# Calculate combined extent of the two rasters in native coordinates
ext1_hr <- ext(r1_hr)
ext2_hr <- ext(r2_hr)
combined_ext_hr <- ext(
  min(ext1_hr[1], ext2_hr[1]),
  max(ext1_hr[2], ext2_hr[2]),
  min(ext1_hr[3], ext2_hr[3]),
  max(ext1_hr[4], ext2_hr[4])
)

xlims_hr <- c(combined_ext_hr[1] - pad, combined_ext_hr[2] + pad)
ylims_hr <- c(combined_ext_hr[3] - pad, combined_ext_hr[4] + pad)

output_path_hr <- "/home/coder/forest_types_r/output/oregon_western_1900_map_highres.png"
print(paste("Plotting High Resolution (Original Untouched Scanned Map) to:", output_path_hr))

png(output_path_hr, width = 8000, height = 7200, res = 200)

# Scale line widths and text size (4x scaled up) for the giant map canvas
plot(or_counties_native, col = "gray95", border = "gray70", lwd = 4,
     xlim = xlims_hr, ylim = ylims_hr,
     main = "Western Oregon Year 1900 Forest Fires (Plates CXXVI & CXXVII-South) - High Res",
     mar = c(3, 3, 4, 3), cex.main = 4)

# Overlay the two untouched rasters (completely pristine original pixels!)
plotRGB(r2_hr, r = 1, g = 2, b = 3, add = TRUE)
plotRGB(r1_hr, r = 1, g = 2, b = 3, add = TRUE)

# Redraw county boundaries on top with scaled line width (4.8)
plot(or_counties_native, col = NA, border = "black", lwd = 4.8, add = TRUE)

# Overlay 1900 fires with scaled line width (4)
if (nrow(fires_1900_native) > 0) {
  plot(fires_1900_native, col = rgb(1, 0, 0, 0.4), border = "darkred", lwd = 4, add = TRUE)
}

# Add legend with scaled text size (cex = 3.2)
legend("bottomleft", legend = c("County Boundaries", "1900 Forest Fires"),
       col = c("black", "darkred"), lty = 1, lwd = c(4.8, 4),
       fill = c(NA, rgb(1, 0, 0, 0.4)), border = c("black", "darkred"),
       bg = "white", cex = 3.2)

dev.off()

print("Both maps completed successfully!")
