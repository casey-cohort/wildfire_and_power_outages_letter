options(scipen = 999)
if (!require("pacman", quietly = TRUE)) {
  install.packages("pacman")
}
pacman::p_load(tidyverse, here, fs, sf, tigris)

dir_create(here('data/raw/county'))

county_sf <- map(2018:2025, ~counties(year = .x, progress_bar = FALSE,  refresh = TRUE))
names(county_sf) <- 2018:2025
map(names(county_sf), ~write_sf(county_sf[[.x]], here(paste0('data/raw/county/county_', .x, '.geojson'))))
