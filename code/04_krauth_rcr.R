# Krauth (2016) RCR bounds, original 30-country dataset, 7 assumption scenarios.
# Requires the author's R wrapper and installed Python dependency; see README.
if (!requireNamespace("rcrbounds", quietly = TRUE)) {
 stop("Krauth RCR package not installed; see README installation instructions.")
}
input <- "data/processed/institutional_30_country_export.csv"
if (!file.exists(input)) stop("Missing ", input)
d <- read.csv(input, stringsAsFactors=FALSE)
needed <- c("iso3c", "avg_log_homicide", "avg_market_gini",
  "avg_redistribution", "avg_log_gdp", "avg_unemployment",
  "avg_urbanization", "avg_working_age", "paired_years")
if (!all(needed %in% names(d))) stop("Required institutional columns absent.")
if (nrow(d)!=30 || length(unique(d$iso3c))!=30 || sum(d$paired_years)!=351) {
 stop("Sample mismatch; expected 30 countries, 351 matched country-years.")
}
if (anyNA(d[,needed])) stop("Missing institutional values.")
formula <- avg_log_homicide ~ avg_redistribution | avg_market_gini +
  avg_log_gdp + avg_unemployment + avg_urbanization + avg_working_age
ols <- lm(avg_log_homicide ~ avg_redistribution + avg_market_gini +
  avg_log_gdp + avg_unemployment + avg_urbanization + avg_working_age, data=d)
stopifnot(abs(unname(coef(ols)["avg_redistribution"]) + 0.0864) < 1e-4)
scenarios <- data.frame(
  scenario = c("lambda = 0 (OLS)", "0 to 0.25", "0 to 0.5", "0 to 1",
               "-0.25 to 0.25", "-0.5 to 0.5", "-1 to 1"),
  lambda_low = c(0,0,0,0,-.25,-.5,-1),
  lambda_high = c(0,.25,.5,1,.25,.5,1),
  stringsAsFactors=FALSE)
get_par <- function(fit, p) {
  cf <- coef(fit)
  if (p %in% names(cf)) unname(cf[[p]]) else NA_real_
}
results <- vector("list", nrow(scenarios))
full_fit <- NULL
for (i in seq_len(nrow(scenarios))) {
  sc <- scenarios[i,]
  cat("Krauth RCR scenario:", sc$scenario, "\n")
  fit <- rcrbounds::rcr(formula, data=d,
    rc_range=c(sc$lambda_low,sc$lambda_high))
  int <- confint(fit, parm="effect", citype="Imbens-Manski")
  ci <- as.numeric(int[1,])
  results[[i]] <- data.frame(scenario=sc$scenario,
    lambda_low=sc$lambda_low, lambda_high=sc$lambda_high,
    effect_low=get_par(fit,"effectL"), effect_high=get_par(fit,"effectH"),
    lambda_at_zero=get_par(fit,"rc0"), ci_low=ci[1], ci_high=ci[2])
  if (sc$lambda_low == -1 && sc$lambda_high == 1) full_fit <- fit
}
table_a6 <- do.call(rbind, results)
dir.create("results/generated", recursive=TRUE, showWarnings=FALSE)
write.csv(table_a6,"results/generated/A6_Krauth_RCR_bounds.csv", row.names=FALSE)
if (!is.null(full_fit)) {
 cat("\nFull [−1, 1] RCR summary (includes conservative CI):\n")
 print(summary(full_fit))
 p_zero <- rcrbounds::effect_test(full_fit, h0=0)
 print(p_zero)
 write.csv(data.frame(lambda_inf=get_par(full_fit,"rcInf"),
    effect_inf=get_par(full_fit,"effectInf"), lambda_at_zero=get_par(full_fit,"rc0"),
    p_value_zero_coefficient=unname(p_zero)),
    "results/generated/A6_RCR_diagnostics.csv",row.names=FALSE)
}
# Note: These point bounds depend on relative-correlation restrictions and do not identify causal effects.
