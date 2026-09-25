options(scipen = 999)
if (!require("pacman", quietly = TRUE)) {
  install.packages("pacman")
}
pacman::p_load(tidyverse, here, fs, arrow, PNWColors, sf, tigris)
pacman::p_load_gh('lpiep/gguw')

ds <- read_parquet(here('merged.parquet')) %>%
  mutate(threshold = factor(threshold, levels = c('1%', '5%', '10%')))

conus_sf <- tigris::states(cb = TRUE) %>% 
  filter(STUSPS %in% c(state.abb, 'DC'), !(STUSPS %in% c('AK', 'HI'))) %>%
  transmute(
    state_fips = STATEFP,
    state_abb = STUSPS,
    state = NAME
  )

summary_spatial <- ds %>%
  mutate(state_fips = substr(county_fips, 1, 2)) %>%
  group_by(state_fips, threshold) %>%
  summarize(
    apocalypse = mean(all(outage, wfbz_affected, wfs_smoke_day_gt10)),
    outage_and_wf = mean(outage & (wfbz_affected | wfs_smoke_day_gt10)),
    outage_and_wfbz = mean(outage & wfbz_affected),
    outage_and_wfs = mean(outage & wfs_smoke_day_gt10),
    wfbz_and_wfs = mean(wfbz_affected & wfs_smoke_day_gt10),
    outage = mean(outage),
    wfbz_affected = mean(wfbz_affected),
    wfs_smoke_day_gt10 = mean(wfs_smoke_day_gt10),
    .groups = "drop_last"
  ) %>%
  left_join(conus_sf, by = join_by(state_fips)) %>%
  st_as_sf()

p_outage <- ggplot() + 
  geom_sf(data = summary_spatial, aes(fill = outage)) + 
  facet_wrap(~threshold, ncol = 1) + 
  scale_fill_distiller(name = 'Mean county outage days', palette = 'Spectral', labels = scales::percent) +
  theme_void() +
  ggtitle('Power outages by state')


p_wfbz <- ggplot() + 
  geom_sf(data = summary_spatial, aes(fill = wfbz_affected)) + 
  facet_wrap(~threshold, ncol = 1) + 
  scale_fill_distiller(name = 'Mean county WFBZ days', palette = 'Spectral', labels = scales::percent) +
  theme_void() +
  ggtitle('WFBZ-affected days by state')

p_wfs <- ggplot() + 
  geom_sf(data = summary_spatial, aes(fill = wfs_smoke_day_gt10)) + 
  facet_wrap(~threshold, ncol = 1) + 
  scale_fill_distiller(name = 'Mean county smoke days', palette = 'Spectral', labels = scales::percent) +
  theme_void() +
  ggtitle('Smoke days (>10µg/m3) by state')

p_all <- ggplot() + 
  geom_sf(data = summary_spatial, aes(fill = apocalypse)) + 
  facet_wrap(~threshold, ncol = 1) + 
  scale_fill_distiller(name = 'Mean county apocalypse days', palette = 'Spectral', labels = scales::percent) +
  theme_void() +
  ggtitle('Apocalypse days (all three factors) by state')

p_two <- ggplot() + 
  geom_sf(data = summary_spatial, aes(fill = outage_and_wf)) + 
  facet_wrap(~threshold, ncol = 1) + 
  scale_fill_distiller(name = 'Mean county outage + WF days', palette = 'Spectral', labels = scales::percent) +
  theme_void() +
  ggtitle('Days with outage and either WF metric by state')

p_outage_wfbz <- ggplot() + 
  geom_sf(data = summary_spatial, aes(fill = outage_and_wfbz)) + 
  facet_wrap(~threshold, ncol = 1) + 
  scale_fill_distiller(name = 'Mean county outage + WFBZ days', palette = 'Spectral', labels = scales::percent) +
  theme_void() +
  ggtitle('Days with outage and WFBZ by state')

p_outage_wfs <- ggplot() + 
  geom_sf(data = summary_spatial, aes(fill = outage_and_wfs)) + 
  facet_wrap(~threshold, ncol = 1) + 
  scale_fill_distiller(name = 'Mean county outage + WFS days', palette = 'Spectral', labels = scales::percent) +
  theme_void() +
  ggtitle('Days with outage and WFS > 10µg/m3 by state')

p_wfbz_wfs <- ggplot() + 
  geom_sf(data = summary_spatial, aes(fill = wfbz_and_wfs)) + 
  facet_wrap(~threshold, ncol = 1) + 
  scale_fill_distiller(name = 'Mean county WFBZ + WFS days', palette = 'Spectral', labels = scales::percent) +
  theme_void() +
  ggtitle('Days with WFBZ and WFS > 10µg/m3 by state')


dir_create(here('figures/by_state'))
ggsave(plot = p_outage, here('figures/by_state/outage.png'), height = 4, width = 2)
ggsave(plot = p_wfbz, here('figures/by_state/wfbz.png'), height = 4, width = 2)
ggsave(plot = p_wfs, here('figures/by_state/wfs.png'), height = 4, width = 2)
ggsave(plot = p_all, here('figures/by_state/all.png'), height = 4, width = 2)
ggsave(plot = p_two, here('figures/by_state/outage_any_wf.png'), height = 4, width = 2)
ggsave(plot = p_outage_wfbz, here('figures/by_state/outage_wfbz.png'), height = 4, width = 2)
ggsave(plot = p_outage_wfs, here('figures/by_state/outage_wfs.png'), height = 4, width = 2)
ggsave(plot = p_wfbz_wfs, here('figures/by_state/wfbz_wfs.png'), height = 4, width = 2)

