# ---------------------------------------------------------------------------
# 14_outcomes.R
#
# Population-level outcomes.
#
# THE IDENTIFICATION PROBLEM, stated before any number is produced.
#
# Screening is a HOSPITAL-level exposure with an ICC of 0.936. Two consequences
# follow and neither can be modelled away:
#
#   1. A hospital random intercept cannot be used to estimate its effect. The
#      exposure is constant within hospital, so the random effect absorbs it
#      entirely. Any model of the form
#         outcome ~ screening + (1 | hospitalid)
#      is not identified. Cluster-robust fixed-effects models are used instead.
#
#   2. Comparing outcomes between screening and non-screening hospitals is
#      comparing hospitals, not comparing screened and unscreened patients.
#      Unmeasured institutional differences -- staffing, protocols, case mix
#      beyond APACHE, referral patterns -- are not separable from screening.
#
# So this script does two different things and labels them differently:
#
#   PART A -- POPULATION BURDEN. Purely descriptive, fully defensible: how many
#             patients received care where no screening program existed.
#
#   PART B -- OUTCOME ASSOCIATION. Ecological and patient-level associations,
#             reported with cluster-robust inference and framed as associational
#             only. This CANNOT support a claim that screening changes outcomes,
#             and the manuscript must not imply that it does.
# ---------------------------------------------------------------------------

for (.p in c("R/00_common.R", "00_common.R", "../R/00_common.R"))
  if (file.exists(.p)) { source(.p); break }
if (!exists("PROJ")) stop("run this from the repository root", call. = FALSE)
suppressPackageStartupMessages({library(sandwich); library(lmtest)})

d <- load_cohort()
OUT <- "any_delirium_strict"

h <- d[, .(n = .N, scr = 100 * mean(get(OUT))), by = hospitalid]
h[, adopter := scr >= 10]
h[, block := cumsum(c(1, diff(sort(hospitalid)) > 5))[order(order(hospitalid))]]
d <- merge(d, h[, .(hospitalid, scr, adopter, block)], by = "hospitalid")

cat("=====================================================================\n")
cat(" PART A -- POPULATION BURDEN (descriptive)\n")
cat("=====================================================================\n\n")

hb <- h[n >= MIN_STAYS]
zero <- hb[scr == 0]$hospitalid
low  <- hb[scr < 10]$hospitalid
cat(sprintf("  cohort: %s stays at %d hospitals\n\n", format(nrow(d), big.mark = ","), nrow(h)))
cat(sprintf("  stays at hospitals with NO validated screening at all : %s (%.1f%%)\n",
            format(sum(d$hospitalid %in% zero), big.mark = ","),
            100 * mean(d$hospitalid %in% zero)))
cat(sprintf("  stays at hospitals screening under 10%%               : %s (%.1f%%)\n",
            format(sum(d$hospitalid %in% low), big.mark = ","),
            100 * mean(d$hospitalid %in% low)))
cat(sprintf("  stays personally receiving a validated assessment      : %s (%.1f%%)\n",
            format(sum(d[[OUT]]), big.mark = ","), 100 * mean(d[[OUT]])))
v <- d[ventilated == 1 & los_days >= 2]
cat(sprintf("\n  in the strongest-indication group (ventilated, LOS >= 48 h, n = %s):\n",
            format(nrow(v), big.mark = ",")))
cat(sprintf("    received a validated assessment: %s (%.1f%%)\n",
            format(sum(v[[OUT]]), big.mark = ","), 100 * mean(v[[OUT]])))
cat(sprintf("    cared for where no program existed: %s (%.1f%%)\n",
            format(sum(v$hospitalid %in% zero), big.mark = ","),
            100 * mean(v$hospitalid %in% zero)))

cat("\n=====================================================================\n")
cat(" PART B -- OUTCOME ASSOCIATION (associational only)\n")
cat("=====================================================================\n")

# --- B1. ecological: hospital standardized mortality ratio vs screening -----
cat("\n--- B1. Hospital standardized mortality ratio vs screening ----------\n")
dm <- d[!is.na(pred_mort_c) & !is.na(died_hosp)]
hs <- dm[, .(n = .N, obs = sum(died_hosp), exp = sum(pred_mort_c),
             scr = scr[1], adopter = adopter[1], block = block[1]), by = hospitalid][n >= 50]
hs[, smr := obs / exp]
cat(sprintf("    %d hospitals with >= 50 scorable stays\n", nrow(hs)))
cat(sprintf("    SMR median %.2f (IQR %.2f-%.2f)\n",
            median(hs$smr), quantile(hs$smr, .25), quantile(hs$smr, .75)))
ct <- cor.test(hs$scr, hs$smr, method = "spearman", exact = FALSE)
cat(sprintf("    Spearman rho(screening rate, SMR) = %.3f, p = %.3f\n", ct$estimate, ct$p.value))
cat(sprintf("    SMR median: adopters %.2f vs non-adopters %.2f (Wilcoxon p = %.3f)\n",
            median(hs[adopter == TRUE]$smr), median(hs[adopter == FALSE]$smr),
            wilcox.test(smr ~ adopter, data = hs)$p.value))

# --- B2. patient level, cluster-robust, NO random intercept ----------------
cat("\n--- B2. Patient-level association, cluster-robust at system level ---\n")
cat("    (a hospital random intercept is NOT used: the exposure is constant\n")
cat("     within hospital and the random effect would absorb it entirely)\n\n")
dd <- dm[!is.na(gender) & !is.na(unit_f)]
dd[, lp := qlogis(pmin(pmax(pred_mort_c, 1e-6), 1 - 1e-6))]
m <- glm(died_hosp ~ adopter + lp + scale(age_i) + gender + ventilated + unit_f,
         data = dd, family = binomial)
naive <- coeftest(m)
clu   <- coeftest(m, vcov. = vcovCL(m, cluster = dd$block, type = "HC0"))
i <- which(rownames(clu) == "adopterTRUE")
cat(sprintf("    hospital mortality, adopter vs non-adopter hospital\n"))
cat(sprintf("      naive OR            %.3f (95%% CI %.3f-%.3f), p = %.3f\n",
            exp(naive[i,1]), exp(naive[i,1] - 1.96*naive[i,2]), exp(naive[i,1] + 1.96*naive[i,2]), naive[i,4]))
cat(sprintf("      system-clustered OR %.3f (95%% CI %.3f-%.3f), p = %.3f  <- report this\n",
            exp(clu[i,1]), exp(clu[i,1] - 1.96*clu[i,2]), exp(clu[i,1] + 1.96*clu[i,2]), clu[i,4]))

# --- B3. ICU length of stay -------------------------------------------------
cat("\n--- B3. ICU length of stay ------------------------------------------\n")
dd[, loglos := log(los_days)]
ml <- lm(loglos ~ adopter + lp + scale(age_i) + gender + ventilated + unit_f, data = dd)
cl2 <- coeftest(ml, vcov. = vcovCL(ml, cluster = dd$block, type = "HC0"))
j <- which(rownames(cl2) == "adopterTRUE")
cat(sprintf("    median ICU LOS: adopter %.1f d vs non-adopter %.1f d\n",
            median(dd[adopter == TRUE]$los_days), median(dd[adopter == FALSE]$los_days)))
cat(sprintf("    adjusted ratio of geometric means %.3f (95%% CI %.3f-%.3f), p = %.3f (clustered)\n",
            exp(cl2[j,1]), exp(cl2[j,1] - 1.96*cl2[j,2]), exp(cl2[j,1] + 1.96*cl2[j,2]), cl2[j,4]))

cat("\n--- INTERPRETATION GUARD -------------------------------------------\n")
cat("  Any association above is between HOSPITALS, not between screened and\n")
cat("  unscreened patients. With ICC 0.936 the exposure is very nearly a label\n")
cat("  for the institution. A null result does not mean screening is useless,\n")
cat("  and a positive result would not mean screening works. Report as an\n")
cat("  association, state the identification problem, and make no causal claim.\n")

saveRDS(list(hosp_smr = hs, m = m, clustered = clu), file.path(PROJ, "results", "14_outcomes.rds"))
cat("\nwrote results/14_outcomes.rds\n")
