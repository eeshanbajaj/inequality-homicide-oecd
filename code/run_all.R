# Run from the repository root (open inequality-homicide-oecd.Rproj in RStudio).
if (!file.exists("data/processed/homicide_gini_oecd_2000_2019.csv")) {
  stop("Please run from repository root. Open inequality-homicide-oecd.Rproj.")
}
source("code/01_descriptive.R")
source("code/02_institutional_models.R")
if (file.exists("data/processed/panel_with_both_gdp_series_569.csv")) {
  if (requireNamespace("fixest", quietly = TRUE)) {
    source("code/03_panel_models.R")
  } else message("Skipping panel models: install.packages('fixest').")
} else {
  message("Skipping panel models: add data/processed/panel_with_both_gdp_series_569.csv.")
}
if (requireNamespace("rcrbounds", quietly = TRUE)) {
  source("code/04_krauth_rcr.R")
} else {
  message("Skipping Krauth RCR: install the 'rcrbounds' package (README instructions).")
}
message("Completed available replication steps. Check outputs in results/generated/.")
