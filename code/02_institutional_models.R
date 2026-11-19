# Reproduce the paper's four 30-country institutional models and HC3 robust SE.
# This script is self-contained with the supplied processed cross-section.
if (!requireNamespace("sandwich", quietly = TRUE) ||
    !requireNamespace("lmtest", quietly = TRUE)) {
  stop("Install required packages: install.packages(c('sandwich','lmtest'))")
}
input <- "data/processed/institutional_30_country_export.csv"
if (!file.exists(input)) stop("Missing ", input, "; run from repository root.")
d <- read.csv(input, stringsAsFactors = FALSE)
needed <- c("iso3c", "avg_log_homicide", "avg_market_gini",
  "avg_redistribution", "avg_log_gdp", "avg_unemployment",
  "avg_urbanization", "avg_working_age", "paired_years")
if (!all(needed %in% names(d))) stop("Missing columns: ", paste(setdiff(needed, names(d)), collapse=", "))
if (nrow(d) != 30 || length(unique(d$iso3c)) != 30 || sum(d$paired_years) != 351) {
  stop("Unexpected institutional sample. Expected 30 countries and 351 underlying country-years.")
}
if (anyNA(d[, needed])) stop("Institutional sample contains missing values.")

models <- list(
  "1_market_only" = lm(avg_log_homicide ~ avg_market_gini, data = d),
  "2_plus_redistribution" = lm(avg_log_homicide ~ avg_market_gini + avg_redistribution, data = d),
  "3_market_plus_controls" = lm(avg_log_homicide ~ avg_market_gini + avg_log_gdp +
    avg_unemployment + avg_urbanization + avg_working_age, data = d),
  "4_full" = lm(avg_log_homicide ~ avg_market_gini + avg_redistribution +
    avg_log_gdp + avg_unemployment + avg_urbanization + avg_working_age, data = d)
)
res <- do.call(rbind, lapply(names(models), function(nm) {
  m <- models[[nm]]
  mat <- lmtest::coeftest(m, vcov. = sandwich::vcovHC(m, type = "HC3"))
  data.frame(model = nm, term = row.names(mat),
    coefficient = unname(mat[,1]), hc3_se = unname(mat[,2]),
    t_value = unname(mat[,3]), p_value = unname(mat[,4]),
    n = nobs(m), r_squared = summary(m)$r.squared, row.names = NULL)
}))
full <- models[["4_full"]]
stopifnot(abs(unname(coef(full)["avg_market_gini"]) - 0.088966) < 1e-4,
          abs(unname(coef(full)["avg_redistribution"]) + 0.086400) < 1e-4,
          abs(summary(full)$r.squared - 0.65952) < 1e-3)
cat("Verified full institutional regression:\n")
print(res[res$model == "4_full", ], row.names = FALSE)
dir.create("results/generated", recursive = TRUE, showWarnings = FALSE)
write.csv(res, "results/generated/institutional_models_HC3.csv", row.names = FALSE)
