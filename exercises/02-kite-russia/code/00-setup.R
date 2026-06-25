###
# 00 - Setup: install KITE@release/26.05, load 2022 ICIO initial conditions,
#      country groups, sector groups, helpers
# 260625
###

if (!require("pacman")) install.packages("pacman"); library(pacman)
p_load(data.table)
p_load(magrittr)
p_load(stringr)
p_load(ggplot2)
p_load(scales)
p_load(countrycode)
p_load(remotes)

# 0 - settings ----

`%nin%` <- Negate(`%in%`)

dir.create("output/figures", showWarnings = FALSE, recursive = TRUE)
dir.create("output/tables",  showWarnings = FALSE, recursive = TRUE)
dir.create("temp/results",   showWarnings = FALSE, recursive = TRUE)

# 1 - install KITE from the pinned release ----

# Public KITE, release/26.05 (package version 26.05). Models are bare function
# symbols passed to update_equilibrium(); there is no bundled data and no
# pre-fit model object.
if (!require("KITE")) {
  message("Installing KITE@release/26.05 from GitHub (julianhinz/KITE)...")
  remotes::install_github("julianhinz/KITE", ref = "release/26.05", upgrade = "never")
  library(KITE)
}
stopifnot(exists("update_equilibrium"), exists("process_results"),
          exists("chowdhry_hinz_kamin_wanner_2022"))

# 2 - initial conditions (2022 ICIO, committed in-repo) ----

IC_PATH <- "input/initial_conditions/initial_conditions_ICIO_2022.rds"
stopifnot(file.exists(IC_PATH))
initial_conditions <- readRDS(IC_PATH)

COUNTRIES <- sort(unique(initial_conditions$trade_balance$country))
SECTORS   <- initial_conditions$trade_elasticity$sector
stopifnot(length(COUNTRIES) == 81L, length(SECTORS) == 50L,
          "RUS" %in% COUNTRIES)

# 3 - country groups (UPPERCASE ISO3, intersected with the IC's 81) ----

TARGET_RUSSIA <- "RUS"

# G7 + EU27 + EEA/CH + AUS/NZL/JPN/KOR sanctioning bloc (Feb 2022).
COALITION_G7_EU <- intersect(c(
  "DEU", "FRA", "ITA", "ESP", "NLD", "BEL", "IRL", "LUX", "PRT", "AUT", "DNK",
  "SWE", "FIN", "GRC", "POL", "CZE", "SVK", "HUN", "ROU", "BGR", "SVN", "HRV",
  "EST", "LVA", "LTU", "CYP", "MLT", "USA", "CAN", "GBR", "JPN", "KOR", "CHE",
  "NOR", "AUS", "NZL"
), COUNTRIES)

# Largest plausible circumvention hubs present in the IC.
CIRCUMVENTION_HUBS <- intersect(c("CHN", "IND", "TUR", "ARE", "KAZ"), COUNTRIES)

stopifnot(length(COALITION_G7_EU) > 30L, length(CIRCUMVENTION_HUBS) >= 5L)

# 4 - coalition_member element (country-indexed 0/1 over all 81) ----

# KITE's chowdhry_hinz_kamin_wanner_2022 model reads coalition_member from the
# (merged) inputs; we attach it to initial_conditions.
coalition_member <- data.table(
  country = COUNTRIES,
  value   = as.integer(COUNTRIES %in% COALITION_G7_EU)
)
initial_conditions$coalition_member <- coalition_member

# 5 - sector groups (real ISIC rev4 codes; verified against the IC) ----

SECTORS_ENERGY  <- c("B05", "B06", "C19")   # coal; oil & gas; refined petroleum
SECTORS_DUALUSE <- c("C26", "C28", "C29")   # electronics; machinery; vehicles
SECTORS_LUXURY  <- c("C31T33")              # furniture / other manufacturing
stopifnot(all(c(SECTORS_ENERGY, SECTORS_DUALUSE, SECTORS_LUXURY) %in% SECTORS))

# 6 - helpers ----

#' Build a gross-factor ntb_new from a baseline ntb data.table.
#'
#' Multiplies matched (origin, destination, sector) cells by `factor`
#' (a gross factor: 2.5 = +150%). Since the baseline ntb level is 1, the
#' matched cells become exactly `factor`. Stacks multiplicatively if applied
#' more than once to the same cell.
#'
#' @param ntb data.table with columns origin, destination, sector, value.
#' @param origins character vector of origin ISO3 codes.
#' @param destinations character vector of destination ISO3 codes.
#' @param sectors character vector of ICIO sector codes.
#' @param factor gross factor (>= 1): 2.5 = +150%.
#' @return a copy of `ntb` with matched cells scaled by `factor`.
set_ntb_factor <- function(ntb, origins, destinations, sectors, factor) {
  stopifnot(is.numeric(factor), length(factor) == 1L, factor >= 1)
  out <- copy(ntb)
  out[origin %in% origins & destination %in% destinations & sector %in% sectors,
      value := value * factor]
  out
}

# 7 - plot palette (Flexoki, dark accents; see ~/styles/PLOTSTYLE.md) ----

flexoki <- c(
  red     = "#D14D41",
  orange  = "#DA702C",
  yellow  = "#D0A215",
  green   = "#879A39",
  cyan    = "#3AA99F",
  blue    = "#4385BE",
  purple  = "#8B7EC8",
  magenta = "#CE5D97"
)

message("00-setup done.")
