source(file.path("..", "..", "R/functions/nonresponse.R"), encoding = "UTF-8", local = TRUE)
nr_config <- yaml::read_yaml(file.path("..", "..", "config/config.yml"))$non_reponse
nr_base <- readRDS(file.path("..", "..", "data/simulated/echantillon_initial.rds"))
testthat::test_that("la non-réponse est reproductible et conserve les données initiales", {
  x <- simuler_non_reponse(nr_base, nr_config)
  testthat::expect_identical(x, simuler_non_reponse(nr_base, nr_config))
  testthat::expect_equal(nrow(x), 2000L)
  testthat::expect_identical(x$id_enseignant, nr_base$id_enseignant)
  testthat::expect_identical(x$poids_base, nr_base$poids_base)
  testthat::expect_true(all(x$prob_reponse_theorique > 0 & x$prob_reponse_theorique < 1))
  testthat::expect_equal(mean(x$prob_reponse_theorique), nr_config$taux_reponse_attendu, tolerance = 1e-9)
  testthat::expect_setequal(unique(x$repondant), 0:1)
  testthat::expect_false(anyNA(x))
})
testthat::test_that("une cible ou des coefficients invalides sont refusés", {
  mauvais <- nr_config
  mauvais$taux_reponse_attendu <- 1
  testthat::expect_error(simuler_non_reponse(nr_base, mauvais))
  mauvais <- nr_config
  mauvais$coefficients$college <- NA_real_
  testthat::expect_error(simuler_non_reponse(nr_base, mauvais))
})
