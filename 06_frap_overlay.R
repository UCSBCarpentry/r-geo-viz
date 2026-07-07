# Script 06: Overlay California FRAP Fire Perimeters on Scanned Maps
# -------------------------------------------------------------
# Reads the three new scanned California maps:
# 1. Placerville Quadrangle (Plate LXXXV)
# 2. Big Trees Quadrangle (Plate LXXXVIII)
# 3. Port Orford California (Plate CXXVI)
#
# Then overlays the relevant geographic portion of the FRAP dataset
# (California wildfire history back to the 1800s) on top.
# Saves three separate 50% sized PNG representation maps in the output/ directory.

source("utils.R")

# Ensure output directory exists
ensure_output_dir("output")

log_msg("Starting Script 06: Overlaying FRAP wildfires on California maps...")

# Paths to the raw .tif maps
map_paths <- list(
  Placerville = "data/forest_maps/Plate LXXXV. Placerville Quadrangle, Land Classifi1421207396314396259/Plate_LXXXV.tif",
  BigTrees = "data/forest_maps/Plate LXXXVIII. Big Trees Quadrangle, California. 4509540713732862480/Plate_LXXXVIII.tif",
  PortOrford = "data/forest_maps/Plate_CXXVI._Port_Orford_California,_Oregon,_Land_3920186228952328253/Plate_CXXVI.tif"
)

# Verify all file paths exist
for (name in names(map_paths)) {
  if (!file.exists(map_paths[[name]])) {
    stop(paste("Required scanned map does not exist:", map_paths[[name]]))
  }
}

# 1. Load the FRAP dataset
frap_path <- "data/California_Historic_Fire_Perimeters_FRAP/California_Fire_Perimeters_(all).shp"
if (!file.exists(frap_path)) {
  stop(paste("FRAP dataset shapefile not found at:", frap_path))
}
log_msg("Loading FRAP wildfire perimeters...")
frap_all <- terra::vect(frap_path)

# Let's write a function to generate a 50% sized PNG representation for each map
process_map_frap <- function(map_name, map_path) {
  log_msg(paste("Processing map:", map_name))
  
  # Load the full high-res raster
  r <- terra::rast(map_path)
  
  # Determine dimensions
  dims <- dim(r)
  original_h <- dims[1]
  original_w <- dims[2]
  
  # Calculate 50% dimensions
  target_w <- round(original_w * 0.5)
  target_h <- round(original_h * 0.5)
  log_msg(sprintf("Original dimensions: %dx%d. Target 50%% dimensions: %dx%d", original_w, original_h, target_w, target_h))
  
  # Aggregate (downsample) by factor of 2 to achieve 50% dimensions
  log_msg("Downsampling map to 50% using aggregation...")
  r_50 <- terra::aggregate(r, fact = 2)
  
  # Project the FRAP vector dataset to match the native CRS of the scanned map
  native_crs <- terra::crs(r_50)
  log_msg("Projecting FRAP perimeters to raster native CRS...")
  frap_projected <- terra::project(frap_all, native_crs)
  
  # Crop the projected FRAP perimeters to the extent of the scanned map to get the "relevant portion"
  log_msg("Cropping FRAP perimeters to map extent...")
  map_extent <- terra::ext(r_50)
  frap_cropped <- terra::crop(frap_projected, map_extent)
  
  # Define PNG output path
  output_png <- file.path("output", paste0("06_frap_overlay_", map_name, ".png"))
  log_msg(paste("Plotting and saving map to:", output_png))
  
  # We set the png resolution/dimensions based on the 50% size.
  # Let's specify exact dimensions to preserve 50% sizing precisely.
  png(output_png, width = target_w, height = target_h)
  
  # Set margins to 0 to maximize map coverage and keep clean edges
  par(mar = c(0, 0, 0, 0))
  
  # Plot the RGB scanned map base
  terra::plotRGB(r_50, r = 1, g = 2, b = 3, mar = c(0, 0, 0, 0))
  
  # Plot cropped FRAP perimeters on top
  if (nrow(frap_cropped) > 0) {
    log_msg(sprintf("Found %d historic FRAP wildfires overlapping this map.", nrow(frap_cropped)))
    # Use semi-transparent red for fire perimeters with dark red borders
    terra::plot(frap_cropped, col = rgb(1, 0, 0, 0.4), border = "darkred", lwd = 1.5, add = TRUE)
  } else {
    log_msg("No overlapping FRAP wildfires found in this map's extent.")
  }
  
  # Draw a simple decorative/informative title box in the top-left corner
  # Use some basic coordinates relative to the extent
  x_min <- map_extent[1]
  x_max <- map_extent[2]
  y_min <- map_extent[3]
  y_max <- map_extent[4]
  
  box_w <- (x_max - x_min) * 0.45
  box_h <- (y_max - y_min) * 0.08
  
  # Background for title
  rect(x_min + (x_max - x_min)*0.02, y_max - (y_max - y_min)*0.02 - box_h,
       x_min + (x_max - x_min)*0.02 + box_w, y_max - (y_max - y_min)*0.02,
       col = rgb(1, 1, 1, 0.9), border = "black", lwd = 1.5)
  
  text(x_min + (x_max - x_min)*0.03, y_max - (y_max - y_min)*0.05,
       labels = paste(map_name, "Quadrangle with FRAP Wildfires"),
       adj = c(0, 0.5), font = 2, cex = 1.5)
  
  text(x_min + (x_max - x_min)*0.03, y_max - (y_max - y_min)*0.08,
       labels = "Red overlays indicate historic California fire perimeters",
       adj = c(0, 0.5), font = 3, cex = 1.1, col = "darkred")
  
  dev.off()
  log_msg(paste("Successfully saved", output_png))
}

# Run the function for all three maps
process_map_frap("Placerville", map_paths$Placerville)
process_map_frap("BigTrees", map_paths$BigTrees)
process_map_frap("PortOrford", map_paths$PortOrford)

log_msg("Script 06 complete!")
