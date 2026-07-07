# Script to crop legends from forest map images
library(terra)
library(magick)

# Path to forest maps
map_dir <- "data/forest_maps"
output_dir <- "output"

# List all jpg files in the directory
jpg_files <- list.files(map_dir, pattern = "\\.jpg$", full.names = TRUE)

# Note: Since the exact coordinates of the legends are not known, 
# this script provides a template to crop a specific area.
# You may need to adjust the geometry (width, height, x, y) based on the images.

for (img_path in jpg_files) {
  img_name <- basename(img_path)
  
  # Read the image using magick for cropping
  img <- image_read(img_path)
  
  # Example crop: Right side of the image where legends usually are
  # Adjust these values based on the actual layout of your maps
  info <- image_info(img)
  width <- info$width
  height <- info$height
  
  # Cropping the rightmost 20% of the image as a guess for the legend area
  crop_width <- width * 0.2
  
  legend_crop <- image_crop(img, geometry = paste0(crop_width, "x", height, "+", 
                                                  round(width - crop_width), "+0"))
  
  # Save as PNG
  output_path <- file.path(output_dir, paste0("legend_", gsub("\\.jpg$", ".png", img_name)))
  image_write(legend_crop, path = output_path)
  
  message(paste("Saved legend for", img_name, "to", output_path))
}
