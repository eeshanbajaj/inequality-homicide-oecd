# Income inequality and homicide across OECD countries, 2000–2019

**Research replication materials — MA Economics empirical paper (ECON 899)**

This repository documents an observational study of income inequality and homicide rates across OECD countries from 2000 to 2019. Its central question is whether the positive **between-country** association also appears **within countries over time**. A related cross-country analysis examines market-income inequality, measured redistribution, and homicide. The paper does **not** claim causal identification.

## What is included

| Folder | Contents |
|---|---|
| `code/` | R scripts for descriptive analysis, institutional models, Krauth (2016) sensitivity analysis, and controlled panel and within–between models |
| `data/processed/` | Cleaned, matched World Bank panel (569 country-years, 37 countries) and the 30-country institutional dataset (351 underlying matched country-years) |
| `results/` | Exported, previously calculated institutional checks and Krauth RCR results for Appendix Table A6 |
| `paper/` | Placeholder for the final paper; no draft PDF included in this starter package |

**Current replication status:** The processed 569-observation panel with both GDP-per-capita measures is now provided, alongside the 30-country institutional sample. The original pooled, fixed-effects, and within–between specifications can be estimated without redownloading the World Bank controls. **Please run `code/run_all.R` successfully in RStudio before claiming end-to-end reproducibility.** The remaining appendix robustness scripts and final manuscript PDF are not yet included.

## Data sources and construction

- **World Bank, World Development Indicators (WDI)**: intentional homicide rate, Gini index, GDP per capita, unemployment, urban population percentage, and working-age population share. The core cleaned `homicide_gini_oecd_2000_2019.csv` file includes 569 matched country-years for 37 countries.
- **OECD Income Distribution Database (IDD)**: market-income Gini (`INC_MRKT_GINI`) and disposable-income Gini (`INC_DISP_GINI`), each converted to the 0–100 scale. Redistribution is calculated as **market Gini minus disposable Gini** (Gini points). In the institutional analysis, country-year observations have matched homicide, both OECD Gini measures, and controls. The preferred institutional sample has 30 countries with **at least five matched years** each, comprising 351 country-year records before aggregation.
- The outcome for the institutional regressions is the **country mean of `log(homicide_rate + 0.01)`**, not the log of the country mean homicide rate.
- The Gini measure in the main WDI panel is **not interchangeable** with the OECD IDD market-/disposable-income Gini measures.

See [`data/SOURCES.md`](data/SOURCES.md) for attribution and licensing links. Please consult the relevant sources' data terms before reusing the data.

## How to run in RStudio

1. Download/extract this repository and open `inequality-homicide-oecd.Rproj` in RStudio, so that the project's **root folder is the working directory**.
2. Install the ordinary R packages once:

   ```r
   install.packages(c("sandwich", "lmtest", "fixest"))
   ```
3. Run the scripts individually, or run:

   ```r
   source("code/run_all.R")
   ```

   This runs the self-contained descriptive and institutional models first. The controlled panel script runs when `data/processed/panel_with_both_gdp_series_569.csv` is present. RCR runs **only if** Krauth's package is installed (instructions below).
4. New tables and checks are written to `results/generated/`. Supplied original result CSVs stay in `results/`.

### Krauth (2016) RCR package

The RCR estimator relies on Brian Krauth's `rcrbounds` R wrapper and its Python dependency. One-time installation in the RStudio Console:

```r
install.packages("remotes")
remotes::install_github("bvkrauth/rcr", subdir = "r/rcrbounds")
library(rcrbounds)
rcrbounds::install_rcrpy()
```

After installation, run:

```r
source("code/04_krauth_rcr.R")
```

This reproduces the seven **illustrative** relative-correlation scenarios used for Appendix A6. The ranges are **maintained assumptions**, not estimates of the amount of omitted-variable bias. Consult Krauth (2016) for identification and inference, particularly near the estimated identification threshold.

## Main-panel GDP measures: important replication detail

`data/processed/panel_with_both_gdp_series_569.csv` includes **both** real GDP-per-capita measures, together with the original 569 observations and four other model variables:

- `gdp_pc_ppp` (and `log_gdp_pc_ppp`): World Bank `NY.GDP.PCAP.PP.KD`, constant international dollars, PPP-adjusted. **This was used in the original controlled pooled OLS and fixed-effects models**, with pooled Gini coefficient `0.086746` and R² `0.655740`.
- `gdp_per_capita` (and `log_gdp_per_capita`): World Bank `NY.GDP.PCAP.KD`, constant US dollars. **This was used in the original within–between specification**, yielding Gini coefficients `0.093750` (between) and `−0.020931` (within). The two-way fixed-effects Gini coefficient with PPP GDP was `−0.015404`.

See `results/gdp_version_regression_check.csv` for the verified comparison. You can run `source("code/03_panel_models.R")` to regenerate the main model checks. Source database values can be revised over time; the archived processed data preserve this replication version.

## Key outputs (previously verified)

- Descriptive cross-country correlation between average WDI Gini and average homicide: approximately **0.7147** (37 countries).
- Preferred institutional model (30 countries): market-income Gini **+0.08897**, redistribution **−0.08640**, R² approximately **0.6595**.
- Krauth RCR, restricting relative correlation to **[−1, 1]**: redistribution coefficient point bounds approximately **[−0.2882, −0.0588]**. For this range, the previously recorded 95% Imbens–Manski interval was **[−1.8544, −0.0070]**. These are assumption-dependent bounds, **not causal effects**.

See `results/` for the underlying exported calculations. Generated results should be compared with these files. In particular, uncertainty estimates rely on the specific method used (HC3 for the conventional institutional regressions; RCR inference for sensitivity bounds).

## Citation and paper

**Paper:** Insert the final paper citation, DOI (if any), and PDF in the `paper/` directory when finalized. This repository can be cited by its permanent GitHub URL; optionally create a tagged release or a Zenodo archive for an immutable version.

**Methods:**
- Krauth, B. (2016). *Bounding a Linear Causal Effect Using Relative Correlation Restrictions*. Journal of Econometric Methods, 5(1), 117–141. https://doi.org/10.1515/jem-2013-0013

## Reuse and scope

Data from the World Bank and OECD are subject to their **own source licenses and attribution requirements**, regardless of any license applied to the code. No code license is assigned in this starter package. Do not upload raw RStudio `.RData` files, personal notes, private accounts, or unrelated project materials.
