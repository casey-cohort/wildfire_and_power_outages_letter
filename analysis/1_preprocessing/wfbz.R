# Aggregate wildfire burn zones by county

# Since most fires don't have an end/containment date, 
#  we conservatively consider fires to last 4 days if not
#  otherwise known, which is the 25th percentile length 
#  of fires that _did_ have an end date. 

options(scipen = 999)
if (!require("pacman", quietly = TRUE)) {
  install.packages("pacman")
}
pacman::p_load(tidyverse, here, fs, sf, arrow, tigris)

dir_create(here('data/processed'))

wfbz <- read_sf(here('data/raw/wfbz/wfbz.geojson')) %>% 
  filter(between(wildfire_year, 2018, 2024)) %>% 
  transmute(
    wildfire_year,
    start = wildfire_ignition_date, 
    end = if_else(is.na(wildfire_containment_date), start + 4L, wildfire_containment_date)
  ) %>% 
  split(.$wildfire_year) 

county_sf <- list(
  `2018` = read_sf(here('data/raw/county/county_2018.geojson')),
  `2019` = read_sf(here('data/raw/county/county_2019.geojson')),
  `2020` = read_sf(here('data/raw/county/county_2020.geojson')),
  `2021` = read_sf(here('data/raw/county/county_2021.geojson')),
  `2022` = read_sf(here('data/raw/county/county_2021.geojson')),#using 2021 for subsequent years since other data sets don't use CT's new counties
  `2023` = read_sf(here('data/raw/county/county_2021.geojson')), 
  `2024` = read_sf(here('data/raw/county/county_2021.geojson'))
) %>%
  map(~select(.x, county_fips = GEOID)) %>%
  map(~filter(.x, !(substr(county_fips, 1, 2) %in% c('02', '15', '60', '66', '69', '72', '78')))) # no AK, HI, territory

wfbz_occurrence <- map2(
  county_sf,
  wfbz,
  ~st_drop_geometry(st_join(.x, st_transform(.y, st_crs(.x)), left = FALSE))
) %>%
  bind_rows()

wfbz_occurrence <- county_days %>% 
  mutate(wildfire_year = year(day)) %>%
  left_join(wfbz_occurrence, by = c('county_fips', 'wildfire_year'), relationship = 'many-to-many') %>%
  mutate(event = if_else(!is.na(start), between(as.integer(day), as.integer(start), as.integer(end)), FALSE)) %>%
  group_by(county_fips, day) %>%
  summarize(wfbz_occurrence = any(event), .groups = 'drop') 

write_parquet(wfbz_occurrence, here('data/processed/wfbz.parquet'))
