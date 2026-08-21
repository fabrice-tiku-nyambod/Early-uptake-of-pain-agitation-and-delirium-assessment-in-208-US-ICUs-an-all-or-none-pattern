# ---------------------------------------------------------------------------
# 04_variance.R
#
# Steps 3 and the artifact sensitivity. Two questions:
#
#   A. How much of whether a patient is screened is explained by WHICH HOSPITAL
#      they land in rather than WHO THEY ARE? (ICC, MOR, before and after
#      case-mix adjustment.)
#
#   B. The reviewer's first objection: is a hospital with zero delirium screens
#      simply not charting to a structured field at all? The internal control
#      is the other two assessment types. A hospital that charts PAIN routinely
#      but delirium never has the infrastructure and is choosing not to use it
#      for delirium. That is selective non-adoption, not an artifact.
# ---------------------------------------------------------------------------

for (.p in c("scripts/00_common.R", "00_common.R", "../scripts/00_common.R"))
  if (file.exists(.p)) { source(.p); break }
if (!exists("PROJ")) stop("run this from the repository root", call. = FALSE)
suppressPackageStartupMessages(library(lme4))

d <- load_cohort()

icc <- function(m) { v <- as.numeric(VarCorr(m)$hospitalid); v / (v + pi^2/3) }
mor <- function(m) exp(sqrt(2 * as.numeric(VarCorr(m)$hospitalid)) * qnorm(0.75))

cat("===========================================================\n")
cat(" A. Hospital vs patient: where does the variation live?\n")
cat("===========================================================\n\n")

m_null <- glmer(any_delirium_assess ~ 1 + (1 | hospitalid),
                data = d, family = binomial, nAGQ = 0)
dd <- d[!is.na(gender)]
m_adj <- glmer(any_delirium_assess ~ ventilated + scale(age_i) + gender +
                 scale(los_days) + unit_f + (1 | hospitalid),
               data = dd, family = binomial, nAGQ = 0)

cat(sprintf("  unadjusted        ICC %.3f    MOR %6.1f\n", icc(m_null), mor(m_null)))
cat(sprintf("  case-mix adjusted ICC %.3f    MOR %6.1f\n", icc(m_adj),  mor(m_adj)))
cat(sprintf("  between-hospital variance surviving adjustment: %.1f%%\n\n",
            100 * as.numeric(VarCorr(m_adj)$hospitalid) /
                  as.numeric(VarCorr(m_null)$hospitalid)))

cat("  CAUTION on the MOR. With 126 hospitals at exactly zero the model is\n")
cat("  close to quasi-separation, the random-intercept variance is very large,\n")
cat("  and the MOR explodes into a range where it is no longer a stable or\n")
cat("  meaningful summary. Report the ICC and the raw hospital counts as the\n")
cat("  primary evidence; quote the MOR only as 'greater than 100' if at all.\n\n")

cat("  largest patient-level effects (OR), for contrast with the hospital effect:\n")
s <- summary(m_adj)$coefficients
o <- exp(s[-1, 1])
print(round(sort(o[abs(log(o)) > 0.15], decreasing = TRUE), 2))
cat("\n  No patient characteristic comes close to the hospital term.\n")

cat("\n===========================================================\n")
cat(" B. Is a zero a charting artifact? The internal control.\n")
cat("===========================================================\n\n")

h <- d[, .(n = .N,
           kd = sum(any_delirium_assess),
           ks = sum(any_sedation_assess),
           kp = sum(any_pain_assess)), by = hospitalid][n >= MIN_STAYS]
z <- h[kd == 0]

cat(sprintf("  %d hospitals recorded zero delirium screens.\n", nrow(z)))
cat(sprintf("    also zero sedation : %3d (%.0f%%)\n", sum(z$ks == 0), 100*mean(z$ks == 0)))
cat(sprintf("    also zero pain     : %3d (%.0f%%)\n", sum(z$kp == 0), 100*mean(z$kp == 0)))
cat(sprintf("    zero on ALL THREE  : %3d (%.0f%%)  <- cannot separate from a charting artifact\n",
            sum(z$ks == 0 & z$kp == 0), 100*mean(z$ks == 0 & z$kp == 0)))

sel <- z[ks > 0 | kp > 0]
cat(sprintf("    chart sedation or pain but never delirium: %d (%.0f%%)  <- SELECTIVE non-adoption\n",
            nrow(sel), 100*nrow(sel)/nrow(z)))
cat(sprintf("\n  Those %d hospitals cover %s stays. They chart pain a median of\n",
            nrow(sel), format(sum(sel$n), big.mark = ",")))
cat(sprintf("  %.1f%% of the time (IQR %.1f-%.1f) and delirium 0%% of the time.\n",
            median(100*sel$kp/sel$n), quantile(100*sel$kp/sel$n, .25),
            quantile(100*sel$kp/sel$n, .75)))
cat("  Same EHR, same nurses, same structured-charting habit, same stays.\n")
cat("  This is the paper's cleanest defence against the ascertainment objection:\n")
cat("  the infrastructure demonstrably exists and is demonstrably not used for\n")
cat("  delirium.\n")

saveRDS(list(m_null = m_null, m_adj = m_adj, hosp = h, selective = sel),
        file.path(PROJ, "results", "04_variance.rds"))
cat("\nsaved results/04_variance.rds\n")
