###
# 99 - examples
# 260626
###

# load packages
library(pacman)
p_load(data.table)
p_load(ggplot2)
p_load(lubridate)
p_load(stringr)
p_load(fixest)

# 0 - load the data ----
data = fread("exercises/01-colombia-venezuela/input/colombian_trade.csv.gz")
head(data)

# 1 - plot exports to different markets ----
plot_data = data[, .(value = sum(value_usd)),
                 by = .(date = paste0(year, str_pad(month, 2, "left", "0"), "01"), dest)]
plot_data[, date := ymd(date)]

plot = ggplot() +
  theme_minimal() +
  geom_line(data = plot_data[dest %in% c("FRA", "USA", "VEN")],
                             aes(x = date, y = value, group = dest, color = dest)) +
  scale_y_log10("Exports in USD") +
  scale_x_date(NULL) +
  scale_color_discrete(NULL)
plot

# 2 - firm-level regression ----
reg_data = data[, .(value = sum(value_usd),
                    kg = sum(kg)),
                by = .(nit, dest, date = paste0(year, str_pad(month, 2, "left", "0"), "01"))]
reg_data[, date := ymd(date)]

# create fixed effects
reg_data[, firm_date := paste0(nit, date)]
reg_data[, firm_dest := paste0(nit, dest)]

# create variable of interest
reg_data[, sanctions := as.integer(dest == "VEN" & date >= ymd("2015-01-01"))]

# run regression
reg = fepois(value ~ sanctions | firm_date + firm_dest, data = reg_data)
summary(reg)
