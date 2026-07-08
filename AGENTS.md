# Agent Guidance: forest_types_r

## Project Overview
R project for exploratory geospatial data analysis using the `terra` package.

## High-Signal Facts
- **Language/Environment**: R.
- **Key Dependencies**: `terra` package.
- **Data Structure**:
  - `data/`: Contains shapefiles and geospatial data.
  - `data/forest_maps/`: Contains georeferenced rasters and world files.
- **Workflow**:
  1. Load vector data (e.g., shapefiles).
  2. Filter and project vector data to match native raster CRS.
  3. Load and map rasters.
  4. Perform geospatial analysis or overlays.
  5. Export results to the `output/` directory.
- **Verification**: Whenever any `.R` script is edited, run all scripts in sequence to ensure consistency and verify output.
- **Vision Capability**: The underlying models have machine vision. You can request the model to analyze images in the `output/` directory to verify map quality, legend placement, or geospatial accuracy.
- **Versioning Outputs**: For iterative design tasks (like those in Script 5), dynamically increment the output filenames (e.g., `v5.1`, `v5.2`, `v5.3`) and imprint the exact generating prompt within a dedicated text box panel in the lower-left corner of the generated image to preserve history.

