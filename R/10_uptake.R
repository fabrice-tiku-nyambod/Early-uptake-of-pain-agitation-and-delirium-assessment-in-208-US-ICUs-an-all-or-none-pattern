# ---------------------------------------------------------------------------
# 10_uptake.R
#
# The paper's centrepiece, added 2026-08-20.
#
# eICU-CRD covers 2014-2015 only (verified against patient.hospitaldischargeyear:
# 95,513 stays in 2014, 105,346 in 2015, nothing else). The contemporaneous
# guideline is therefore PAD 2013 (Barr, Crit Care Med 2013;41(1):263-306), NOT
# PADIS 2018, which postdates the data by three years. That makes this window
# one to two years post-publication -- the early uptake period.
#
# So the question sharpens from "how many ICUs comply" to "what does early
# guideline uptake look like, and does the bundle arrive all at once or element
# by element?"
#
# Outcome remains DOCUMENTATION of an assessment, never delirium itself.
# ---------------------------------------------------------------------------
for (.p in c("R/00_common.R", "00_common.R", "../R/00_common.R"))
  if (file.exists(.p)) { source(.p); break }
if (!exists("PROJ")) stop("run this from the repository root", call. = FALSE)

d <- load_cohort()
y <- fread(file.path(PROJ, "data_private", "stay_year.csv"))
d <- merge(d, y, by = "patientunitstayid", all.x = TRUE)
stopifnot(!any(is.na(d$yr)))

MIN_YR <- 15   # stays per hospital-year to characterize that hospital-year

## --- 1. national uptake by element -----------------------------------------
cat("=== 1. National uptake, 2014 -> 2015 ==============================\n")
el <- c(pain = "any_pain_assess", sedation = "any_sedation_assess",
        delirium = "any_delirium_strict")
nat <- rbindlist(lapply(names(el), function(e) {
  d[, .(element = e, stays = .N, pct = 100 * mean(get(el[[e]]))), by = yr]
}))
w <- dcast(nat, element ~ yr, value.var = "pct")
setnames(w, c("element", "y2014", "y2015"))
w[, `:=`(abs_change = y2015 - y2014, rel_change = 100 * (y2015 - y2014) / y2014)]
print(w[order(-abs_change)], digits = 3)

## --- 2. within-hospital change, composition removed -------------------------
cat("\n=== 2. Within-hospital change (hospitals in both years) ===========\n")
hy <- d[, .(n = .N,
            pain = 100 * mean(any_pain_assess),
            sedation = 100 * mean(any_sedation_assess),
            delirium = 100 * mean(any_delirium_strict)),
        by = .(hospitalid, yr)][n >= MIN_YR]
keep <- hy[, .N, by = hospitalid][N == 2]$hospitalid
hy <- hy[hospitalid %in% keep]
cat("hospitals characterized in both years:", length(keep), "\n\n")

wide <- dcast(hy, hospitalid ~ yr,
              value.var = c("pain", "sedation", "delirium", "n"))
for (e in names(el)) {
  a <- wide[[paste0(e, "_2014")]]; b <- wide[[paste0(e, "_2015")]]
  tt <- suppressWarnings(wilcox.test(a, b, paired = TRUE))
  cat(sprintf("  %-9s %5.1f%% -> %5.1f%%  change %+5.2f pp | up %2d  down %2d  static %3d | p = %.3f\n",
      e, mean(a), mean(b), mean(b - a),
      sum(b > a), sum(b < a), sum(b == a), tt$p.value))
}

## --- 3. HOW does the bundle arrive? ------------------------------------------
# The cross-sectional picture is all-or-nothing; the longitudinal one shows
# movement. These reconcile only if we know what state a hospital was in when
# it added an element. Do programs switch on whole, or accrete element by
# element?
cat("\n=== 3. Mechanism: what state did new adopters come from? ==========\n")
TH <- 10
for (e in names(el)) {
  wide[[paste0(e, "_a14")]] <- wide[[paste0(e, "_2014")]] >= TH
  wide[[paste0(e, "_a15")]] <- wide[[paste0(e, "_2015")]] >= TH
}
wide[, k14 := pain_a14 + sedation_a14 + delirium_a14]
wide[, k15 := pain_a15 + sedation_a15 + delirium_a15]

cat("bundle elements adopted, 2014 -> 2015 (n =", nrow(wide), "hospitals):\n")
print(table(`2014` = wide$k14, `2015` = wide$k15))
cat(sprintf("\n  gained >=1 element: %d | lost >=1: %d | unchanged: %d\n",
    sum(wide$k15 > wide$k14), sum(wide$k15 < wide$k14), sum(wide$k15 == wide$k14)))

cat("\n  new DELIRIUM adopters -- what did they already have in 2014?\n")
nd <- wide[delirium_a14 == FALSE & delirium_a15 == TRUE]
if (nrow(nd)) {
  cat(sprintf("    n = %d hospitals\n", nrow(nd)))
  cat(sprintf("    already had pain + sedation : %d\n",
      sum(nd$pain_a14 & nd$sedation_a14)))
  cat(sprintf("    had exactly one of the two  : %d\n",
      sum(xor(nd$pain_a14, nd$sedation_a14))))
  cat(sprintf("    had neither (cold start)    : %d\n",
      sum(!nd$pain_a14 & !nd$sedation_a14)))
  print(nd[order(-delirium_2015),
       .(hospitalid, n14 = n_2014, n15 = n_2015,
         del14 = round(delirium_2014, 1), del15 = round(delirium_2015, 1),
         pain14 = round(pain_2014, 1), sed14 = round(sedation_2014, 1))])
}

## --- 4. is hospital ID adjacency predicting charting? (non-independence) -----
# Defining systems BY charting signature and then concluding adoption is
# system-determined would be circular. Instead: hospital IDs carry no
# charting information by construction, so if signature clusters along the ID
# sequence more than chance allows, hospitals are not independent. Permutation
# test on the number of adjacent same-signature pairs.
cat("\n=== 4. Non-independence: does signature cluster along hospital ID? =\n")
h <- d[, .(n = .N, pain = 100 * mean(any_pain_assess),
           sed = 100 * mean(any_sedation_assess),
           del = 100 * mean(any_delirium_strict),
           imp = 100 * mean(impression_only)),
       by = hospitalid][n >= MIN_STAYS][order(hospitalid)]
h[, sig := paste0(as.integer(pain > 1), as.integer(sed > 1),
                  as.integer(del > 1), as.integer(imp > 1))]
obs <- sum(head(h$sig, -1) == tail(h$sig, -1))
set.seed(20260820)
perm <- replicate(10000, {
  s <- sample(h$sig); sum(head(s, -1) == tail(s, -1))
})
cat(sprintf("  adjacent same-signature pairs: observed %d, permuted mean %.1f (SD %.1f)\n",
    obs, mean(perm), sd(perm)))
cat(sprintf("  permutation p = %.5f   (10,000 shuffles)\n",
    (1 + sum(perm >= obs)) / (1 + length(perm))))
cat(sprintf("  z = %.1f\n", (obs - mean(perm)) / sd(perm)))
cat("\n  -> hospital IDs encode contributing system; hospitals sharing an ID\n")
cat("     neighbourhood share a chart template. Unit of inference is the\n")
cat("     SYSTEM, not the hospital.\n")

saveRDS(list(national = w, within = wide, hosp = h,
             perm = list(obs = obs, null_mean = mean(perm), null_sd = sd(perm))),
        file.path(PROJ, "results", "10_uptake.rds"))
cat("\nwrote results/10_uptake.rds\n")
