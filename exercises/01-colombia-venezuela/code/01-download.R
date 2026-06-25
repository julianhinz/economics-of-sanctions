###
# 01 - Scrape DANE catalog 472 export microdata -> colombian_trade.csv.gz
# 260625
#
# PRE-RUN. Produces the shareable bundle input/colombian_trade.csv.gz.
# The Makefile detects that file and SKIPS this script when it is present.
# Adapted from julianhinz/global-firm-trade (Colombia/code/download.R).
#
# DANE export catalog 472 (credential-free):
#   http://microdatos.dane.gov.co/catalog/472/get_microdata
# Export schema (catalog 472): FECH (YYMM), COD_PAI4 (ISO3 destination),
# POSAR (10-digit HS), FOBDOL (FOB USD), PNK (net kg), NIT (exporter id),
# RAZ_SIAL (exporter name). Year = 2000 + FECH %/% 100; month = FECH %% 100.
###

source("code/00-setup.R")

p_load(rvest)
p_load(httr)
p_load(R.utils)

# 0 - settings ----

OUT_FILE   <- "input/colombian_trade.csv.gz"
CATALOG    <- "http://microdatos.dane.gov.co/catalog/472/get_microdata"
KEEP_YEARS <- 2010:2019

if (file.exists(OUT_FILE)) {
  message(sprintf("%s already present -- skipping scrape.", OUT_FILE))
  quit(save = "no", status = 0)
}

dir.create("input/raw", showWarnings = FALSE, recursive = TRUE)
dir.create("temp",      showWarnings = FALSE, recursive = TRUE)

# 1 - discover the per-year export zips ----

# DANE serves the catalog page over a host whose cert does not validate; use an
# insecure connection (matches the upstream scraper).
html <- httr::with_config(
  config = config(ssl_verifypeer = 0L, ssl_verifyhost = 0L),
  expr   = read_html(CATALOG)
)

file_names <- html %>% html_elements("input") %>% html_attr("onclick") %>%
  str_extract_all("Expo_.*(?=\\.zip)") %>% unlist()
file_links <- html %>% html_elements("input") %>% html_attr("onclick") %>%
  str_extract_all("https.*\\b") %>% unlist()

available <- unique(data.table(file_names, file_links))

# Restrict to the years we model.
available <- available[
  as.integer(str_extract(file_names, "\\d{4}")) %in% KEEP_YEARS
]
stopifnot(nrow(available) > 0)

# 2 - download + unzip two levels (yearly zip -> monthly zips -> CSV) ----
#
# Archive layout (catalog 472): the yearly zip extracts to an `Expo_YYYY/`
# subdirectory of monthly zips (`Enero.zip`, ...); each monthly zip holds a
# `.csv` (Latin-1, comma-separated) alongside `.txt`/`.dta` we ignore.

for (i in seq_len(nrow(available))) {
  nm  <- available$file_names[i]
  lnk <- available$file_links[i]
  outdir <- file.path("input/raw", nm)
  if (dir.exists(outdir) && length(list.files(outdir, pattern = "\\.csv\\.gz$"))) {
    message(sprintf(" - %s already unpacked, skipping", nm)); next
  }
  dir.create(outdir, showWarnings = FALSE, recursive = TRUE)

  zip_path <- file.path("temp", paste0(nm, ".zip"))
  Sys.sleep(sample(5:15, 1))
  message(sprintf(" - downloading %s", nm))
  download.file(lnk, destfile = zip_path, method = "curl", extra = "--insecure",
                headers = c("User-Agent" = "Mozilla/5.0 (compatible)"))

  # level 1: outer zip -> monthly zips (inside an Expo_YYYY/ subdir)
  scratch <- file.path("temp", paste0(nm, "_x"))
  unlink(scratch, recursive = TRUE); dir.create(scratch, recursive = TRUE)
  unzip(zip_path, exdir = scratch)

  # level 2: each monthly zip -> its .csv member, flattened into outdir
  monthly <- list.files(scratch, pattern = "\\.zip$", recursive = TRUE,
                        full.names = TRUE)
  for (mz in monthly) {
    csvs <- grep("\\.csv$", unzip(mz, list = TRUE)$Name,
                 ignore.case = TRUE, value = TRUE)
    if (length(csvs)) unzip(mz, files = csvs, exdir = outdir, junkpaths = TRUE)
  }

  # gzip the extracted CSVs
  for (f in list.files(outdir, pattern = "\\.csv$", full.names = TRUE)) {
    gzip(f, overwrite = TRUE)
  }

  unlink(scratch, recursive = TRUE)
  file.remove(zip_path)
}

# 3 - parse Latin-1 CSVs, normalise schema, filter manufactured 28-96 ----

csv_files <- list.files("input/raw", pattern = "\\.csv\\.gz$",
                        recursive = TRUE, full.names = TRUE)
stopifnot(length(csv_files) > 0)

# Some monthly files use a decimal COMMA (e.g. "191,63", ",35"), others a
# decimal point. Normalise comma->point before coercion so FOBDOL/PNK don't
# silently become NA. (No thousands separators occur in this catalog.)
num <- function(x) as.numeric(gsub(",", ".", as.character(x), fixed = TRUE))

read_one <- function(f) {
  dt <- fread(f, encoding = "Latin-1", showProgress = FALSE)
  setnames(dt, toupper(names(dt)))                      # DANE headers are upper
  need <- c("FECH", "COD_PAI4", "POSAR", "FOBDOL", "PNK", "NIT", "RAZ_SIAL")
  miss <- setdiff(need, names(dt))
  if (length(miss)) { warning(sprintf("%s missing %s", basename(f),
                                      paste(miss, collapse = ","))); return(NULL) }
  out <- dt[, .(
    nit       = as.character(NIT),
    raz_sial  = as.character(RAZ_SIAL),
    hs10      = str_pad(as.character(POSAR), 10, "left", "0"),
    dest      = toupper(as.character(COD_PAI4)),
    fech      = as.integer(FECH),
    value_usd = num(FOBDOL),
    kg        = num(PNK)
  )]
  out[, `:=`(year = 2000L + fech %/% 100L, month = fech %% 100L,
             hs6 = substr(hs10, 1, 6))]
  out[is_manufactured(hs6) & year %in% KEEP_YEARS,
      .(nit, raz_sial, hs10, hs6, dest, year, month, value_usd, kg)]
}

colombian_trade <- rbindlist(lapply(csv_files, function(f) {
  cat(" -", basename(f), "\n"); read_one(f)
}), use.names = TRUE, fill = TRUE)

stopifnot(nrow(colombian_trade) > 0)
fwrite(colombian_trade, OUT_FILE)

message(sprintf("colombian_trade.csv.gz: %s rows, %s years (%s-%s)",
                format(nrow(colombian_trade), big.mark = ","),
                uniqueN(colombian_trade$year),
                min(colombian_trade$year), max(colombian_trade$year)))
message("01-download done.")
