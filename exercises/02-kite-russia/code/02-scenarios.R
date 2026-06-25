###
# 02 - Alternative scenarios: extended coalition + energy lever off
# 260625
###

source("code/00-setup.R")

#' Solve one scenario and return a light result list.
#'
#' @param ntb_new gross-factor ntb data.table (see set_ntb_factor()).
#' @param coalition_vec character vector of coalition-member ISO3 codes.
#' @param label short scenario label for progress output.
#' @return list(welfare = <data.table>, info = <update_equilibrium info>).
solve_scenario <- function(ntb_new, coalition_vec, label) {
  ic <- copy(initial_conditions)
  ic$coalition_member <- data.table(
    country = COUNTRIES,
    value   = as.integer(COUNTRIES %in% coalition_vec)
  )
  cat(sprintf("Solving %s scenario...\n", label))
  result <- update_equilibrium(
    model              = chowdhry_hinz_kamin_wanner_2022,
    initial_conditions = ic,
    model_scenario     = list(ntb_new = ntb_new),
    settings           = list(verbose = 2L, tolerance = 1e-4)
  )
  if (!isTRUE(result$info$convergence)) {
    warning(sprintf("%s: convergence = %s", label, result$info$convergence))
  }
  processed <- process_results(result)
  list(welfare = processed$output$welfare_change, info = result$info)
}

# 1 - extended coalition (add circumvention hubs as sanctioners) ----

COALITION_EXTENDED <- c(COALITION_G7_EU, CIRCUMVENTION_HUBS)
ntb_extended <- copy(initial_conditions$ntb) %>%
  set_ntb_factor(COALITION_EXTENDED, TARGET_RUSSIA,      SECTORS_DUALUSE, 2.5) %>%
  set_ntb_factor(COALITION_EXTENDED, TARGET_RUSSIA,      SECTORS_LUXURY,  1.8) %>%
  set_ntb_factor(TARGET_RUSSIA,      COALITION_EXTENDED, SECTORS_ENERGY,  3.0)

saveRDS(solve_scenario(ntb_extended, COALITION_EXTENDED, "extended-coalition"),
        "temp/results/extended_coalition.rds", compress = "xz")

# 2 - energy embargo off (baseline minus the energy lever) ----

ntb_no_energy <- copy(initial_conditions$ntb) %>%
  set_ntb_factor(COALITION_G7_EU, TARGET_RUSSIA, SECTORS_DUALUSE, 2.5) %>%
  set_ntb_factor(COALITION_G7_EU, TARGET_RUSSIA, SECTORS_LUXURY,  1.8)

saveRDS(solve_scenario(ntb_no_energy, COALITION_G7_EU, "energy-off"),
        "temp/results/energy_off.rds", compress = "xz")

message("02-scenarios done.")
