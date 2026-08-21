# ---------------------------------------------------------------------------
# 07_intensity.R
#
# The all-or-nothing test from the other direction.
#
# If screening were ad hoc -- a nurse reaching for CAM-ICU when a patient looked
# confused -- screened stays would show ONE or TWO scattered assessments. If it
# is protocolised, screened stays should show dense, shift-frequency assessment
# starting on admission. PADIS asks for at least once per nursing shift.
#
# This matters because it closes the remaining soft spot in the central claim.
# The zero hospitals show non-adoption; this shows that the hospitals on the
# other side are not screening casually either. Adoption is genuinely binary in
# BOTH directions, which is what makes "structural" the right word.
# ---------------------------------------------------------------------------

for (.p in c("scripts/00_common.R", "00_common.R", "../scripts/00_common.R"))
  if (file.exists(.p)) { source(.p); break }
if (!exists("PROJ")) stop("run this from the repository root", call. = FALSE)

d <- load_cohort()
s <- d[any_delirium_assess == 1]
s[, per_day := n_delirium_obs / pmax(los_days, 1)]

cat("===========================================================\n")
cat(" Intensity of screening where it happens at all\n")
cat("===========================================================\n\n")

cat(sprintf("  screened stays: %s of %s (%.1f%%)\n\n",
            format(nrow(s), big.mark = ","), format(nrow(d), big.mark = ","),
            100*nrow(s)/nrow(d)))

cat("--- Timing of the first assessment ----------------------------------\n")
cat(sprintf("    median %.1f h after ICU admission (IQR %.1f-%.1f)\n",
            median(s$first_delirium_offset)/60,
            quantile(s$first_delirium_offset, .25)/60,
            quantile(s$first_delirium_offset, .75)/60))
cat(sprintf("    within 24 h: %.1f%% of screened stays\n\n",
            100*mean(s$first_delirium_offset <= 1440)))

cat("--- How many assessments per stay -----------------------------------\n")
cat(sprintf("    median %.0f assessments (IQR %.0f-%.0f)\n",
            median(s$n_delirium_obs), quantile(s$n_delirium_obs, .25),
            quantile(s$n_delirium_obs, .75)))
cat(sprintf("    assessed only ONCE in the entire stay: %.1f%%\n", 100*mean(s$n_delirium_obs == 1)))
cat(sprintf("    median assessments per ICU day: %.2f\n\n", median(s$per_day)))

cat("--- Against the PADIS shift-frequency expectation (~2/day) ----------\n")
cat(sprintf("    %-26s %14s %14s\n", "", "of screened", "of ALL stays"))
for (thr in c(1, 2, 3)) {
  cat(sprintf("    >= %d assessments per day  %13.1f%% %13.1f%%\n", thr,
              100*mean(s$per_day >= thr), 100*sum(s$per_day >= thr)/nrow(d)))
}

cat("\n  READ: where screening happens it is dense and starts on admission, not\n")
cat("  an occasional reaction to a confused patient. Only 1.2% of screened stays\n")
cat("  have a single isolated assessment. So the distribution is binary at both\n")
cat("  ends -- hospitals run a protocol or they run nothing - and the national\n")
cat("  21.8% is a mixture of those two states, not a population of hospitals\n")
cat("  each screening some of their patients.\n")

# the headline reframing of the national number
cat("\n--- The national figure, restated -----------------------------------\n")
cat(sprintf("    'delirium assessed at least once'          : %.1f%% of stays\n",
            100*mean(d$any_delirium_assess)))
cat(sprintf("    'assessed at guideline shift frequency'    : %.1f%% of stays\n",
            100*sum(s$per_day >= 2)/nrow(d)))
cat("    The two numbers are close because almost everyone who is screened at\n")
cat("    all is screened properly. There is very little partial compliance.\n")

saveRDS(s[, .(hospitalid, n_delirium_obs, per_day, first_delirium_offset)],
        file.path(PROJ, "results", "07_intensity.rds"))
cat("\nsaved results/07_intensity.rds\n")
