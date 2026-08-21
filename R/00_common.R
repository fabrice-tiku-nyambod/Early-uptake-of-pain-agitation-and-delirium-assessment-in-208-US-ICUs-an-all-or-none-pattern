# ---------------------------------------------------------------------------
# 00_common.R
#
# Shared loading, derivation and plot theme for the delirium-assessment paper.
# Sourced by every downstream script so the cohort is defined in exactly one
# place.
#
# Framing note carried through every script: the outcome is DOCUMENTATION of an
# assessment, never delirium itself. An EHR can say who was screened; it cannot
# say who was delirious without ascertainment bias.
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(data.table); library(ggplot2)
})

# --- locate the project root, wherever this is run from --------------------
# Walks up from the working directory looking for the .projectroot sentinel,
# so the pipeline runs identically from the repository root, from R/, or from
# an IDE with a different working directory. No absolute paths anywhere.
.find_root <- function(start = getwd()) {
  p <- normalizePath(start, winslash = "/", mustWork = FALSE)
  for (i in 1:8) {
    if (file.exists(file.path(p, ".projectroot"))) return(p)
    parent <- dirname(p)
    if (identical(parent, p)) break
    p <- parent
  }
  stop("Could not find the project root. Run from the repository, which must ",
       "contain a .projectroot file.", call. = FALSE)
}
PROJ <- .find_root()

# minimum stays for a hospital to be characterized on its own screening rate
MIN_STAYS <- 25

load_cohort <- function() {
  d <- fread(file.path(PROJ, "data_private", "cohort_raw.csv"))

  # The strict delirium definition. 01_build_cohort.sql matches
  # LOWER(label) LIKE '%delirium%', which pools a validated instrument with a
  # nursing impression; the label audit showed the two fields are disjoint and
  # not equivalent. sql/03_delirium_strict.sql splits them per stay.
  #
  #   any_delirium_strict      'Delirium Scale/Score'         CAM-ICU / ICDSC
  #   any_delirium_impression  'Symptoms of Delirium Present' Yes/No impression
  #
  # PADIS requires a validated tool, so any_delirium_strict is the definition
  # the guideline actually implies. Stays absent from the file charted neither.
  sf <- file.path(PROJ, "data_private", "delirium_strict.csv")
  if (file.exists(sf)) {
    s <- fread(sf)
    d <- merge(d, s, by = "patientunitstayid", all.x = TRUE)
    for (v in c("any_delirium_strict", "n_delirium_strict_obs",
                "any_delirium_impression", "n_delirium_impression_obs")) {
      set(d, which(is.na(d[[v]])), v, 0L)
    }
    # impression charted but never a validated tool -- these stays count as
    # screened under the current definition and not under the strict one
    d[, impression_only := as.integer(any_delirium_impression == 1L &
                                      any_delirium_strict == 0L)]
  } else {
    warning("delirium_strict.csv not found; strict definition unavailable")
  }

  # age arrives as INT64 from SAFE_CAST, so the eICU '> 89' category lands as
  # NA. Those are the only missing ages; recode to 91, the convention used in
  # the code-status paper on the same source.
  d[, age_i := fifelse(is.na(age), 91L, age)]
  d[, age90 := as.integer(is.na(age))]

  d[, los_days := unitdischargeoffset / 1440]
  d[, died_hosp := fifelse(hospitaldischargestatus == "Expired", 1L,
                    fifelse(hospitaldischargestatus == "Alive", 0L, NA_integer_))]
  d[, died_icu  := fifelse(unitdischargestatus == "Expired", 1L,
                    fifelse(unitdischargestatus == "Alive", 0L, NA_integer_))]

  # blanks in the hospital descriptors are genuinely unknown, not a level
  for (v in c("region", "numbedscategory", "gender", "ethnicity",
              "unitadmitsource", "apacheadmissiondx")) {
    set(d, which(d[[v]] == ""), v, NA_character_)
  }

  d[, teaching := factor(fifelse(teachingstatus, "Teaching", "Non-teaching"),
                         levels = c("Non-teaching", "Teaching"))]
  d[, beds := factor(numbedscategory,
                     levels = c("<100", "100 - 249", "250 - 499", ">= 500"))]
  d[, region_f := factor(region,
                         levels = c("Midwest", "South", "West", "Northeast"))]
  d[, unit_f := relevel(factor(unittype), ref = "Med-Surg ICU")]

  # APACHE IVa is the case-mix handle; -1 is a sentinel for unscorable
  d[, apache := fifelse(apache_iva < 0, NA_real_, as.numeric(apache_iva))]
  d[, pred_mort_c := fifelse(pred_mort < 0, NA_real_, as.numeric(pred_mort))]

  d[]
}

# hospital-level screening rates, restricted to hospitals with enough stays
hospital_rates <- function(d, min_stays = MIN_STAYS) {
  h <- d[, .(n          = .N,
             pct_delir  = 100 * mean(any_delirium_assess),
             pct_sed    = 100 * mean(any_sedation_assess),
             pct_pain   = 100 * mean(any_pain_assess),
             n_vent     = sum(ventilated),
             pct_delir_vent = 100 * mean(any_delirium_assess[ventilated == 1]),
             teaching   = first(teaching),
             beds       = first(beds),
             region_f   = first(region_f)),
         by = hospitalid]
  h[n >= min_stays][order(-pct_delir)]
}

# --- figure furniture ------------------------------------------------------
FONT  <- "serif"            # standing preference: serif everywhere
INK   <- "#1a1a1a"
MUTED <- "#5c5c5c"
GRID  <- "#d9d9d9"
# ordinal blue ramp, the candidate that passed the code-status paper's OKLab /
# CVD / greyscale validation (R/10_validate_palette.R there)
PAL   <- c("#86b6ef", "#3987e5", "#1c5cab", "#0d366b")
ACC   <- "#b2182b"          # single accent for reference lines and highlights

th <- function(base = 11) theme_minimal(base_size = base, base_family = FONT) +
  theme(text            = element_text(family = FONT, color = INK),
        panel.grid.minor = element_blank(),
        panel.grid.major = element_line(color = GRID, linewidth = .25),
        axis.text       = element_text(color = MUTED, size = base - 1),
        axis.title      = element_text(color = INK, size = base),
        plot.title      = element_text(color = INK, size = base + 1, face = "bold"),
        plot.subtitle   = element_text(color = MUTED, size = base - 1),
        strip.text      = element_text(color = INK, size = base, face = "bold"),
        legend.position = "bottom",
        legend.key.height = unit(.32, "cm"))

# TIFF for submission, PDF alongside for any LaTeX build
save_fig <- function(p, name, w, h) {
  dir.create(file.path(PROJ, "figures"), showWarnings = FALSE)
  f <- file.path(PROJ, "figures", paste0(name, ".tiff"))
  ggsave(f, p, device = "tiff", width = w, height = h, units = "in",
         dpi = 600, compression = "lzw", bg = "white")
  g <- file.path(PROJ, "figures", paste0(name, ".pdf"))
  ggsave(g, p, device = cairo_pdf, width = w, height = h, units = "in",
         bg = "white")
  cat(sprintf("  %-30s %5.1f MB tiff | %4.0f KB pdf\n",
              basename(f), file.size(f)/1e6, file.size(g)/1024))
}
