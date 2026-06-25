###
# 03 - Estimate firm-level sanction effects on Colombian exports
# 260625
###

source("code/00-setup.R")

# 1 - load clean panel + restrict to the analysis destinations ----

panel <- readRDS("input/clean/panel.rds")
setDT(panel)

# Scope to keep the exercise fast enough to run live in class while preserving
# the gravity DiD:
#  - destinations: Venezuela + placebo markets (the comparison set the DiD
#    needs; the full 200+ DANE destinations are not required for "VEN vs rest").
#  - firms: Colombian exporters that ever served Venezuela (the population of
#    interest). This is what shrinks the firm x product fixed effect -- the
#    binding cost in the PPML -- from ~110k to ~55k levels.
ANALYSIS_DESTS <- c(VEN, PLACEBO_DESTINATIONS)
panel <- panel[destination %in% ANALYSIS_DESTS]
panel <- panel[nit %in% unique(panel[destination == VEN, nit])]

# `dest_treat` is the categorical destination, USA as the omitted baseline,
# used only by the placebo specification.
panel[, dest_treat := relevel(factor(destination), ref = "USA")]

# 2 - intensive margin: PPML gravity ----

# Structural-gravity DiD. Fixed effects:
#   nit^hs6         firm x product  (exporter-product quality / scale)
#   hs6^destination product x dest  (the bilateral gravity term: product-
#                                    specific destination affinity / resistance)
#   hs6^year        product x year  (multilateral resistance / global demand)
# The treatment `sanction` = 1[dest = VEN] x 1[year >= 2014] varies at the
# destination x year level. The bilateral term is product x destination (time-
# invariant), NOT product x destination x year, so it does not absorb the shock;
# beta is identified off Venezuela vs the placebo markets within product-year.

ppml_main <- fepois(
  value_usd ~ sanction | nit^hs6 + hs6^destination + hs6^year,
  data = panel,
  cluster = ~nit
)

ppml_event <- fepois(
  value_usd ~ i(year, treated_dest, ref = 2013)
              | nit^hs6 + hs6^destination + hs6^year,
  data = panel,
  cluster = ~nit
)

ppml_placebo <- fepois(
  value_usd ~ i(dest_treat, post)
              | nit^hs6 + hs6^destination + hs6^year,
  data = panel,
  cluster = ~nit
)

# 3 - extensive margin: LPM on a balanced firm x product x dest panel ----

# Build the balance: for every (firm, hs6) that ever exported to the comparison
# set, create one row per (destination, year) in the window.
firms_products <- unique(panel[, .(nit, hs6)])
destinations   <- ANALYSIS_DESTS
years          <- c(PRE_YEARS, POST_YEARS)

balanced <- CJ(
  nit_hs6     = paste0(firms_products$nit, "::", firms_products$hs6),
  destination = destinations,
  year        = years
)
balanced[, `:=`(
  nit = sub("::.*", "", nit_hs6),
  hs6 = sub(".*::", "", nit_hs6)
)]
balanced[, nit_hs6 := NULL]

balanced <- panel[
  balanced,
  on = .(nit, hs6, destination, year)
][, exporting := as.integer(!is.na(value_usd))]

balanced[, treated_dest := destination == VEN]
balanced[, post         := year >= TREATMENT_YEAR]
balanced[, sanction     := treated_dest & post]

# LPM on the extensive margin --- one observation per (firm, product, dest, year)
lpm_main <- feols(
  exporting ~ sanction | nit^hs6 + hs6^destination + hs6^year,
  data = balanced,
  cluster = ~nit,
  mem.clean = TRUE
)

lpm_event <- feols(
  exporting ~ i(year, treated_dest, ref = 2013)
              | nit^hs6 + hs6^destination + hs6^year,
  data = balanced,
  cluster = ~nit,
  mem.clean = TRUE
)

# 4 - save ----

results <- list(
  ppml_main    = ppml_main,
  ppml_event   = ppml_event,
  ppml_placebo = ppml_placebo,
  lpm_main     = lpm_main,
  lpm_event    = lpm_event,
  meta = list(
    n_firms        = uniqueN(panel$nit),
    n_products     = uniqueN(panel$hs6),
    n_destinations = uniqueN(panel$destination),
    treatment_year = TREATMENT_YEAR
  )
)
saveRDS(results, "temp/results.rds", compress = "xz")

message("03-estimate done.")
