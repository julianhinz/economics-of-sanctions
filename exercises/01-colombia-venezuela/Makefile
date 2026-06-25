.PHONY: all download clean-data clean estimate output

all: output/figures/event_study.pdf output/tables/regression.tex

# default to fast path: assume input/colombian_trade.csv.gz already exists
estimate: temp/results.rds
output: output/figures/event_study.pdf output/tables/regression.tex

# 1 - scrape DANE catalog 472 -> shareable bundle (PRE-RUN; skipped if present)
input/colombian_trade.csv.gz: code/01-download.R
	Rscript code/01-download.R

# 2 - clean the bundle into a firm x hs6 x dest x year panel
input/clean/panel.rds: code/02-clean.R code/00-setup.R input/colombian_trade.csv.gz
	Rscript code/02-clean.R

# 3 - estimate the regressions
temp/results.rds: code/03-estimate.R code/00-setup.R input/clean/panel.rds
	Rscript code/03-estimate.R

# 4 - generate plots and tables
output/figures/event_study.pdf output/tables/regression.tex: code/04-output.R code/00-setup.R temp/results.rds
	Rscript code/04-output.R

clean:
	rm -rf temp/* output/figures/* output/tables/*
