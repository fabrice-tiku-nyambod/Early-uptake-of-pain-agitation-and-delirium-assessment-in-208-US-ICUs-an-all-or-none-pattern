# ---------------------------------------------------------------------------
# run_all.R -- reproduce every number, table and figure in the manuscript
#
#   Rscript run_all.R            # full pipeline
#   Rscript run_all.R --quick    # skip the bootstrap-heavy steps
#
# Run from the repository root. Requires data_private/ to be populated; see
# DATA_SOURCE.md for how to regenerate it from BigQuery, since the data cannot
# be redistributed under the PhysioNet data use agreement.
# ---------------------------------------------------------------------------

t0 <- Sys.time()
QUICK <- "--quick" %in% commandArgs(trailingOnly = TRUE)

for (.p in c("R/00_common.R", "00_common.R")) if (file.exists(.p)) { source(.p); break }
if (!exists("PROJ")) stop("run this from the repository root", call. = FALSE)

need <- c("data_private/cohort_raw.csv",
          "data_private/delirium_strict.csv",
          "data_private/stay_year.csv")
miss <- need[!file.exists(file.path(PROJ, need))]
if (length(miss))
  stop("missing input data:\n  ", paste(miss, collapse = "\n  "),
       "\nSee DATA_SOURCE.md.", call. = FALSE)

dir.create(file.path(PROJ, "results"), showWarnings = FALSE)
dir.create(file.path(PROJ, "figures"), showWarnings = FALSE)
dir.create(file.path(PROJ, "docs"),    showWarnings = FALSE)

# (script, description, slow?)
STEPS <- list(
  c("02_bimodality.R",         "distribution shape and zero-inflation",      "no"),
  c("03_ventilation.R",        "ventilation, within vs between hospital",    "no"),
  c("04_variance.R",           "ICC, case mix, and the internal control",    "no"),
  c("05_adoption.R",           "hospital predictors of adoption",            "no"),
  c("06_sensitivity.R",        "threshold and influence sensitivity",        "yes"),
  c("07_intensity.R",          "intensity of assessment where it occurs",    "no"),
  c("08_bundle.R",             "all three bundle elements",                  "yes"),
  c("09_strict.R",             "validated-instrument definition",            "no"),
  c("10_uptake.R",             "2014 to 2015 uptake and clustering",         "no"),
  c("12_tables.R",             "Tables 1-3 -> docs/TABLES.md",               "yes"),
  c("13_stresstest.R",         "adversarial checks",                         "yes"),
  c("14_outcomes.R",           "population burden and outcome association",  "no"),
  c("16_figures.R",            "the three manuscript figures",               "no"),
  c("15_build_docx.R",         "submission package -> Journal-of-Critical-Care/*.docx",    "no")
)

log <- file.path(PROJ, "results", "run_all.log")
con <- file(log, "wt"); sink(con, split = TRUE); on.exit({sink(); close(con)}, add = TRUE)

cat("pipeline started", format(t0), "\n")
cat("R ", as.character(getRversion()), " | ", ifelse(QUICK, "QUICK mode", "full run"), "

", sep = "")

ok <- 0L
for (st in STEPS) {
  f <- file.path(PROJ, "R", st[1])
  if (QUICK && st[3] == "yes") { cat(sprintf("  SKIP  %-28s (slow)\n", st[1])); next }
  cat(sprintf("  RUN   %-28s %s\n", st[1], st[2])); flush.console()
  t <- system.time(res <- try(source(f, local = new.env(), echo = FALSE), silent = TRUE))
  if (inherits(res, "try-error")) {
    cat(sprintf("  FAIL  %-28s %s\n", st[1], conditionMessage(attr(res, "condition"))))
  } else {
    cat(sprintf("  DONE  %-28s %5.1f s\n", st[1], t[["elapsed"]])); ok <- ok + 1L
  }
}

cat(sprintf("\n%d of %d steps completed in %.1f min\n", ok, length(STEPS),
            as.numeric(difftime(Sys.time(), t0, units = "mins"))))
cat("log written to results/run_all.log\n")
