# Aggregate wildfire burn zones by county

# Since most fires don't have an end/containment date, 
#  we conservatively consider fires to last 4 days if not
#  otherwise known, which is the 25th percentile length 
#  of fires that _did_ have an end date. 

options(scipen = 999)
if (!require("pacman", quietly = TRUE)) {
  install.packages("pacman")
}
pacman::p_load(tidyverse, here, fs, sf, arrow, tigris, terra, exactextractr)

dir_create(here('data/processed'))

wfbz <- read_sf(here('data/raw/wfbz/wfbz.geojson')) %>% 
  filter(between(wildfire_year, 2018, 2024)) %>% 
  transmute(
    wildfire_id,
    wildfire_year,
    start = wildfire_ignition_date, 
    end = if_else(is.na(wildfire_containment_date), start + 4L, wildfire_containment_date)
  ) %>% 
  filter(!st_is_empty(geometry)) %>%
  #group_by(wildfire_year) %>% 
  #sample_n(2) %>% #DEBUG
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
  map(~filter(.x, !(substr(county_fips, 1, 2) %in% c('02', '15', '60', '66', '69', '72', '78')))) %>% # no AK, HI, territory
  map(~mutate(.x, pop20 = exactextractr::exact_extract(pop20, st_transform(geometry, crs = crs(pop20)), fun = 'sum')))

county_days <- map2(
  county_sf, 
  c(2018:2024), 
  ~expand_grid(
    county_fips = .x$county_fips, 
    day = seq.Date(ymd(paste(.y, '01', '01')), ymd(paste(.y, '12', '31')), by = 'days')
  )
) %>%
  bind_rows() 

pop20 <- rast('data/raw/GHS_POP_E2020_GLOBE_R2023A_54009_100_V1_0.tif')

wfbz_occurrence <- map2(
  # find the union of the fire buffers in each county on each day, then find pop
  county_sf,
  wfbz,
  function(county_sf, wfbz){
    wfbz_buffered <- st_transform(wfbz, st_crs(county_sf)) %>%
      mutate(geometry = st_buffer(geometry, 10000))
    county_fire_encounters <- st_intersection(county_sf, wfbz_buffered) %>%
      inner_join(county_days, by = join_by(county_fips, y$day <= x$end, y$day >= x$start)) %>%
      group_by(county_fips, day) %>%
      summarize(geometry = st_union(geometry), .groups = 'drop') %>% 
      mutate(geom_hash = purrr::map_chr(geometry, ~ digest::digest(sf::st_as_binary(.x))))

    unique_geoms <- county_fire_encounters %>% # extract only on unique geometries
      distinct(geom_hash, .keep_all = TRUE)
    
    unique_geoms$pop20_affected <- exactextractr::exact_extract(
      pop20, st_transform(unique_geoms, crs = crs(pop20)), fun = 'sum'
    )
    
    county_fire_encounters <- county_fire_encounters %>%
      left_join(st_drop_geometry(unique_geoms) %>% select(geom_hash, pop20_affected), by = 'geom_hash')
    
    st_drop_geometry(county_fire_encounters) %>% 
      left_join(st_drop_geometry(county_sf), by = 'county_fips') %>%
      transmute(
        county_fips, 
        day,
        `1%` =  (pop20_affected/pop20) > .01 | (pop20_affected >= 5000),
        `5%` =  (pop20_affected/pop20) > .05 | (pop20_affected >= 5000),
        `10%` = (pop20_affected/pop20) > .10 | (pop20_affected >= 5000)
      ) 
  }
) %>%
  bind_rows() %>%
  pivot_longer(cols = matches('%'), names_to = 'threshold', values_to = 'wfbz_affected') 

write_parquet(wfbz_occurrence, here('data/processed/wfbz.parquet'))
