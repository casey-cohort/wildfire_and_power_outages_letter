options(scipen = 999)
if (!require("pacman", quietly = TRUE)) {
  install.packages("pacman")
}
pacman::p_load(tidyverse, here, fs, arrow, sf)

ds <- full_join(
  read_parquet(here('data/processed/eagle-i.parquet')),
  read_parquet(here('data/processed/wfbz.parquet')),
  by = c('county_fips', 'day', 'threshold'),
  relationship = 'one-to-one'
) %>%
  full_join(
    read_parquet(here('data/processed/wfsmoke.parquet')),
    by = c('county_fips', 'day'),
    relationship = 'many-to-one'
  ) %>%
  filter(as.numeric(county_fips) < 60000) %>% # no territories
  filter(!(substr(county_fips, 1, 2) %in% c('02', '15'))) # conus only

if(!all(complete.cases(ds))) stop('There are unmatched counties/days in one or more of the data sets.')
if(!is.logical(ds$outage)) stop('There are invalid values for `outage`.')
if(!is.logical(ds$wfbz_affected)) stop('There are invalid values for `wfbz_occurrence`.')
if(!is.logical(ds$wfs_smoke_day_any)) stop('There are invalid values for `wfs_smoke_day`.')
if(!is.numeric(ds$wfs_pm)) stop('There are invalid values for `wfs_smoke_day`.')

write_parquet(ds, here('merged.parquet'))
