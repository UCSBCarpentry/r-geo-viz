## About this project

- This repo demonstrates a geospatial exploratory visualization of pre-1900 wildfire data in the US Pacific Northwest
- It uses R and Terra
- The scripts were created using various LLMs underneath OpenCode, including CIT's Gemma 4 and the DREAM Lab's granted GCP.
- Viewing the maps against the data allowed me to conclude that any fire marked 1900 meant that it was BEFORE 1900.
  - That is stated in the metadata. 

## Things I learned

1. Telling the agent to run all the scripts to learn about the repo seems like a good first step
1. Gemma needs to iterate over R scripts to get libraries set up. It will do it largely unsupervised

## Didactic
1. Explore the scenario
2. Show the outputs
3. Show the reproduction or live-code a reproduction
  1. First try (7/7/26) is to add Placerville, Big Trees, and Port Orford
  2. I started with the prompt:  `time for script #6. I have added scanned maps for Placerville, Big Trees, and Port
Orford California. There is a dataset on the web called FRAP that shows California
wildfires back to the 1800s. Get that dataset and make me 3 separate 50% sized png
representations of the 3 new maps. each one should be the scanned map with the
relevent portion of the FRAP dataset overlaid on top.`

I'm curious about whether gemini can follow along with what is in the history and files. I see it fetching California fire perimeters from arcgis online addresses. both living atlas and cnra.ca.gov addresses. that was slower than googling and downloading a shapefile myself, so I paused the agent and let it keep going
