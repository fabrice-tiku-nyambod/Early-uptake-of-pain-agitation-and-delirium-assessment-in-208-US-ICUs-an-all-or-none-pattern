# ---------------------------------------------------------------------------
# tests/testthat.R -- run the validation suite
#
#   Rscript tests/testthat.R
#
# Tests that need the restricted data skip cleanly when data_private/ is empty,
# so the suite is runnable by anyone who clones the repository even though the
# patient records cannot be redistributed.
# ---------------------------------------------------------------------------

library(testthat)

# walk up from the working directory to the .projectroot sentinel
root <- normalizePath(getwd(), winslash = "/", mustWork = FALSE)
for (i in 1:6) {
  if (file.exists(file.path(root, ".projectroot"))) break
  root <- dirname(root)
}
if (!file.exists(file.path(root, ".projectroot")))
  stop("run this from the repository", call. = FALSE)
Sys.setenv(PAD_TEST_ROOT = root)

res <- test_dir(file.path(root, "tests", "testthat"), reporter = "summary", stop_on_failure = FALSE)
df <- as.data.frame(res)
fail <- sum(df$failed) + sum(df$error)
cat(sprintf("\n%d passed | %d failed | %d skipped\n",
            sum(df$passed), sum(df$failed) + sum(df$error), sum(df$skipped)))
if (fail > 0) quit(status = 1)
