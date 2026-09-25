# Wildfire and Power Outages Research Letter

This repository contains/will contain analysis code, figures, and text for a research letter exploring the co-occurance of [wildfire disasters](https://github.com/lpiep/wildfire_disasters_lite), 
wildfire smoke events, and power outages in the US over time. 

## Setup and Run

Cloning this repo and running `make` should rebuild all the data sets and figures (can take a few hours).

`quarto render` should rebuild the letter itself to `_manuscript`. 


## Note on geography changes

### Connecticut County Changes

Eagle-i and the Childs WFS data sets do not use the updated counties in CT after 2024,
so we aggregated WFBZs by 2023 boundaries (which use the historical counties) for 
both 2024 and 2025. This is the only county change affecting all three data sets. 
