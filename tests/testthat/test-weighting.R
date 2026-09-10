source("../../R/functions/weighting.R",encoding="UTF-8",local=TRUE)
source("../../R/functions/strates.R",encoding="UTF-8",local=TRUE)
w_config <- yaml::read_yaml("../../config/config.yml")
w_lire <- function(p) readRDS(file.path("../..",p))
w_clean <- w_lire(w_config$nettoyage$sortie_clean)
w_initial <- w_lire(w_config$echantillon$sortie)
w_suivi <- w_lire(w_config$non_reponse$sortie_complete)
w_population <- construire_strates_sondage(w_lire(w_config$population$sortie))$population
testthat::test_that("les poids enregistrés corrigent les inclus et restituent les marges", {
  x <- w_lire(w_config$ponderation$sortie)
  testthat::expect_identical(x$id_enseignant,w_clean$id_enseignant)
  testthat::expect_identical(x$poids_base,w_clean$poids_base)
  testthat::expect_equal(x$poids_nr,x$poids_base*x$facteur_nr)
  testthat::expect_true(all(is.finite(x$poids_final)&x$poids_final>0))
  testthat::expect_true(all(x$facteur_calibration>=.5 & x$facteur_calibration<=2))
  testthat::expect_equal(sum(x$poids_nr),nrow(w_population),tolerance=1e-8)
  for(nom in c("strate_sondage","degre","secteur","education_prioritaire","sexe")) {
    for(g in unique(w_population[[nom]])) testthat::expect_equal(sum(x$poids_final[x[[nom]]==g]),sum(w_population[[nom]]==g),tolerance=1e-7)
  }
  testthat::expect_equal(sum(x$poids_final*x$anciennete_classe),sum(w_population$anciennete_classe),tolerance=1e-7)
  testthat::expect_identical(x$EXP01,w_clean$EXP01)
})
testthat::test_that("une cellule sans répondants bloque la pondération", {
  b <- w_clean[w_clean$strate_sondage!=w_clean$strate_sondage[1],]
  testthat::expect_error(ponderer_questionnaire(b,w_initial,w_suivi,w_population,w_config$ponderation),"Cellule insuffisante")
})
