source(file.path("..", "..", "R/functions/strates.R"), encoding = "UTF-8", local = TRUE)
source(file.path("..", "..", "R/functions/tirage.R"), encoding = "UTF-8", local = TRUE)
base_tirage <- data.frame(id_enseignant = paste0("T", 1:11),
                          strate_sondage = c(rep("A", 10), "B"), age = 31:41)
plan_tirage <- calculer_allocation(data.frame(strate_sondage = c("A", "B"),
                                             N_h = c(10L, 1L)), c(A = 3, B = 1), 4)
testthat::test_that("tirage sans remise, reproductible, avec une strate à unité unique", {
  x <- tirer_echantillon_stratifie(base_tirage, plan_tirage, 20260910)
  testthat::expect_identical(x, tirer_echantillon_stratifie(base_tirage, plan_tirage, 20260910))
  testthat::expect_equal(nrow(x), 4)
  testthat::expect_equal(anyDuplicated(x$id_enseignant), 0)
  testthat::expect_true("T11" %in% x$id_enseignant)
  testthat::expect_equal(x$pi_h[x$strate_sondage == "B"], 1)
  testthat::expect_true(all(verifier_echantillon(x, base_tirage, plan_tirage)$ecart == 0))
  altere <- x
  altere$poids_base[1] <- -1
  testthat::expect_error(verifier_echantillon(altere, base_tirage, plan_tirage))
  altere <- x
  altere$id_enseignant[2] <- altere$id_enseignant[1]
  testthat::expect_error(verifier_echantillon(altere, base_tirage, plan_tirage))
  faux_plan <- plan_tirage
  faux_plan$N_h[1] <- 11L
  testthat::expect_error(tirer_echantillon_stratifie(base_tirage, faux_plan, 1))
})
