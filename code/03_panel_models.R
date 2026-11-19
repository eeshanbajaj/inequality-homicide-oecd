# Controlled panel models. Requires user's original 569-row *final* panel.
# NOT fully reproducible from the two processed CSVs supplied initially.
if (!requireNamespace("fixest", quietly = TRUE)) stop("Install 'fixest' first.")
input <- "data/processed/panel_with_controls_569.csv"
if (!file.exists(input)) stop("Missing exact final panel with controls: ", input)
d <- read.csv(input, stringsAsFactors = FALSE)
needed <- c("country", "iso3c", "year", "homicide_rate", "gini", "gdp_per_capita",
            "unemployment_rate", "urbanization_rate", "working_age_share")
if (!all(needed %in% names(d))) stop("Missing panel columns: ", paste(setdiff(needed, names(d)), collapse=", "))
if (nrow(d) != 569 || length(unique(d$iso3c)) != 37) stop("Expected 569 observations in 37 countries.")
if (anyNA(d[, needed])) stop("Original controlled estimation panel should have no missing model variables.")
if (any(d$gdp_per_capita <= 0)) stop("GDP per capita must be strictly positive.")
if (any(duplicated(d[c("iso3c", "year")]))) stop("Duplicate country-years.")
d$log_homicide <- log(d$homicide_rate + 0.01)
d$log_gdp_per_capita <- log(d$gdp_per_capita)
for (v in c("gini", "log_gdp_per_capita", "unemployment_rate", "urbanization_rate", "working_age_share")) {
  mu <- ave(d[[v]], d$iso3c, FUN = mean)
  d[[paste0(v,"_between")]] <- mu
  d[[paste0(v,"_within")]] <- d[[v]] - mu
}
pooled <- fixest::feols(log_homicide ~ gini + log_gdp_per_capita + unemployment_rate +
  urbanization_rate + working_age_share, data = d, cluster = ~iso3c)
fe <- fixest::feols(log_homicide ~ gini + log_gdp_per_capita + unemployment_rate +
  urbanization_rate + working_age_share | iso3c + year, data = d, cluster = ~iso3c)
wb <- fixest::feols(log_homicide ~ gini_between + gini_within +
  log_gdp_per_capita_between + log_gdp_per_capita_within +
  unemployment_rate_between + unemployment_rate_within +
  urbanization_rate_between + urbanization_rate_within +
  working_age_share_between + working_age_share_within | year,
  data = d, cluster = ~iso3c)
cat("Controlled pooled, FE, and within–between:\n")
print(fixest::etable(pooled, fe, wb, fitstat = ~n+r2+ar2))
b <- coef(wb); V <- vcov(wb, cluster=~iso3c)
contrast <- unname(b["gini_between"] - b["gini_within"])
se_contrast <- sqrt(V["gini_between", "gini_between"] + V["gini_within", "gini_within"] - 2*V["gini_between", "gini_within"])
p_norm <- 2 * pnorm(abs(contrast/se_contrast), lower.tail=FALSE)
checks <- data.frame(model = c("pooled", "country_year_FE", "within_between"),
  n = c(nobs(pooled), nobs(fe), nobs(wb)),
  gini_effect = c(unname(coef(pooled)["gini"]), unname(coef(fe)["gini"]), unname(b["gini_between"])),
  secondary_within_gini = c(NA, NA, unname(b["gini_within"])))
cat(sprintf("Within minus between contrast: between - within = %.6f, SE = %.6f, normal approximation p=%.6g\n",
            contrast, se_contrast, p_norm))
dir.create("results/generated", recursive=TRUE, showWarnings=FALSE)
write.csv(checks, "results/generated/panel_model_checks.csv", row.names=FALSE)
write.csv(data.frame(difference_between_minus_within=contrast, standard_error=se_contrast, normal_approx_p=p_norm),
          "results/generated/between_within_difference.csv", row.names=FALSE)
# Original expected benchmark: pooled Gini about 0.0867, two-way FE Gini about -0.0154,
# within-between: between about +0.09375, within about -0.02093.
# If numbers differ, investigate exact data version and preprocessing before release.
