# Les tests sont lancés depuis la racine avec testthat::test_dir().
racine <- normalizePath(file.path("..", ".."), mustWork = TRUE)
source(file.path(racine, "R/functions/population.R"), encoding = "UTF-8", local = TRUE)
configuration <- yaml::read_yaml(file.path(racine, "config/config.yml"))
configuration$population$taille <- 3000L
population_test <- generer_population(configuration)

testthat::test_that("la simulation est reproductible et respecte les contraintes", {
  testthat::expect_identical(population_test, generer_population(configuration))
  testthat::expect_true(verifier_population(population_test, configuration))
  testthat::expect_equal(nrow(population_test), 3000L)
  testthat::expect_length(unique(population_test$discipline[population_test$degre == "Collège"]),
                          length(configuration$population$disciplines$college))
})

testthat::test_that("les contrôles rejettent les anomalies métier", {
  anomalies <- list(
    function(x) { x$id_enseignant[2] <- x$id_enseignant[1]; x },
    function(x) { x$age[1] <- 100L; x },
    function(x) { x$anciennete[1] <- -1L; x },
    function(x) { x$anciennete[1] <- x$age[1]; x },
    function(x) { x$anciennete_classe[1] <- x$anciennete[1] + 1L; x },
    function(x) { x$effectif_classe[1] <- 0L; x },
    function(x) { x$strate[1] <- NA_character_; x },
    function(x) { x$discipline[1] <- ""; x },
    function(x) { x$sexe[1] <- "Inconnu"; x },
    function(x) { x$formation_continue[1] <- -1L; x },
    function(x) {
      i <- which(x$secteur == "Privé sous contrat")[1]
      x$education_prioritaire[i] <- "REP"
      x$strate <- construire_strate(x)
      x
    },
    function(x) {
      i <- which(x$degre == "Premier degré")[1]
      x$discipline[i] <- "Mathématiques"
      x
    }
  )
  for (introduire_anomalie in anomalies) {
    testthat::expect_error(verifier_population(introduire_anomalie(population_test), configuration))
  }
})

testthat::test_that("une configuration de probabilités invalide est refusée", {
  invalide <- configuration
  invalide$population$probabilites_degre <- c(0.9, 0.9)
  testthat::expect_error(generer_population(invalide))
})
