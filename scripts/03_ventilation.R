# ---------------------------------------------------------------------------
# 03_ventilation.R
#
# The ventilated subgroup is where PADIS is most emphatic, so "are ventilated
# patients screened more?" is the paper's clinical hinge.
#
# The CRUDE answer and the WITHIN-HOSPITAL answer point in opposite directions.
# That reversal is Simpson's paradox and it has to be handled explicitly, not
# reported as a null. Marginally, ventilated patients look no more likely to be
# screened; conditional on hospital they are roughly twice as likely. The crude
# comparison is dominated by WHERE ventilated patients are cared for, because
# the large hospitals that never screen hold a disproportionate share of them.
# ---------------------------------------------------------------------------

for (.p in c("scripts/00_common.R", "00_common.R", "../scripts/00_common.R"))
  if (file.exists(.p)) { source(.p); break }
if (!exists("PROJ")) stop("run this from the repository root", call. = FALSE)
suppressPackageStartupMessages(library(lme4))

d <- load_cohort()
h <- hospital_rates(d)

cat("===========================================================\n")
cat(" Ventilation and delirium-screening documentation\n")
cat("===========================================================\n\n")

# --- crude -----------------------------------------------------------------
cat("--- CRUDE (marginal, pooling all hospitals) -------------------------\n")
for (g in 0:1) {
  s <- d[ventilated == g]
  b <- binom.test(sum(s$any_delirium_assess), nrow(s))$conf.int
  cat(sprintf("  %-15s n = %6s   screened %.1f%% (95%% CI %.1f-%.1f)\n",
              ifelse(g == 1, "ventilated", "not ventilated"),
              format(nrow(s), big.mark = ","),
              100*mean(s$any_delirium_assess), 100*b[1], 100*b[2]))
}
ft <- fisher.test(table(d$ventilated, d$any_delirium_assess))
cat(sprintf("  crude OR %.2f (95%% CI %.2f-%.2f), p = %.3g\n\n",
            ft$estimate, ft$conf.int[1], ft$conf.int[2], ft$p.value))

# --- within hospital -------------------------------------------------------
cat("--- WITHIN HOSPITAL (random intercept) ------------------------------\n")
m0 <- glmer(any_delirium_assess ~ ventilated + (1 | hospitalid),
            data = d, family = binomial, nAGQ = 0)
s0 <- summary(m0)$coefficients
cat(sprintf("  ventilation OR %.2f (95%% CI %.2f-%.2f), p = %.3g\n",
            exp(s0[2,1]), exp(s0[2,1] - 1.96*s0[2,2]),
            exp(s0[2,1] + 1.96*s0[2,2]), s0[2,4]))

# case-mix adjusted, to check the within-hospital effect is not just severity
m1 <- glmer(any_delirium_assess ~ ventilated + scale(age_i) + gender +
              scale(los_days) + unit_f + (1 | hospitalid),
            data = d[!is.na(gender)], family = binomial, nAGQ = 0)
s1 <- summary(m1)$coefficients
cat(sprintf("  adjusted for age, sex, LOS, unit type: OR %.2f (95%% CI %.2f-%.2f)\n\n",
            exp(s1[2,1]), exp(s1[2,1] - 1.96*s1[2,2]), exp(s1[2,1] + 1.96*s1[2,2])))

# --- the compositional mechanism -------------------------------------------
cat("--- WHY the crude and conditional answers disagree ------------------\n")
low <- h[pct_delir < 10]$hospitalid
cat(sprintf("  ventilated stays sitting in a <10%%-screening hospital : %.1f%%\n",
            100 * d[ventilated == 1, mean(hospitalid %in% low)]))
cat(sprintf("  non-ventilated stays in a <10%%-screening hospital     : %.1f%%\n",
            100 * d[ventilated == 0, mean(hospitalid %in% low)]))
cat("  Ventilated patients are over-represented in exactly the hospitals that\n")
cat("  never screen, which cancels the within-hospital effect when pooled.\n\n")

# --- restricted to hospitals with a screening programme --------------------
ad <- d[hospitalid %in% h[pct_delir >= 10]$hospitalid]
cat(sprintf("--- Restricted to the %d hospitals that screen at all (n = %s) ---\n",
            nrow(h[pct_delir >= 10]), format(nrow(ad), big.mark = ",")))
for (g in 0:1) {
  s <- ad[ventilated == g]
  cat(sprintf("  %-15s screened %.1f%%\n", ifelse(g == 1, "ventilated", "not ventilated"),
              100*mean(s$any_delirium_assess)))
}

# --- paired, hospital by hospital ------------------------------------------
hv <- d[, .(nv = sum(ventilated), nnv = sum(ventilated == 0),
            pv = 100*mean(any_delirium_assess[ventilated == 1]),
            pn = 100*mean(any_delirium_assess[ventilated == 0])),
        by = hospitalid][nv >= 10 & nnv >= 10]
hv <- hv[!is.na(pv) & !is.na(pn)]
scr <- hv[pv > 0 | pn > 0]
cat(sprintf("\n--- Paired within-hospital contrast (%d hospitals screening at all) ---\n",
            nrow(scr)))
cat(sprintf("  median ventilated %.1f%% vs non-ventilated %.1f%%, median paired diff %+.1f pp\n",
            median(scr$pv), median(scr$pn), median(scr$pv - scr$pn)))
cat(sprintf("  paired Wilcoxon p = %.3g; %d of %d hospitals screen ventilated patients more\n",
            wilcox.test(scr$pv, scr$pn, paired = TRUE)$p.value,
            sum(scr$pv > scr$pn), nrow(scr)))

saveRDS(list(crude = ft, m0 = m0, m1 = m1, paired = scr),
        file.path(PROJ, "results", "03_ventilation.rds"))
cat("\nsaved results/03_ventilation.rds\n")
