###
# 00 - Setup: libraries, paths, country groups, helpers
# 260611
###

if (!require("pacman")) install.packages("pacman"); library(pacman)
p_load(data.table)
p_load(magrittr)
p_load(stringr)
p_load(fixest)
p_load(ggplot2)
p_load(scales)
p_load(arrow)
p_load(countrycode)

# 0 - pinned versions ----

# fixest >= 0.11.0 ships the `mem.clean` argument used by 03-estimate.R
# on the balanced extensive-margin panel; earlier versions silently ignore it
# and can blow up memory on Colombian DIAN-scale data.
if (packageVersion("fixest") < "0.11.0") {
  stop("This exercise needs fixest >= 0.11.0. Run install.packages('fixest').")
}

# 0 - settings ----

`%nin%` <- Negate(`%in%`)

options(
  datatable.print.nrows = 30,
  datatable.print.class = TRUE
)

# 1 - paths ----

dir.create("input/raw", showWarnings = FALSE, recursive = TRUE)
dir.create("input/clean", showWarnings = FALSE, recursive = TRUE)
dir.create("output/figures", showWarnings = FALSE, recursive = TRUE)
dir.create("output/tables", showWarnings = FALSE, recursive = TRUE)
dir.create("temp", showWarnings = FALSE, recursive = TRUE)

# 2 - country groups ----

# Treated destination
VEN <- "VEN"

# Placebos: regional neighbours and the largest non-regional destination
PLACEBO_DESTINATIONS <- c(
  "ECU",  # Ecuador
  "PER",  # Peru
  "MEX",  # Mexico
  "USA"   # United States
)

# Sample restriction: only manufactured exports
# HS chapters 28-96 (chemicals through misc manufactured articles)
MANUFACTURED_HS_RANGE <- c("28", "96")

# Treatment break --- Maduro currency consolidation + foreign-exchange controls.
# DANE export catalog 472 publishes from 2011 on, so the pre-period starts 2011.
TREATMENT_YEAR <- 2014L
PRE_YEARS  <- 2011:2013
POST_YEARS <- 2014:2019

# 3 - helpers ----

is_manufactured <- function(hs6) {
  chap <- substr(hs6, 1, 2)
  chap >= MANUFACTURED_HS_RANGE[1] & chap <= MANUFACTURED_HS_RANGE[2]
}

# 4 - plot palette (Flexoki, dark accents; see ~/styles/PLOTSTYLE.md) ----

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
