options(scipen = 999)
if (!require("pacman", quietly = TRUE)) {
  install.packages("pacman")
}
pacman::p_load(tidyverse, here, fs, arrow, PNWColors)
pacman::p_load_gh('lpiep/gguw')

ds <- read_parquet(here('data/processed/merged.parquet')) %>%
  select(-wfs_pm) %>%
  pivot_longer(-c(day, county_fips), names_to = 'event') %>%
  mutate(
    event = case_when(
      event == 'outage' ~ 'Power Outage',
      event == 'wfbz_occurrence' ~ 'Wildfire',
      event == 'wfs_smoke_day' ~ 'Smoke day'   
    )
  ) %>% 
  group_by(day, event) %>%
  summarize(
    `Counties experiencing event` = sum(value),
    .groups = 'drop'
  ) 

ggplot(ds) + 
  geom_area(aes(x = day, y = `Counties experiencing event`, fill = event)) + 
  scale_fill_manual(values = PNWColors::pnw_palette('Sunset2', 3), guide = 'none') +
  scale_x_date(breaks = seq.Date(min(ds$day), max(ds$day)+1, by = '4 months'), date_labels = '%b \'%y', name = '') + 
  facet_wrap(~event, ncol = 1, scales = 'free_y') + 
  theme_uw() + 
  theme(
    panel.grid.major.y = element_line(linewidth = .1, color = 'grey50'),
    axis.text.x = element_text(angle = 3*90, vjust = 0.5),
    axis.ticks.x = element_line(linewidth = .1, color = 'grey50'),
    axis.ticks.length.x = unit(1, 'pt')
  )

ggsave(filename = here('figures/time_series.png'), dpi = 300, width = 4, height = 3)



ds_combos <- read_parquet(here('data/processed/merged.parquet')) %>%
  transmute(
    county_fips,
    day,
    event = case_when(
      outage & wfs_smoke_day ~ 'Smoke and Outage',
      outage & wfbz_occurrence ~ 'Wildfire and Outage',
      outage & wfbz_occurrence & wfs_smoke_day ~ 'Wildfire, Smoke, and Outage',
      TRUE ~ NA
    )
  ) %>%
  na.omit() %>% 
  group_by(event, day) %>% 
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
  )
p
ggsave(plot = p, filename = here('figures/time_series_combos.png'), width = 6, height = 3, scale = .6)
