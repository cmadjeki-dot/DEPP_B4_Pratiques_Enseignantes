# Contrôles du contrat de métadonnées, sans simulation de réponses.
dictionnaire_test <- read.csv(file.path("..", "..", "metadata/dictionnaire_variables.csv"),
                              fileEncoding = "UTF-8", stringsAsFactors = FALSE)
dimensions_test <- c("EXP", "DIF", "EVA", "GCL", "COL", "NUM", "DEV", "REL")
codes_pratiques_test <- unlist(lapply(dimensions_test, function(d) paste0(d, sprintf("%02d", 1:6))))
testthat::test_that("le dictionnaire contient le schéma et les 68 codes uniques attendus", {
  testthat::expect_identical(names(dictionnaire_test), c("variable", "libelle", "bloc", "dimension",
    "type", "modalites", "minimum", "maximum", "score_associe", "item_inverse", "obligatoire", "description"))
  testthat::expect_equal(nrow(dictionnaire_test), 68L)
  testthat::expect_equal(anyDuplicated(dictionnaire_test$variable), 0L)
  testthat::expect_false(anyNA(dictionnaire_test))
  testthat::expect_setequal(dictionnaire_test$variable, c(codes_pratiques_test,
    paste0("FAIS_", dimensions_test), paste0("PRIO_", dimensions_test), sprintf("CTRL%02d", 1:4)))
  testthat::expect_true(all(nzchar(trimws(dictionnaire_test$libelle))))
  testthat::expect_true(all(nzchar(trimws(dictionnaire_test$description))))
})
testthat::test_that("les quatre blocs et les huit dimensions ont les effectifs exacts", {
  effectifs <- table(factor(dictionnaire_test$bloc,
    levels = c("PRATIQUES", "FAISABILITE", "PRIORITE", "CONTROLE")))
  testthat::expect_identical(as.integer(effectifs), c(48L, 8L, 8L, 4L))
  for (dimension in dimensions_test) {
    testthat::expect_equal(sum(dictionnaire_test$bloc == "PRATIQUES" &
                                dictionnaire_test$dimension == dimension), 6L)
    testthat::expect_equal(sum(dictionnaire_test$bloc == "FAISABILITE" &
                                dictionnaire_test$dimension == dimension), 1L)
    testthat::expect_equal(sum(dictionnaire_test$bloc == "PRIORITE" &
                                dictionnaire_test$dimension == dimension), 1L)
  }
})
testthat::test_that("les codes de modalités sont uniques et conformes aux bornes", {
  conformes <- vapply(seq_len(nrow(dictionnaire_test)), function(i) {
    modalites <- strsplit(dictionnaire_test$modalites[i], " | ", fixed = TRUE)[[1]]
    codes <- suppressWarnings(as.integer(sub("=.*$", "", modalites)))
    libelles <- sub("^[^=]*=", "", modalites)
    !anyNA(codes) && !anyDuplicated(codes) && all(nzchar(libelles)) &&
      identical(codes, seq.int(dictionnaire_test$minimum[i], dictionnaire_test$maximum[i]))
  }, logical(1))
  testthat::expect_true(all(conformes))
  principaux <- dictionnaire_test[dictionnaire_test$bloc == "PRATIQUES", ]
  testthat::expect_true(all(principaux$minimum == 1 & principaux$maximum == 5))
  testthat::expect_true(all(principaux$modalites ==
    "1=Jamais | 2=Rarement | 3=Parfois | 4=Souvent | 5=Très souvent"))
  testthat::expect_true(all(dictionnaire_test$type %in% c("entier_ordinal", "entier_binaire")))
})
testthat::test_that("les scores sont limités aux pratiques et les réponses restent facultatives", {
  principaux <- dictionnaire_test$bloc == "PRATIQUES"
  testthat::expect_identical(dictionnaire_test$score_associe[principaux],
                             paste0("SCORE_", dictionnaire_test$dimension[principaux]))
  testthat::expect_true(all(dictionnaire_test$score_associe[!principaux] == "AUCUN"))
  testthat::expect_type(dictionnaire_test$item_inverse, "logical")
  testthat::expect_setequal(dictionnaire_test$variable[dictionnaire_test$item_inverse], c("CTRL02", "CTRL04"))
  testthat::expect_type(dictionnaire_test$obligatoire, "logical")
  testthat::expect_false(any(dictionnaire_test$obligatoire))
})
