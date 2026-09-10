# Traits, items, faisabilité et priorité ; scores moyens uniquement provisoires.
# Exécution depuis la racine : Rscript.exe R/04_questionnaire_simulation.R
if (!file.exists("config/config.yml")) stop("Exécuter depuis la racine du projet.")
if (!requireNamespace("yaml", quietly = TRUE)) stop("Restaurer les dépendances renv.")
config <- yaml::read_yaml("config/config.yml")
source("R/functions/latents.R", encoding = "UTF-8")
parametres <- config$dimensions_latentes
message(config$projet$avertissement)

# Générer le socle sur la base initiale, puis sélectionner les répondants par identifiant.
base_latente <- readRDS(config$echantillon$sortie)
stopifnot(nrow(base_latente) == config$echantillon$taille,
          !anyNA(base_latente$id_enseignant), !anyDuplicated(base_latente$id_enseignant))
if (!identical(parametres$population_reference, "repondants_simules")) {
  stop("Périmètre attendu : repondants_simules.")
}
repondants_latents <- readRDS(config$non_reponse$sortie_repondants)
statuts_latents <- readRDS(config$non_reponse$sortie_complete)
stopifnot(identical(statuts_latents$id_enseignant, base_latente$id_enseignant),
          identical(repondants_latents$id_enseignant,
                    statuts_latents$id_enseignant[statuts_latents$repondant == 1L]),
          !anyDuplicated(repondants_latents$id_enseignant),
          all(repondants_latents$repondant == 1L), nrow(repondants_latents) > 3L)
message("Traits sélectionnés pour ", nrow(repondants_latents), " répondants simulés.")

# Afficher et vérifier la matrice théorique AVANT le tirage.
correlation_theorique <- construire_correlation_latente(parametres)
cat("\nMatrice de corrélation théorique :\n")
print(correlation_theorique)
valeurs_propres <- verifier_correlation_latente(correlation_theorique)
cat("\nValeurs propres (toutes strictement positives) :\n")
print(valeurs_propres)
traits <- simuler_traits_latents(base_latente$id_enseignant, correlation_theorique, parametres$graine)
stopifnot(identical(traits, simuler_traits_latents(
  base_latente$id_enseignant, correlation_theorique, parametres$graine)))
# Garder les valeurs déjà attribuées, indépendamment du nombre de répondants.
indices_repondants <- match(repondants_latents$id_enseignant, traits$id_enseignant)
stopifnot(!anyNA(indices_repondants))
traits <- traits[indices_repondants, , drop = FALSE]
rownames(traits) <- NULL
correlation_observee <- cor(traits[-1])
dimnames(correlation_observee) <- dimnames(correlation_theorique)
cat("\nCorrélations observées de Pearson (non pondérées) :\n")
print(round(correlation_observee, 4))
indices <- which(upper.tri(correlation_theorique), arr.ind = TRUE)
comparaison <- data.frame(
  dimension_1 = rownames(correlation_theorique)[indices[, 1]],
  dimension_2 = colnames(correlation_theorique)[indices[, 2]],
  theorique = correlation_theorique[indices], observee = correlation_observee[indices]
)
comparaison$ecart <- comparaison$observee - comparaison$theorique
comparaison$ecart_absolu <- abs(comparaison$ecart)
comparaison$vigilance <- comparaison$ecart_absolu > parametres$seuil_ecart_descriptif
cat("\nComparaison des 28 paires :\n")
print(comparaison, row.names = FALSE, digits = 5)
cat("\nÉcart absolu maximal :", max(comparaison$ecart_absolu),
    "; écart absolu moyen :", mean(comparaison$ecart_absolu), "\n")
cat("\nMoyennes et écarts-types observés :\n")
print(data.frame(dimension = parametres$dimensions, moyenne = colMeans(traits[-1]),
                  ecart_type = vapply(traits[-1], sd, numeric(1))), row.names = FALSE)
if (any(comparaison$vigilance)) {
  warning("Écart supérieur au seuil descriptif : examiner le diagnostic ; ne pas forcer les corrélations.")
}

# Les huit dimensions sont actuellement un socle N_8(0, R), sans effets contextuels.
# Les effets de contexte seront introduits et documentés dans une étape distincte.
attr(traits, "avertissement") <- config$projet$avertissement
attr(traits, "population_reference") <- parametres$population_reference
attr(traits, "graine") <- parametres$graine
attr(traits, "correlation_theorique") <- correlation_theorique
attr(traits, "effets_contextuels") <- "Non introduits à cette étape"
sortie <- parametres$sortie
stopifnot(length(sortie) == 1L, grepl("^data/simulated/[[:alnum:]_-]+[.]rds$", sortie),
          !anyNA(traits), ncol(traits) == 9L)
if (file.exists(sortie)) {
  if (!identical(readRDS(sortie), traits)) stop("Une sortie différente existe : choisir un nouveau nom.")
} else {
  saveRDS(traits, sortie, compress = "gzip", version = 3)
}
stopifnot(identical(readRDS(sortie), traits))
exporter_matrice <- function(matrice, chemin) {
  tableau <- data.frame(dimension = rownames(matrice), matrice, row.names = NULL)
  tableau$population_reference <- parametres$population_reference
  tableau$avertissement <- config$projet$avertissement
  write.csv(tableau, chemin, row.names = FALSE, fileEncoding = "UTF-8")
}
exporter_matrice(correlation_theorique, "outputs/tables/correlation_latente_theorique.csv")
exporter_matrice(correlation_observee, "outputs/tables/correlation_latente_observee.csv")
comparaison$population_reference <- parametres$population_reference
comparaison$avertissement <- config$projet$avertissement
write.csv(comparaison, "outputs/tables/comparaison_correlations_latentes.csv",
           row.names = FALSE, fileEncoding = "UTF-8")
message("Traits continus validés et reproductibles : ", nrow(traits),
        " enseignants, 8 dimensions de référence. Sortie : ", sortie)

# Ajouter les effets contextuels sans écraser le socle latent de référence.
source("R/functions/items.R", encoding = "UTF-8")
contexte <- contextualiser_traits(traits, repondants_latents, base_latente,
                                  config$simulation_items$effets_contextuels)
traits_contextuels <- contexte$traits
correlation_contextuelle <- cor(traits_contextuels[-1])
stopifnot(min(eigen(correlation_contextuelle, symmetric = TRUE, only.values = TRUE)$values) > 0,
          max(abs(correlation_contextuelle[upper.tri(correlation_contextuelle)])) < 0.70)
cat("\nEffets contextuels sur les traits (avant/après) :\n")
print(contexte$diagnostic, row.names = FALSE, digits = 4)
cat("\nCorrélations après effets contextuels :\n")
print(round(correlation_contextuelle, 3))

# Définir les paramètres une seule fois, sans recherche d'un alpha cible.
dictionnaire <- read.csv("metadata/dictionnaire_variables.csv", stringsAsFactors = FALSE, fileEncoding = "UTF-8")
parametres_items <- parametrer_items(dictionnaire, config$simulation_items)
items <- simuler_items_ordinaux(traits_contextuels, parametres_items, config$simulation_items$graine_erreurs)
stopifnot(identical(items, simuler_items_ordinaux(traits_contextuels, parametres_items,
                                               config$simulation_items$graine_erreurs)))
codes_items <- dictionnaire$variable[dictionnaire$bloc == "PRATIQUES"]
stopifnot(identical(names(items)[-1], codes_items), identical(items$id_enseignant, repondants_latents$id_enseignant),
          length(codes_items) == 48L, !anyDuplicated(items$id_enseignant))
reponses_items <- repondants_latents
reponses_items[codes_items] <- items[codes_items]
attr(reponses_items, "parametres_items") <- parametres_items
attr(reponses_items, "graine_items") <- config$simulation_items$graine_erreurs
attr(reponses_items, "effets_contextuels") <- attr(traits_contextuels, "effets_contextuels")
stopifnot(nrow(reponses_items) == nrow(repondants_latents),
          ncol(reponses_items) == ncol(repondants_latents) + 48L, !anyNA(reponses_items))
for (nom in names(repondants_latents)) stopifnot(identical(reponses_items[[nom]], repondants_latents[[nom]]))

# Fréquences complètes : conserver les catégories absentes avec effectif zéro.
frequences_items <- do.call(rbind, lapply(codes_items, function(code) {
  effectifs <- tabulate(items[[code]], nbins = 5)
  data.frame(variable = code, dimension = sub("[0-9]+$", "", code),
    modalite = 1:5, effectif = effectifs, pourcentage = 100 * effectifs / nrow(items))
}))
distributions_dimensions <- aggregate(effectif ~ dimension + modalite, frequences_items, sum)
distributions_dimensions$pourcentage <- 100 * distributions_dimensions$effectif / (6 * nrow(items))
stopifnot(nrow(frequences_items) == 48L * 5L,
          all(tapply(frequences_items$effectif, frequences_items$variable, sum) == nrow(items)),
          all(tapply(distributions_dimensions$effectif, distributions_dimensions$dimension, sum) == 6 * nrow(items)))
cat("\nDistribution de chaque dimension : réponses regroupées aux six items (pas des scores) :\n")
print(distributions_dimensions, row.names = FALSE, digits = 4)
cat("\nFréquences du premier item de chaque dimension :\n")
print(frequences_items[grepl("01$", frequences_items$variable), ], row.names = FALSE, digits = 4)
cat("\nSaturations :", range(parametres_items$loading),
    "; variances d'erreur :", range(parametres_items$variance_erreur), "\n")
plancher_plafond <- frequences_items[frequences_items$modalite %in% c(1L, 5L), ]
cat("Parts extrêmes par item (minimum/maximum, en %) :", range(plancher_plafond$pourcentage), "\n")

# Sauvegarder les deux objets distincts ; ne pas mélanger les traits vrais et les réponses.
sauver_simulation_validee(traits_contextuels, config$simulation_items$sortie_traits)
sauver_simulation_validee(reponses_items, config$simulation_items$sortie_reponses)
write.csv(parametres_items, "metadata/parametres_items.csv", row.names = FALSE, fileEncoding = "UTF-8")
exporter_matrice(correlation_contextuelle, "outputs/tables/correlation_latente_contextuelle.csv")
for (nom in c("frequences_items", "distributions_dimensions")) {
  tableau <- get(nom)
  tableau$avertissement <- config$projet$avertissement
  write.csv(tableau, paste0("outputs/tables/", nom, ".csv"), row.names = FALSE, fileEncoding = "UTF-8")
}
message("Génération validée : ", nrow(reponses_items), " répondants, 48 items entiers entre 1 et 5 ; ",
        "aucune valeur manquante à cette étape.")

# Simuler les deux blocs complémentaires et calculer les seuls scores exploratoires.
source("R/functions/faisabilite_priorite.R", encoding = "UTF-8")
p_complements <- config$faisabilite_priorite
dimensions <- parametres$dimensions
complements <- simuler_faisabilite_priorite(reponses_items, traits_contextuels, base_latente, dimensions, p_complements)
stopifnot(identical(complements, simuler_faisabilite_priorite(
  reponses_items, traits_contextuels, base_latente, dimensions, p_complements)))
codes_complements <- c(paste0("FAIS_", dimensions), paste0("PRIO_", dimensions))
stopifnot(setequal(codes_complements, dictionnaire$variable[dictionnaire$bloc %in% c("FAISABILITE", "PRIORITE")]))
frequences_complements <- do.call(rbind, lapply(codes_complements, function(nom) {
  effectifs <- tabulate(complements[[nom]], nbins = 5)
  data.frame(variable = nom, modalite = 1:5, effectif = effectifs,
    pourcentage = 100 * effectifs / nrow(complements))
}))
diagnostic_complements <- do.call(rbind, lapply(dimensions, function(d) {
  score <- complements[[paste0("SCORE_PROV_", d)]]
  gap <- complements[[paste0("GAP_", d)]]
  data.frame(dimension = d, score_provisoire_moyen = mean(score), gap_moyen = mean(gap),
    gap_min = min(gap), gap_max = max(gap),
    rho_priorite_pratiques = cor(complements[[paste0("PRIO_", d)]], score, method = "spearman"))
}))
stopifnot(nrow(frequences_complements) == 80L,
  all(tapply(frequences_complements$effectif, frequences_complements$variable, sum) == nrow(complements)),
  all(is.finite(diagnostic_complements$rho_priorite_pratiques)))
print(frequences_complements, row.names = FALSE)
print(diagnostic_complements, row.names = FALSE)
sauver_simulation_validee(complements, p_complements$sortie)
for (nom in c("frequences_complements", "diagnostic_complements")) {
  tableau <- get(nom)
  tableau$avertissement <- config$projet$avertissement
  chemin <- paste0("outputs/tables/", nom, ".csv")
  write.csv(tableau, chemin, row.names = FALSE, fileEncoding = "UTF-8")
  stopifnot(isTRUE(all.equal(tableau, read.csv(chemin, fileEncoding = "UTF-8"), check.attributes = FALSE)))
}
message("Compléments validés : 8 FAIS, 8 PRIO, 8 SCORE_PROV et 8 GAP exploratoires.")

# Ajouter les quatre contrôles et conserver séparément leurs deux recodages.
source("R/functions/controles.R", encoding = "UTF-8")
questionnaire <- simuler_controles(complements, config$controles)
stopifnot(identical(questionnaire, simuler_controles(complements, config$controles)),
  all(dictionnaire$variable %in% names(questionnaire)),
  setequal(dictionnaire$variable[dictionnaire$item_inverse], c("CTRL02", "CTRL04")))
frequences_controles <- do.call(rbind, lapply(sprintf("CTRL%02d", 1:4), function(nom) {
  ligne <- dictionnaire[dictionnaire$variable == nom, ]
  modalites <- seq.int(ligne$minimum, ligne$maximum)
  valeurs <- questionnaire[[nom]]
  stopifnot(all(valeurs %in% modalites), !anyNA(valeurs))
  effectifs <- as.integer(table(factor(valeurs, levels = modalites)))
  data.frame(variable = nom, modalite = modalites, effectif = effectifs,
    pourcentage = 100 * effectifs / nrow(questionnaire), avertissement = config$projet$avertissement)
}))
print(frequences_controles[1:4], row.names = FALSE)
sauver_simulation_validee(questionnaire, config$controles$sortie)
write.csv(frequences_controles, "outputs/tables/frequences_controles.csv", row.names = FALSE, fileEncoding = "UTF-8")
stopifnot(isTRUE(all.equal(frequences_controles,
  read.csv("outputs/tables/frequences_controles.csv", fileEncoding = "UTF-8"))))
message("Contrôles validés : CTRL01 à CTRL04 et deux recodages inverses ; aucun score principal modifié.")
