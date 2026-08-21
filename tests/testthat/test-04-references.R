# Reference-list integrity. These run only where the manuscript source is
# present; the published repository does not distribute the paper itself.

ref_path <- function() file.path(ROOT, "docs", "REFERENCES_ama.md")
man_path <- function() file.path(ROOT, "docs", "MANUSCRIPT_v1.md")

# expand a citation group such as "4-6,9" into c(4,5,6,9)
expand_group <- function(g) {
  g <- gsub("[^0-9,-]", "", gsub(intToUtf8(8211), "-", g))   # en dash -> hyphen
  parts <- strsplit(g, ",", fixed = TRUE)[[1]]
  out <- integer(0)
  for (p in parts) {
    p <- trimws(p)
    if (grepl("^[0-9]+-[0-9]+$", p)) {
      ab <- as.integer(strsplit(p, "-", fixed = TRUE)[[1]])
      out <- c(out, seq(ab[1], ab[2]))
    } else if (grepl("^[0-9]+$", p)) {
      out <- c(out, as.integer(p))
    }
  }
  out
}

cited_in_order <- function() {
  M <- paste(readLines(man_path(), warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  body <- sub("## References.*", "", sub(".*## 1[.] Introduction", "", M))
  grp <- regmatches(body, gregexpr("\\[[0-9][0-9,[:space:][:punct:]]*\\]", body))[[1]]
  seen <- integer(0)
  for (g in grp) for (n in expand_group(g)) if (!(n %in% seen)) seen <- c(seen, n)
  seen
}

listed_numbers <- function() {
  R <- grep("^[0-9]+[.] ", readLines(ref_path(), warn = FALSE, encoding = "UTF-8"), value = TRUE)
  as.integer(sub("^([0-9]+)[.].*$", "\\1", R))
}

test_that("every reference is cited and every citation resolves", {
  if (!file.exists(man_path()) || !file.exists(ref_path()))
    skip("manuscript source is not distributed with this repository")
  cited <- cited_in_order()
  listed <- listed_numbers()
  expect_gt(length(cited), 20)
  expect_setequal(sort(unique(cited)), listed)
})

test_that("references are numbered in order of first appearance", {
  if (!file.exists(man_path()) || !file.exists(ref_path()))
    skip("manuscript source is not distributed with this repository")
  cited <- cited_in_order()
  expect_equal(cited, seq_along(cited))
})

test_that("every reference carries a DOI", {
  if (!file.exists(ref_path()))
    skip("reference list is not distributed with this repository")
  R <- grep("^[0-9]+[.] ", readLines(ref_path(), warn = FALSE, encoding = "UTF-8"), value = TRUE)
  expect_gt(length(R), 0)
  expect_true(all(grepl("doi:10[.]", R)))
})
