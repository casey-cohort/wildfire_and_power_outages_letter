options(scipen = 999)
if (!require("pacman", quietly = TRUE)) {
  install.packages("pacman")
}
pacman::p_load(tidyverse, here, fs, arrow, PNWColors)
pacman::p_load_gh('lpiep/gguw')

ds <- read_parquet(here('data/processed/merged.parquet')) %>%
  select(-wfs_pm, -wfs_smoke_day_gt05, -wfs_smoke_day_any) %>%
  pivot_longer(-c(day, county_fips, threshold), names_to = 'event') %>%
  mutate(
    event = case_when(
      event == 'outage' ~ 'Power Outage',
      event == 'wfbz_affected' ~ 'Wildfire',
      event == 'wfs_smoke_day_gt10' ~ 'Smoke day',
      TRUE ~ NA
    )
  ) %>% 
  group_by(day, event, threshold) %>%
  summarize(
    `Counties experiencing event` = sum(value),
    .groups = 'drop'
  ) 

ggplot(ds) + 
  geom_area(aes(x = day, y = `Counties experiencing event`, fill = event)) + 
  scale_fill_manual(values = PNWColors::pnw_palette('Sunset2', 3), guide = 'none') +
  scale_x_date(breaks = seq.Date(min(ds$day), max(ds$day)+1, by = '4 months'), date_labels = '%b \'%y', name = '') + 
  facet_grid(event~threshold, scales = 'free_y') + 
  theme_uw() + 
  theme(
    panel.grid.major.y = element_line(linewidth = .1, color = 'grey50'),
    axis.text.x = element_text(angle = 3*90, vjust = 0.5),
    axis.ticks.x = element_line(linewidth = .1, color = 'grey50'),
    axis.ticks.length.x = unit(1, 'pt')
  )

ggsave(filename = here('figures/time_series.png'), dpi = 300, width = 12, height = 3)



ds_combos <- read_parquet(here('data/processed/merged.parquet')) %>%
  transmute(
    county_fips,
    day,
    event = case_when(
      outage & wfs_smoke_day_gt10 ~ 'Smoke and Outage',
      outage & wfbz_affected ~ 'Wildfire and Outage',
      outage & wfbz_affected & wfs_smoke_day_gt10 ~ 'Wildfire, Smoke, and Outage',
      TRUE ~ NA
    )
  ) %>%
  na.omit() %>% 
  group_by(event, day, threshold) %>% 
  summarize(
    `Counties experiencing event` = n(),
    .groups = 'drop'
  ) 

p <- ggplot(ds_combos) + 
  geom_area(aes(x = day, y = `Counties experiencing event`, fill = event)) + 
  scale_fill_manual(values = PNWColors::pnw_palette('Sunset2', 2), name = '') +
  scale_x_date(breaks = seq.Date(min(ds$day), max(ds$day)+1, by = '4 months'), date_labels = '%b \'%y', name = '') + 
  scale_y_continuous(expand = expansion(add = 0)) + 
  theme_uw() + 
  theme(
    panel.grid.major.y = element_line(linewidth = .1, color = 'grey50'),
    axis.text.x = element_text(angle = 3*90),
    axis.ticks.x = element_line(linewidth = .1, color = 'grey50')
  ) +
  facet_wrap(~threshold, ncol = 1)

p
ggsave(plot = p, filename = here('figures/time_series_combos.png'), width = 6, height = 9, scale = .6)
