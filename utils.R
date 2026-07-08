library(terra)
# Utility functions for the r-geo-viz project
# -------------------------------------------------
# Centralised helpers to reduce duplication across scripts

# Simple timestamped logger
log_msg <- function(msg) {
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  message(sprintf("[%s] %s", timestamp, msg))
}

# Load Oregon counties (STATEFP == "41") and return as SpatVector
load_oregon_counties <- function(crs_target = NULL) {
  log_msg("Loading county shapefile and filtering for Oregon")
  counties <- terra::vect("data/tl_2023_us_county.shp")
  or_cnty <- counties[counties$STATEFP == "41", ]
  if (!is.null(crs_target)) {
    log_msg(paste("Projecting counties to", crs_target))
    or_cnty <- terra::project(or_cnty, crs_target)
  }
  return(or_cnty)
}

# Load historic fires, optionally filter by year and reproject
load_historic_fires <- function(crs_target = NULL, year = NULL) {
  log_msg("Loading historic fires shapefile")
  fires <- terra::vect("data/Historic_OR_Fires/Historic_Fires_(pre_2000).shp")
  if (!is.null(year)) {
    # Ensure year column is numeric for reliable comparison
    fires$FIRE_YEAR <- suppressWarnings(as.numeric(fires$FIRE_YEAR))
    fires <- fires[!is.na(fires$FIRE_YEAR) & fires$FIRE_YEAR == year, ]
    log_msg(paste("Filtered fires for year", year, "- records:", nrow(fires)))
  }
  if (!is.null(crs_target)) {
    log_msg(paste("Projecting fires to", crs_target))
    fires <- terra::project(fires, crs_target)
  }
  return(fires)
}

# Load rasters from forest_maps (without resampling or projection)
load_rasters <- function() {
  raster_files <- list.files("data/forest_maps", pattern = "\\.(jpg|tif)$", full.names = TRUE)
  log_msg(paste("Found", length(raster_files), "raster files"))
  rasters <- lapply(raster_files, function(rf) {
    log_msg(paste("Processing", basename(rf)))
    r <- terra::rast(rf)
    setNames(list(r), basename(rf))
  })
  # flatten named list
  if (length(rasters) == 0) return(list())
  out <- do.call(c, rasters)
  return(out)
}

# Ensure output directory exists
ensure_output_dir <- function(dir = "output") {
  if (!dir.exists(dir)) {
    dir.create(dir, recursive = TRUE)
    log_msg(paste("Created output directory", dir))
  }
}
