###
# 03 - Output: welfare barchart, comparison table, sender choropleth map
# 260625
###

source("code/00-setup.R")
p_load(rnaturalearth)
p_load(sf)

# 1 - load scenarios ----

scenarios <- list(
  baseline           = readRDS("temp/results/baseline.rds"),
  extended_coalition = readRDS("temp/results/extended_coalition.rds"),
  energy_off         = readRDS("temp/results/energy_off.rds")
)

welfare <- rbindlist(lapply(names(scenarios), function(s) {
  w <- copy(scenarios[[s]]$welfare)[, .(country, value = welfare_change)]
  w[, scenario := s]
  w
}))

welfare[, group := fcase(
  country == TARGET_RUSSIA,        "Russia",
  country %in% COALITION_G7_EU,    "G7 + EU",
  country %in% CIRCUMVENTION_HUBS, "Circumvention hubs",
  default                         = "Rest of World"
)]

# 2 - barchart of welfare change by group ----

# Note: unweighted country mean within group, kept simple for teaching.
welfare_group <- welfare[
  , .(welfare_change_pct = 100 * (mean(value) - 1)),
  by = .(scenario, group)
]
welfare_group[, scenario := factor(scenario,
  levels = c("baseline", "energy_off", "extended_coalition"),
  labels = c("Baseline 2022", "Energy off", "Extended coalition"))]
welfare_group[, group := factor(group,
  levels = c("Russia", "G7 + EU", "Circumvention hubs", "Rest of World"))]

# Horizontal grouped bars (long group names), legend on top, value labels on
# the bars, gridlines suppressed in the bar direction (see PLOTSTYLE.md).
p_bar <- ggplot(welfare_group,
                aes(x = welfare_change_pct,
                    y = factor(group, levels = rev(levels(group))),
                    fill = scenario)) +
  geom_col(position = position_dodge(0.8), width = 0.7, alpha = 0.85) +
  geom_vline(xintercept = 0, colour = "grey40", linewidth = 0.3) +
  geom_text(aes(label = sprintf("%+.1f", welfare_change_pct),
                hjust = fifelse(welfare_change_pct >= 0, -0.2, 1.2)),
            position = position_dodge(0.8), size = 2.4, colour = "grey30") +
  scale_x_continuous(labels = label_percent(scale = 1, accuracy = 0.1),
                     expand = expansion(mult = c(0.12, 0.12))) +
  scale_fill_manual(values = c("Baseline 2022"      = flexoki[["blue"]],
                               "Energy off"         = flexoki[["yellow"]],
                               "Extended coalition" = flexoki[["red"]])) +
  labs(x = "Welfare change", y = NULL, fill = NULL,
       title = "Russia 2022 sanctions: welfare across scenarios",
       subtitle = "Unweighted country mean within group.",
       caption = "Source: public KITE (release/26.05), 2022 ICIO.") +
  theme_minimal(base_size = 11) +
  theme(legend.position = "top",
        plot.title.position = "plot",
        plot.caption.position = "plot",
        panel.grid.major.y = element_blank())

ggsave("output/figures/welfare_barchart.png", p_bar,
       width = 20 / 2.54, height = 10 / 2.54, dpi = 300, bg = "white")
ggsave("output/figures/welfare_barchart.pdf", p_bar,
       width = 20 / 2.54, height = 10 / 2.54)
fwrite(welfare_group, "output/figures/welfare_barchart_data.csv")
rm(p_bar)

# 3 - comparison table ----

welfare_wide <- dcast(
  welfare[country %in% c(TARGET_RUSSIA, COALITION_G7_EU)],
  country ~ scenario, value.var = "value"
)
welfare_wide[, country_name := countrycode(country, "iso3c", "country.name")]
setcolorder(welfare_wide, c("country", "country_name"))
fwrite(welfare_wide, "output/tables/welfare_comparison.csv")

welfare_top <- welfare_wide[country %in% c("RUS", "DEU", "FRA", "ITA", "USA", "GBR", "JPN")]
cat(file = "output/tables/welfare_comparison.tex",
"\\begin{tabular}{lrrr}\n\\toprule\n",
"Country & Baseline & Energy off & Extended coal. \\\\\n\\midrule\n",
paste(welfare_top[, sprintf("%s & %.4f & %.4f & %.4f \\\\\n",
        country_name, baseline, energy_off, extended_coalition)],
      collapse = ""),
"\\bottomrule\n\\end{tabular}\n")

# 4 - sender choropleth (baseline) ----

welfare_baseline_map <- welfare[
  scenario == "baseline" & country != TARGET_RUSSIA,
  .(iso_a3 = country, welfare_change_pct = 100 * (value - 1))
]

# Symmetric, squished diverging scale (red = loss, green = gain); Robinson
# projection; stripped axes; legend on the right (PLOTSTYLE.md map recipe).
cap <- max(abs(welfare_baseline_map$welfare_change_pct), na.rm = TRUE)

world <- tryCatch(ne_countries(scale = "medium", returnclass = "sf"),
                  error = function(e) NULL)

if (!is.null(world)) {
  world_dt <- merge(world, welfare_baseline_map,
                    by.x = "iso_a3_eh", by.y = "iso_a3", all.x = TRUE)
  p_map <- ggplot(world_dt) +
    geom_sf(aes(fill = welfare_change_pct), colour = "grey60", linewidth = 0.1) +
    scale_fill_gradient2(low = flexoki[["red"]], mid = "#FFFFFF",
      high = flexoki[["green"]], midpoint = 0,
      limits = c(-cap, cap), oob = scales::squish, na.value = "grey85",
      labels = label_percent(scale = 1, accuracy = 0.1), name = "Welfare\nchange") +
    coord_sf(crs = "+proj=robin") +
    labs(title = "Sender welfare losses, Russia 2022 baseline (KITE)",
         subtitle = "Per-country welfare delta from the baseline 2022 shock.",
         caption = "Source: public KITE (release/26.05), 2022 ICIO.") +
    theme_minimal(base_size = 11) +
    theme(legend.position = "right",
          plot.title.position = "plot", plot.caption.position = "plot",
          panel.grid = element_blank(),
          axis.text = element_blank(), axis.ticks = element_blank(),
          axis.title = element_blank()) +
    guides(fill = guide_colourbar(barheight = unit(3, "cm")))
  ggsave("output/figures/welfare_map.png", p_map,
         width = 20 / 2.54, height = 12 / 2.54, dpi = 300, bg = "white")
  ggsave("output/figures/welfare_map.pdf", p_map,
         width = 20 / 2.54, height = 12 / 2.54)
  rm(p_map, world_dt)
} else {
  message("rnaturalearth data unavailable; skipping choropleth.")
}

message("03-output done.")
