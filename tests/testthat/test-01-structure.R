test_that("the repository exposes the pipeline it documents", {
  expect_true(dir.exists(file.path(ROOT, "scripts")))
  expect_true(file.exists(file.path(ROOT, "run_all.R")))
  expect_true(file.exists(file.path(ROOT, "renv.lock")))
  expect_true(file.exists(file.path(ROOT, ".env.example")))
})

test_that("every pipeline step named in run_all.R exists", {
  txt <- readLines(file.path(ROOT, "run_all.R"), warn = FALSE)
  steps <- regmatches(txt, regexpr("[0-9]{2}_[A-Za-z_]+\\.R", txt))
  steps <- unique(steps[nzchar(steps)])
  expect_gt(length(steps), 5)
  for (s in steps)
    expect_true(file.exists(file.path(ROOT, "scripts", s)), info = s)
})

test_that("no script hardcodes an absolute path", {
  fs <- list.files(file.path(ROOT, "scripts"), "[.]R$", recursive = TRUE, full.names = TRUE)
  for (f in fs) {
    txt <- paste(readLines(f, warn = FALSE), collapse = "\n")
    expect_false(grepl("C:/Users|/home/|/Users/", txt), info = basename(f))
  }
})

test_that(".env.example carries no real secret", {
  txt <- readLines(file.path(ROOT, ".env.example"), warn = FALSE)
  vals <- sub("^[^=]*=", "", grep("^[A-Z_]+=", txt, value = TRUE))
  # a populated NCBI key is 36 hex characters; nothing here should look like one
  expect_false(any(grepl("^[0-9a-f]{20,}$", vals)))
})
