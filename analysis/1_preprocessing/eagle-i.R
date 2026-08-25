# Identify whether counties experienced power outages in 2018 - 2024
# 
# A county experiences a power outage when either 5000+ customers or 
#  1% of the estimated total customers in a county report outage 
#  for 8 hours or more. 
#
# Only annual, statewide totals of customers were provided, and only
#  through 2024. We therefore used the ACS to estimate the percentage
#  of each state's households were in each county (annually), and assigned
#  the statewide number of electric customers accordingly. FUTURE: When no 
#  statewide total was reported (after 2024), we carried forward the 
#  previous year's total. When no census estimates were available in 
#  2025, we carried forward 2024's census data. 
#

options(scipen = 999)
if (!require("pacman", quietly = TRUE)) {
  install.packages("pacman")
}
pacman::p_load(tidyverse, dbplyr, here, lubridate, slider, data.table, fs, arrow, tidycensus, sf)

if(Sys.getenv('CENSUS_API_KEY') == '') stop("Install a Census API Key with tidycensus (https://walker-data.com/tidycensus/reference/census_api_key.html).")

dir_create(here('data/processed'))

county_sf <- list(
  `2018` = read_sf(here('data/raw/county/county_2018.geojson')),
  `2019` = read_sf(here('data/raw/county/county_2019.geojson')),
  `2020` = read_sf(here('data/raw/county/county_2020.geojson')),
  `2021` = read_sf(here('data/raw/county/county_2021.geojson')),
  `2022` = read_sf(here('data/raw/county/county_2021.geojson')),#using 2021 for subsequent years since other data sets don't use CT's new counties
  `2023` = read_sf(here('data/raw/county/county_2021.geojson')), 
  `2024` = read_sf(here('data/raw/county/county_2021.geojson')),
) %>%
  map(~select(.x, county_fips = GEOID)) %>%
  map(~filter(.x, !(substr(county_fips, 1, 2) %in% c('02', '15', '72', '78')))) %>% # no AK, HI
  st_drop_geometry() 

county_days <- map2(
  county_sf, 
  c(2018:2024), 
  ~expand_grid(
    threshold = c('1%', '5%', '10%'),
    county_fips = .x$county_fips, 
    day = seq.Date(ymd(paste(.y, '01', '01')), ymd(paste(.y, '12', '31')), by = 'days')
  )
) %>%
  bind_rows() 

fips_codes <- tidycensus::fips_codes %>%
  transmute(county_fips = paste0(state_code, county_code), state, county)

annual_cov <- fread(here('data/raw/eagle-i/coverage_history.csv')) %>%
  transmute(
    year = lubridate::year(mdy(year)),
    state,
    total_customers
  ) %>%
  left_join(
    fips_codes %>%
      transmute(
        state_fips = substr(county_fips, 1, 2),
        state
      ) %>%
      distinct(),
      by = c('state')
    ) 

# carry forward 2022 number of customers after 2022
annual_cov <- annual_cov %>%
  select(state, state_fips) %>%
  distinct() %>%
  cross_join(tibble(year = 2023:2024)) %>%
  bind_rows(annual_cov) %>%
  group_by(state_fips) %>%
  arrange(year) %>%
  fill(total_customers) %>%
  ungroup() 

eaglei_annual_files <- dir_ls(here('data/raw/eagle-i'), glob = '*eaglei_outages*csv')
eaglei_annual_files <- eaglei_annual_files[which(between(as.numeric(str_extract(eaglei_annual_files, '[0-9]{4}')), 2018, 2024))]
eaglei <- map(
  eaglei_annual_files,
  function(eaglei_annual_file){

    county_households <- suppressMessages(
      get_acs(
        geography = 'county', 
        variables = 'B11001_001', 
        year = pmin(2024, as.numeric(str_extract(eaglei_annual_file, '[0-9]{4}'))) # use 2024 ACS estimate since 2025 not yet avail
      )
    ) %>%
      transmute(
        fips_code = GEOID, 
        state_fips = substr(fips_code, 1, 2),
        year = as.numeric(str_extract(eaglei_annual_file, '[0-9]{4}')),
        estimate,
        moe
      ) %>%
      left_join(annual_cov, by = c('state_fips', 'year')) %>%
      group_by(state_fips) %>%
      mutate(
        pct_state_households = estimate / sum(estimate),
        est_total_customers = round(total_customers * pct_state_households)
      ) %>%
      ungroup() %>%
      select(fips_code, est_total_customers)

    eaglei <- read_csv(eaglei_annual_file, show_col_types = FALSE) %>%
      mutate(fips_code = str_pad(fips_code, width = 5, pad = '0')) %>% 
      left_join(county_households,  join_by(fips_code))

    if('sum' %in% names(eaglei)) eaglei <- rename(eaglei, customers_out = sum) # fix inconsistent naming
    
    # identify hours affected by outage
    eaglei <- eaglei %>%
      select(-matches('^total_customers$')) %>% # this only appears sometimes
      mutate(
        `1%` = (customers_out / est_total_customers) > .01 | customers_out >= 5000, # 1% of the county's customers
        `5%` = (customers_out / est_total_customers) > .05 | customers_out >= 5000, # 5% of the county's customers
        `10%` = (customers_out / est_total_customers) > .10 | customers_out >= 5000, # 10% of the county's customers
        hour = round_date(run_start_time, unit = 'hour'),
        fips_code = str_pad(fips_code, 5, pad = '0')
      ) %>%
      pivot_longer(cols = matches('%'), names_to = 'threshold', values_to = 'outage_on') %>% 
      group_by(threshold, fips_code, hour) %>%
      summarize(outage_on = max(outage_on), .groups = 'drop')

    # add day indicator
    eaglei <- 
      eaglei %>%
      mutate(day = as.Date(hour))

    # group by day and find if there are 8 consecutive hrs in that day
    eaglei <- eaglei %>%
      group_by(threshold, fips_code, day) %>%
      mutate(
        outage_8hr = slide_lgl(outage_on, ~all(.x == 1), .before = 7, .complete = TRUE)
      )

    eaglei <- setDT(eaglei)

    eaglei_summary <- eaglei[, .(
      outage = ifelse(all(is.na(outage_8hr)), 0L, max(outage_8hr, na.rm = TRUE))
    ), by = .(threshold, fips_code, day)]

    setnames(eaglei_summary, 'fips_code', 'county_fips')

    left_join(eaglei_summary, fips_codes, by = 'county_fips')
  }
) %>%
  bind_rows() %>%
  select(-c(state, county)) %>% 
  mutate(outage = as.logical(outage))  
eaglei <- left_join(county_days, eaglei, by = c('threshold', 'county_fips', 'day')) %>%
  complete(fill = list(outage = FALSE))
write_parquet(eaglei, here('data/processed/eagle-i.parquet'))
