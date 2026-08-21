test_that("the cohort has the documented shape", {
  skip_without_data()
  d <- cohort()
  expect_equal(nrow(d), 110257L)
  expect_equal(uniqueN(d$hospitalid), 208L)
  expect_true(all(d$unitdischargeoffset >= 1440))
})

test_that("age recoding preserves the aggregated over-89 group", {
  skip_without_data()
  d <- cohort()
  expect_true(all(d$age_i[d$age90 == 1] == 91))
  expect_equal(sum(d$age90), sum(is.na(d$age)))
  expect_true(all(d$age_i >= 18))
})

test_that("assessment flags are binary and complete", {
  skip_without_data()
  d <- cohort()
  for (v in c("any_pain_assess", "any_sedation_assess",
              "any_delirium_assess", "any_delirium_strict")) {
    expect_true(all(d[[v]] %in% c(0L, 1L)), info = v)
    expect_false(anyNA(d[[v]]), info = v)
  }
})
