source("../../R/functions/controles.R", encoding = "UTF-8", local = TRUE)
ctrl_p <- yaml::read_yaml("../../config/config.yml")$controles
ctrl_base <- readRDS("../../data/simulated/reponses_faisabilite_priorite.rds")
testthat::test_that("les contrôles sont reproductibles et préservent les scores", {
  x <- simuler_controles(ctrl_base, ctrl_p)
  testthat::expect_identical(x, simuler_controles(ctrl_base, ctrl_p))
  testthat::expect_equal(ncol(x), ncol(ctrl_base) + 6L)
  testthat::expect_true(all(vapply(names(ctrl_base), function(nom) identical(x[[nom]], ctrl_base[[nom]]), logical(1))))
  testthat::expect_identical(x$CTRL02_reverse, 6L - x$CTRL02)
  testthat::expect_identical(x$CTRL04_reverse, 6L - x$CTRL04)
  testthat::expect_true(all(as.matrix(x[c("CTRL01", "CTRL02", "CTRL04")]) %in% 1:5))
  testthat::expect_true(all(x$CTRL03 %in% 0:1))
  testthat::expect_false(anyNA(x))
})
testthat::test_that("une réapplication ou des seuils invalides sont refusés", {
  testthat::expect_error(simuler_controles(simuler_controles(ctrl_base, ctrl_p), ctrl_p))
  p <- ctrl_p
  p$seuils[2] <- p$seuils[1]
  testthat::expect_error(simuler_controles(ctrl_base, p))
})
