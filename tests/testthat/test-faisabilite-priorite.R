source(file.path("..", "..", "R/functions/faisabilite_priorite.R"), encoding = "UTF-8", local = TRUE)
fp_config <- yaml::read_yaml("../../config/config.yml")
fp_reponses <- readRDS("../../data/simulated/reponses_items_principaux.rds")
fp_traits <- readRDS("../../data/simulated/traits_latents_contextuels.rds")
fp_reference <- readRDS("../../data/simulated/echantillon_initial.rds")
fp_simuler <- function(reponses = fp_reponses, traits = fp_traits, reference = fp_reference) {
  simuler_faisabilite_priorite(reponses, traits, reference,
    fp_config$dimensions_latentes$dimensions, fp_config$faisabilite_priorite)
}
testthat::test_that("les compléments sont reproductibles et préservent les réponses", {
  x <- fp_simuler()
  testthat::expect_identical(x, fp_simuler())
  testthat::expect_equal(ncol(x), ncol(fp_reponses) + 32L)
  testthat::expect_true(all(vapply(names(fp_reponses), function(nom) identical(x[[nom]], fp_reponses[[nom]]), logical(1))))
  testthat::expect_false(anyNA(x))
  codes <- grep("^(FAIS|PRIO)_", names(x), value = TRUE)
  testthat::expect_length(codes, 16L)
  testthat::expect_true(all(as.matrix(x[codes]) %in% 1:5))
  for (d in fp_config$dimensions_latentes$dimensions) {
    testthat::expect_equal(x[[paste0("GAP_", d)]], x[[paste0("PRIO_", d)]] -
      rowMeans(fp_reponses[paste0(d, sprintf("%02d", 1:6))]))
  }
})
testthat::test_that("les identifiants désalignés et les items incomplets sont refusés", {
  testthat::expect_error(fp_simuler(traits = fp_traits[nrow(fp_traits):1, ]))
  incomplet <- fp_reponses
  incomplet$EXP01[1] <- NA_integer_
  testthat::expect_error(fp_simuler(reponses = incomplet))
})
testthat::test_that("les classes plus chargées réduisent la faisabilité à bruit fixé", {
  x <- fp_simuler()
  reference <- fp_reference
  indices <- match(fp_reponses$id_enseignant, reference$id_enseignant)
  # Perturbation d'une unité ; même graine et même population de référence.
  reference$effectif_classe[indices[1]] <- reference$effectif_classe[indices[1]] + 100
  y <- fp_simuler(reference = reference)
  codes <- grep("^FAIS_", names(x), value = TRUE)
  testthat::expect_true(all(unlist(y[1, codes]) <= unlist(x[1, codes])))
  testthat::expect_true(any(unlist(y[1, codes]) < unlist(x[1, codes])))
})
