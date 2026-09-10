# Tests d'intégration sur les fichiers produits, sans les modifier ni les régénérer.
racine_sampling <- normalizePath(file.path("..", ".."), mustWork = TRUE)
population_sampling <- readRDS(file.path(racine_sampling, "data/simulated/population_enseignants.rds"))
echantillon_sampling <- readRDS(file.path(racine_sampling, "data/simulated/echantillon_initial.rds"))
allocation_sampling <- read.csv(file.path(racine_sampling, "metadata/allocation_echantillon.csv"),
                                stringsAsFactors = FALSE)
allocation_cible_sampling <- c(
  P1_PUBLIC_HEP = 620L, P1_PUBLIC_REP = 130L, P1_PUBLIC_REPPLUS = 100L,
  P1_PRIVE = 150L, COL_PUBLIC_HEP = 600L, COL_PUBLIC_REP = 150L,
  COL_PUBLIC_REPPLUS = 100L, COL_PRIVE = 150L
)

testthat::test_that("la population enregistrée contient 100000 enseignants", {
  testthat::expect_s3_class(population_sampling, "data.frame")
  testthat::expect_equal(nrow(population_sampling), 100000L)
})

testthat::test_that("l'échantillon enregistré contient 2000 enseignants", {
  testthat::expect_s3_class(echantillon_sampling, "data.frame")
  testthat::expect_equal(nrow(echantillon_sampling), 2000L)
})

testthat::test_that("les identifiants sont renseignés et uniques dans les deux fichiers", {
  for (x in list(population_sampling, echantillon_sampling)) {
    testthat::expect_true("id_enseignant" %in% names(x))
    testthat::expect_false(anyNA(x$id_enseignant))
    testthat::expect_true(all(nzchar(trimws(x$id_enseignant))))
    testthat::expect_equal(anyDuplicated(x$id_enseignant), 0L)
  }
  testthat::expect_true(all(echantillon_sampling$id_enseignant %in% population_sampling$id_enseignant))
})

testthat::test_that("les strates descriptives et de sondage sont complètes et cohérentes", {
  testthat::expect_true("strate" %in% names(population_sampling))
  testthat::expect_true(all(c("strate", "strate_sondage") %in% names(echantillon_sampling)))
  for (x in list(population_sampling$strate, echantillon_sampling$strate,
                 echantillon_sampling$strate_sondage)) {
    testthat::expect_false(anyNA(x))
    testthat::expect_true(all(nzchar(trimws(x))))
  }
  testthat::expect_setequal(unique(echantillon_sampling$strate_sondage), names(allocation_cible_sampling))
  # Reconstituer indépendamment les codes depuis les caractéristiques métier.
  degre_code <- c("Premier degré" = "P1", "Collège" = "COL")
  ep_code <- c("Hors EP" = "HEP", "REP" = "REP", "REP+" = "REPPLUS")
  codes_population <- paste0(degre_code[population_sampling$degre], "_",
    ifelse(population_sampling$secteur == "Privé sous contrat", "PRIVE",
           paste0("PUBLIC_", ep_code[population_sampling$education_prioritaire])))
  origines <- match(echantillon_sampling$id_enseignant, population_sampling$id_enseignant)
  testthat::expect_identical(echantillon_sampling$strate, population_sampling$strate[origines])
  testthat::expect_identical(echantillon_sampling$strate_sondage, unname(codes_population[origines]))
})

testthat::test_that("les probabilités d'inclusion sont finies et strictement positives", {
  testthat::expect_true("pi_h" %in% names(echantillon_sampling))
  testthat::expect_type(echantillon_sampling$pi_h, "double")
  testthat::expect_true(all(is.finite(echantillon_sampling$pi_h)))
  testthat::expect_true(all(echantillon_sampling$pi_h > 0))
})

testthat::test_that("les probabilités ne dépassent pas 1 et valent n_h sur N_h", {
  testthat::expect_true(all(echantillon_sampling$pi_h <= 1))
  testthat::expect_equal(echantillon_sampling$pi_h,
                        echantillon_sampling$n_h / echantillon_sampling$N_h, tolerance = 1e-12)
})

testthat::test_that("les poids sont strictement positifs et inverses des probabilités", {
  testthat::expect_true("poids_base" %in% names(echantillon_sampling))
  testthat::expect_type(echantillon_sampling$poids_base, "double")
  testthat::expect_true(all(is.finite(echantillon_sampling$poids_base)))
  testthat::expect_true(all(echantillon_sampling$poids_base > 0))
  testthat::expect_equal(echantillon_sampling$poids_base, 1 / echantillon_sampling$pi_h,
                        tolerance = 1e-12)
})

testthat::test_that("l'allocation imposée est respectée et les N_h proviennent de la population", {
  testthat::expect_equal(nrow(allocation_sampling), 8L)
  testthat::expect_equal(anyDuplicated(allocation_sampling$strate_sondage), 0L)
  testthat::expect_setequal(allocation_sampling$strate_sondage, names(allocation_cible_sampling))
  testthat::expect_equal(sum(allocation_sampling$n_h), 2000)
  for (strate in names(allocation_cible_sampling)) {
    x <- echantillon_sampling[echantillon_sampling$strate_sondage == strate, ]
    ligne <- allocation_sampling[allocation_sampling$strate_sondage == strate, ]
    premier <- startsWith(strate, "P1_")
    prive <- endsWith(strate, "_PRIVE")
    ep <- if (endsWith(strate, "_REPPLUS")) "REP+" else if (endsWith(strate, "_REP")) "REP" else "Hors EP"
    # Conditions séparées pour garder les comparaisons et leur priorité explicites.
    dans_degre <- population_sampling$degre == (if (premier) "Premier degré" else "Collège")
    dans_secteur <- population_sampling$secteur == (if (prive) "Privé sous contrat" else "Public")
    N_reel <- sum(dans_degre & dans_secteur & population_sampling$education_prioritaire == ep)
    testthat::expect_equal(nrow(x), unname(allocation_cible_sampling[strate]))
    testthat::expect_equal(ligne$n_h, unname(allocation_cible_sampling[strate]))
    testthat::expect_equal(ligne$N_h, N_reel)
    testthat::expect_true(all(x$n_h == allocation_cible_sampling[strate]))
    testthat::expect_true(all(x$N_h == N_reel))
  }
})

testthat::test_that("les sommes de poids restituent la population globale et par strate", {
  # Tolérance absolue, limitée aux arrondis en virgule flottante.
  testthat::expect_lt(abs(sum(echantillon_sampling$poids_base) - nrow(population_sampling)), 1e-8)
  testthat::expect_lt(abs(sum(echantillon_sampling$poids_base) - 100000), 1e-8)
  for (strate in names(allocation_cible_sampling)) {
    poids <- echantillon_sampling$poids_base[echantillon_sampling$strate_sondage == strate]
    N_h <- allocation_sampling$N_h[allocation_sampling$strate_sondage == strate]
    testthat::expect_lt(abs(sum(poids) - N_h), 1e-8)
  }
})
