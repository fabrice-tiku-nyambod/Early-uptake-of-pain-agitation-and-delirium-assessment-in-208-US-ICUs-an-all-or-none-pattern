# ---------------------------------------------------------------------------
# 08_bundle.R
#
# The paper's final framing: not "delirium screening is low" but "US ICUs adopt
# the PADIS assessment bundle all-or-nothing, and delirium is the element most
# often dropped."
#
# Everything established for delirium is re-run across all three assessment
# types so the bundle claim rests on the same machinery: structural
# non-adoption (zero-inflated beta-binomial), hospital dominance (ICC), and
# all-or-nothing intensity where adoption happens.
# ---------------------------------------------------------------------------

for (.p in c("R/00_common.R", "00_common.R", "../R/00_common.R"))
  if (file.exists(.p)) { source(.p); break }
if (!exists("PROJ")) stop("run this from the repository root", call. = FALSE)
suppressPackageStartupMessages(library(lme4))

d <- load_cohort()
ELEMENTS <- c(Pain = "any_pain_assess", Sedation = "any_sedation_assess",
              Delirium = "any_delirium_assess")

cat("===========================================================\n")
cat(" PADIS assessment bundle: adoption across all three elements\n")
cat("===========================================================\n\n")

# --- 1. national rates -----------------------------------------------------
cat("--- 1. National documentation rate ----------------------------------\n")
for (e in names(ELEMENTS)) {
  x <- d[[ELEMENTS[e]]]
  b <- binom.test(sum(x), length(x))$conf.int
  cat(sprintf("    %-9s %5.1f%% (95%% CI %.1f-%.1f)\n", e, 100*mean(x), 100*b[1], 100*b[2]))
}

# --- 2. how many hospitals adopt how much of the bundle --------------------
cat("\n--- 2. Bundle completeness by hospital ------------------------------\n")
hh <- d[, .(n = .N,
            P = 100*mean(any_pain_assess),
            S = 100*mean(any_sedation_assess),
            D = 100*mean(any_delirium_assess)), by = hospitalid][n >= MIN_STAYS]
hh[, n_adopted := (P >= 10) + (S >= 10) + (D >= 10)]
tb <- hh[, .(hospitals = .N, stays = sum(n)), by = n_adopted][order(n_adopted)]
cat(sprintf("    %-22s %10s %12s %12s\n", "elements adopted", "hospitals", "% of hosp", "% of stays"))
for (i in seq_len(nrow(tb)))
  cat(sprintf("    %-22s %10d %11.1f%% %11.1f%%\n",
              paste0(tb$n_adopted[i], " of 3"), tb$hospitals[i],
              100*tb$hospitals[i]/nrow(hh), 100*tb$stays[i]/sum(hh$n)))
cat(sprintf("\n    ALL THREE: %d of %d hospitals (%.1f%%)\n",
            sum(hh$n_adopted == 3), nrow(hh), 100*mean(hh$n_adopted == 3)))
cat(sprintf("    NONE     : %d of %d hospitals (%.1f%%)\n",
            sum(hh$n_adopted == 0), nrow(hh), 100*mean(hh$n_adopted == 0)))

cat("\n    Adoption is piecemeal, NOT a clean implementation sequence:\n")
viol <- hh[(D >= 10 & S < 10) | (D >= 10 & P < 10) | (S >= 10 & P < 10)]
cat(sprintf("    %d hospitals (%.1f%%) violate the pain >= sedation >= delirium nesting,\n",
            nrow(viol), 100*nrow(viol)/nrow(hh)))
cat("    so do not claim a fixed adoption order. Claim piecemeal adoption.\n")
cat(sprintf("    Of the %d hospitals that screen pain, only %.0f%% also screen delirium.\n",
            sum(hh$P >= 10), 100*mean(hh[P >= 10]$D >= 10)))

# --- 3. structural non-adoption, element by element ------------------------
cat("\n--- 3. Structural non-adoption (zero-inflated beta-binomial) --------\n")
fit_zibb <- function(col) {
  dat <- d[, .(n = .N, k = sum(get(col))), by = hospitalid][n >= MIN_STAYS]
  nll_bb <- function(p) { a <- exp(p[1]); b <- exp(p[2])
    -sum(lchoose(dat$n,dat$k) + lbeta(dat$k+a, dat$n-dat$k+b) - lbeta(a,b)) }
  nll_zi <- function(p) { a <- exp(p[1]); b <- exp(p[2]); pi0 <- plogis(p[3])
    l <- lchoose(dat$n,dat$k) + lbeta(dat$k+a, dat$n-dat$k+b) - lbeta(a,b)
    -sum(ifelse(dat$k == 0, log(pi0 + (1-pi0)*exp(l)), log(1-pi0) + l)) }
  f1 <- optim(c(0,0), nll_bb, method = "BFGS")
  f2 <- optim(c(f1$par,0), nll_zi, method = "BFGS")
  lr <- 2*(f1$value - f2$value)
  list(pi0 = plogis(f2$par[3]), lr = lr, p = 0.5*pchisq(lr, 1, lower.tail = FALSE),
       n_zero = sum(dat$k == 0), n_hosp = nrow(dat))
}
cat(sprintf("    %-9s %10s %14s %12s %12s\n", "element", "zero hosp", "non-adopter pi0", "LRT chi2", "p"))
zres <- list()
for (e in names(ELEMENTS)) {
  r <- fit_zibb(ELEMENTS[e]); zres[[e]] <- r
  cat(sprintf("    %-9s %7d/%-3d %13.3f %12.1f %12.2g\n",
              e, r$n_zero, r$n_hosp, r$pi0, r$lr, r$p))
}

# --- 4. hospital dominance, element by element -----------------------------
cat("\n--- 4. ICC: how much is explained by which hospital you land in ----\n")
for (e in names(ELEMENTS)) {
  f <- as.formula(sprintf("%s ~ 1 + (1|hospitalid)", ELEMENTS[e]))
  m <- glmer(f, data = d, family = binomial, nAGQ = 0)
  v <- as.numeric(VarCorr(m)$hospitalid)
  cat(sprintf("    %-9s ICC = %.3f\n", e, v/(v + pi^2/3)))
}

# --- 5. all-or-nothing intensity -------------------------------------------
cat("\n--- 5. Where adoption happens, is it a real protocol? ---------------\n")
cat("    (delirium and sedation only; the extraction counts observations for\n")
cat("     those two elements)\n")
for (e in c("Delirium", "Sedation")) {
  col <- if (e == "Delirium") "n_delirium_obs" else "n_sedation_obs"
  s <- d[get(ELEMENTS[e]) == 1]
  pd <- s[[col]] / pmax(s$los_days, 1)
  cat(sprintf("    %-9s median %.0f assessments, %.2f/day; %.1f%% reach >=2/day\n",
              e, median(s[[col]]), median(pd), 100*mean(pd >= 2)))
}

saveRDS(list(hosp = hh, zibb = zres), file.path(PROJ, "results", "08_bundle.rds"))
cat("\nsaved results/08_bundle.rds\n")
