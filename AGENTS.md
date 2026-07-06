# Agent Guidance: forest_types_r

## Project Overview
R project for exploratory geospatial data analysis using the `terra` package.

## High-Signal Facts
- **Language/Environment**: R.
- **Key Dependencies**: `terra` package.
- **Data Structure**:
  - `data/tl_2023_us_county.shp`: US county shapefiles.
  - `data/forest_maps/`: Contains georeferenced JPEGs (`.jpg`) and world files (`.jgw`).
  - `data/Historic_OR_Fires/`: Contains pre-2000 fires shapefile.
- **Workflow**:
  1. Load county shapefiles.
  2. Filter for Oregon (STATEFP == "41").
  3. Load and map rasters from `data/forest_maps`.
  4. Manipulate data so that it can be mapped to individual images
  5. Export result to PNG in the project `output/` as seen in file tree).
- **Verification**: Whenever any `.R` script is edited, run all scripts in sequence (`01` through `05`) to ensure consistency and verify output.

