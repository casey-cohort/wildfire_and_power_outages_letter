options(scipen = 999)
if (!require("pacman", quietly = TRUE)) {
  install.packages("pacman")
}
pacman::p_load(tidyverse, here, fs, arrow)


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


ds <- list(
  `eagle-i` = read_parquet(here('data/processed/eagle-i.parquet')),
  `wfbz`    = read_parquet(here('data/processed/wfbz.parquet')),
  `wfs`     = read_parquet(here('data/processed/wfsmoke.parquet'))
)

if(!all(complete.cases(bind_rows(ds)))) stop('There are missing values in one or more of the data sets.')

ds <- reduce(ds, full_join, by = c('county_fips', 'day'))

if(!is.logical(ds$outage)) stop('There are invalid values for `outage`.')
if(!is.logical(ds$wfbz_occurrence)) stop('There are invalid values for `wfbz_occurrence`.')
if(!is.logical(ds$wfs_smoke_day)) stop('There are invalid values for `wfs_smoke_day`.')

write_parquet(ds, here('data/processed/merged.parquet'))