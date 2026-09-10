testthat::test_that("les livrables descriptifs sont complets et leurs estimations cohérentes", {
  scores <- read.csv("../../outputs/tables/scores_provisoires_et_gaps.csv",fileEncoding="UTF-8")
  dims <- c("EXP","DIF","EVA","GCL","COL","NUM","DEV","REL")
  testthat::expect_true(all(paste0("score_provisoire_",dims) %in% names(scores)))
  valeurs <- as.matrix(scores[paste0("score_provisoire_",dims)])
  testthat::expect_true(all(is.na(valeurs)|(valeurs>=1&valeurs<=5)))
  for(fichier in c("scores_par_contexte","comparaison_pratique_faisabilite_priorite")) {
    z <- read.csv(paste0("../../outputs/tables/",fichier,".csv"),fileEncoding="UTF-8")
    testthat::expect_gt(nrow(z),0)
    testthat::expect_true(all(is.finite(z$moyenne_ponderee)))
    testthat::expect_true(all(z$ic95_inf<=z$moyenne_ponderee & z$ic95_sup>=z$moyenne_ponderee))
  }
  z <- read.csv("../../outputs/tables/comparaison_scores_degre.csv",fileEncoding="UTF-8")
  testthat::expect_equal(nrow(z),8L)
  testthat::expect_equal(z$college-z$premier_degre,z$difference_college_moins_premier)
  testthat::expect_true(all(z$premier_degre>=1&z$premier_degre<=5&z$college>=1&z$college<=5))
  testthat::expect_true(all(z$ic95_inf<=z$difference_college_moins_premier & z$ic95_sup>=z$difference_college_moins_premier))
  testthat::expect_true(all(z$p_holm>=z$p_value & z$p_holm<=1))
})
