###
# 99 - example code for KITE simulation
# 260626
###

library(pacman)
p_load(data.table)
p_load(KITE)
p_load(ggplot2)

# load calibration
calibration = readRDS("exercises/02-kite-russia/input/initial_conditions/initial_conditions_ICIO_2022.rds")
summary(calibration)
calibration$trade_share

# scenarios
## sanctions
sanctions = copy(calibration$ntb)
sanctions[, value := 1]
sanctions[destination == "RUS" & origin %in% c("FRA", "DEU", "ITA",
                                               "ESP", "GBR", "AUS",
                                               "POR", "USA", "CHN"), value := 15]
sanctions[origin == "RUS" & destination %in% c("FRA", "DEU", "ITA",
                                               "ESP", "GBR", "AUS",
                                               "POR", "USA", "CHN"), value := 15]
# View(sanctions[destination == "RUS"])

simulation_sanctions = update_equilibrium(model = caliendo_parro_2015,
                                initial_conditions = calibration,
                                model_scenario = list(ntb_change = sanctions),
                                settings = list(verbose = T))
simulation_sanctions = KITE::process_results(simulation_sanctions)

## embargo
embargo = copy(calibration$ntb)
embargo[, value := 1]
embargo[destination == "RUS" & origin != "RUS", value := 15]
embargo[origin == "RUS" & destination != "RUS", value := 15]
# View(embargo[destination == "RUS"])

simulation_embargo = update_equilibrium(model = caliendo_parro_2015,
                                initial_conditions = calibration,
                                model_scenario = list(ntb_change = embargo),
                                settings = list(verbose = T))
simulation_embargo = KITE::process_results(simulation_embargo)


# plot wage changes
plot_data = copy(simulation_embargo$output$welfare_change)
plot_data[, country := factor(country,
                              levels = simulation_embargo$output$welfare_change[order(-value)]$country)]
top10 = plot_data[order(value)][1:10, country]

plot_data[, value := (value - 1)]
View(plot_data)

plot = ggplot() +
  theme_minimal() +
  geom_point(data = plot_data[country %in% top10],
           aes(x = country, y = value, group = country)) +
  scale_y_continuous(labels = scales::percent)
plot
