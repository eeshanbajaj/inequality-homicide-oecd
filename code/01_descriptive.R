# Reproduce descriptive WDI country average relationship.
input <- "data/processed/homicide_gini_oecd_2000_2019.csv"
if (!file.exists(input)) stop("Missing ", input, "; run from repository root.")
d <- read.csv(input, stringsAsFactors = FALSE)
needed <- c("iso3c", "country", "year", "homicide_rate", "gini")
if (!all(needed %in% names(d))) stop("Required columns missing: ", paste(setdiff(needed, names(d)), collapse = ", "))
if (nrow(d) != 569 || length(unique(d$iso3c)) != 37) stop("Unexpected descriptive sample. Expected 569 observations in 37 countries.")
if (anyNA(d[, needed])) stop("Missing values in matched descriptive sample.")

by_country <- split(d, d$iso3c)
means <- do.call(rbind, lapply(by_country, function(z) {
  data.frame(iso3c = z$iso3c[1], country = z$country[1],
    avg_gini = mean(z$gini), avg_homicide_rate = mean(z$homicide_rate),
    matched_years = nrow(z))
}))
row.names(means) <- NULL
r <- cor(means$avg_gini, means$avg_homicide_rate)
fit <- lm(avg_homicide_rate ~ avg_gini, data = means)
cat(sprintf("Descriptive country correlation = %.7f (expected 0.7147414)\n", r))
cat(sprintf("OLS country slope = %.6f (expected about 0.7206)\n", coef(fit)["avg_gini"]))
if (abs(r - 0.7147414) > 1e-5 || abs(coef(fit)["avg_gini"] - 0.7206) > .001) {
  warning("Descriptive estimates differ from the originally reported results.")
}
dir.create("results/generated", recursive = TRUE, showWarnings = FALSE)
write.csv(means, "results/generated/descriptive_country_averages.csv", row.names = FALSE)
write.csv(data.frame(countries = nrow(means), observations = nrow(d),
  correlation = r, slope = unname(coef(fit)["avg_gini"]),
  r_squared = summary(fit)$r.squared),
  "results/generated/descriptive_reproduction_check.csv", row.names = FALSE)
# A simple reproducible figure. Not an exact style copy of the paper's published figure.
png("results/generated/descriptive_scatter.png", width = 1400, height = 900, res = 160)
plot(means$avg_gini, means$avg_homicide_rate,
  xlab = "Average Gini index (WDI)", ylab = "Average homicide rate per 100,000",
  main = "Income inequality and homicide across OECD countries, 2000-2019",
  pch = 19, col = "gray35")
abline(fit, lwd = 2, col = "gray20")
dev.off()
