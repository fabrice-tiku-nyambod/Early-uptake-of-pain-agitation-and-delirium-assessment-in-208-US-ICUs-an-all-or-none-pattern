# ---------------------------------------------------------------------------
# 05_adoption.R
#
# Step 2 of the plan, and the question that fixes the paper's framing.
#
# If adoption tracks teaching status, size or region, the story is "screening
# has diffused to a recognisable class of hospital and not yet to the rest" --
# a diffusion-of-innovation paper with an obvious target for intervention.
#
# If adoption is NOT predictable from observable hospital characteristics, the
# story is stronger: there is no type of hospital that does this, adoption looks
# idiosyncratic, and the intervention target is universal rather than targeted.
#
# The decisive quantity is not any single odds ratio. It is how much of the
# between-hospital variance the observable characteristics explain -- compare
# the random-intercept variance before and after entering them.
# ---------------------------------------------------------------------------

for (.p in c("scripts/00_common.R", "00_common.R", "../scripts/00_common.R"))
  if (file.exists(.p)) { source(.p); break }
if (!exists("PROJ")) stop("run this from the repository root", call. = FALSE)
suppressPackageStartupMessages(library(lme4))

d <- load_cohort()
h <- hospital_rates(d)
h[, adopter := as.integer(pct_delir >= 10)]
h[, size_k  := n / 100]

cat("===========================================================\n")
cat(" Which hospitals adopt delirium screening?\n")
cat("===========================================================\n\n")

cat(sprintf("  %d hospitals, %d adopters (%.1f%%), %d non-adopters\n\n",
            nrow(h), sum(h$adopter), 100*mean(h$adopter), sum(h$adopter == 0)))

# --- descriptive: adoption rate by each characteristic ---------------------
cat("--- Adoption rate by hospital characteristic ------------------------\n")
show_by <- function(var, lab) {
  t <- h[!is.na(get(var)), .(hospitals = .N, adopters = sum(adopter),
                             pct = 100*mean(adopter),
                             med_rate = median(pct_delir)), by = var][order(get(var))]
  cat(sprintf("\n  %s\n", lab))
  for (i in seq_len(nrow(t)))
    cat(sprintf("    %-14s %3d hospitals   %2d adopt (%4.1f%%)   median screening rate %.1f%%\n",
                as.character(t[[var]][i]), t$hospitals[i], t$adopters[i],
                t$pct[i], t$med_rate[i]))
  n_miss <- sum(is.na(h[[var]]))
  if (n_miss) cat(sprintf("    %-14s %3d hospitals (characteristic unrecorded)\n", "missing", n_miss))
}
show_by("teaching", "Teaching status")
show_by("beds",     "Bed size category")
show_by("region_f", "Census region")

# --- hospital-level logistic ----------------------------------------------
cat("\n\n--- Hospital-level logistic regression for adoption -----------------\n")
hc <- h[!is.na(teaching) & !is.na(beds) & !is.na(region_f)]
cat(sprintf("    complete cases: %d of %d hospitals\n\n", nrow(hc), nrow(h)))
fit <- glm(adopter ~ teaching + beds + region_f + size_k,
           data = hc, family = binomial)
sm <- summary(fit)$coefficients
ci <- suppressMessages(confint(fit))
cat(sprintf("    %-24s %8s  %18s  %8s\n", "term", "OR", "95% CI", "p"))
for (i in 2:nrow(sm))
  cat(sprintf("    %-24s %8.2f  %8.2f - %-7.2f %8.3f\n",
              rownames(sm)[i], exp(sm[i,1]), exp(ci[i,1]), exp(ci[i,2]), sm[i,4]))

lrt <- anova(glm(adopter ~ 1, data = hc, family = binomial), fit, test = "LRT")
cat(sprintf("\n    joint LRT for all hospital characteristics: chi2 = %.2f on %d df, p = %.3f\n",
            lrt$Deviance[2], lrt$Df[2], lrt$`Pr(>Chi)`[2]))
cat(sprintf("    McFadden pseudo-R2 = %.3f\n", 1 - fit$deviance/fit$null.deviance))

# discrimination: can these characteristics identify an adopter at all?
p_hat <- predict(fit, type = "response")
auc <- { r <- rank(p_hat); n1 <- sum(hc$adopter); n0 <- nrow(hc) - n1
         (sum(r[hc$adopter == 1]) - n1*(n1+1)/2) / (n1*n0) }
cat(sprintf("    in-sample AUC = %.3f  (0.5 = characteristics carry no information)\n", auc))

# --- the decisive quantity: variance explained -----------------------------
cat("\n--- How much between-hospital variance do these characteristics explain? ---\n")
dm <- d[hospitalid %in% hc$hospitalid & !is.na(teaching) & !is.na(beds) & !is.na(region_f)]
m_null <- glmer(any_delirium_assess ~ 1 + (1 | hospitalid),
                data = dm, family = binomial, nAGQ = 0)
m_hosp <- glmer(any_delirium_assess ~ teaching + beds + region_f + (1 | hospitalid),
                data = dm, family = binomial, nAGQ = 0)
v0 <- as.numeric(VarCorr(m_null)$hospitalid)
v1 <- as.numeric(VarCorr(m_hosp)$hospitalid)
cat(sprintf("    random-intercept variance, empty model          : %.3f\n", v0))
cat(sprintf("    random-intercept variance, + teaching/beds/region: %.3f\n", v1))
cat(sprintf("    proportion of between-hospital variance EXPLAINED: %.1f%%\n", 100*(v0-v1)/v0))
cat(sprintf("    ICC falls from %.3f to %.3f\n", v0/(v0+pi^2/3), v1/(v1+pi^2/3)))

saveRDS(list(h = h, fit = fit, auc = auc, v0 = v0, v1 = v1),
        file.path(PROJ, "results", "05_adoption.rds"))
cat("\nsaved results/05_adoption.rds\n")
