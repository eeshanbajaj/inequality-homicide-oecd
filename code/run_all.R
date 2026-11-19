# Run from the repository root (open the .Rproj file in RStudio).
if (!file.exists("data/processed/homicide_gini_oecd_2000_2019.csv")) {
  stop("Run code/run_all.R from the repository root. Open inequality-homicide-oecd.Rproj.")
}
source("code/01_descriptive.R")
source("code/02_institutional_models.R")
if (file.exists("data/processed/panel_with_controls_569.csv")) {
  if (requireNamespace("fixest", quietly = TRUE)) {
    source("code/03_panel_models.R")
  } else message("Skipping controlled panel models: install.packages('fixest')")
} else {
  message("Skipping controlled panel / within-between models: exact panel_with_controls_569.csv has not been supplied.")
}
if (requireNamespace("rcrbounds", quietly = TRUE)) {
  source("code/04_krauth_rcr.R")
} else {
  message("Skipping Krauth RCR: install Krauth's 'rcrbounds' package (see README).")
}
message("Completed all currently available replication steps.")
