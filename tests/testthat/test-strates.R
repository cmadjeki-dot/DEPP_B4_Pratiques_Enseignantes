source(file.path("..", "..", "R", "functions", "strates.R"), encoding = "UTF-8", local = TRUE)
testthat::test_that("l'allocation associe les effectifs par nom et contrôle la capacité", {
  tailles <- data.frame(strate_sondage = c("A", "B"), N_h = c(100L, 200L))
  allocation <- calculer_allocation(tailles, c(B = 40, A = 10), 50)
  testthat::expect_identical(allocation$n_h, c(10L, 40L))
  testthat::expect_equal(allocation$pi_h, c(0.1, 0.2))
  testthat::expect_equal(allocation$poids_base, c(10, 5))
  testthat::expect_error(calculer_allocation(tailles, c(A = 101, B = 1), 102))
  testthat::expect_error(calculer_allocation(tailles, c(A = 10, C = 40), 50))
  testthat::expect_error(calculer_allocation(tailles, c(A = 10, B = 40), 51))
  testthat::expect_error(calculer_allocation(tailles, c(A = 0, B = 50), 50))
  testthat::expect_error(calculer_allocation(tailles, c(A = 10.5, B = 39.5), 50))
})
cas_strates <- data.frame(
  id_enseignant = paste0("T", 1:8),
  degre = rep(c("Premier degré", "Collège"), each = 4),
  secteur = rep(c("Public", "Public", "Public", "Privé sous contrat"), 2),
  education_prioritaire = rep(c("Hors EP", "REP", "REP+", "Hors EP"), 2)
)
testthat::test_that("les huit cas métier sont affectés une seule fois", {
  resultat <- construire_strates_sondage(cas_strates)
  testthat::expect_identical(resultat$population$strate_sondage, c(
    "P1_PUBLIC_HEP", "P1_PUBLIC_REP", "P1_PUBLIC_REPPLUS", "P1_PRIVE",
    "COL_PUBLIC_HEP", "COL_PUBLIC_REP", "COL_PUBLIC_REPPLUS", "COL_PRIVE"))
  testthat::expect_identical(resultat$tailles$N_h, rep(1L, 8))
  testthat::expect_equal(sum(resultat$tailles$part_population), 1)
  testthat::expect_identical(resultat$population[names(cas_strates)], cas_strates)
})
testthat::test_that("les cas non admissibles ne sont pas affectés silencieusement", {
  invalide <- cas_strates
  invalide$education_prioritaire[4] <- "REP"
  testthat::expect_error(construire_strates_sondage(invalide))
  invalide <- cas_strates
  invalide$degre[1] <- NA_character_
  testthat::expect_error(construire_strates_sondage(invalide))
  invalide <- cas_strates
  invalide$secteur[1] <- "Autre"
  testthat::expect_error(construire_strates_sondage(invalide))
  invalide <- cas_strates
  invalide$id_enseignant[2] <- invalide$id_enseignant[1]
  testthat::expect_error(construire_strates_sondage(invalide))
})
