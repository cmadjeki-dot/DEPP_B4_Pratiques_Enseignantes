testthat::test_that("la référence accepte seulement les différences numériques négligeables", {
  source("../../R/functions/scores_definitifs.R",encoding="UTF-8",local=TRUE)
  ref <- read.csv("../../metadata/loadings_efa_reference.csv",fileEncoding="UTF-8",check.names=FALSE)
  testthat::expect_equal(verifier_reference_charges(ref,ref),0)
  proche <- ref; proche$F1[1] <- proche$F1[1]+1e-12
  testthat::expect_lte(verifier_reference_charges(proche,ref),1e-10)
  different <- ref; different$F1[1] <- different$F1[1]+.001
  testthat::expect_error(verifier_reference_charges(different,ref),"Charges modifiées")
  different <- ref; different$item[1] <- "AUTRE"
  testthat::expect_error(verifier_reference_charges(different,ref),"Items")
  different <- ref; different$F1[1] <- NA_real_
  testthat::expect_error(verifier_reference_charges(different,ref),"non finies")
})

testthat::test_that("la factorisation globale produit une solution cohérente", {
  p <- read.csv("../../outputs/tables/parallel_global.csv")
  l <- read.csv("../../outputs/tables/loadings_efa.csv",check.names=FALSE)
  h <- read.csv("../../outputs/tables/communalities_efa.csv")
  f <- grep("^F[0-9]+$",names(l),value=TRUE)
  testthat::expect_equal(length(f),p$facteurs_suggeres)
  testthat::expect_equal(nrow(l),p$nb_items)
  testthat::expect_true(all(is.finite(as.matrix(l[f]))))
  testthat::expect_true(all(h$communalite>=0 & h$communalite<=1))
  testthat::expect_equal(h$communalite+h$unicite,rep(1,nrow(h)),tolerance=1e-7)
  testthat::expect_true(file.exists("../../outputs/figures/parallel_global.png"))
})

testthat::test_that("les scores respectent les items retenus et les réponses minimales", {
  b <- readRDS("../../data/processed/questionnaire_clean.rds")
  s <- readRDS("../../data/processed/questionnaire_scores.rds")
  regles <- read.csv("../../outputs/tables/regles_scores_definitifs.csv")
  testthat::expect_identical(b$id_enseignant,s$id_enseignant)
  # Le sous-ensemble d'un data.frame peut retirer ses attributs métier : comparer directement.
  testthat::expect_true(all(vapply(names(b),function(nom) identical(s[[nom]],b[[nom]]),logical(1))))
  attributs <- setdiff(names(attributes(b)),"names")
  testthat::expect_identical(attributes(s)[attributs],attributes(b)[attributs])
  for(i in seq_len(nrow(regles))) {
    d <- regles$dimension[i]; it <- strsplit(regles$items[i],"|",fixed=TRUE)[[1]]
    n <- rowSums(!is.na(b[it])); v <- s[[paste0("SCORE_",d)]]
    testthat::expect_identical(unname(is.na(v)),unname(n<regles$minimum_reponses[i]))
    testthat::expect_true(all(v>=1 & v<=5,na.rm=TRUE))
    complet <- n==length(it)
    testthat::expect_equal(v[complet],unname(rowMeans(b[complet,it])))
    z <- s[[paste0("Z_",d)]]
    testthat::expect_equal(mean(z,na.rm=TRUE),0,tolerance=1e-10)
    testthat::expect_equal(sd(z,na.rm=TRUE),1,tolerance=1e-10)
  }
})
