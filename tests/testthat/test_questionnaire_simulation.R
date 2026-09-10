# Tests d'intégration sur les sorties enregistrées, sans régénération des données.
qs_config <- yaml::read_yaml("../../config/config.yml")
qs_lire <- function(chemin) readRDS(file.path("../..", chemin))
qs_brut <- qs_lire(qs_config$questionnaire_brut$sortie)
qs_complet <- qs_lire(qs_config$controles$sortie)
qs_imparfait <- qs_lire(qs_config$imperfections$sortie)
qs_initial <- qs_lire(qs_config$echantillon$sortie)
qs_latents <- qs_lire(qs_config$simulation_items$sortie_traits)
qs_socle <- qs_lire(qs_config$dimensions_latentes$sortie)
qs_dict <- read.csv("../../metadata/dictionnaire_variables.csv", fileEncoding = "UTF-8")
qs_ordre <- read.csv("../../questionnaire/ordre_passation.csv", fileEncoding = "UTF-8")
qs_dimensions <- c("EXP", "DIF", "EVA", "GCL", "COL", "NUM", "DEV", "REL")
qs_items <- unlist(lapply(qs_dimensions, function(d) paste0(d, sprintf("%02d", 1:6))))

testthat::test_that("toutes les questions existent dans la référence et la livraison brute", {
  attendus <- c(qs_items, paste0("FAIS_", qs_dimensions), paste0("PRIO_", qs_dimensions), sprintf("CTRL%02d", 1:4))
  testthat::expect_setequal(qs_dict$variable, attendus)
  for (base in list(qs_complet, qs_imparfait, qs_brut)) {
    testthat::expect_true(all(attendus %in% names(base)))
    testthat::expect_equal(anyDuplicated(names(base)), 0L)
  }
})

testthat::test_that("les huit dimensions comportent exactement six items chacune", {
  codes <- grep("^(EXP|DIF|EVA|GCL|COL|NUM|DEV|REL)[0-9]+$", names(qs_brut), value = TRUE)
  testthat::expect_length(codes, 48L)
  testthat::expect_setequal(codes, qs_items)
  testthat::expect_setequal(qs_dict$variable[qs_dict$bloc == "PRATIQUES"], qs_items)
  testthat::expect_setequal(sub("[0-9]+$", "", codes), qs_dimensions)
  testthat::expect_true(all(table(sub("[0-9]+$", "", codes)) == 6L))
})

testthat::test_that("les réponses ordinales sont entre 1 et 5 ou NA, CTRL03 reste binaire", {
  ordinaux <- setdiff(qs_dict$variable, "CTRL03")
  for (base in list(qs_complet, qs_imparfait, qs_brut)) {
    valeurs <- as.matrix(base[ordinaux])
    testthat::expect_true(all(is.na(valeurs) | valeurs %in% 1:5))
    testthat::expect_true(all(vapply(base[ordinaux], is.integer, logical(1))))
    testthat::expect_true(all(is.na(base$CTRL03) | base$CTRL03 %in% 0:1))
  }
})

testthat::test_that("les identifiants sont uniques et les répondants restent alignés", {
  # Aucun doublon technique n'est prévu dans le scénario courant.
  for (base in list(qs_initial, qs_complet, qs_imparfait, qs_brut, qs_latents, qs_socle)) {
    testthat::expect_false(anyNA(base$id_enseignant))
    testthat::expect_equal(anyDuplicated(base$id_enseignant), 0L)
  }
  for (base in list(qs_complet, qs_imparfait, qs_latents, qs_socle)) {
    testthat::expect_identical(base$id_enseignant, qs_brut$id_enseignant)
  }
  testthat::expect_true(all(qs_brut$id_enseignant %in% qs_initial$id_enseignant))
})

testthat::test_that("les huit traits latents enregistrés ont une variance strictement positive", {
  codes <- paste0("latent_", qs_dimensions)
  for (base in list(qs_socle, qs_latents)) {
    testthat::expect_setequal(grep("^latent_", names(base), value = TRUE), codes)
    testthat::expect_true(all(is.finite(as.matrix(base[codes]))))
    variances <- vapply(base[codes], var, numeric(1))
    testthat::expect_true(all(is.finite(variances) & variances > 0))
  }
})

testthat::test_that("les corrélations moyennes intra-dimension sont positives", {
  # Diagnostic ordinal de Spearman, paires disponibles ; aucune optimisation d'alpha.
  for (base in list(qs_complet, qs_brut)) for (d in qs_dimensions) {
    items <- base[paste0(d, sprintf("%02d", 1:6))]
    correlations <- cor(items, use = "pairwise.complete.obs", method = "spearman")
    paires <- correlations[upper.tri(correlations)]
    testthat::expect_true(all(is.finite(paires)), info = d)
    testthat::expect_gt(mean(paires), 0, label = paste("Corrélation moyenne", d))
  }
})

testthat::test_that("la taille initiale reste de 2000 avant non-réponse", {
  testthat::expect_equal(nrow(qs_initial), 2000L)
  testthat::expect_equal(nrow(qs_initial), qs_config$echantillon$taille)
  suivi <- qs_lire(qs_config$non_reponse$sortie_complete)
  testthat::expect_identical(suivi$id_enseignant, qs_initial$id_enseignant)
  testthat::expect_setequal(qs_brut$id_enseignant, suivi$id_enseignant[suivi$repondant == 1L])
})

testthat::test_that("les manquants, les questionnaires partiels et les abandons sont présents", {
  codes <- qs_dict$variable
  testthat::expect_false(anyNA(qs_complet[codes]))
  testthat::expect_gt(sum(is.na(qs_brut[codes])), 0)
  testthat::expect_gt(mean(is.na(qs_brut[tail(qs_ordre$variable, qs_config$imperfections$nombre_items_fin)])),
    mean(is.na(qs_brut[head(qs_ordre$variable, -qs_config$imperfections$nombre_items_fin)])))
  testthat::expect_gt(sum(qs_brut$statut_questionnaire == "Partiel"), 0)
  testthat::expect_equal(sum(qs_brut$statut_questionnaire == "Abandon"), qs_config$imperfections$nombre_abandons)
  testthat::expect_equal(qs_brut$taux_completion, unname(rowMeans(!is.na(qs_brut[codes]))))
  testthat::expect_true(all(vapply(codes, function(nom) identical(qs_brut[[nom]], qs_imparfait[[nom]]), logical(1))))
})

testthat::test_that("les durées rapides et les réponses constantes injectées subsistent", {
  p <- qs_config$imperfections
  rapides <- qs_imparfait$flag_rapide_simule
  constants <- qs_imparfait$flag_straightlining_simule
  testthat::expect_equal(sum(rapides), p$nombre_rapides)
  testthat::expect_equal(sum(constants), p$nombre_straightlining)
  testthat::expect_true(all(qs_brut$duree_secondes[rapides] >= min(p$duree_rapide) &
    qs_brut$duree_secondes[rapides] <= max(p$duree_rapide)))
  testthat::expect_true(all(qs_brut$duree_secondes[!rapides] >= p$duree_min_normale))
  nombres <- rowSums(!is.na(qs_brut[qs_items]))
  part_modale <- apply(qs_brut[qs_items], 1, function(z) max(table(z)) / sum(!is.na(z)))
  testthat::expect_true(all(nombres[constants] > 0))
  testthat::expect_true(all(part_modale[constants] >= 0.90))
  # La vérité d'injection sert aux tests, jamais comme entrée du détecteur qualité.
  testthat::expect_false(any(c("flag_rapide_simule", "flag_straightlining_simule") %in% names(qs_brut)))
})
