source(file.path("..", "..", "R/functions/latents.R"), encoding = "UTF-8", local = TRUE)
parametres_latents_test <- list(dimensions = c("EXP", "DIF", "EVA", "GCL", "COL", "NUM", "DEV", "REL"),
  correlation_commune = 0.20, correlations_specifiques = list(EXP_EVA = 0.45,
    DIF_EVA = 0.40, DIF_DEV = 0.40, COL_DEV = 0.45, NUM_DEV = 0.25, REL_GCL = 0.30))
testthat::test_that("la matrice est définie positive et respecte les associations fixées", {
  r <- construire_correlation_latente(parametres_latents_test)
  testthat::expect_true(all(verifier_correlation_latente(r) > 0))
  testthat::expect_equal(r["EXP", "EVA"], 0.45)
  testthat::expect_equal(r["REL", "GCL"], 0.30)
  invalide <- r
  invalide[1, 2] <- 0.7
  testthat::expect_error(verifier_correlation_latente(invalide))
  invalide <- matrix(-0.5, 8, 8, dimnames = dimnames(r))
  diag(invalide) <- 1
  testthat::expect_error(verifier_correlation_latente(invalide))
})
testthat::test_that("le tirage multivarié est reproductible et retrouve la covariance cible", {
  r <- construire_correlation_latente(parametres_latents_test)
  ids <- paste0("T", seq_len(20000L))
  x <- simuler_traits_latents(ids, r, 20260911)
  testthat::expect_identical(x, simuler_traits_latents(ids, r, 20260911))
  testthat::expect_identical(x$id_enseignant, ids)
  testthat::expect_equal(ncol(x), 9L)
  testthat::expect_lt(max(abs(cov(x[-1]) - r)), 0.05)
  testthat::expect_false(isTRUE(all.equal(unname(cor(x[-1])), unname(r), tolerance = 1e-12)))
})
