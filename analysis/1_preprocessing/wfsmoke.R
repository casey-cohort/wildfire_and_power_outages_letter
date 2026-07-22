# Wildfire Smoke
#
# Not much to do here, just rename some vars to match the others and
#  expand to include non-smoke days


options(scipen = 999)
if (!require("pacman", quietly = TRUE)) {
  install.packages("pacman")
}
pacman::p_load(tidyverse, here, fs, arrow)

dir_create('data/processed')

read_rds(here('data/raw/wfsmoke/wfsmoke.rds')) %>%
  transmute(
    county_fips = GEOID,
    day = date,
    wfs_pm = smokePM_pred,
    wfs_smoke_day = TRUE
  ) %>%
  group_by(county_fips) %>% 
  complete(
    day = seq.Date(min(day), max(day), by = 'days'),
    fill = list(
      wfs_pm = 0,
      wfs_smoke_day = FALSE
    )
  ) %>%
  write_parquet(here('data/processed/wfsmoke.parquet'))
