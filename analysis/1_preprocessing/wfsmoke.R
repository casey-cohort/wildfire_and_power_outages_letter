# Wildfire Smoke
#
# Not much to do here, just rename some vars to match the others and
#  expand to include non-smoke days


options(scipen = 999)
if (!require("pacman", quietly = TRUE)) {
  install.packages("pacman")
}
pacman::p_load(tidyverse, here, fs, arrow)

dir_create(here('data/processed'))


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
  map(~filter(.x, !(substr(county_fips, 1, 2) %in% c('02', '15', '72', '78')))) %>% # no AK, HI
  st_drop_geometry() 

county_days <- map2(
  county_sf, 
  c(2018:2024), 
  ~expand_grid(
    county_fips = .x$county_fips, 
    day = seq.Date(ymd(paste(.y, '01', '01')), ymd(paste(.y, '12', '31')), by = 'days')
  )
) %>%
  bind_rows() 

wfs <- read_rds(here('data/raw/wfsmoke/wfsmoke.rds')) %>%
  transmute(
    county_fips = GEOID,
    day = date,
    wfs_pm = smokePM_pred,
    wfs_smoke_day = TRUE
  ) 
# Account for county changes over time
#  Commented out since we are only using 2018+, but left in case we want to do comparisons without eagle-i
#bind_rows( # duplicate records for Bedford City VA before 2013 since this data set
#  # only considers the consolidated city-county
#  wfs,
#  wfs %>% filter(county_fips == '51019', day < mdy('July 1, 2013')) %>% mutate(county_fips == '51515')
#) %>%
#mutate(
#  county_fips = if_else((county_fips == '46102') & (day < mdy('May 1, 2015')), '46113', '46102') # Shannon -> Oglala Lakota county name change
#)
  
wfs <- left_join(county_days, wfs, by = c('county_fips', 'day')) %>%
  group_by(county_fips) %>% 
  complete(
    day = seq.Date(min(day), max(day), by = 'days'),
    fill = list(
      wfs_pm = 0,
      wfs_smoke_day = FALSE
    )
  )


write_parquet(wfs, here('data/processed/wfsmoke.parquet'))
