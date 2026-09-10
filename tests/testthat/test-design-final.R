source("../../R/functions/diagnostic_weights.R",encoding="UTF-8",local=TRUE)
stopifnot(requireNamespace("survey",quietly=TRUE))
testthat::test_that("le plan final conserve poids stratification et calibration", {
  d <- readRDS("../../data/processed/design_depp.rds")
  x <- readRDS("../../data/processed/questionnaire_weighted.rds")
  testthat::expect_s3_class(d,"survey.design")
  testthat::expect_equal(as.numeric(weights(d)),x$poids_final)
  testthat::expect_equal(length(unique(d$strata[[1]])),8L)
  testthat::expect_gt(length(d$postStrata),0)
  testthat::expect_equal(as.numeric(coef(survey::svymean(~I(degre == 'Premier degré'),d)))[2],.57882,tolerance=1e-7)
})
testthat::test_that("les diagnostics de Kish sont invariants à une constante multiplicative", {
  x <- readRDS("../../data/processed/questionnaire_weighted.rds")
  a <- diagnostiquer_poids(x)$diagnostic_poids
  y <- x
  for(nom in c("poids_base","poids_nr","poids_final")) y[[nom]] <- 10*y[[nom]]
  b <- diagnostiquer_poids(y)$diagnostic_poids
  testthat::expect_equal(a$design_effect_kish,1+a$coefficient_variation^2)
  testthat::expect_equal(a$effective_sample_size,nrow(x)/a$design_effect_kish)
  testthat::expect_equal(a$design_effect_kish,b$design_effect_kish)
})
