###
# 04 - Output: event study figure + regression table
# 260611
###

source("code/00-setup.R")

# 1 - load results ----

results <- readRDS("temp/results.rds")

# 2 - event-study figure ----

## 2.1 - extract coefficients ----

extract_event <- function(model, label) {
  coefs <- coef(model)
  ses   <- se(model)
  # fixest names the i(year, treated_dest) terms "year::2014:treated_dest";
  # pull the 4-digit year out of that.
  idx <- grepl("^year::\\d{4}", names(coefs))
  data.table(
    label = label,
    year  = as.integer(sub("^year::(\\d{4}).*", "\\1", names(coefs)[idx])),
    coef  = as.numeric(coefs[idx]),
    se    = as.numeric(ses[idx])
  )
}

event_data <- rbind(
  extract_event(results$ppml_event, "Intensive (PPML)"),
  extract_event(results$lpm_event,  "Extensive (LPM)")
)
event_data[, `:=`(lwr = coef - 1.96 * se, upr = coef + 1.96 * se)]

# Add the omitted reference period at zero
ref_row <- event_data[, .(year = 2013, coef = 0, se = NA_real_,
                          lwr = 0, upr = 0), by = label]
event_data <- rbind(event_data, ref_row)[order(label, year)]

## 2.2 - plot ----

p_event <- ggplot(event_data, aes(year, coef, ymin = lwr, ymax = upr,
                                  group = label, colour = label)) +
  geom_hline(yintercept = 0, linetype = "dashed", colour = "grey50") +
  geom_vline(xintercept = TREATMENT_YEAR - 0.5,
             linetype = "dotted", colour = "grey50") +
  geom_pointrange(position = position_dodge(0.4)) +
  geom_line(position = position_dodge(0.4)) +
  scale_colour_manual(values = c("Intensive (PPML)" = flexoki[["red"]],
                                 "Extensive (LPM)"  = flexoki[["blue"]])) +
  scale_x_continuous(breaks = pretty(event_data$year, n = 8)) +
  labs(x = NULL, y = "Coefficient on treated x year", colour = NULL,
       title = "Colombian exporters to Venezuela, 2011-2019",
       subtitle = "Reference year = 2013. 95% CI, clustered by firm.",
       caption = "Source: DANE customs export microdata (catalog 472), manufactured HS 28-96.") +
  theme_minimal(base_size = 11) +
  theme(legend.position = "top",
        plot.title.position = "plot",
        plot.caption.position = "plot")

ggsave("output/figures/event_study.png", p_event,
       width = 16 / 2.54, height = 10 / 2.54, dpi = 300, bg = "white")
ggsave("output/figures/event_study.pdf", p_event,
       width = 16 / 2.54, height = 10 / 2.54)
fwrite(event_data, "output/figures/event_study_data.csv")
rm(p_event)

# 3 - margins decomposition ----

margins_data <- data.table(
  margin = c("Intensive (PPML)", "Extensive (LPM)"),
  coef   = c(coef(results$ppml_main)["sanctionTRUE"],
             coef(results$lpm_main)["sanctionTRUE"]),
  se     = c(se(results$ppml_main)["sanctionTRUE"],
             se(results$lpm_main)["sanctionTRUE"])
)
margins_data[, `:=`(lwr = coef - 1.96 * se, upr = coef + 1.96 * se)]

p_margins <- ggplot(margins_data, aes(margin, coef, ymin = lwr, ymax = upr)) +
  geom_hline(yintercept = 0, linetype = "dashed", colour = "grey50") +
  geom_pointrange(colour = flexoki[["red"]]) +
  labs(x = NULL, y = "Sanction effect",
       title = "Sanction effect on Colombian exporters to Venezuela",
       subtitle = "Post-2014 average, 95% CI clustered by firm.",
       caption = "Source: DANE customs export microdata (catalog 472), manufactured HS 28-96.") +
  theme_minimal(base_size = 11) +
  theme(plot.title.position = "plot",
        plot.caption.position = "plot")

ggsave("output/figures/margins.png", p_margins,
       width = 16 / 2.54, height = 10 / 2.54, dpi = 300, bg = "white")
ggsave("output/figures/margins.pdf", p_margins,
       width = 16 / 2.54, height = 10 / 2.54)
fwrite(margins_data, "output/figures/margins_data.csv")
rm(p_margins)

# 4 - regression table ----

etable(
  results$ppml_main, results$lpm_main, results$ppml_placebo,
  tex = TRUE,
  file = "output/tables/regression.tex",
  replace = TRUE,
  headers = c("PPML (int.)", "LPM (ext.)", "PPML w/ placebos"),
  signif.code = c("***" = .01, "**" = .05, "*" = .1),
  fixef.group = list("Fixed effects" = c("nit^hs6", "nit^year", "hs6^destination^year"))
)

# 5 - log ----

message("Sample meta:")
str(results$meta)
message("04-output done.")
