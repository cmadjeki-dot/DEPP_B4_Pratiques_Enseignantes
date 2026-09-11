testthat::test_that("la note reprend au plus huit indicateurs calculés", {
  t <- read.csv("../../outputs/tables/indicateurs_cles_decideur.csv",fileEncoding="UTF-8")
  c <- read.csv("../../outputs/tables/catalogue_indicateurs.csv",fileEncoding="UTF-8")
  m <- read.csv("../../outputs/tables/modeles_finaux.csv",fileEncoding="UTF-8")
  testthat::expect_true(nrow(t)>=5 && nrow(t)<=8)
  testthat::expect_equal(anyDuplicated(t$code_indicateur),0L)
  communs <- t$code_indicateur %in% c$code_indicateur
  testthat::expect_equal(t$valeur[communs],c$valeur[match(t$code_indicateur[communs],c$code_indicateur)])
  testthat::expect_equal(t$valeur[t$code_indicateur=="ASSOCIATION_EQUIPEMENT_NUM"],m$effet[m$modele=="mod_num_final" & m$terme=="equipement_numeriqueBon"])
  messages <- readLines("../../outputs/tables/messages_cles_decideur.md",encoding="UTF-8")
  messages <- messages[grepl("^[1-5][.] Dans les données simulées,",messages)]
  testthat::expect_equal(length(messages),5L)
  testthat::expect_true(all(grepl("Constat.*Interprétation.*Limite",messages)))
  testthat::expect_true(file.info("../../outputs/figures/synthese_decideur.png")$size>1000)
})
