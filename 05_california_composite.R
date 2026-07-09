# Script 05: Overall Composite Map (All Scanned Maps, OR & CA Counties, Decadal Fires)
# -----------------------------------------------------------------------------
source("utils.R")

ensure_output_dir("output")
log_msg("Starting Script 05: Creating Overall Composite Map with ALL georeferenced scanned maps...")

# Define the generation details (filename increment & generating prompt box)
generation_version <- "5.6"
generation_prompt <- "flip the color scheme so that red is oldest and yellow is newest. Clearly explain as AI-generated."

# 1. Discover and load ALL georeferenced rasters across all directories
all_files <- list.files("data/forest_maps", pattern = "\\.(jpg|tif)$", full.names = TRUE, recursive = TRUE)
log_msg(paste("Discovered", length(all_files), "total raster files. Filtering for georeferenced maps..."))

rasters <- list()
for (f in all_files) {
  tryCatch({
    r <- terra::rast(f)
    if (nchar(terra::crs(r)) > 0) {
      fname <- basename(f)
      
      # Skip high-res rotated or problematic offset GR.tif
      if (grepl("GR\\.tif$", fname)) {
        log_msg(paste("Skipping rotated/offset GR.tif:", fname))
        next
      }
      # Skip raw unreferenced files starting with "6322"
      if (grepl("^6322", fname)) {
        next
      }
      
      log_msg(paste("Loaded georeferenced map:", fname))
      rasters[[fname]] <- r
    }
  }, error = function(e) {
    # Skip gracefully
  })
}

if (length(rasters) == 0) stop("No georeferenced rasters found.")

# Project everything to Web Mercator (EPSG:3857)
target_crs <- "EPSG:3857"

# 2. Downsample, project, and crop each raster by 10% on each side
log_msg("Processing, downsampling, projecting, and cropping all rasters...")
projected_rasters <- list()
for (name in names(rasters)) {
  r <- rasters[[name]]
  
  # Downsample if resolution is extremely fine to keep operations high performance
  dims <- dim(r)
  max_dim <- max(dims[1], dims[2])
  if (max_dim > 3000) {
    fact <- round(max_dim / 1000)
    log_msg(paste("Aggregating raster", name, "with factor:", fact))
    r <- terra::aggregate(r, fact = fact)
  }
  
  log_msg(paste("Reprojecting raster:", name, "to target CRS (EPSG:3857)..."))
  r_proj <- terra::project(r, target_crs)
  
  # Calculate 10% crop limits
  e <- terra::ext(r_proj)
  w <- e[2] - e[1]
  h <- e[4] - e[3]
  
  crop_ext <- terra::ext(
    e[1] + w * 0.10, # crop 10% from left
    e[2] - w * 0.10, # crop 10% from right
    e[3] + h * 0.10, # crop 10% from bottom
    e[4] - h * 0.10  # crop 10% from top
  )
  
  log_msg(paste("Cropping raster:", name, "by 10% on each side"))
  r_cropped <- terra::crop(r_proj, crop_ext)
  projected_rasters[[name]] <- r_cropped
}

# 3. Load and filter US Counties for California (06) and Oregon (41)
log_msg("Loading US counties...")
us_counties <- terra::vect("data/tl_2023_us_county.shp")
or_ca_counties <- us_counties[us_counties$STATEFP %in% c("41", "06"), ]
log_msg("Projecting counties to target CRS...")
counties_projected <- terra::project(or_ca_counties, target_crs)

# 4. Load and project Oregon Fires
log_msg("Loading and projecting Oregon historic fires...")
or_fires <- terra::vect("data/Historic_OR_Fires/Historic_Fires_(pre_2000).shp")
or_fires <- terra::project(or_fires, target_crs)
or_fires$year <- suppressWarnings(as.numeric(or_fires$FIRE_YEAR))

# 5. Load and project California FRAP Fires
log_msg("Loading and projecting California FRAP fires...")
ca_fires <- terra::vect("data/California_Historic_Fire_Perimeters_FRAP/California_Fire_Perimeters_(all).shp")
ca_fires <- terra::project(ca_fires, target_crs)
ca_fires$year <- suppressWarnings(as.numeric(ca_fires$YEAR_))

# 6. Combine and process fires by decade
log_msg("Combining Oregon and California fires...")
or_fires_valid <- or_fires[!is.na(or_fires$year), ]
ca_fires_valid <- ca_fires[!is.na(ca_fires$year), ]

or_fires_valid$decade <- floor(or_fires_valid$year / 10) * 10
ca_fires_valid$decade <- floor(ca_fires_valid$year / 10) * 10

# Calculate combined extents of correctly projected rasters to set the map limits
extents <- lapply(projected_rasters, terra::ext)
min_x <- min(sapply(extents, function(e) e[1]))
max_x <- max(sapply(extents, function(e) e[2]))
min_y <- min(sapply(extents, function(e) e[3]))
max_y <- max(sapply(extents, function(e) e[4]))

# Let's crop counties and fires to a window slightly padded around our scanned maps
pad_x <- (max_x - min_x) * 0.15
pad_y <- (max_y - min_y) * 0.15
map_extent <- terra::ext(min_x - pad_x, max_x + pad_x, min_y - pad_y, max_y + pad_y)

log_msg("Cropping counties and fires to the mapped area...")
counties_cropped <- terra::crop(counties_projected, map_extent)
or_fires_cropped <- terra::crop(or_fires_valid, map_extent)
ca_fires_cropped <- terra::crop(ca_fires_valid, map_extent)

# Determine the decades present in either cropped dataset
all_decades <- sort(unique(c(or_fires_cropped$decade, ca_fires_cropped$decade)))
# Filter to valid decadal groups (e.g. up to year 2000/2010 to keep it clear)
all_decades <- all_decades[all_decades >= 1800 & all_decades <= 2020]

# Flipped Color Scheme: red is oldest, yellow is newest
# -------------------------------------------------------------
# Old scheme: yellow -> orange -> red -> darkred
# New scheme: darkred -> red -> orange -> yellow
colors <- colorRampPalette(c("#4a0000", "#b22222", "#ff4500", "#ffa500", "#ffed6f"))(length(all_decades))
trans_colors <- paste0(colors, "80")

# Helper function to draw readable labeled text on base plots
draw_labeled_text <- function(x, y, label, text_color = "black", bg_color = "white") {
  tw <- strwidth(label, cex = 1.0)
  th <- strheight(label, cex = 1.0)
  rect(x - tw * 0.6, y - th * 0.6, x + tw * 0.6, y + th * 0.6, col = bg_color, border = "#374151", lwd = 1)
  text(x, y, labels = label, col = text_color, cex = 1.0, font = 2)
}

# 7. Plotting
# Increment filenames as requested: e.g. 05_california_composite_map_v5.5.jpg
output_path <- file.path("output", paste0("05_california_composite_map_v", generation_version, ".jpg"))
log_msg(paste("Saving composite map to:", output_path))
jpeg(output_path, width = 3000, height = 2400, res = 200)

# Plot counties base first
terra::plot(counties_cropped, col = "#f5f5f4", border = "#d1d5db", lwd = 1,
            xlim = c(map_extent[1], map_extent[2]),
            ylim = c(map_extent[3], map_extent[4]),
            main = paste0("Pacific Coast Historical Forest Maps & Wildfires by Decade\n(Oregon & California Overall Composite - Version ", generation_version, ")"),
            mar = c(3, 3, 4, 3))

# Overlay each scanned map raster
for (name in names(projected_rasters)) {
  log_msg(paste("Drawing scanned map:", name))
  tryCatch({
    r_to_plot <- projected_rasters[[name]]
    terra::plotRGB(r_to_plot, r = 1, g = 2, b = 3, add = TRUE)
  }, error = function(e) {
    log_msg(paste("Skipped or erred on raster", name, ":", e$message))
  })
}

# Redraw county outlines on top of the rasters for proper framing
terra::plot(counties_cropped, col = NA, border = "#374151", lwd = 1.2, add = TRUE)

# Overlay decadal fires (Oregon and California combined)
log_msg("Plotting Oregon & California fires by decade...")
for (i in 1:length(all_decades)) {
  dec <- all_decades[i]
  of <- or_fires_cropped[or_fires_cropped$decade == dec, ]
  cf <- ca_fires_cropped[ca_fires_cropped$decade == dec, ]
  
  if (nrow(of) > 0) {
    terra::plot(of, col = trans_colors[i], border = NA, add = TRUE)
  }
  if (nrow(cf) > 0) {
    terra::plot(cf, col = trans_colors[i], border = NA, add = TRUE)
  }
}

# Add clear map titles strictly ON TOP of the fire polygons
log_msg("Adding raster labels on top of fire polygons...")
for (name in names(projected_rasters)) {
  tryCatch({
    r_to_plot <- projected_rasters[[name]]
    e <- terra::ext(r_to_plot)
    cx <- (e[1] + e[2]) / 2
    cy <- (e[3] + e[4]) / 2
    
    clean_title <- gsub("\\.(jpg|tif)$", "", name)
    clean_title <- gsub("_", " ", clean_title)
    
    draw_labeled_text(cx, cy, clean_title, text_color = "black", bg_color = "#fef08a")
  }, error = function(e) {})
}

# Render the Prompt Box on the lower left
log_msg("Drawing generating prompt card...")

# Split prompt by newlines, then do soft-wrapping for very long lines
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

# Construct the prompt card title
title_line <- paste0("GENERATION PROMPT (v", generation_version, "):")
card_lines <- c(title_line, "", paste0("  ", final_wrapped_lines))

# We measure string height and widths dynamically to perfectly pad and size the background panel
max_line_width <- max(sapply(card_lines, function(l) strwidth(l, cex = 0.85)))
total_card_height <- sum(sapply(card_lines, function(l) strheight(l, cex = 0.85))) + (length(card_lines) * strheight("M", cex = 0.85) * 0.2)

# Position prompt card beautifully in the bottom-left corner with 3% margin
box_x_min <- map_extent[1] + (map_extent[2] - map_extent[1]) * 0.03
box_x_max <- box_x_min + max_line_width + (map_extent[2] - map_extent[1]) * 0.04
box_y_min <- map_extent[3] + (map_extent[4] - map_extent[3]) * 0.03
box_y_max <- box_y_min + total_card_height + (map_extent[4] - map_extent[3]) * 0.04

# Draw panel box for the prompt
rect(box_x_min, box_y_min, box_x_max, box_y_max, col = "white", border = "darkblue", lwd = 1.5)

# Render each line of the prompt on a separate vertical anchor to guarantee zero overflow
y_cursor <- box_y_max - (map_extent[4] - map_extent[3]) * 0.02
for (idx in seq_along(card_lines)) {
  line_text <- card_lines[idx]
  col <- if (idx == 1) "darkblue" else "#1e3a8a"
  font <- if (idx == 1) 2 else 3
  
  text(
    x = box_x_min + (map_extent[2] - map_extent[1]) * 0.015,
    y = y_cursor,
    labels = line_text,
    adj = c(0, 1),
    cex = 0.85,
    col = col,
    font = font
  )
  y_cursor <- y_cursor - strheight(line_text, cex = 0.85) - strheight("M", cex = 0.85) * 0.3
}

# Position the Decadal Color Legend DIRECTLY ABOVE the Prompt Box on the lower-left
log_msg("Drawing decadal color legend directly above the prompt box...")

# Define the coordinates for the legend box above the prompt box.
# We dynamically measure its width based on the decadal labels ("Fires by Decade" & "1900s") rather than forcing it to match the prompt card width.
dec_labels <- c("Fires by Decade", paste0(all_decades, "s"))
max_leg_text_width <- max(sapply(dec_labels, function(l) strwidth(l, cex = 0.9)))

# We need extra space for the color box box_size_x and a small padding
box_size_x <- (map_extent[2] - map_extent[1]) * 0.025
leg_x_min <- box_x_min
leg_x_max <- leg_x_min + max_leg_text_width + box_size_x + (map_extent[2] - map_extent[1]) * 0.045
leg_y_min <- box_y_max + (map_extent[4] - map_extent[3]) * 0.02

# We calculate the height of the legend box based on the number of decades
num_decades <- length(all_decades)
item_height <- strheight("1900s", cex = 1.0)
leg_padding_y <- (map_extent[4] - map_extent[3]) * 0.02
total_leg_height <- (num_decades + 1) * item_height * 1.5 + leg_padding_y

leg_y_max <- leg_y_min + total_leg_height

# Draw background panel box for the legend
rect(leg_x_min, leg_y_min, leg_x_max, leg_y_max, col = "white", border = "#374151", lwd = 1.5)

# Add Legend Title
text(
  x = leg_x_min + (map_extent[2] - map_extent[1]) * 0.015,
  y = leg_y_max - (map_extent[4] - map_extent[3]) * 0.015,
  labels = "Fires by Decade",
  adj = c(0, 1),
  cex = 1.0,
  font = 2,
  col = "black"
)

# Draw decadal items with their respective color boxes and text labels
y_leg_cursor <- leg_y_max - (map_extent[4] - map_extent[3]) * 0.045
box_size_y <- (map_extent[4] - map_extent[3]) * 0.012

for (i in seq_along(all_decades)) {
  dec_label <- paste0(all_decades[i], "s")
  
  # Coordinate boundaries for color box
  bx1 <- leg_x_min + (map_extent[2] - map_extent[1]) * 0.015
  bx2 <- bx1 + box_size_x
  by1 <- y_leg_cursor - box_size_y
  by2 <- y_leg_cursor
  
  rect(bx1, by1, bx2, by2, col = trans_colors[i], border = colors[i], lwd = 1)
  
  text(
    x = bx2 + (map_extent[2] - map_extent[1]) * 0.015,
    y = y_leg_cursor - box_size_y * 0.1,
    labels = dec_label,
    adj = c(0, 1),
    cex = 0.9,
    font = 2,
    col = "black"
  )
  
  y_leg_cursor <- y_leg_cursor - item_height * 1.5
}

dev.off()
log_msg("Script 05 complete!")
