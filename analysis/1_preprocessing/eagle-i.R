## LP note: only 2024 has total_customers column!
# Quickly identify the number of 8+ hour power outages by county in 2024

# Libraries
options(scipen = 999)
if (!require("pacman", quietly = TRUE)) {
  install.packages("pacman")
}
pacman::p_load(tidyverse, dbplyr, here, lubridate, slider, data.table, fs, arrow, tidycensus)

dir_create('data/processed')

fips_codes <- tidycensus::fips_codes %>%
  transmute(county_fips = paste0(state_code, county_code), state, county)

map(
  dir_ls(here('data/raw/eagle-i'), glob = '*eaglei_outages*csv'),
  function(eaglei_annual_file){

    eaglei <- fread(eaglei_annual_file)

    # identify hours affected by outage
    eaglei <- eaglei %>%
      select(-matches('total_customers')) %>% # this only appears sometimes
      mutate(
        outage_on = ifelse(customers_out > 5000, 1, 0), # can't do percentage most of the time -- just doing 5k for now
        hour = round_date(run_start_time, unit = 'hour'),
        fips_code = str_pad(fips_code, 5, pad = '0')
      ) %>%
      group_by(fips_code, hour) %>%
      summarize(outage_on = max(outage_on), .groups = 'drop')

    # add day indicator
    eaglei <- 
      eaglei %>%
      mutate(day = round_date(hour, unit = 'day'))

    # group by day and find if there are 8 consecutive hrs in that day
    eaglei <- eaglei %>%
      group_by(fips_code, day) %>%
      mutate(
        outage_8hr = slide_lgl(outage_on, ~all(.x == 1), .before = 7, .complete = TRUE)
      )

    eaglei <- setDT(eaglei)

    eaglei_summary <- eaglei[, .(
      outage = ifelse(all(is.na(outage_8hr)), 0L, max(outage_8hr, na.rm = TRUE))
    ), by = .(fips_code, day)]

    setnames(eaglei_summary, 'fips_code', 'county_fips')

    left_join(eaglei_summary, fips_codes, by = 'county_fips')
  }
) %>%
  bind_rows() %>%
  filter(day >= ymd('2018-01-01')) %>%
  write_parquet(here('data/processed/eagle-i.parquet'))
