# Wildfire and Power Outages Research Letter

This repository contains/will contain analysis code, figures, and text for a research letter exploring the co-occurance of [wildfire disasters](https://github.com/lpiep/wildfire_disasters_lite), 
wildfire smoke events, and power outages in the US over time. 

## Setup and Run

Cloning this repo and running `make` should rebuild all the data sets and figures (can take a few hours).

`quarto render` should rebuild the letter itself to `_manuscript`. 

## What's what? 

### Manuscript

- `research_letter.qmd` markdown/quarto document containing raw manuscript text
- `references.bib` bibtex bibliography
- `_manuscript` rendered manuscript files

### Analysis code

- `analysis/0_data` scripts to download each source data set
- `analysis/1_preprocessing` scripts to turn each data set into a binary daily exposure, then merge
- `analysis/2_figures` scripts to produce figures (not just the main figure for the paper)

### Data

Not on Github. Will be populated when you run `make`. Gets to about 24 GB. 

- `data/raw` produced by `analysis/0_data`
- `data/processed` produced by `analysis/1_preprocessing`

On Github:

- `merged.parquet` the analytic data set produced by the pipeline. 

## Note on geography changes

### Connecticut County Changes

Eagle-i and the Childs WFS data sets do not use the updated counties in CT after 2024,
so we aggregated WFBZs by 2023 boundaries (which use the historical counties) for 
both 2024 and 2025. This is the only county change affecting all three data sets. 
