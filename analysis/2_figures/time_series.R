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
  scale_x_date(date_breaks = 'years', date_labels = '%b \'%y', name = '') + 
  facet_wrap(~event, ncol = 1, scales = 'free_y') + 
  theme_uw() + 
  theme(
    panel.grid.major.y = element_line(linewidth = .1, color = 'grey50'),
    axis.text.x = element_text(angle = 3*90)
  )

ggsave(filename = here('figures/time_series.png'), dpi = 300, width = 4, height = 3)
