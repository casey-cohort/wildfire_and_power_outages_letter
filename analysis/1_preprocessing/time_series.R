options(scipen = 999)
if (!require("pacman", quietly = TRUE)) {
  install.packages("pacman")
}
pacman::p_load(tidyverse, here, arrow)

list(
  `eagle-i` = read_parquet(here('data/processed/eagle-i.parquet')),
  `wfbz`    = read_parquet(here('data/processed/wfbz.parquet')),
  `wfs`     = read_parquet(here('data/processed/wfsmoke.parquet'))
) %>%
  reduce(~full_join(.x, .y, by = c('county_fips', 'day')))
