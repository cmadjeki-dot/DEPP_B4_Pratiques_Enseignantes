# Contrat d'intégration du pipeline : comparer les livrables et leurs références.
stopifnot(requireNamespace("survey", quietly = TRUE))
pw_config <- yaml::read_yaml("../../config/config.yml")
pw_lire <- function(p) readRDS(file.path("../..", p))
pw_base <- pw_lire(pw_config$ponderation$sortie)
pw_clean <- pw_lire(pw_config$nettoyage$sortie_clean)
pw_initial <- pw_lire(pw_config$echantillon$sortie)
pw_population <- pw_lire(pw_config$population$sortie)
pw_design <- pw_lire("data/processed/design_depp.rds")

testthat::test_that("la population analytique est non vide et sans duplication non voulue", {
  testthat::expect_gt(nrow(pw_base), 0)
  testthat::expect_identical(pw_base$id_enseignant, pw_clean$id_enseignant)
  testthat::expect_false(anyNA(pw_base$id_enseignant))
  testthat::expect_equal(anyDuplicated(pw_base$id_enseignant), 0L)
  testthat::expect_true(all(pw_base$flag_analyse_principale))
  testthat::expect_false(any(pw_base$decision_doublon == "EXCLURE_COPIE"))
})

testthat::test_that("les poids sont présents positifs et couvrent toutes les strates", {
  for (nom in c("poids_base", "poids_nr", "poids_final")) {
    testthat::expect_false(anyNA(pw_base[[nom]]))
    testthat::expect_true(all(is.finite(pw_base[[nom]]) & pw_base[[nom]] > 0))
  }
  testthat::expect_false(anyNA(pw_base$strate_sondage))
  testthat::expect_setequal(pw_base$strate_sondage, pw_initial$strate_sondage)
  testthat::expect_setequal(pw_base$strate_sondage, names(pw_config$echantillon$allocation))
})

testthat::test_that("le design sauvegardé restitue les marges dans la tolérance configurée", {
  testthat::expect_s3_class(pw_design, "survey.design")
  testthat::expect_identical(pw_design$variables$id_enseignant, pw_base$id_enseignant)
  testthat::expect_equal(as.numeric(weights(pw_design)), pw_base$poids_final)
  testthat::expect_gt(length(pw_design$postStrata), 0)
  testthat::expect_setequal(as.character(pw_design$strata[[1]]), pw_initial$strate_sondage)
  tol <- pw_config$ponderation$tolerance * 10
  testthat::expect_lt(abs(sum(weights(pw_design)) / nrow(pw_population) - 1), tol)
  for (nom in c("degre", "secteur", "education_prioritaire", "sexe")) {
    for (g in unique(pw_population[[nom]])) {
      plan <- pw_design
      plan$variables$controle_marge <- as.numeric(plan$variables[[nom]] == g)
      estime <- as.numeric(coef(survey::svymean(~controle_marge, plan)))
      cible <- mean(pw_population[[nom]] == g)
      testthat::expect_lt(abs(estime - cible), tol, label = paste(nom, g))
    }
  }
  total <- as.numeric(coef(survey::svytotal(~anciennete_classe, pw_design)))
  testthat::expect_lt(abs(total / sum(pw_population$anciennete_classe) - 1), tol)
})
