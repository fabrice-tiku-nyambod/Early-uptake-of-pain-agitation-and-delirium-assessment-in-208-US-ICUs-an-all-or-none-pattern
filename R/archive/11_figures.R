# ---------------------------------------------------------------------------
# 11_figures.R
#
# Three figures for the uptake paper. Serif throughout, TIFF at 1200 dpi, LZW.
#
#   Figure 1  uptake trajectories, 2014 -> 2015, one line per hospital
#   Figure 2  forest plot of adoption predictors, naive vs cluster-robust
#   Figure 3  Love plot -- patient case mix, adopter vs non-adopter hospitals
#
# Note on Figure 1: eICU carries a discharge YEAR and nothing finer, so there
# are exactly two time points. A conventional time-series line chart would
# imply a resolution the data do not have. A paired slope plot shows every
# hospital's actual movement and is the honest form.
# ---------------------------------------------------------------------------
for (.p in c("R/00_common.R", "00_common.R", "../R/00_common.R"))
  if (file.exists(.p)) { source(.p); break }
if (!exists("PROJ")) stop("run this from the repository root", call. = FALSE)
suppressPackageStartupMessages({library(sandwich); library(lmtest); library(cobalt)})

FIG <- file.path(PROJ, "figures")
dir.create(FIG, showWarnings = FALSE)
d <- load_cohort()
d <- merge(d, fread(file.path(PROJ, "data_private", "stay_year.csv")),
           by = "patientunitstayid", all.x = TRUE)

thm <- theme_bw(base_size = 9, base_family = "serif") +
  theme(panel.grid.minor = element_blank(),
        strip.background = element_rect(fill = "grey92", colour = "grey60"),
        strip.text = element_text(face = "bold", size = 9),
        legend.position = "bottom", legend.key.width = unit(16, "pt"),
        legend.margin = margin(t = -4))
PAL <- c("#1B3A57", "#2E7D8C", "#B07A2E", "#9E4426")

## ===== FIGURE 1: uptake trajectories =======================================
hy <- d[, .(n = .N,
            Pain = 100 * mean(any_pain_assess),
            Sedation = 100 * mean(any_sedation_assess),
            Delirium = 100 * mean(any_delirium_strict)),
        by = .(hospitalid, yr)][n >= 15]
keep <- hy[, .N, by = hospitalid][N == 2]$hospitalid
hy <- hy[hospitalid %in% keep]
lg <- melt(hy, id.vars = c("hospitalid", "yr", "n"),
           variable.name = "element", value.name = "pct")
lg[, element := factor(element, levels = c("Pain", "Sedation", "Delirium"))]

# national marginal rate per element-year, for the bold overlay
natl <- d[, .(Pain = 100 * mean(any_pain_assess),
              Sedation = 100 * mean(any_sedation_assess),
              Delirium = 100 * mean(any_delirium_strict)), by = yr]
natl <- melt(natl, id.vars = "yr", variable.name = "element", value.name = "pct")
natl[, element := factor(element, levels = c("Pain", "Sedation", "Delirium"))]

# colour a hospital by direction of change
dirn <- dcast(lg, hospitalid + element ~ yr, value.var = "pct")
setnames(dirn, c("hospitalid", "element", "y14", "y15"))
dirn[, dir := fifelse(y15 - y14 > 2, "Increased",
              fifelse(y15 - y14 < -2, "Decreased", "No change"))]
lg <- merge(lg, dirn[, .(hospitalid, element, dir)],
            by = c("hospitalid", "element"))
lg[, dir := factor(dir, levels = c("Increased", "No change", "Decreased"))]

p1 <- ggplot(lg, aes(factor(yr), pct, group = hospitalid)) +
  geom_line(aes(colour = dir), linewidth = .35, alpha = .55) +
  geom_line(data = natl, aes(group = 1), colour = "black", linewidth = 1.1) +
  geom_point(data = natl, aes(group = 1), colour = "black", size = 2.2) +
  facet_wrap(~element, nrow = 1) +
  scale_colour_manual(values = c(Increased = "#1B6E4F",
                                 `No change` = "grey72",
                                 Decreased = "#9E4426"), name = NULL) +
  scale_y_continuous(limits = c(0, 100), breaks = seq(0, 100, 25)) +
  labs(x = NULL, y = "Stays with assessment documented (%)") + thm
tiff(file.path(FIG, "Figure1_uptake_trajectories.tiff"), width = 7.2, height = 3.4,
     units = "in", res = 1200, compression = "lzw"); print(p1); invisible(dev.off())

## ===== FIGURE 2: forest, adoption predictors ===============================
h <- d[, .(n = .N, del = 100 * mean(any_delirium_strict),
           teach = teaching[1], beds = beds[1], region = region_f[1]),
       by = hospitalid][n >= MIN_STAYS]
h[, adopter := as.integer(del >= 10)]
h[, vol := log(n)]
h[, block := cumsum(c(1, diff(sort(hospitalid)) > 5))[order(order(hospitalid))]]

m <- glm(adopter ~ teach + beds + region + vol, data = h, family = binomial)
naive <- coeftest(m)
clust <- coeftest(m, vcov. = vcovCL(m, cluster = h$block, type = "HC0"))
mk <- function(ct, lab) {
  k <- rownames(ct) != "(Intercept)"
  data.frame(term = rownames(ct)[k], est = ct[k, 1], se = ct[k, 2], model = lab)
}
fp <- rbind(mk(naive, "Hospital as unit"), mk(clust, "System-clustered"))
fp <- within(fp, {
  or <- exp(est); lo <- exp(est - 1.96 * se); hi <- exp(est + 1.96 * se)
})
fp$term <- gsub("^teach", "", fp$term); fp$term <- gsub("^beds", "Beds ", fp$term)
fp$term <- gsub("^region_f|^region", "", fp$term)
fp$term <- gsub("^vol$", "Volume (log stays)", fp$term)
fp$model <- factor(fp$model, levels = c("Hospital as unit", "System-clustered"))
fp$hi <- pmin(fp$hi, 60); fp$lo <- pmax(fp$lo, 0.005)

p2 <- ggplot(fp, aes(or, term, colour = model)) +
  geom_vline(xintercept = 1, linetype = "22", colour = "grey45", linewidth = .4) +
  geom_errorbarh(aes(xmin = lo, xmax = hi), height = .22, linewidth = .45,
                 position = position_dodge(width = .55)) +
  geom_point(size = 2, position = position_dodge(width = .55)) +
  scale_x_log10(breaks = c(.01, .1, 1, 10, 60)) +
  scale_colour_manual(values = c("#1B3A57", "#9E4426"), name = NULL) +
  labs(x = "Odds ratio for being a delirium-screening adopter (log scale)",
       y = NULL) + thm
tiff(file.path(FIG, "Figure2_adoption_forest.tiff"), width = 6.4, height = 4.0,
     units = "in", res = 1200, compression = "lzw"); print(p2); invisible(dev.off())

## ===== FIGURE 3: Love plot, patient case mix ===============================
# The claim is that screening is hospital-determined, not patient-determined.
# If patients at adopter and non-adopter hospitals look alike, case mix cannot
# be the explanation. Unweighted standardized differences make that visible.
ad <- h[, .(hospitalid, adopter)]
pt <- merge(d, ad, by = "hospitalid")
pt <- pt[!is.na(apache) & !is.na(pred_mort_c)]
covs <- data.frame(
  Age = pt$age_i,
  Female = as.integer(pt$gender == "Female"),
  `APACHE IVa` = pt$apache,
  `Predicted mortality` = pt$pred_mort_c,
  `Mechanically ventilated` = pt$ventilated,
  `ICU length of stay (d)` = pt$los_days,
  `Medical ICU` = as.integer(pt$unittype == "MICU"),
  `Surgical ICU` = as.integer(pt$unittype == "SICU"),
  `Med-Surg ICU` = as.integer(pt$unittype == "Med-Surg ICU"),
  `Admitted from ED` = as.integer(pt$unitadmitsource == "Emergency Department"),
  check.names = FALSE)
bt <- bal.tab(covs, treat = pt$adopter, binary = "std", continuous = "std",
              s.d.denom = "pooled")
p3 <- love.plot(bt, stat = "mean.diffs", abs = FALSE, thresholds = c(m = .1),
                var.order = "unadjusted", colours = "#1B3A57",
                title = NULL, sample.names = "Unadjusted") +
  labs(x = "Standardized difference (adopter minus non-adopter hospitals)") + thm
tiff(file.path(FIG, "Figure3_caseMix_love.tiff"), width = 6.2, height = 4.0,
     units = "in", res = 1200, compression = "lzw"); print(p3); invisible(dev.off())

cat("\n--- standardized differences, adopter vs non-adopter ---\n")
print(bt)
cat("\nlargest |SMD|:", round(max(abs(bt$Balance$Diff.Un), na.rm = TRUE), 3), "\n")
cat("\nwrote three figures to figures/\n")
