# Main panel replication — verified 569-country-year dataset with both GDP series.
# Uses the EXACT GDP series from the original models:
#   Pooled controlled OLS: constant PPP GDP per capita (NY.GDP.PCAP.PP.KD).
#   Country FE and country+year FE: constant PPP GDP (NY.GDP.PCAP.PP.KD).
#   Within-between decomposition: constant USD GDP (NY.GDP.PCAP.KD).
# The values differ conceptually: this maintains reproducibility of the original estimates.
# The final manuscript should explain why the specifications use different GDP units.

if (!requireNamespace("fixest", quietly = TRUE)) {
  stop("Install the 'fixest' package first: install.packages('fixest')")
}
input <- "data/processed/panel_with_both_gdp_series_569.csv"
if (!file.exists(input)) stop("Missing data file: ", input)
d <- read.csv(input, stringsAsFactors = FALSE)
needed <- c("country", "iso3c", "year", "homicide_rate", "gini",
            "gdp_per_capita", "gdp_pc_ppp", "unemployment_rate",
            "urbanization_rate", "working_age_share")
missing <- setdiff(needed, names(d))
if (length(missing)) stop("Missing columns: ", paste(missing, collapse=", "))
if (nrow(d) != 569 || length(unique(d$iso3c)) != 37) {
  stop("Unexpected main panel: expected 569 country-years in 37 countries.")
}
if (anyNA(d[, needed])) stop("Missing model data; review dataset before proceeding.")
if (anyDuplicated(d[c("iso3c", "year")])) stop("Duplicate country-years detected.")
if (any(d$gdp_per_capita <= 0) || any(d$gdp_pc_ppp <= 0)) {
  stop("GDP values must be positive to take logs.")
}
if (any(d$homicide_rate < 0)) stop("Negative homicide rate encountered.")

d$year <- as.integer(d$year)
d$log_homicide <- log(d$homicide_rate + 0.01)
d$log_gdp_usd <- log(d$gdp_per_capita)
d$log_gdp_ppp <- log(d$gdp_pc_ppp)

# Original controlled pooled OLS — PPP-adjusted GDP.
pooled <- fixest::feols(
  log_homicide ~ gini + log_gdp_ppp + unemployment_rate +
    urbanization_rate + working_age_share,
  data = d, cluster = ~iso3c
)

# Original country and country+year FE — PPP-adjusted GDP.
country_fe <- fixest::feols(
  log_homicide ~ gini + log_gdp_ppp + unemployment_rate +
    urbanization_rate + working_age_share | iso3c,
  data = d, cluster = ~iso3c
)
country_year_fe <- fixest::feols(
  log_homicide ~ gini + log_gdp_ppp + unemployment_rate +
    urbanization_rate + working_age_share | iso3c + year,
  data = d, cluster = ~iso3c
)

# Original within-between model — constant-USD GDP, country means and
# deviations calculated from the available matched country-years.
for (v in c("gini", "log_gdp_usd", "unemployment_rate", "urbanization_rate", "working_age_share")) {
  country_mean <- ave(d[[v]], d$iso3c, FUN = mean)
  d[[paste0(v, "_between")]] <- country_mean
  d[[paste0(v, "_within")]] <- d[[v]] - country_mean
}
wb <- fixest::feols(
  log_homicide ~
    gini_between + gini_within +
    log_gdp_usd_between + log_gdp_usd_within +
    unemployment_rate_between + unemployment_rate_within +
    urbanization_rate_between + urbanization_rate_within +
    working_age_share_between + working_age_share_within | year,
  data = d, cluster = ~iso3c
)

cat("Main models (pooled/FE PPP GDP; within-between constant-USD GDP):\n")
print(fixest::etable(pooled, country_fe, country_year_fe, wb,
                    fitstat = ~n+r2+ar2))

b <- coef(wb)
V <- vcov(wb, cluster = ~iso3c)
contrast <- unname(b["gini_between"] - b["gini_within"])
contrast_se <- sqrt(V["gini_between", "gini_between"] +
                    V["gini_within", "gini_within"] -
                    2 * V["gini_between", "gini_within"])
p_norm <- 2 * pnorm(abs(contrast / contrast_se), lower.tail = FALSE)

check <- data.frame(
  model = c("controlled_pooled_ppp", "country_FE_ppp", "country_year_FE_ppp", "within_between_usd"),
  gdp_indicator = c(rep("NY.GDP.PCAP.PP.KD", 3), "NY.GDP.PCAP.KD"),
  observations = c(nobs(pooled), nobs(country_fe), nobs(country_year_fe), nobs(wb)),
  gini_coefficient = c(
    unname(coef(pooled)["gini"]),
    unname(coef(country_fe)["gini"]),
    unname(coef(country_year_fe)["gini"]),
    unname(b["gini_between"])
  ),
  within_gini_coefficient = c(NA, NA, NA, unname(b["gini_within"])),
  r_squared = c(as.numeric(fixest::r2(pooled, "r2")),
                as.numeric(fixest::r2(country_fe, "r2")),
                as.numeric(fixest::r2(country_year_fe, "r2")),
                as.numeric(fixest::r2(wb, "r2")))
)

# Halt if values no longer match the paper (using rounding tolerance).
stopifnot(
  abs(check$gini_coefficient[1] - 0.086745865) < 1e-4,
  abs(check$r_squared[1] - 0.655740115) < 1e-4,
  abs(check$gini_coefficient[2] + 0.013591) < 1e-4,
  abs(check$gini_coefficient[3] + 0.015404) < 1e-4,
  abs(check$gini_coefficient[4] - 0.093749506) < 1e-4,
  abs(check$within_gini_coefficient[4] + 0.020931053) < 1e-4
)
cat("\nAll key Gini coefficients match the originally reported values.\n")
print(check, row.names = FALSE)
cat(sprintf("Between minus within: %.6f (SE %.6f; normal-approximation p %.6g)\n",
            contrast, contrast_se, p_norm))

dir.create("results/generated", recursive = TRUE, showWarnings = FALSE)
write.csv(check, "results/generated/panel_model_checks.csv", row.names = FALSE)
write.csv(data.frame(
  difference_between_minus_within = contrast,
  standard_error = contrast_se,
  normal_approx_p = p_norm
), "results/generated/between_within_difference.csv", row.names = FALSE)
