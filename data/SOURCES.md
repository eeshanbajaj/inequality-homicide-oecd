# Data sources, processing, and reuse

1. **World Bank, World Development Indicators (WDI)** — https://databank.worldbank.org/source/world-development-indicators / https://data.worldbank.org/
   - Intentional homicide rate (per 100,000 people); WDI Gini index. These appear in `processed/homicide_gini_oecd_2000_2019.csv`.
   - Controls in the original controlled regressions: real GDP per capita (`NY.GDP.PCAP.KD`), unemployment (`SL.UEM.TOTL.ZS`), urbanization (`SP.URB.TOTL.IN.ZS`), and working-age population share (`SP.POP.1564.TO.ZS`). Note: some earlier exploratory calculations used alternative GDP series. The final scripts use the variables documented in the paper's later empirical revision.
   - World Bank data licensing: https://www.worldbank.org/ext/en/legal/terms-conditions/datasets (typically CC BY 4.0 plus World Bank additional terms).

2. **OECD Income Distribution Database (IDD)** — https://www.oecd.org/en/data/datasets/income-and-wealth-distribution-database.html
   - Market-income Gini (`INC_MRKT_GINI`) and disposable-income Gini (`INC_DISP_GINI`). OECD measurements were converted from the 0–1 to the 0–100 scale. Redistribution in Gini points = market minus disposable Gini.
   - The 30-country processed file contains matched country averages, not raw OECD IDD downloads. Matched-year coverage is recorded in `paired_years`.
   - OECD data terms: https://www.oecd.org/en/about/terms-conditions.html

## Sampling notes

- Study period: 2000–2019.
- Main WDI homicide × WDI Gini panel: 569 matched observations from 37 OECD countries.
- Institutional cross-section: 30 countries with at least five matched country-years; 351 country-years underlying country averages.
- For institutional models, mean log homicide is the mean of year-level `log(homicide_rate + 0.01)`. Do not replace it with `log(mean(homicide_rate) + 0.01)`.
- Sample data were supplied as processed exports from the researcher's original RStudio session. They are not a guarantee that a fresh WDI/OECD download will be byte-for-byte identical, because source databases are revised.

If you add a raw-data archive later, record the exact retrieval date and source metadata. Respect the licensing terms of each provider; a source-data license should not be silently replaced with a license for the researcher's code.
