testthat::test_that("les descriptifs couvrent 48 items et des distributions complètes", {
  x <- read.csv("../../outputs/tables/descriptif_items.csv",fileEncoding="UTF-8")
  testthat::expect_equal(nrow(x),48L)
  testthat::expect_equal(anyDuplicated(x$variable),0L)
  testthat::expect_true(all(x$moyenne_ponderee>=1&x$moyenne_ponderee<=5))
  testthat::expect_equal(rowSums(x[paste0("n_",1:5)]),x$n)
  testthat::expect_equal(rowSums(x[paste0("proportion_",1:5)]),rep(1,48),tolerance=1e-8)
})
testthat::test_that("les scores exigent six réponses et les GAP utilisent des paires", {
  x <- readRDS("../../data/processed/questionnaire_clean.rds")
  s <- read.csv("../../outputs/tables/scores_provisoires_et_gaps.csv",fileEncoding="UTF-8")
  testthat::expect_identical(s$id_enseignant,x$id_enseignant)
  for(d in c("EXP","DIF","EVA","GCL","COL","NUM","DEV","REL")) {
    score <- rowMeans(x[paste0(d,sprintf("%02d",1:6))])
    testthat::expect_equal(s[[paste0("score_provisoire_",d)]],unname(score))
    testthat::expect_equal(s[[paste0("GAP_",d)]],unname(x[[paste0("PRIO_",d)]]-score))
  }
})
