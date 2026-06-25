###
# 01 - Baseline scenario: G7+EU vs Russia, 2022-style shock
# 260625
#
# Pedagogical KITE Russia 2022 baseline -- NOT a calibrated replication of
# Chowdhry-Hinz-Kamin-Wanner (2024). Three hand-picked NTB gross factors
# (dual-use, luxury, energy) make the qualitative point: Russia worst,
# Baltics among the worst senders, EU members mildly negative.
###

source("code/00-setup.R")

# 1 - encode the baseline 2022 shock as ntb_new gross factors ----

# Keep tariffs unchanged; encode the package as NTB gross factors between the
# coalition and Russia. Baseline ntb is 1, so factor 2.5 == +150%.
ntb_new <- copy(initial_conditions$ntb) %>%
  set_ntb_factor(COALITION_G7_EU, TARGET_RUSSIA,   SECTORS_DUALUSE, 2.5) %>%  # +150%
  set_ntb_factor(COALITION_G7_EU, TARGET_RUSSIA,   SECTORS_LUXURY,  1.8) %>%  #  +80%
  set_ntb_factor(TARGET_RUSSIA,   COALITION_G7_EU, SECTORS_ENERGY,  3.0)      # +200%

# 2 - solve ----

cat("Solving baseline scenario...\n")
result <- update_equilibrium(
  model              = chowdhry_hinz_kamin_wanner_2022,   # bare symbol
  initial_conditions = initial_conditions,                # carries coalition_member
  model_scenario     = list(ntb_new = ntb_new),
  settings           = list(verbose = 2L, tolerance = 1e-4)
)

# Honest convergence check (TRUE / FALSE / NA).
if (!isTRUE(result$info$convergence)) {
  warning(sprintf("baseline: solver convergence = %s (criterion %.2e, %d iters)",
                  result$info$convergence, result$info$criterion,
                  result$info$iterations))
}

# 3 - post-process + persist a light result ----

processed <- process_results(result)
welfare   <- processed$output$welfare_change

saveRDS(list(welfare = welfare, info = result$info),
        "temp/results/baseline.rds", compress = "xz")

# 4 - quick look (gross factor: value < 1 is a welfare loss) ----

print(welfare[order(welfare_change)][c(1:5, (.N - 4):.N),
      .(country, welfare_change)])
cat("Russia welfare_change:", welfare[country == "RUS", welfare_change], "\n")

message("01-baseline done.")
