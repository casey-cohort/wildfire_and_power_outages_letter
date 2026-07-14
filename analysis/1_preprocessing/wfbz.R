# Aggregate wildfire burn zones by county

# Since most fires don't have an end/containment date, 
#  we conservatively consider fires to last 4 days if not
#  otherwise known, which is the 25th percentile length 
#  of fires that _did_ have an end date. 

options(scipen = 999)
if (!require("pacman", quietly = TRUE)) {
  install.packages("pacman")
}
pacman::p_load(tidyverse, here, sf, arrow, tigris)

dir_create('data/processed')

wfbz <- read_sf(here('data/raw/wfbz/wfbz.geojson')) %>% 
  filter(wildfire_year >= 2018) %>% 
  transmute(
    wildfire_year,
    start = wildfire_ignition_date, 
    end = if_else(is.na(wildfire_containment_date), start + 4L, wildfire_containment_date)
  ) %>% 
  split(.$wildfire_year) 
county_sf <- map(2018:2025, ~counties(year = .x, progress_bar = FALSE)) %>%
  map(~select(.x, county_fips = GEOID))

wfbz_occurrence <- map2(
  county_sf,
  wfbz,
  ~st_drop_geometry(st_join(.x, st_transform(.y, st_crs(.x)), left = FALSE))
) %>%
  bind_rows()

wfbz_occurrence <- expand_grid(
  county_fips = wfbz_occurrence$county_fips,
  day = seq.Date(ymd('2018-01-01'), ymd('2025-12-31'))
) %>% 
  mutate(wildfire_year = year(day)) %>%
  left_join(wfbz_occurrence, by = c('county_fips', 'wildfire_year'), relationship = 'many-to-many') %>%
  mutate(event = if_else(!is.na(start), between(as.integer(day), as.integer(start), as.integer(end)), FALSE)) %>%
  group_by(county_fips, day) %>%
  summarize(wfbz_occurrence = as.integer(any(event)))

write_parquet(wfbz_occurrence, here('data/processed/wfbz.parquet'))