source("../../R/functions/cleaning.R",encoding="UTF-8",local=TRUE)
cl_config <- yaml::read_yaml("../../config/config.yml")
cl_base <- readRDS(file.path("../..",cl_config$questionnaire_brut$sortie))
cl_flags <- read.csv("../../outputs/tables/qualite_flags.csv",fileEncoding="UTF-8")
cl_dict <- read.csv("../../metadata/dictionnaire_variables.csv",fileEncoding="UTF-8")
cl_pop <- readRDS(file.path("../..",cl_config$population$sortie))
cl_run <- function(b=cl_base,f=cl_flags) nettoyer_questionnaire(b,f,cl_dict,cl_pop,cl_config$nettoyage)
testthat::test_that("les décisions conservent toutes les observations et la source", {
  avant <- serialize(cl_base,NULL); z <- cl_run()
  testthat::expect_identical(serialize(cl_base,NULL),avant)
  testthat::expect_equal(nrow(z$clean)+nrow(z$exclus),nrow(cl_base))
  testthat::expect_equal(sort(c(z$clean$ligne_source,z$exclus$ligne_source)),seq_len(nrow(cl_base)))
  testthat::expect_true(all(nzchar(z$exclus$raison_exclusion)))
  testthat::expect_true(all(z$toutes$flag_analyse_sensibilite<=z$toutes$flag_analyse_principale))
  testthat::expect_equal(nrow(z$journal),0)
  testthat::expect_equal(nrow(z$doublons),0)
})
testthat::test_that("les valeurs impossibles sont journalisées avant conversion en NA", {
  b <- cl_base
  b$EXP01[1] <- 9L; b$FAIS_EXP[1] <- -1L; b$PRIO_EXP[1] <- 7L
  b$age[1] <- 200L; b$anciennete[1] <- -2L; b$effectif_classe[1] <- 100L
  b$territoire[1] <- "Inconnu"
  z <- cl_run(b)
  testthat::expect_equal(nrow(z$journal),7)
  testthat::expect_true(all(is.na(z$toutes[1,c("EXP01","FAIS_EXP","PRIO_EXP","age","anciennete","effectif_classe","territoire")])))
  testthat::expect_true(all(z$journal$nouvelle_valeur=="NA"))
  testthat::expect_identical(b$EXP01[1],9L)
})
testthat::test_that("les doublons sont départagés sans supprimer de ligne et la qualité exige un cumul", {
  # Deux copies identiques : priorité finale au numéro de ligne initial.
  i <- which(cl_base$taux_completion==1)[1]
  b <- cl_base[c(i,i),]; f <- cl_flags[c(i,i),]; f$ligne_source <- 1:2
  z <- cl_run(b,f)
  testthat::expect_identical(z$toutes$decision_doublon,c("CONSERVER_REFERENCE","EXCLURE_COPIE"))
  testthat::expect_equal(nrow(z$toutes),2)
  testthat::expect_equal(z$toutes$statut_analyse[2],"EXCLU_DOUBLON")
  b <- cl_base[i,,drop=FALSE]; f <- cl_flags[i,,drop=FALSE]; f$ligne_source <- 1L
  f$flag_tres_rapide <- TRUE; f$flag_straightlining <- FALSE; f$Q023 <- FALSE
  testthat::expect_equal(cl_run(b,f)$toutes$statut_analyse,"INCLUS")
  f$flag_straightlining <- TRUE; f$Q023 <- TRUE
  testthat::expect_equal(cl_run(b,f)$toutes$statut_analyse,"EXCLU_QUALITE")
})
