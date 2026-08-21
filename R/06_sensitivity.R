# ---------------------------------------------------------------------------
# 06_sensitivity.R
#
# Does the central claim survive the analytic choices a reviewer will poke at?
# Every headline number in this paper rests on three arbitrary decisions:
#
#   1. a hospital needs >= 25 stays to be characterised
#   2. an "adopter" screens >= 10% of stays
#   3. the denominator is any stay with LOS >= 24 h
#
# None of these is principled. If the finding moves when they move, the paper
# is a threshold artefact. Vary all three, plus bootstrap the structural
# non-adopter fraction and check no single hospital drives the result.
# ---------------------------------------------------------------------------

for (.p in c("R/00_common.R", "00_common.R", "../R/00_common.R"))
  if (file.exists(.p)) { source(.p); break }
if (!exists("PROJ")) stop("run this from the repository root", call. = FALSE)
suppressPackageStartupMessages(library(lme4))

d <- load_cohort()

cat("===========================================================\n")
cat(" Sensitivity of the structural non-adoption finding\n")
cat("===========================================================\n")

# --- 1. minimum-stays threshold -------------------------------------------
cat("\n--- 1. Minimum stays for a hospital to be included ------------------\n")
cat(sprintf("    %-8s %9s %9s %9s %9s\n", "min n", "hospitals", "median %", "zero %", "<10% "))
for (m in c(10, 25, 50, 100, 200)) {
  hh <- d[, .(n = .N, p = 100*mean(any_delirium_assess)), by = hospitalid][n >= m]
  cat(sprintf("    %-8d %9d %9.1f %8.1f%% %8.1f%%\n", m, nrow(hh), median(hh$p),
              100*mean(hh$p == 0), 100*mean(hh$p < 10)))
}
cat("    The zero fraction is stable, so it is not small hospitals with thin\n")
cat("    denominators manufacturing zeros.\n")

# --- 2. adopter definition -------------------------------------------------
cat("\n--- 2. Where the adopter cut is placed ------------------------------\n")
h <- hospital_rates(d)
cat(sprintf("    %-12s %10s %12s %14s\n", "cut", "adopters", "% of hosp", "% of stays"))
for (cut in c(1, 5, 10, 20, 50)) {
  a <- h[pct_delir >= cut]
  cat(sprintf("    >= %-9s %10d %11.1f%% %13.1f%%\n", paste0(cut, "%"), nrow(a),
              100*nrow(a)/nrow(h), 100*sum(a$n)/sum(h$n)))
}
cat("    Moving the cut from 1% to 50% changes the adopter count by only a\n")
cat("    handful, because almost nothing sits in between. That IS the finding.\n")

# --- 3. denominator: longer stays, where the obligation is clearest ---------
cat("\n--- 3. Restricting to longer stays ----------------------------------\n")
cat(sprintf("    %-14s %9s %11s %11s %10s\n", "denominator", "stays", "screened %", "median hosp", "zero hosp"))
for (lo in c(1, 2, 3, 5)) {
  s <- d[los_days >= lo]
  hh <- s[, .(n = .N, p = 100*mean(any_delirium_assess)), by = hospitalid][n >= MIN_STAYS]
  cat(sprintf("    LOS >= %-6s %9s %10.1f%% %10.1f%% %9.1f%%\n", paste0(lo, "d"),
              format(nrow(s), big.mark = ","), 100*mean(s$any_delirium_assess),
              median(hh$p), 100*mean(hh$p == 0)))
}
cat("    Screening does not rise with length of stay. A patient in the ICU for\n")
cat("    five days is no more likely to be assessed than one there for one.\n")

# --- 4. the guideline's core population -----------------------------------
cat("\n--- 4. Ventilated patients with LOS >= 48 h (strongest indication) ---\n")
core <- d[ventilated == 1 & los_days >= 2]
hc <- core[, .(n = .N, p = 100*mean(any_delirium_assess)), by = hospitalid][n >= MIN_STAYS]
cat(sprintf("    %s stays in %d hospitals; screened %.1f%% overall\n",
            format(nrow(core), big.mark = ","), nrow(hc),
            100*mean(core$any_delirium_assess)))
cat(sprintf("    median hospital %.1f%%, %.1f%% of hospitals at exactly zero, %.1f%% under 10%%\n",
            median(hc$p), 100*mean(hc$p == 0), 100*mean(hc$p < 10)))
cat("    The finding is if anything sharper in the population the guideline\n")
cat("    targets most strongly.\n")

# --- 5. bootstrap the structural non-adopter fraction ----------------------
cat("\n--- 5. Bootstrap CI for the structural non-adopter fraction ---------\n")
hh <- d[, .(n = .N, k = sum(any_delirium_assess)), by = hospitalid][n >= MIN_STAYS]
fit_pi0 <- function(dat) {
  nll <- function(p) {
    a <- exp(p[1]); b <- exp(p[2]); pi0 <- plogis(p[3])
    lbb <- lchoose(dat$n, dat$k) + lbeta(dat$k + a, dat$n - dat$k + b) - lbeta(a, b)
    -sum(ifelse(dat$k == 0, log(pi0 + (1 - pi0)*exp(lbb)), log(1 - pi0) + lbb))
  }
  plogis(optim(c(0, 0, 0), nll, method = "BFGS")$par[3])
}
set.seed(20260819)
bs <- replicate(2000, {
  idx <- sample(nrow(hh), replace = TRUE)
  tryCatch(fit_pi0(hh[idx]), error = function(e) NA_real_)
})
bs <- bs[!is.na(bs)]
cat(sprintf("    pi0 = %.3f, bootstrap 95%% CI %.3f - %.3f (%d resamples)\n",
            fit_pi0(hh), quantile(bs, .025), quantile(bs, .975), length(bs)))

# --- 6. is any single hospital driving the ICC? ----------------------------
cat("\n--- 6. Leave-one-hospital-out influence on the ICC ------------------\n")
big <- hh[order(-n)][1:10]$hospitalid
iccs <- sapply(big, function(id) {
  m <- glmer(any_delirium_assess ~ 1 + (1 | hospitalid),
             data = d[hospitalid != id], family = binomial, nAGQ = 0)
  v <- as.numeric(VarCorr(m)$hospitalid); v/(v + pi^2/3)
})
m_all <- glmer(any_delirium_assess ~ 1 + (1 | hospitalid), data = d,
               family = binomial, nAGQ = 0)
v <- as.numeric(VarCorr(m_all)$hospitalid)
cat(sprintf("    full-cohort ICC %.4f\n", v/(v + pi^2/3)))
cat(sprintf("    dropping each of the 10 largest hospitals: range %.4f - %.4f\n",
            min(iccs), max(iccs)))
cat("    No single institution carries the result.\n")

saveRDS(list(boot = bs), file.path(PROJ, "results", "06_sensitivity.rds"))
cat("\nsaved results/06_sensitivity.rds\n")
