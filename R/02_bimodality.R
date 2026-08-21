# ---------------------------------------------------------------------------
# 02_bimodality.R
#
# Step 1 of the analysis plan: is the between-hospital distribution of delirium
# screening a GRADIENT or a near-binary adopt / not-adopt split?
#
# This is a framing decision, not a decoration. A gradient says "hospitals vary
# in quality of screening"; a two-point mixture says "hospitals vary in whether
# a screening protocol exists at all", and the intervention implied is
# completely different.
#
# Three independent lines of evidence:
#   1. Hartigan dip test        -- rejects unimodality without assuming a shape
#   2. Gaussian mixture (mclust)-- does BIC prefer >1 component?
#   3. Mass at the boundaries   -- what share of hospitals sit at ~0 or ~100?
# ---------------------------------------------------------------------------

for (.p in c("R/00_common.R", "00_common.R", "../R/00_common.R"))
  if (file.exists(.p)) { source(.p); break }
if (!exists("PROJ")) stop("run this from the repository root", call. = FALSE)
suppressPackageStartupMessages({ library(diptest); library(mclust) })

d <- load_cohort()
h <- hospital_rates(d)

cat("===========================================================\n")
cat(" Between-hospital distribution of delirium-screening rate\n")
cat(sprintf(" %d hospitals with >= %d qualifying stays\n", nrow(h), MIN_STAYS))
cat("===========================================================\n\n")

describe <- function(x, lab) {
  cat(sprintf("%s\n", lab))
  cat(sprintf("  median %.1f%%  IQR %.1f-%.1f  range %.1f-%.1f  mean %.1f\n",
              median(x), quantile(x,.25), quantile(x,.75), min(x), max(x), mean(x)))
  cat(sprintf("  at exactly 0%%: %d (%.1f%%)   <10%%: %d (%.1f%%)   ",
              sum(x == 0), 100*mean(x == 0), sum(x < 10), 100*mean(x < 10)))
  cat(sprintf(">90%%: %d (%.1f%%)\n", sum(x > 90), 100*mean(x > 90)))
  cat(sprintf("  in the middle (10-90%%): %d (%.1f%%)\n\n",
              sum(x >= 10 & x <= 90), 100*mean(x >= 10 & x <= 90)))
}
describe(h$pct_delir, "DELIRIUM screening")
describe(h$pct_sed,   "SEDATION screening")
describe(h$pct_pain,  "PAIN screening")

# --- 1. Hartigan dip test --------------------------------------------------
cat("--- Hartigan dip test for unimodality -------------------------------\n")
cat("    H0: the distribution is unimodal. Rejection => at least two modes.\n\n")
dip_res <- list()
for (v in c(delirium = "pct_delir", sedation = "pct_sed", pain = "pct_pain")) {
  x <- h[[v]]
  dt <- dip.test(x, simulate.p.value = TRUE, B = 10000)
  dip_res[[v]] <- dt
  cat(sprintf("  %-9s D = %.4f, p = %.4f  %s\n", names(which(c(delirium="pct_delir",
      sedation="pct_sed", pain="pct_pain") == v)), dt$statistic, dt$p.value,
      ifelse(dt$p.value < 0.05, "<- unimodality REJECTED", "unimodal not rejected")))
}

# The dip test is conservative against a distribution with a hard point mass at
# zero, so report the rate among hospitals that screen at all as a sensitivity.
nz <- h[pct_delir > 0]$pct_delir
cat(sprintf("\n  sensitivity, the %d hospitals with any screening at all:\n", length(nz)))
dtz <- dip.test(nz, simulate.p.value = TRUE, B = 10000)
cat(sprintf("    D = %.4f, p = %.4f   median %.1f%%, IQR %.1f-%.1f\n",
            dtz$statistic, dtz$p.value, median(nz), quantile(nz,.25), quantile(nz,.75)))

# --- 2. Gaussian mixture ---------------------------------------------------
cat("\n--- Gaussian finite mixture, BIC over 1-4 components ----------------\n")
set.seed(20260819)
mc <- Mclust(h$pct_delir, G = 1:4, verbose = FALSE)
bic <- mclustBIC(h$pct_delir, G = 1:4, verbose = FALSE)
cat(sprintf("    best model: %s with G = %d components\n", mc$modelName, mc$G))
print(round(summary(bic), 1))
if (mc$G > 1) {
  cat("\n    component means (%), variances, and mixing weights:\n")
  for (k in seq_len(mc$G))
    cat(sprintf("      k=%d  mean %6.1f  sd %5.1f  weight %.3f  n~%3.0f\n", k,
                mc$parameters$mean[k],
                sqrt(mc$parameters$variance$sigmasq[min(k, length(mc$parameters$variance$sigmasq))]),
                mc$parameters$pro[k], mc$parameters$pro[k]*nrow(h)))
}

# --- 2b. Zero-inflated beta-binomial ---------------------------------------
# The dip test looks for a VALLEY between two humps. With a hard point mass at
# zero there is no valley, so the dip test is the wrong instrument here and it
# under-rejects. The question that actually matters is different: is the mass
# at zero LARGER than a single continuous distribution of hospital rates could
# produce by sampling alone? A hospital with 30 stays and a true rate of 5%
# draws a zero about 21% of the time, so some zeros are noise. Fit a
# beta-binomial (one continuous rate distribution, no structural zeros) against
# a zero-inflated beta-binomial (a structural non-adopter class plus adopters)
# and compare.
cat("
--- Zero-inflated beta-binomial vs beta-binomial --------------------
")
hh <- d[, .(n = .N, k = sum(any_delirium_assess)), by = hospitalid][n >= MIN_STAYS]

nll_bb <- function(p) {
  a <- exp(p[1]); b <- exp(p[2])
  -sum(lchoose(hh$n, hh$k) + lbeta(hh$k + a, hh$n - hh$k + b) - lbeta(a, b))
}
nll_zibb <- function(p) {
  a <- exp(p[1]); b <- exp(p[2]); pi0 <- plogis(p[3])
  lbb <- lchoose(hh$n, hh$k) + lbeta(hh$k + a, hh$n - hh$k + b) - lbeta(a, b)
  -sum(ifelse(hh$k == 0, log(pi0 + (1 - pi0) * exp(lbb)), log(1 - pi0) + lbb))
}
f_bb   <- optim(c(0, 0), nll_bb, method = "BFGS")
f_zibb <- optim(c(f_bb$par, 0), nll_zibb, method = "BFGS")
lr <- 2 * (f_bb$value - f_zibb$value)
# pi0 = 0 sits on the boundary of the parameter space, so the null distribution
# is a 50:50 mixture of chi2(0) and chi2(1); halve the naive p-value.
p_lr <- 0.5 * pchisq(lr, df = 1, lower.tail = FALSE)

cat(sprintf("    beta-binomial          logLik %8.1f   BIC %7.1f
",
            -f_bb$value,   2*f_bb$value   + 2*log(nrow(hh))))
cat(sprintf("    zero-inflated beta-bin logLik %8.1f   BIC %7.1f
",
            -f_zibb$value, 2*f_zibb$value + 3*log(nrow(hh))))
cat(sprintf("    LRT chi2 = %.2f, p = %.3g (boundary-corrected)
", lr, p_lr))
a_ad <- exp(f_zibb$par[1]); b_ad <- exp(f_zibb$par[2]); pi0 <- plogis(f_zibb$par[3])
cat(sprintf("    structural non-adopter fraction = %.3f (~%.0f of %d hospitals)
",
            pi0, pi0 * nrow(hh), nrow(hh)))
cat(sprintf("    adopters ~ Beta(%.2f, %.2f), mean rate %.1f%%
",
            a_ad, b_ad, 100 * a_ad / (a_ad + b_ad)))
cat(sprintf("    both Beta shape parameters < 1 (%s), so even among adopters the
",
            ifelse(a_ad < 1 && b_ad < 1, "yes", "no")))
cat("    rate distribution is U-shaped, piling up near 0%% and 100%%.
")

# how tightly are the observed zeros pinned? a zero in a large hospital cannot
# be sampling noise
zh <- hh[k == 0]
zh[, ub := 100 * qbeta(.975, k + .5, n - k + .5)]
cat(sprintf("
    %d hospitals recorded ZERO screens across %s stays
",
            nrow(zh), format(sum(zh$n), big.mark = ",")))
cat(sprintf("    their sizes: median %.0f stays (IQR %.0f-%.0f, max %.0f)
",
            median(zh$n), quantile(zh$n,.25), quantile(zh$n,.75), max(zh$n)))
cat(sprintf("    upper 95%% bound on the true rate: median %.2f%%; %d of %d bounded below 1%%
",
            median(zh$ub), sum(zh$ub < 1), nrow(zh)))

# --- 3. how much of the cohort sits in a non-screening hospital -------------
cat("\n--- Patient-level consequence ---------------------------------------\n")
cat(sprintf("    stays in hospitals screening <10%%: %s of %s (%.1f%%)\n",
            format(sum(h[pct_delir < 10]$n), big.mark = ","),
            format(sum(h$n), big.mark = ","),
            100*sum(h[pct_delir < 10]$n)/sum(h$n)))
cat(sprintf("    stays in hospitals screening >90%%: %s (%.1f%%)\n",
            format(sum(h[pct_delir > 90]$n), big.mark = ","),
            100*sum(h[pct_delir > 90]$n)/sum(h$n)))

saveRDS(list(h = h, dip = dip_res, dip_nonzero = dtz, mclust = mc,
             zibb = list(bb = f_bb, zibb = f_zibb, lr = lr, p = p_lr,
                         pi0 = pi0, a = a_ad, b = b_ad)),
        file.path(PROJ, "results", "02_bimodality.rds"))
cat("\nsaved results/02_bimodality.rds\n")
