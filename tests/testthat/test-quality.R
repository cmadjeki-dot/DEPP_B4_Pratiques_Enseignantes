source("../../R/functions/quality.R", encoding = "UTF-8", local = TRUE)
q_config <- yaml::read_yaml("../../config/config.yml")
q_lire <- function(p) readRDS(file.path("../..", p))
q_base <- q_lire(q_config$questionnaire_brut$sortie)
q_plan <- read.csv("../../metadata/plan_controles.csv", fileEncoding = "UTF-8")
q_audit <- function(base) auditer_qualite(base, q_lire(q_config$echantillon$sortie),
  q_lire(q_config$non_reponse$sortie_complete), q_lire(q_config$population$sortie),
  read.csv("../../metadata/dictionnaire_variables.csv", fileEncoding = "UTF-8"),
  read.csv("../../questionnaire/ordre_passation.csv", fileEncoding = "UTF-8"), q_plan)
testthat::test_that("le référentiel couvre les familles et l'audit préserve la source", {
  testthat::expect_setequal(q_plan$categorie, c("STRUCTURE", "IDENTIFIANTS", "COMPLETUDE", "MODALITES", "BORNES", "COHERENCE", "TEMPS_DE_REPONSE", "STRAIGHTLINING", "DOUBLONS", "NON_REPONSE", "SONDAGE", "PSYCHOMETRIE_PRELIMINAIRE"))
  avant <- serialize(q_base, NULL)
  z <- q_audit(q_base)
  testthat::expect_identical(serialize(q_base, NULL), avant)
  testthat::expect_setequal(z$synthese$id_controle, q_plan$id_controle)
  testthat::expect_equal(sum(z$flags$Q015, na.rm = TRUE), 25)
  testthat::expect_equal(sum(z$flags$Q016, na.rm = TRUE), 30)
  testthat::expect_equal(sum(is.na(z$flags$Q016)), 3)
  testthat::expect_equal(sum(z$flags$Q007), 927)
})
testthat::test_that("les cellules invalides et les doublons sont diagnostiqués sans correction", {
  b <- q_base
  b$EXP01[1] <- 7L
  b$CTRL03[2] <- 3L
  b$id_enseignant[2] <- b$id_enseignant[1]
  b$duree_secondes[3] <- NA_integer_
  z <- q_audit(b)
  testthat::expect_true(all(z$flags$Q009[1:2]))
  testthat::expect_true(all(z$flags$Q005[1:2]))
  testthat::expect_true(is.na(z$flags$Q015[3]))
  testthat::expect_identical(b$EXP01[1], 7L)
})
testthat::test_that("les schémas incomplets et les types invalides bloquent les contrôles dépendants", {
  b <- q_base; b$EXP01 <- NULL
  z <- q_audit(b)
  testthat::expect_true("EXP01" %in% z$variables_absentes$variable)
  testthat::expect_equal(z$synthese$resultat[z$synthese$id_controle == "Q002"], "ANOMALIE")
  b <- q_base; b$EXP01 <- as.character(b$EXP01)
  z <- q_audit(b)
  testthat::expect_equal(z$synthese$n_anomalies[z$synthese$id_controle == "Q025"], 1)
  testthat::expect_equal(z$synthese$resultat[z$synthese$id_controle == "Q009"], "NON_EVALUABLE")
})

testthat::test_that("les indicateurs comportementaux respectent les seuils et les cas non évaluables", {
  codes <- read.csv("../../metadata/dictionnaire_variables.csv", fileEncoding = "UTF-8")$variable
  principaux <- grep("^(EXP|DIF|EVA|GCL|COL|NUM|DEV|REL)[0-9]{2}$", codes, value = TRUE)
  b <- q_base
  b[1, codes] <- NA_integer_
  b[2, codes] <- 3L
  b$statut_questionnaire[2] <- "Abandon"
  b$duree_secondes[3] <- 0L
  z <- diagnostiquer_comportements(b, b[codes], principaux)$individus
  testthat::expect_true(is.na(z$flag_straightlining[1]))
  testthat::expect_true(is.na(z$flag_rapide[1]))
  testthat::expect_true(is.na(z$flag_tres_rapide[3]))
  testthat::expect_equal(z$statut_completion[2], "ABANDON")
  testthat::expect_equal(z$variance_intra_repondant[2], 0)
  testthat::expect_equal(z$nb_modalites_utilisees[2], 1)
  testthat::expect_equal(z$longueur_max_sequence[2], 48)
  testthat::expect_equal(z$nb_items_repondus + z$nb_items_manquants, z$nb_items_attendus)
  testthat::expect_true(all(!z$flag_tres_rapide | z$flag_rapide, na.rm = TRUE))
})
