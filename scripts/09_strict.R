# ---------------------------------------------------------------------------
# 09_strict.R
#
# The strict delirium definition: validated instrument only.
#
# The label audit established that 'Delirium Scale/Score' (CAM-ICU, ICDSC) and
# 'Symptoms of Delirium Present' (a Yes/No nursing impression) are disjoint and
# not equivalent. PADIS asks for a validated tool, so pooling them overstates
# guideline-concordant screening. This quantifies the difference and isolates
# the hospitals that chart only the impression.
#
# Outcome remains DOCUMENTATION of an assessment, never delirium itself.
# ---------------------------------------------------------------------------
for (.p in c("scripts/00_common.R", "00_common.R", "../scripts/00_common.R"))
  if (file.exists(.p)) { source(.p); break }
if (!exists("PROJ")) stop("run this from the repository root", call. = FALSE)

d <- load_cohort()
stopifnot("any_delirium_strict" %in% names(d))

cat("cohort:", format(nrow(d), big.mark = ","), "stays,",
    uniqueN(d$hospitalid), "hospitals\n\n")

## --- 1. national rates -----------------------------------------------------
cat("--- 1. National screening rate --------------------------------------\n")
cur <- 100 * mean(d$any_delirium_assess)
str <- 100 * mean(d$any_delirium_strict)
imp <- 100 * mean(d$impression_only)
cat(sprintf("    current (either field)      %5.1f%%\n", cur))
cat(sprintf("    strict  (validated tool)    %5.1f%%\n", str))
cat(sprintf("    impression-only stays       %5.1f%%  (n = %s)\n",
            imp, format(sum(d$impression_only), big.mark = ",")))
cat(sprintf("    absolute drop               %5.1f pp (%.1f%% relative)\n\n",
            cur - str, 100 * (cur - str) / cur))

## --- 2. hospital-level ------------------------------------------------------
cat("--- 2. Hospital-level adoption (>= 25 stays) ------------------------\n")
h <- d[, .(n = .N,
           pct_cur = 100 * mean(any_delirium_assess),
           pct_str = 100 * mean(any_delirium_strict),
           pct_imp = 100 * mean(impression_only),
           pct_sed = 100 * mean(any_sedation_assess),
           pct_pain = 100 * mean(any_pain_assess)),
       by = hospitalid][n >= MIN_STAYS]

f <- function(p) c(adopters = sum(p >= 10), zero = sum(p == 0),
                   median = median(p), q1 = quantile(p, .25),
                   q3 = quantile(p, .75))
cat(sprintf("    hospitals characterized: %d\n", nrow(h)))
for (nm in c("pct_cur", "pct_str")) {
  v <- f(h[[nm]])
  cat(sprintf("    %-8s adopters(>=10%%) %3d | zero %3d (%.1f%%) | median %.1f%% | IQR %.1f-%.1f\n",
      ifelse(nm == "pct_cur", "current", "strict"),
      v["adopters"], v["zero"], 100 * v["zero"] / nrow(h),
      v["median"], v["q1.25%"], v["q3.75%"]))
}

## --- 3. the impression-only hospitals ---------------------------------------
cat("\n--- 3. Hospitals charting ONLY the non-validated impression ---------\n")
io <- h[pct_cur >= 10 & pct_str < 10]
cat(sprintf("    %d hospitals are adopters under the current definition but not\n", nrow(io)))
cat("    under the strict one -- they chart something, but not a PADIS tool.\n")
if (nrow(io)) {
  cat(sprintf("    covering %s stays; median current %.1f%%, median strict %.1f%%\n",
      format(sum(io$n), big.mark = ","), median(io$pct_cur), median(io$pct_str)))
  print(io[order(-pct_cur), .(hospitalid, n,
        current = round(pct_cur, 1), strict = round(pct_str, 1),
        impression_only = round(pct_imp, 1))], nrows = 20)
}

## --- 4. does the bundle story survive? --------------------------------------
cat("\n--- 4. Bundle adoption under the strict definition -------------------\n")
h[, `:=`(a_pain = pct_pain >= 10, a_sed = pct_sed >= 10,
         a_del_cur = pct_cur >= 10, a_del_str = pct_str >= 10)]
for (lab in c("cur", "str")) {
  k <- h$a_pain + h$a_sed + h[[paste0("a_del_", lab)]]
  tb <- table(factor(k, levels = 0:3))
  cat(sprintf("    %-7s  0:%3d (%4.1f%%)  1:%3d  2:%3d  3:%3d (%4.1f%%)\n",
      ifelse(lab == "cur", "current", "strict"),
      tb[1], 100*tb[1]/nrow(h), tb[2], tb[3], tb[4], 100*tb[4]/nrow(h)))
}
pain_ad <- h[a_pain == TRUE]
cat(sprintf("\n    of %d pain-screening hospitals, also screen delirium:\n",
            nrow(pain_ad)))
cat(sprintf("       current %.0f%%   strict %.0f%%\n",
    100 * mean(pain_ad$a_del_cur), 100 * mean(pain_ad$a_del_str)))

saveRDS(list(national = c(current = cur, strict = str, impression_only = imp),
             hospitals = h, impression_only_hosp = io),
        file.path(PROJ, "results", "09_strict.rds"))
cat("\nwrote results/09_strict.rds\n")
