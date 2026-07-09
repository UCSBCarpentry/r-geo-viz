## About this project

- This repo demonstrates a geospatial exploratory visualization of pre-1900 wildfire data in the US Pacific Northwest
- It uses R and Terra
- The scripts were created using various LLMs underneath OpenCode, including CIT's Gemma 4 and the DREAM Lab's granted GCP.
- The models used by OpenCode possess machine vision capabilities, allowing them, to some extent, to verify the results saved to the `output/` directory.
- Viewing the maps against the data allowed me to conclude that any fire marked 1900 meant that it was BEFORE 1900.
  - That is a detail that was NOT stated in the metadata. 

## Things I learned

1. Between sessions, telling the agent to run all the scripts to learn about the repo seemed to help
1. When moving to a new Coder workspace, the AI will iterate over R scripts to get libraries set up. It will do it largely unsupervised

## Didactic
[Here is an outline of how I got to the 9 R scripts](didactic.qmd)

I'm curious about whether gemini can follow along with what is in the history and files. I see it fetching California fire perimeters from arcgis online addresses. both living atlas and cnra.ca.gov addresses. that was slower than googling and downloading a shapefile myself, so I paused the agent and let it keep going
