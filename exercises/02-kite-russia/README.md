# Exercise 2 — Public KITE: Russia 2022 counterfactuals

Run macro counterfactuals of the 2022 sanctions against Russia using the
public [`julianhinz/KITE`](https://github.com/julianhinz/KITE/tree/release/26.05)
package (Chowdhry–Hinz–Kamin–Wanner 2024 implementation), 2022 ICIO initial
conditions. Mirrors the methodology of the Chowdhry et al.\ (2024) coalition
paper at smaller scope.

## Repository structure

```
exercises/02-kite-russia/
├── Makefile
├── README.md
├── code/
│   ├── 00-setup.R            # install KITE, load initial conditions
│   ├── 01-baseline.R         # 2022 baseline shock + solve
│   ├── 02-scenarios.R        # coalition + sectoral variants
│   └── 03-output.R           # welfare barchart, map, comparison table
├── input/
│   └── initial_conditions/   # initial_conditions_ICIO_2022.rds (committed in-repo)
├── output/
│   ├── figures/
│   └── tables/
└── temp/
    └── results/              # raw KITE outputs per scenario
```

## Quickstart

```bash
make             # baseline → scenarios → output
make baseline    # 01 only (warm-up)
make scenarios   # 02
make output      # 03
make clean       # nuke output/ and temp/
```

## Initial conditions

The public KITE repo does not ship initial conditions. We use a 2022 ICIO
input-output table prepared by the course instructor and **committed in this
repo** (so a fresh clone runs the exercise with no separate download):

```
input/initial_conditions/initial_conditions_ICIO_2022.rds
```

containing a named list with at least:

| element              | description                                  |
|----------------------|----------------------------------------------|
| `tariff`             | data.table(origin, destination, sector, value) — `value = 1 + tariff` |
| `ntb`                | data.table(origin, destination, sector, value) — NTB level |
| `trade_share`        | trade shares                                 |
| `value_added`        | value added per country × sector             |
| `trade_balance`      | aggregate bilateral balances                 |
| `trade_elasticity`   | sectoral trade elasticities                  |
| ...                  | (see `?update_equilibrium`)                  |

No sector aggregation: the 50 ISIC-rev4 sectors are kept as in the 2022 ICIO release.

## Scenarios

| Scenario               | Description                                                         |
|------------------------|---------------------------------------------------------------------|
| `baseline`             | G7+EU vs Russia — full 2022-style trade restriction on dual-use, defence, energy tech and CBR-style finance translated to NTBs |
| `extended_coalition`   | Add CHN, IND, TUR to the sanctioning coalition (zero diversion)     |
| `energy_off`           | Drop the energy embargo from `baseline` — show the oil-cap counterfactual |

Each is a small change on top of the baseline shock matrix. All run under
the `chowdhry_hinz_kamin_wanner_2022` model (Chowdhry et al., 2024).

## What students do in class

1. **Together** — `00-setup.R` and `01-baseline.R`: install KITE, load IC,
   encode the baseline shock, solve. Inspect `results$welfare`.
2. **Students** — `02-scenarios.R`: run the two variants, compare welfare panels.
3. **Together** — `03-output.R`: bar chart of country-level welfare, world map,
   comparison table.
4. **Discussion** — terms-of-trade vs reallocation, third-country gains,
   why the energy lever moves the numbers so much.

## References

- Chowdhry, Hinz, Kamin & Wanner (2024), *Brothers in Arms*, **Economic Policy**.
- Caliendo & Parro (2015), *NAFTA*, **RES**.
- KITE package: <https://github.com/julianhinz/KITE/tree/release/26.05>.
