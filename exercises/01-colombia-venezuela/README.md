# Exercise 1 — Colombia → Venezuela

Estimate the firm-level effect of the Colombia–Venezuela trade collapse on
Colombian exporters, using public DANE/DIAN export microdata. Methodologically
this mirrors Crozet & Hinz (2020) and Aytun, Hinz & Özgüzel (2025) at smaller
scale: a PPML gravity intensive-margin specification plus a linear-probability
extensive-margin model, around the 2014–2017 break.

## Repository structure

```
exercises/01-colombia-venezuela/
├── Makefile
├── README.md
├── code/
│   ├── 00-setup.R         # libraries, paths, country groups
│   ├── 01-download.R      # pre-run; scrapes DANE catalog 472 -> bundle
│   ├── 02-clean.R         # pre-run; builds panel from the bundle
│   ├── 03-estimate.R      # done together in class
│   └── 04-output.R        # done together in class
├── input/                 # gitignored
│   ├── colombian_trade.csv.gz  # shareable bundle (scraped by 01)
│   ├── raw/               # DANE monthly CSVs (intermediate, from 01)
│   └── clean/             # panel.rds (produced by 02)
├── output/                # gitignored
│   ├── figures/
│   └── tables/
└── temp/                  # intermediate model objects
```

## Quickstart

```bash
make                    # full pipeline (skips 01 + 02 if data already present)
make estimate           # 03 + 04 only (recommended in class)
make clean              # nuke output/ and temp/
```

Or run scripts directly:

```bash
Rscript code/00-setup.R     # creates dirs, loads helpers
Rscript code/03-estimate.R
Rscript code/04-output.R
```

## Data — where it comes from

Colombian customs export microdata, scraped credential-free from the DANE
microdata catalog 472 (`microdatos.dane.gov.co`) by `01-download.R` into the
shareable bundle `input/colombian_trade.csv.gz`. Variables:

| Column          | Type   | Description                                |
|-----------------|--------|--------------------------------------------|
| `nit`           | chr    | exporter ID (Colombian tax ID)             |
| `hs6`           | chr    | product (HS 2017, 6-digit aggregation)     |
| `destination`   | chr    | destination country ISO3                   |
| `year`          | int    | calendar year                              |
| `month`         | int    | calendar month                             |
| `value_usd`     | dbl    | FOB value in current USD                   |
| `kg`            | dbl    | net weight in kilograms                    |

The download (`01-download.R`) and cleaning (`02-clean.R`) steps are
pre-run for the workshop — the bundle `input/colombian_trade.csv.gz` is
distributed via the course setup page, and `make` skips the scrape when it
is present. Rerun them yourself if you want fresh data.

## Method

Two specifications on a panel of firm $\times$ HS6 $\times$ destination $\times$ year,
restricted to manufactured exports (HS 28–96), to the comparison set of
destinations (Venezuela + the placebos), and to Colombian firms that ever
exported to Venezuela (the population of interest):

**Intensive margin (PPML).** Conditional on positive trade,
$$
  X_{fpdy} = \exp\big(\alpha_{fp} + \alpha_{pd} + \alpha_{py} + \beta \cdot \mathbf{1}\{d = \mathrm{VEN}\} \cdot \mathbf{1}\{y \geq 2014\}\big)\,\varepsilon_{fpdy}
$$
estimated with `fixest::fepois`.

**Extensive margin (LPM).**
$$
  \mathbf{1}\{X_{fpdy} > 0\} = \alpha_{fp} + \alpha_{pd} + \alpha_{py} + \beta \cdot \mathbf{1}\{d = \mathrm{VEN}\} \cdot \mathbf{1}\{y \geq 2014\} + \varepsilon_{fpdy}
$$
estimated with `fixest::feols` on a balanced firm-product panel.

This is a structural-gravity difference-in-differences: firm$\times$product
($\alpha_{fp}$, exporter-product quality), the bilateral gravity term
product$\times$destination ($\alpha_{pd}$) and product$\times$year
($\alpha_{py}$, multilateral resistance). The treatment varies at the
destination$\times$year level, so the bilateral term is product$\times$destination
(time-invariant) rather than product$\times$destination$\times$year — the latter
would absorb the shock. $\beta$ is identified off Venezuela against the placebo
markets within product-year.

Placebo destinations: Ecuador, Peru, Mexico, USA. We compute the
same coefficients on placebo dummies to gauge identifying variation.

## What students do in class

1. **Together** — run `03-estimate.R`, inspect the saved model objects
   (`temp/`), and discuss the FE structure.
2. **Together** — run `04-output.R`, which produces the event-study
   plot (`output/figures/event_study.pdf`), the margins decomposition
   (`output/figures/margins.pdf`), and the regression table
   (`output/tables/regression.tex`).
3. **Variation** — drop FE layers, narrow the time window, swap the
   placebo set, or restrict to a single HS section, and see what
   changes.

## References

- Crozet & Hinz (2020), *Friendly Fire*, **Economic Policy** 35(101): 97–146.
- Aytun, Hinz & Özgüzel (2025), *Shooting Down Trade*, **JEBO** 231: 106821.
- Bown & Crowley (2013), *Self-Enforcing Trade Agreements*, **AER** 103(2).
