testthat::test_that("la base analytique préserve les poids et les formules des scores", {
  a <- readRDS("../../data/processed/base_analytique.rds")
  b <- readRDS("../../data/processed/questionnaire_clean.rds")
  p <- readRDS("../../data/processed/questionnaire_weighted.rds")
  r <- read.csv("../../outputs/tables/regles_scores_definitifs.csv")
  testthat::expect_identical(a$id_enseignant,b$id_enseignant)
  testthat::expect_equal(anyDuplicated(a$id_enseignant),0L)
  testthat::expect_equal(a$poids_final,p$poids_final[match(a$id_enseignant,p$id_enseignant)])
  testthat::expect_true(all(a$poids_final>0))
  testthat::expect_false(any(vapply(a[vapply(a,is.numeric,logical(1))],function(v)any(is.infinite(v)|is.nan(v)),logical(1))))
  for(d in c("EXP","DIF","EVA","GCL","COL","NUM","DEV","REL")) {
    noms <- paste0(c("SCORE_","Z_","FAIS_","PRIO_","GAP_","CONTRAINTE_","NB_ITEMS_"),d)
    testthat::expect_true(all(noms %in% names(a)))
    score <- a[[paste0("SCORE_",d)]]
    testthat::expect_true(all(score>=1 & score<=5,na.rm=TRUE))
    testthat::expect_equal(mean(a[[paste0("Z_",d)]],na.rm=TRUE),0,tolerance=1e-10)
    items <- strsplit(r$items[r$dimension==d],"|",fixed=TRUE)[[1]]
    n <- rowSums(!is.na(b[items]))
    testthat::expect_identical(is.na(score),unname(n<r$minimum_reponses[r$dimension==d]))
    testthat::expect_equal(a[[paste0("GAP_",d)]],a[[paste0("PRIO_",d)]]-score)
    testthat::expect_equal(a[[paste0("CONTRAINTE_",d)]],5-a[[paste0("FAIS_",d)]])
  }
  dict <- read.csv("../../metadata/dictionnaire_base_analytique.csv",fileEncoding="UTF-8")
  testthat::expect_identical(dict$variable,names(a))
  tab <- read.csv("../../outputs/tables/gap_pratique_priorite.csv")
  testthat::expect_equal(nrow(tab),40L)
})
