.PHONY: all baseline scenarios output clean

all: output/figures/welfare_barchart.pdf output/tables/welfare_comparison.tex

baseline:  temp/results/baseline.rds
scenarios: temp/results/extended_coalition.rds temp/results/energy_off.rds
output:    output/figures/welfare_barchart.pdf output/tables/welfare_comparison.tex

# 0/1 - setup + baseline solve
temp/results/baseline.rds: code/00-setup.R code/01-baseline.R \
                          input/initial_conditions/initial_conditions_ICIO_2022.rds
	Rscript code/01-baseline.R

# 2 - alternative scenarios
temp/results/extended_coalition.rds temp/results/energy_off.rds: \
	code/02-scenarios.R temp/results/baseline.rds
	Rscript code/02-scenarios.R

# 3 - plots and tables
output/figures/welfare_barchart.pdf output/tables/welfare_comparison.tex: \
	code/03-output.R \
	temp/results/baseline.rds temp/results/extended_coalition.rds temp/results/energy_off.rds
	Rscript code/03-output.R

clean:
	rm -rf temp/* output/figures/* output/tables/*
