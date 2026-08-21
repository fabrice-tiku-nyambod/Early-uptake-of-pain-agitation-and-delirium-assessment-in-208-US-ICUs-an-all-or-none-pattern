# ---------------------------------------------------------------------------
# 13_stresstest.R
#
# Adversarial checks on the strict-definition results. Each section is written
# to try to BREAK a claim in the manuscript, not to confirm it.
#
#  1. Pseudo-replication. 10_uptake.R showed adoption signatures cluster among
#     adjacent hospital IDs (p = 0.0001), so hospitals are not independent and
#     every confidence interval in the paper is too narrow. Quantify by how
#     much, using a block bootstrap over contiguous ID runs.
#  2. Does the all-or-none finding survive being computed within a single year?
#     Pooling 2014 and 2015 could manufacture zeros from hospitals that adopted
#     mid-period.
#  3. Are the 12 impression-only hospitals one system's chart template?
#  4. Internal control, recomputed under the strict definition.
#  5. Is the "cold start" claim an artifact of the MIN_YR threshold?
#  6. Are the 17 hospitals absent from one year different from the 173 kept?
#  7. Ventilation Simpson reversal under the strict definition.
# ---------------------------------------------------------------------------

for (.p in c("scripts/00_common.R", "00_common.R", "../scripts/00_common.R"))
  if (file.exists(.p)) { source(.p); break }
if (!exists("PROJ")) stop("run this from the repository root", call. = FALSE)
suppressPackageStartupMessages(library(lme4))

d <- load_cohort()
y <- fread(file.path(PROJ, "data_private", "stay_year.csv"))
d <- merge(d, y, by = "patientunitstayid", all.x = TRUE)
OUT <- "any_delirium_strict"

h <- d[, .(n = .N, k = sum(get(OUT)),
           strict = 100 * mean(get(OUT)),
           sed = 100 * mean(any_sedation_assess),
           pain = 100 * mean(any_pain_assess),
           imp_only = 100 * mean(impression_only)), by = hospitalid][n >= MIN_STAYS][order(hospitalid)]

cat("=====================================================================\n")
cat(" STRESS TEST OF THE STRICT-DEFINITION RESULTS\n")
cat("=====================================================================\n")

# ---------------------------------------------------------------------------
cat("\n--- 1. PSEUDO-REPLICATION: how many independent units are there? ----\n")
# A block is a maximal run of consecutive hospital IDs sharing an adoption
# signature. If IDs encode contributing system and systems share chart
# templates, blocks approximate systems.
h[, sig := paste0((pain >= 10) + 0L, (sed >= 10) + 0L, (strict >= 10) + 0L)]
h[, blk := cumsum(c(1L, as.integer(sig[-1] != sig[-.N])))]
nb <- uniqueN(h$blk)
cat(sprintf("    hospitals: %d   signature blocks: %d\n", nrow(h), nb))
cat(sprintf("    block size: median %.0f, max %.0f\n",
            median(h[, .N, by = blk]$N), max(h[, .N, by = blk]$N)))
cat(sprintf("    design effect if blocks are the true unit: %.2f\n", nrow(h) / nb))
cat(sprintf("    -> effective n is closer to %d than to %d\n\n", nb, nrow(h)))

fit_pi0 <- function(dat) {
  f <- function(p) { a <- exp(p[1]); b <- exp(p[2]); pi0 <- plogis(p[3])
    l <- lchoose(dat$n, dat$k) + lbeta(dat$k + a, dat$n - dat$k + b) - lbeta(a, b)
    -sum(ifelse(dat$k == 0, log(pi0 + (1 - pi0) * exp(l)), log(1 - pi0) + l)) }
  plogis(optim(c(0, 0, 0), f, method = "BFGS")$par[3])
}
set.seed(20260820)
pt <- fit_pi0(h)
bs_h <- replicate(2000, tryCatch(fit_pi0(h[sample(.N, replace = TRUE)]), error = function(e) NA_real_))
blocks <- split(seq_len(nrow(h)), h$blk)
bs_b <- replicate(2000, {
  pick <- sample(seq_along(blocks), length(blocks), replace = TRUE)
  tryCatch(fit_pi0(h[unlist(blocks[pick])]), error = function(e) NA_real_) })
bs_h <- bs_h[!is.na(bs_h)]; bs_b <- bs_b[!is.na(bs_b)]
ci <- function(x) sprintf("%.2f-%.2f", quantile(x, .025), quantile(x, .975))
wid <- function(x) diff(quantile(x, c(.025, .975)))
cat(sprintf("    non-adopter fraction %.2f\n", pt))
cat(sprintf("      hospital bootstrap 95%% CI %s   (width %.3f)\n", ci(bs_h), wid(bs_h)))
cat(sprintf("      BLOCK    bootstrap 95%% CI %s   (width %.3f)\n", ci(bs_b), wid(bs_b)))
cat(sprintf("    CI inflation from respecting clustering: %.2fx\n", wid(bs_b) / wid(bs_h)))
cat("    -> report the block-bootstrap interval; the hospital one is too narrow.\n")

# ---------------------------------------------------------------------------
cat("\n--- 2. Does all-or-none survive WITHIN a single year? ----------------\n")
cat("    (pooling years could turn a mid-period adopter into a partial rate)\n")
for (yy in c(2014, 2015)) {
  hy <- d[yr == yy, .(n = .N, k = sum(get(OUT))), by = hospitalid][n >= MIN_STAYS]
  hy[, pct := 100 * k / n]
  cat(sprintf("    %d: %d hospitals | zero %d (%.1f%%) | 10-90%% band %d (%.1f%%) | pi0 %.2f\n",
              yy, nrow(hy), sum(hy$pct == 0), 100 * mean(hy$pct == 0),
              sum(hy$pct >= 10 & hy$pct <= 90), 100 * mean(hy$pct >= 10 & hy$pct <= 90),
              fit_pi0(hy)))
}
hb <- h[, .(hospitalid, pct = strict)]
cat(sprintf("    pooled: %d hospitals | zero %d (%.1f%%) | 10-90%% band %d (%.1f%%)\n",
            nrow(hb), sum(hb$pct == 0), 100 * mean(hb$pct == 0),
            sum(hb$pct >= 10 & hb$pct <= 90), 100 * mean(hb$pct >= 10 & hb$pct <= 90)))

# ---------------------------------------------------------------------------
cat("\n--- 3. Are the impression-only hospitals a single chart template? ----\n")
io <- h[imp_only >= 50 & strict < 10]
cat(sprintf("    hospitals charting the impression in >=50%% of stays and a\n"))
cat(sprintf("    validated tool in <10%%: %d\n", nrow(io)))
if (nrow(io)) {
  cat(sprintf("    their hospital IDs: %s\n", paste(sort(io$hospitalid), collapse = ", ")))
  rng <- range(io$hospitalid)
  cat(sprintf("    ID range %d-%d spans %d possible IDs for %d hospitals\n",
              rng[1], rng[2], diff(rng) + 1, nrow(io)))
  cat(sprintf("    all within one contiguous ID window: %s\n",
              ifelse(diff(rng) + 1 <= nrow(io) * 2, "YES - almost certainly one system",
                     "no - dispersed")))
}

# ---------------------------------------------------------------------------
cat("\n--- 4. Internal control under the STRICT definition ------------------\n")
z <- h[strict == 0]
cat(sprintf("    hospitals with zero validated screening: %d (%s stays)\n",
            nrow(z), format(sum(z$n), big.mark = ",")))
cat(sprintf("      chart neither pain nor sedation      : %d  (uninformative)\n",
            nrow(z[pain < 10 & sed < 10])))
cat(sprintf("      chart pain or sedation >=10%%         : %d\n", nrow(z[pain >= 10 | sed >= 10])))
strong <- z[pain >= 75 | sed >= 75]
cat(sprintf("      chart pain or sedation >=75%%         : %d  (%s stays) <- the control\n",
            nrow(strong), format(sum(strong$n), big.mark = ",")))
if (nrow(strong)) cat(sprintf("      their median pain documentation: %.1f%%\n", median(strong$pain)))
cat(sprintf("      of the control hospitals, distinct ID blocks: %d\n",
            uniqueN(h[hospitalid %in% strong$hospitalid]$blk)))

# ---------------------------------------------------------------------------
cat("\n--- 5. Is 'cold start' robust to the MIN_YR threshold? ---------------\n")
for (m in c(10, 15, 25, 40)) {
  hy <- d[, .(n = .N, del = 100 * mean(get(OUT)), pain = 100 * mean(any_pain_assess),
              sed = 100 * mean(any_sedation_assess)), by = .(hospitalid, yr)][n >= m]
  kp <- intersect(hy[yr == 2014]$hospitalid, hy[yr == 2015]$hospitalid)
  a <- hy[yr == 2014 & hospitalid %in% kp][order(hospitalid)]
  b <- hy[yr == 2015 & hospitalid %in% kp][order(hospitalid)]
  new <- which(a$del < 10 & b$del >= 10)
  cold <- sum(a$pain[new] < 10 & a$sed[new] < 10)
  cat(sprintf("    MIN_YR %2d: %3d hospitals in both years | new adopters %2d | cold starts %2d (%.0f%%)\n",
              m, length(kp), length(new), cold, 100 * cold / max(length(new), 1)))
}

# ---------------------------------------------------------------------------
cat("\n--- 6. Are hospitals excluded from the paired analysis different? ----\n")
hy <- d[, .(n = .N), by = .(hospitalid, yr)][n >= 15]
kp <- intersect(hy[yr == 2014]$hospitalid, hy[yr == 2015]$hospitalid)
h[, paired := hospitalid %in% kp]
cat(sprintf("    paired %d vs unpaired %d hospitals\n", sum(h$paired), sum(!h$paired)))
cat(sprintf("    median strict screening: paired %.1f%% vs unpaired %.1f%% (Wilcoxon p = %.3f)\n",
            median(h[paired == TRUE]$strict), median(h[paired == FALSE]$strict),
            wilcox.test(strict ~ paired, data = h)$p.value))
cat(sprintf("    zero-screening share   : paired %.1f%% vs unpaired %.1f%%\n",
            100 * mean(h[paired == TRUE]$strict == 0), 100 * mean(h[paired == FALSE]$strict == 0)))
cat(sprintf("    median cohort size     : paired %.0f vs unpaired %.0f\n",
            median(h[paired == TRUE]$n), median(h[paired == FALSE]$n)))

# ---------------------------------------------------------------------------
cat("\n--- 7. Ventilation Simpson reversal, strict definition ---------------\n")
ft <- fisher.test(table(d$ventilated, d[[OUT]]))
cat(sprintf("    crude OR %.2f (95%% CI %.2f-%.2f)\n", ft$estimate, ft$conf.int[1], ft$conf.int[2]))
m <- glmer(as.formula(sprintf("%s ~ ventilated + (1|hospitalid)", OUT)),
           data = d, family = binomial, nAGQ = 0)
s <- summary(m)$coefficients
cat(sprintf("    within-hospital OR %.2f (95%% CI %.2f-%.2f), p = %.3g\n",
            exp(s[2,1]), exp(s[2,1] - 1.96*s[2,2]), exp(s[2,1] + 1.96*s[2,2]), s[2,4]))
cat(sprintf("    reversal preserved under the strict definition: %s\n",
            ifelse(ft$estimate < 1 & exp(s[2,1]) > 1, "YES", "NO -- re-examine")))

saveRDS(list(blocks = nb, pi0 = pt, ci_hosp = quantile(bs_h, c(.025,.975)),
             ci_block = quantile(bs_b, c(.025,.975))),
        file.path(PROJ, "results", "13_stresstest.rds"))
cat("\nwrote results/13_stresstest.rds\n")
