# Economics of Sanctions — PSE Summer School 2026

Course module on the **economics of trade sanctions**: from firm-level customs
records to general-equilibrium counterfactuals, built around the 2014 and 2022
sanctions on Russia. Companion site: <https://sanctions.julianhinz.com>.

This repository ships the two hands-on R exercises and the compiled slide decks.

## Exercises

### `exercises/01-colombia-venezuela/` — firm-level adjustment
PPML (intensive margin) and LPM (extensive margin) estimation of the 2014–2017
Colombia → Venezuela export collapse, a sanctions-like shock seen from the
exporter's side. Data are scraped credential-free from the DANE microdata
catalog 472; for class the prepared bundle `colombian_trade.csv.gz` is
distributed separately and `make` skips the scrape when it is present.

```bash
cd exercises/01-colombia-venezuela && make    # clean → estimate → plot
```

### `exercises/02-kite-russia/` — macro counterfactuals
General-equilibrium counterfactuals of the 2022 Russia sanctions with the public
[`julianhinz/KITE`](https://github.com/julianhinz/KITE/tree/release/26.05)
package. The 2022 ICIO initial conditions ship **inside this repo**
(`exercises/02-kite-russia/input/initial_conditions/initial_conditions_ICIO_2022.rds`),
so a fresh clone runs the exercise with no separate download.

```bash
cd exercises/02-kite-russia && make           # baseline → scenarios → output
```

## Setup

R ≥ 4.0 with `data.table`, `magrittr`, `stringr`, `fixest`, `ggplot2`, `scales`,
`arrow`, `countrycode` (Ex 1) and `remotes`, `rnaturalearth`, `sf` plus
`KITE@release/26.05` (Ex 2). Packages install on first run via `pacman`; see the
[setup guide](https://sanctions.julianhinz.com/setup.html) for details.

## Slides

`slides/part1-intro-frontier.pdf`, `slides/part2-firm-level.pdf`,
`slides/part3-macro-kite.pdf` — the three compiled lecture decks.

## License

Code is released under the **MIT License** (see `LICENSE`). The lecture
material (slide PDFs) is licensed **CC BY 4.0**.
