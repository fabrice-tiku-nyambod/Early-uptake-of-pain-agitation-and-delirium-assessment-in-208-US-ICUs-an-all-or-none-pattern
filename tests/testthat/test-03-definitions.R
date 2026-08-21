test_that("the strict delirium definition is a subset of the permissive one", {
  skip_without_data()
  d <- cohort()
  expect_true(all(d$any_delirium_assess[d$any_delirium_strict == 1] == 1))
  expect_lte(sum(d$any_delirium_strict), sum(d$any_delirium_assess))
})

test_that("the two delirium fields are disjoint, as the label audit found", {
  skip_without_data()
  d <- cohort()
  expect_equal(sum(d$any_delirium_strict == 1 & d$any_delirium_impression == 1), 0L)
})

test_that("impression_only is derived correctly", {
  skip_without_data()
  d <- cohort()
  expect_true(all(d$impression_only ==
                  as.integer(d$any_delirium_impression == 1 & d$any_delirium_strict == 0)))
  # permissive minus strict is exactly the impression-only group
  expect_equal(sum(d$any_delirium_assess) - sum(d$any_delirium_strict),
               sum(d$impression_only))
})

test_that("headline rates match the manuscript", {
  skip_without_data()
  d <- cohort()
  expect_equal(round(100 * mean(d$any_delirium_strict), 1), 16.5)
  expect_equal(round(100 * mean(d$any_delirium_assess), 1), 21.8)
  expect_equal(round(100 * mean(d$any_sedation_assess), 1), 33.6)
  expect_equal(round(100 * mean(d$any_pain_assess), 1), 41.5)
})

test_that("hospital-level counts match the manuscript", {
  skip_without_data()
  d <- cohort()
  h <- d[, .(n = .N, p = 100 * mean(any_delirium_strict)), by = hospitalid][n >= MIN_STAYS]
  expect_equal(nrow(h), 190L)
  expect_equal(sum(h$p == 0), 138L)      # hospitals documenting none
  expect_equal(sum(h$p >= 10), 41L)      # adopters
})
