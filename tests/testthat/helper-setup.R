# Shared setup. Locates the repository and loads the common layer once.
ROOT <- Sys.getenv("PAD_TEST_ROOT", unset = "")
if (!nzchar(ROOT)) {
  p <- normalizePath(getwd(), winslash = "/")
  for (i in 1:6) {
    if (file.exists(file.path(p, ".projectroot"))) { ROOT <- p; break }
    p <- dirname(p)
  }
}
suppressWarnings(suppressMessages(source(file.path(ROOT, "scripts", "00_common.R"))))

# Restricted data is not redistributable, so tests that need it skip cleanly.
has_data <- function() {
  all(file.exists(file.path(ROOT, "data_private",
      c("cohort_raw.csv", "delirium_strict.csv", "stay_year.csv"))))
}
skip_without_data <- function() {
  if (!has_data()) skip("data_private/ not populated; see README")
}
cohort <- local({
  cache <- NULL
  function() {
    if (is.null(cache)) cache <<- load_cohort()
    cache
  }
})
