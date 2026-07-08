# Load utilities
source("utils.R")

# 1. Load Rasters first
log_msg("Loading rasters...")
rasters <- load_rasters()
if (length(rasters) == 0) stop("No rasters found.")

# Define version and generation details
generation_version <- "1.1"
generation_prompt <- "expand context to the southwest to accommodate the text box panel"

# 2. Load all possible vector layers (Counties, Oregon Fires, California Fires)
log_msg("Loading global vector layers...")
all_counties <- terra::vect("data/tl_2023_us_county.shp")
or_fires <- terra::vect("data/Historic_OR_Fires/Historic_Fires_(pre_2000).shp")
ca_fires <- terra::vect("data/California_Historic_Fire_Perimeters_FRAP/California_Fire_Perimeters_(all).shp")

# Ensure output directory exists
ensure_output_dir("output")

# 3. Iterate through each raster and generate a separate padded map
for (name in names(rasters)) {
  log_msg(paste("========================================"))
  log_msg(paste("Processing raster map:", name))
  
  r <- rasters[[name]]
  r_crs <- terra::crs(r)
  
  if (is.na(r_crs) || r_crs == "") {
    log_msg(paste("Skipping", name, "due to missing CRS/world file projection."))
    next
  }
  
  # Reproject all vectors to the current raster's CRS
  log_msg("Projecting vectors to raster CRS...")
  counties_proj <- terra::project(all_counties, r_crs)
  or_fires_proj <- terra::project(or_fires, r_crs)
  ca_fires_proj <- terra::project(ca_fires, r_crs)
  
  # Calculate extent of current raster and apply asymmetrical padding
  # We expand the context significantly to the Southwest (West/South) to prevent text overlap.
  r_ext <- terra::ext(r)
  width <- r_ext[2] - r_ext[1]
  height <- r_ext[4] - r_ext[3]
  
  # Padding values:
  # Southwest expansion: 50% extra to the West, 45% extra to the South
  # Northeast expansion: 15% extra to the East, 15% extra to the North
  xlims <- c(r_ext[1] - (width * 0.50), r_ext[2] + (width * 0.15))
  ylims <- c(r_ext[3] - (height * 0.45), r_ext[4] + (height * 0.15))
  
  # Crop counties and fires to the padded coordinate limits to speed up plotting
  crop_ext <- terra::ext(xlims[1], xlims[2], ylims[1], ylims[2])
  
  counties_cropped <- NULL
  tryCatch({ counties_cropped <- terra::crop(counties_proj, crop_ext) }, error = function(e) {})
  
  or_fires_cropped <- NULL
  tryCatch({ or_fires_cropped <- terra::crop(or_fires_proj, crop_ext) }, error = function(e) {})
  
  ca_fires_cropped <- NULL
  tryCatch({ ca_fires_cropped <- terra::crop(ca_fires_proj, crop_ext) }, error = function(e) {})
  
  # Prepare output path with the vX.X naming convention
  clean_name <- gsub("[^A-Za-z0-9_.-]", "_", name)
  clean_name <- gsub("\\.jpg$|\\.tif$", "", clean_name, ignore.case = TRUE)
  output_path <- file.path("output", paste0("01_map_", clean_name, "_v", generation_version, ".jpg"))
  
  log_msg(paste("Plotting individual map to:", output_path))
  jpeg(output_path, width = 2000, height = 1600, res = 180)
  
  # Set up plot with correct extent and background/title
  title_text <- paste("Georeferenced Historical Map & Vector Context\nMap File:", name)
  
  # Plot counties cropped as the base layer
  if (!is.null(counties_cropped) && nrow(counties_cropped) > 0) {
    terra::plot(counties_cropped, col = "gray95", border = "gray75", lwd = 1,
                xlim = xlims, ylim = ylims, main = title_text, mar = c(3, 3, 4, 3))
  } else {
    # Fallback to empty plot with raster extent if no counties cropped successfully
    terra::plot(r_ext, col = "white", border = NA, xlim = xlims, ylim = ylims,
                main = title_text, mar = c(3, 3, 4, 3))
  }
  
  # Overlay the georeferenced scanned map raster
  tryCatch({
    plotRGB(r, r = 1, g = 2, b = 3, add = TRUE)
  }, error = function(e) {
    log_msg(paste("Error plotting raster", name, ":", e$message))
  })
  
  # Draw county boundaries back on top of the raster
  if (!is.null(counties_cropped) && nrow(counties_cropped) > 0) {
    terra::plot(counties_cropped, col = NA, border = "black", lwd = 1.2, add = TRUE)
  }
  
  # Overlay Oregon fires
  legend_items <- c("County Boundaries")
  legend_cols <- c("black")
  legend_fills <- c(NA)
  legend_borders <- c("black")
  
  if (!is.null(or_fires_cropped) && nrow(or_fires_cropped) > 0) {
    terra::plot(or_fires_cropped, col = rgb(1, 0, 0, 0.3), border = "darkred", lwd = 0.5, add = TRUE)
    legend_items <- c(legend_items, "Historic OR Fires (pre-2000)")
    legend_cols <- c(legend_cols, "darkred")
    legend_fills <- c(legend_fills, rgb(1, 0, 0, 0.3))
    legend_borders <- c(legend_borders, "darkred")
  }
  
  # Overlay California fires
  if (!is.null(ca_fires_cropped) && nrow(ca_fires_cropped) > 0) {
    terra::plot(ca_fires_cropped, col = rgb(1, 0.5, 0, 0.3), border = "darkorange", lwd = 0.5, add = TRUE)
    legend_items <- c(legend_items, "Historic CA FRAP Fires")
    legend_cols <- c(legend_cols, "darkorange")
    legend_fills <- c(legend_fills, rgb(1, 0.5, 0, 0.3))
    legend_borders <- c(legend_borders, "darkorange")
  }
  
  # Draw a subtle bounding box showing the exact boundary of the georeferenced map
  terra::plot(r_ext, border = "blue", lwd = 2, lty = "dashed", add = TRUE)
  legend_items <- c(legend_items, "Scanned Map Extent")
  legend_cols <- c(legend_cols, "blue")
  legend_fills <- c(legend_fills, NA)
  legend_borders <- c(legend_borders, "blue")
  
  # Add Legend (standard vector legend in the top right or custom placement)
  legend("topright", legend = legend_items,
         col = legend_cols, lty = c(rep(1, length(legend_items) - 1), 2), lwd = c(rep(1.2, length(legend_items) - 1), 2),
         fill = legend_fills, border = legend_borders,
         bg = "white", cex = 0.8)
  
  # ==========================================
  # RENDER GENERATION PROMPT PANEL BOX (Lower Left)
  # ==========================================
  # Wrap the generation prompt nicely
  prompt_lines <- unlist(strsplit(generation_prompt, "\n"))
  final_wrapped_lines <- c()
  for (pl in prompt_lines) {
    if (nchar(pl) > 55) {
      words <- unlist(strsplit(pl, " "))
      current_line <- ""
      for (w in words) {
        if (nchar(current_line) + nchar(w) + 1 > 55) {
          final_wrapped_lines <- c(final_wrapped_lines, current_line)
          current_line <- w
        } else {
          current_line <- if (current_line == "") w else paste(current_line, w)
        }
      }
      if (current_line != "") {
        final_wrapped_lines <- c(final_wrapped_lines, current_line)
      }
    } else {
      final_wrapped_lines <- c(final_wrapped_lines, pl)
    }
  }
  
  title_line <- paste0("GENERATION PROMPT (v", generation_version, "):")
  card_lines <- c(title_line, "", paste0("  ", final_wrapped_lines))
  
  max_line_width <- max(sapply(card_lines, function(l) strwidth(l, cex = 0.85)))
  total_card_height <- sum(sapply(card_lines, function(l) strheight(l, cex = 0.85))) + (length(card_lines) * strheight("M", cex = 0.85) * 0.2)
  
  # Position in the padded southwest corner of the map coordinate system
  box_x_min <- xlims[1] + (xlims[2] - xlims[1]) * 0.03
  box_x_max <- box_x_min + max_line_width + (xlims[2] - xlims[1]) * 0.04
  box_y_min <- ylims[1] + (ylims[2] - ylims[1]) * 0.03
  box_y_max <- box_y_min + total_card_height + (ylims[2] - ylims[1]) * 0.04
  
  # Draw background panel rect
  rect(box_x_min, box_y_min, box_x_max, box_y_max, col = "white", border = "darkblue", lwd = 1.5)
  
  # Draw the lines
  y_cursor <- box_y_max - (ylims[2] - ylims[1]) * 0.02
  for (idx in seq_along(card_lines)) {
    line_text <- card_lines[idx]
    col <- if (idx == 1) "darkblue" else "#1e3a8a"
    font <- if (idx == 1) 2 else 3
    
    text(
      x = box_x_min + (xlims[2] - xlims[1]) * 0.015,
      y = y_cursor,
      labels = line_text,
      adj = c(0, 1),
      cex = 0.85,
      col = col,
      font = font
    )
    y_cursor <- y_cursor - strheight(line_text, cex = 0.85) - strheight("M", cex = 0.85) * 0.3
  }
  
  dev.off()
}

log_msg("All individual maps completed successfully!")
