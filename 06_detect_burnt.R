library(terra)

# Load the template
# The user mentioned burnt.jpg, but the file is named burned.jpg
burned_path <- "data/burned.jpg"
if (!file.exists(burned_path)) {
  # Try burnt.jpg just in case
  burned_path <- "data/burnt.jpg"
}

if (!file.exists(burned_path)) {
  stop("Template file not found.")
}

template <- rast(burned_path)
template_values <- values(template)

# Use k-means to find representative colors in the template
set.seed(42)
km <- kmeans(template_values, centers = 10)
centers <- km$centers

detect_burnt <- function(map_path, output_path) {
  print(paste("Processing", map_path))
  map <- rast(map_path)
  
  # Process at full resolution
  map_small <- map
  
  # Calculate R-G (Red minus Green)
  # Based on template analysis:
  # Red stripes have higher R-G (around 10-20)
  # Green stripes have lower R-G (around -1 to 2)
  rg <- map_small[[1]] - map_small[[2]]
  
  is_greenish <- rg < 2
  is_reddish <- rg > 10
  
  # Also check if it matches the general template colors (distance to any center)
  min_dist <- NULL
  for (i in 1:nrow(centers)) {
    d <- sqrt((map_small[[1]] - centers[i,1])^2 + 
              (map_small[[2]] - centers[i,2])^2 + 
              (map_small[[3]] - centers[i,3])^2)
    if (is.null(min_dist)) {
      min_dist <- d
    } else {
      min_dist <- min(min_dist, d)
    }
  }
  is_template_color <- min_dist < 30
  
  # We want areas where BOTH greenish and reddish pixels are present in close proximity
  w <- matrix(1, nrow=7, ncol=7)
  green_density <- focal(is_greenish & is_template_color, w, fun="sum")
  red_density <- focal(is_reddish & is_template_color, w, fun="sum")
  
  # Burnt area has both colors nearby
  # Thresholds can be adjusted
  burnt_areas <- (green_density >= 3) & (red_density >= 3)
  
  # Clean up: remove small isolated patches
  burnt_areas <- focal(burnt_areas, matrix(1,3,3), fun="sum") >= 5
  
  # Export results
  writeRaster(burnt_areas, output_path, overwrite=TRUE)
  
  # Convert to polygons for vector output
  burnt_polys <- as.polygons(burnt_areas)
  if (nrow(burnt_polys) > 0) {
    burnt_polys <- burnt_polys[burnt_polys[[1]] == 1, ]
    if (nrow(burnt_polys) > 0) {
      vector_output <- gsub(".tif", ".geojson", output_path)
      writeVector(burnt_polys, vector_output, overwrite=TRUE)
      print(paste("Saved polygons to", vector_output))
    }
  }

  print(paste("Saved raster to", output_path))
}

# Main execution
output_dir <- "output"
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

target_map <- "data/forest_maps/Plate_CXXVI.jpg"
output_file <- file.path(output_dir, "06_burnt_Plate_CXXVI.tif")

detect_burnt(target_map, output_file)

# Plotting the result
library(terra)
v <- vect(gsub(".tif", ".geojson", output_file))
map <- rast(target_map)
jpg_output <- file.path(output_dir, "06_burnt_plot_CXXVI.jpg")
 
 jpg(jpg_output, width=1200, height=1000)
 plotRGB(map, r=1, g=2, b=3, stretch="lin", main="Burnt Areas Detection - Plate CXXVI\n(Produced by detect_burnt.R)")
 if (nrow(v) > 0) {
   plot(v, add=TRUE, col=rgb(0, 1, 1, 0.4), border="cyan", lwd=1)
 }
 dev.off()
 print(paste("Plot saved to", jpg_output))
