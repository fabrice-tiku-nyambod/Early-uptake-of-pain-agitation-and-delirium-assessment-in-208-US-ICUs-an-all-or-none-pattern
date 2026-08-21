# ---------------------------------------------------------------------------
# 99_write_lockfile.R -- record the exact environment the analysis ran under
#
# renv is not installed here, so this writes a renv-compatible lockfile from
# the live session rather than pretending to a full renv setup. It captures
# what was actually loaded, at the versions actually used, which is what a
# reader needs to reproduce the numbers.
#
#   Rscript R/99_write_lockfile.R
# ---------------------------------------------------------------------------
for (.p in c("scripts/00_common.R", "00_common.R", "../scripts/00_common.R"))
  if (file.exists(.p)) { source(.p); break }
if (!exists("PROJ")) stop("run this from the repository root", call. = FALSE)

PKGS <- c("data.table", "ggplot2", "lme4", "diptest", "sandwich", "lmtest",
          "cobalt", "patchwork", "officer", "flextable", "magick", "scales",
          "Matrix", "httr", "jsonlite", "testthat")

recs <- lapply(sort(PKGS), function(p) {
  v <- tryCatch(as.character(utils::packageVersion(p)), error = function(e) NA_character_)
  if (is.na(v)) return(NULL)
  sprintf('    "%s": {\n      "Package": "%s",\n      "Version": "%s",\n      "Source": "Repository",\n      "Repository": "CRAN"\n    }', p, p, v)
})
recs <- Filter(Negate(is.null), recs)

lock <- sprintf('{
  "R": {
    "Version": "%s",
    "Repositories": [
      {
        "Name": "CRAN",
        "URL": "https://cloud.r-project.org"
      }
    ]
  },
  "Packages": {
%s
  }
}
', getRversion(), paste(recs, collapse = ",\n"))

writeLines(lock, file.path(PROJ, "renv.lock"))
cat(sprintf("wrote renv.lock: R %s, %d packages\n", getRversion(), length(recs)))
