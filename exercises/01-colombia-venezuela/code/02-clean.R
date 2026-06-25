###
# 02 - Clean colombian_trade.csv.gz into a firm x hs6 x dest x year panel
# 260625
#
# PRE-RUN. Reads the shareable bundle input/colombian_trade.csv.gz
# (produced by 01-download.R) and writes input/clean/panel.rds.
###

source("code/00-setup.R")

# 1 - load the bundle ----

BUNDLE <- "input/colombian_trade.csv.gz"
stopifnot(file.exists(BUNDLE))
trade <- fread(BUNDLE)

# 2 - basic cleaning ----

trade[, `:=`(
  nit         = as.character(nit),
  # keep hs6 a 6-char string: fwrite/fread would otherwise read the all-digit
  # codes back as integers, which breaks the balanced-panel join in 03.
  hs6         = str_pad(as.character(hs6), 6, side = "left", pad = "0"),
  destination = toupper(as.character(dest)),
  year        = as.integer(year),
  month       = as.integer(month),
  value_usd   = as.numeric(value_usd),
  kg          = as.numeric(kg)
)]

trade <- trade[
  !is.na(destination) & destination != "" &
  !is.na(nit) & !is.na(hs6) & !is.na(year)
]
trade <- trade[is_manufactured(hs6) & year %in% c(PRE_YEARS, POST_YEARS)]

# 3 - collapse to firm x hs6 x destination x year ----

panel <- trade[
  , .(value_usd = sum(value_usd, na.rm = TRUE),
      kg        = sum(kg,        na.rm = TRUE),
      n_months  = uniqueN(month)),
  by = .(nit, hs6, destination, year)
]

# 4 - treatment dummies ----

panel[, treated_dest := destination == VEN]
panel[, post         := year >= TREATMENT_YEAR]
panel[, sanction     := treated_dest & post]

# 5 - save ----

saveRDS(panel, "input/clean/panel.rds", compress = "xz")
message(sprintf("panel: %s rows, %s firms, %s products, %s destinations",
                format(nrow(panel), big.mark = ","),
                format(uniqueN(panel$nit), big.mark = ","),
                format(uniqueN(panel$hs6), big.mark = ","),
                format(uniqueN(panel$destination), big.mark = ",")))
message("02-clean done.")
