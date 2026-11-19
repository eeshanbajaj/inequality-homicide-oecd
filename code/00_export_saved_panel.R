# Run *only* inside the original RStudio session where `df` was constructed.
# It exports the exact 569-row controlled estimation panel when available.
if (!exists("df", envir = .GlobalEnv, inherits = FALSE) || !is.data.frame(df)) {
  stop("Data frame `df` is not present. Open/load the original saved RStudio session.")
}
needed <- c("country", "iso3c", "year", "homicide_rate", "gini",
  "gdp_per_capita", "unemployment_rate", "urbanization_rate", "working_age_share")
if (!all(needed %in% names(df))) stop("Missing columns: ", paste(setdiff(needed,names(df)),collapse=", "))
out <- df[,needed]
if (nrow(out)!=569 || length(unique(out$iso3c))!=37) {
  stop("Expected 569 rows and 37 countries. Please confirm this is the final main paper panel.")
}
if (anyNA(out)) stop("The final estimation panel contains missing values. Please verify selection.")
write.csv(out, "panel_with_controls_569.csv", row.names=FALSE)
message("Exported panel_with_controls_569.csv into: ", getwd())
message("Move this file into data/processed/ in your GitHub project, then run code/03_panel_models.R there.")
