# ---------------------------------------------------------------------------
# 16_figures.R -- the three manuscript figures
#
#   Figure 1  uptake 2014-2015: a few hospitals switched on, most did not
#   Figure 2  per-hospital shortfall: pain documented, delirium not
#   Figure 3  A intensity where screening happened, B population burden
#
# Palette: ordinal blue ramp #74a9cf / #2166ac / #053061. Pain, sedation and
# delirium are ORDERED by adoption, so a sequential single hue is the correct
# form rather than three categorical hues. Validated (OKLab, x100): worst
# all-pair dE 19.4 (floor 15), worst CVD dE 18.8 across deutan/protan/tritan
# (target 8), monotonic lightness spread 0.399 so it survives greyscale
# printing, minimum contrast 2.52 against white (floor 2.0).
#
# Serif throughout; TIFF at 1200 dpi with LZW compression.
# ---------------------------------------------------------------------------

for (.p in c("R/00_common.R", "00_common.R", "../R/00_common.R"))
  if (file.exists(.p)) { source(.p); break }
if (!exists("PROJ")) stop("run this from the repository root", call. = FALSE)
suppressPackageStartupMessages(library(patchwork))

FIG <- file.path(PROJ, "figures"); dir.create(FIG, showWarnings = FALSE)
d <- load_cohort()
d <- merge(d, fread(file.path(PROJ, "data_private", "stay_year.csv")),
           by = "patientunitstayid", all.x = TRUE)

PAL <- c(Pain = "#74a9cf", Sedation = "#2166ac", Delirium = "#053061")
ACC <- "#b2182b"; INK <- "#1a1a1a"; MUT <- "#5c5c5c"; GRD <- "#dcdcdc"

th <- function(base = 9) theme_minimal(base_size = base, base_family = "serif") +
  theme(text             = element_text(family = "serif", colour = INK),
        panel.grid.minor = element_blank(),
        panel.grid.major = element_line(colour = GRD, linewidth = .22),
        axis.text        = element_text(colour = MUT, size = base - .5),
        axis.title       = element_text(colour = INK, size = base),
        plot.subtitle    = element_text(colour = MUT, size = base - .5, lineheight = 1.15),
        plot.tag         = element_text(colour = INK, size = base + 3, face = "bold"),
        legend.position  = "bottom",
        legend.title     = element_text(size = 8, colour = MUT),
        legend.text      = element_text(size = 7.5, colour = MUT),
        legend.margin    = margin(t = -4))

tif <- function(p, name, w, h) {
  f <- file.path(FIG, paste0(name, ".tiff"))
  tiff(f, width = w, height = h, units = "in", res = 1200, compression = "lzw")
  print(p); invisible(dev.off())
  cat(sprintf("  %-34s %5.1f MB  %.1f x %.1f in @ 1200 dpi\n",
              basename(f), file.size(f)/1e6, w, h))
}

h <- d[, .(n = .N,
           Pain     = 100 * mean(any_pain_assess),
           Sedation = 100 * mean(any_sedation_assess),
           Delirium = 100 * mean(any_delirium_strict)), by = hospitalid][n >= MIN_STAYS]

## ===== FIGURE 2 -- the within-hospital shortfall ===========================
# Hospitals ordered by pain documentation, with pain and validated delirium
# joined by a line. The vertical gap is the shortfall inside one institution,
# holding the nurses, the chart and the patients constant. The long floor of
# dark points at zero under a high pain curve IS the internal control.
hh <- h[order(-Pain)][, idx := .I]
p1 <- ggplot(hh) +
  geom_segment(aes(x = idx, xend = idx, y = Delirium, yend = Pain),
               colour = GRD, linewidth = .35) +
  geom_point(aes(idx, Pain), colour = PAL[["Pain"]], size = .9) +
  geom_point(aes(idx, Delirium), colour = PAL[["Delirium"]], size = .9) +
  annotate("text", x = nrow(hh) * .55, y = 88, hjust = 0, size = 2.7,
           colour = MUT, family = "serif", lineheight = .95,
           label = "Upper point: pain\nLower point: validated delirium\nGap: infrastructure not applied to delirium") +
  scale_y_continuous(limits = c(0, 100), breaks = seq(0, 100, 25),
                     labels = paste0(seq(0, 100, 25), "%")) +
  labs(x = "Hospitals, ordered by pain documentation",
       y = "Stays with assessment documented",
       subtitle = sprintf("%d hospitals; the vertical gap is the within-hospital shortfall", nrow(hh))) +
  th()
tif(p1, "Figure2_shortfall", 6.6, 3.6)

## ===== FIGURE 1 -- uptake, 2014 to 2015 ====================================
# Every hospital contributing in both years. The 14 that crossed the adopter
# threshold are drawn dark; the rest are grey and overwhelmingly flat. The fan
# rising out of zero is the mechanism: programmes switched on, they did not
# drift upward.
MIN_YR <- 15
hy <- d[, .(n = .N, D = 100 * mean(any_delirium_strict)),
        by = .(hospitalid, yr)][n >= MIN_YR]
w <- dcast(hy, hospitalid ~ yr, value.var = "D")
setnames(w, c("hospitalid", "D14", "D15")); w <- w[!is.na(D14) & !is.na(D15)]
mv <- w[D14 < 10 & D15 >= 10]$hospitalid

hycold <- d[, .(n = .N, P = 100*mean(any_pain_assess), S = 100*mean(any_sedation_assess),
                D = 100*mean(any_delirium_strict)), by = .(hospitalid, yr)][n >= MIN_YR]
c14 <- hycold[yr == 2014 & hospitalid %in% mv]
n_cold <- nrow(c14[P < 10 & S < 10])

lgy <- melt(w[, .(hospitalid, `2014` = D14, `2015` = D15)], id.vars = "hospitalid",
            variable.name = "yr", value.name = "pct")
lgy[, adopter := hospitalid %in% mv]
p2 <- ggplot(lgy, aes(yr, pct, group = hospitalid)) +
  geom_line(data = lgy[adopter == FALSE], colour = GRD, linewidth = .4) +
  geom_line(data = lgy[adopter == TRUE], colour = PAL[["Delirium"]], linewidth = .7) +
  geom_point(data = lgy[adopter == TRUE], colour = PAL[["Delirium"]], size = 1.3) +
  annotate("text", x = 1.5, y = 96, size = 2.7, colour = MUT, family = "serif",
           lineheight = .95,
           label = sprintf("%d hospitals became adopters;\n%d of them documented no assessment\nof any kind in 2014",
                           length(mv), n_cold)) +
  scale_y_continuous(limits = c(0, 100), breaks = seq(0, 100, 25),
                     labels = paste0(seq(0, 100, 25), "%")) +
  labs(x = NULL, y = "Stays with validated delirium assessment",
       subtitle = sprintf("Each line is one of %d hospitals contributing in both years", nrow(w))) +
  th()
tif(p2, "Figure1_uptake", 4.6, 4.2)

## ===== FIGURE 3 -- intensity (A) and population burden (B) =================
s <- d[any_delirium_strict == 1][, per_day := n_delirium_strict_obs / pmax(los_days, 1)]
pA <- ggplot(s, aes(pmin(per_day, 12))) +
  geom_histogram(binwidth = .5, boundary = 0, fill = PAL[["Delirium"]],
                 colour = "white", linewidth = .18) +
  annotate("segment", x = 2, xend = 2, y = 0, yend = Inf, colour = ACC,
           linetype = "22", linewidth = .4) +
  annotate("text", x = 2.25, y = Inf, vjust = 1.6, hjust = 0, size = 2.5,
           colour = ACC, family = "serif",
           label = sprintf("twice daily\n%.0f%% at or above", 100*mean(s$per_day >= 2))) +
  scale_x_continuous(breaks = seq(0, 12, 2), labels = c(seq(0, 10, 2), "12+")) +
  scale_y_continuous(expand = expansion(mult = c(0, .08))) +
  labs(x = "Assessments per ICU day", y = "Screened stays", tag = "A",
       subtitle = sprintf("Among the %s stays with a validated assessment (median %.1f per day)",
                          format(nrow(s), big.mark = ","), median(s$per_day))) +
  th()

hz <- d[, .(n = .N, pct = 100 * mean(any_delirium_strict)), by = hospitalid][n >= MIN_STAYS]
d2 <- merge(d, hz[, .(hospitalid, hpct = pct)], by = "hospitalid")
LV <- c("No program (0%)", "Minimal (<10%)", "Partial (10-49%)", "Established (>=50%)")
d2[, band := factor(fifelse(hpct == 0, LV[1], fifelse(hpct < 10, LV[2],
                     fifelse(hpct < 50, LV[3], LV[4]))), levels = LV)]
bb <- d2[, .(stays = .N), by = band][order(band)][, pct := 100*stays/sum(stays)]
bb[, xmax := cumsum(pct)][, xmin := xmax - pct][, xmid := xmin + pct/2]
FILLS <- c("#053061", "#2166ac", "#74a9cf", "#cfe1f2"); names(FILLS) <- LV

pB <- ggplot(bb) +
  geom_rect(aes(xmin = xmin, xmax = xmax, ymin = 0, ymax = 1, fill = band),
            colour = "white", linewidth = 1.1) +
  geom_text(aes(x = xmid, y = .5, label = sprintf("%.1f%%", pct),
                colour = band %in% LV[1:2]), size = 2.9, family = "serif",
            fontface = "bold", show.legend = FALSE) +
  scale_fill_manual(values = FILLS, name = NULL, breaks = LV) +
  scale_colour_manual(values = c(`TRUE` = "white", `FALSE` = INK)) +
  scale_x_continuous(limits = c(0, 100), breaks = seq(0, 100, 25)) +
  guides(fill = guide_legend(nrow = 1, keyheight = unit(7, "pt"), keywidth = unit(11, "pt"))) +
  labs(x = "Stays (%)", y = NULL, tag = "B",
       subtitle = sprintf("All %s qualifying stays by their hospital's screening rate: %s treated where no program existed",
                          format(nrow(d2), big.mark = ","),
                          format(bb[band == LV[1]]$stays, big.mark = ","))) +
  th() + theme(axis.text.y = element_blank(), panel.grid.major.y = element_blank())

tif(pA / pB + plot_layout(heights = c(1.7, 1)), "Figure3_intensity_burden", 6.8, 5.2)

cat("\n3 figures written at 1200 dpi, LZW\n")
