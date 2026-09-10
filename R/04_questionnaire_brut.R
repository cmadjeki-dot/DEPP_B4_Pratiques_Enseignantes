# Assemblage déterministe de la livraison de collecte, sans nettoyage.
# Exécution depuis la racine : Rscript.exe R/04_questionnaire_brut.R
if (!file.exists("config/config.yml")) stop("Exécuter depuis la racine du projet.")
if (!requireNamespace("yaml", quietly = TRUE)) stop("Restaurer les dépendances renv.")
config <- yaml::read_yaml("config/config.yml")
source("R/functions/items.R", encoding = "UTF-8")
collecte <- readRDS(config$imperfections$sortie)
echantillon <- readRDS(config$echantillon$sortie)
dictionnaire <- read.csv("metadata/dictionnaire_variables.csv", fileEncoding = "UTF-8")
variables_questionnaire <- dictionnaire$variable
variables_terrain <- c("repondant", "statut_questionnaire", "duree_secondes",
  "date_reponse_simulee", "taux_completion")
variables_livrees <- c(names(echantillon), variables_questionnaire, variables_terrain)
stopifnot(!anyDuplicated(variables_livrees), all(variables_livrees %in% names(collecte)),
  length(variables_questionnaire) == 68L,
  all(collecte$id_enseignant %in% echantillon$id_enseignant),
  !anyDuplicated(echantillon$id_enseignant))
# Les caractéristiques et poids déjà joints doivent correspondre à la base de sondage.
indices <- match(collecte$id_enseignant, echantillon$id_enseignant)
for (nom in names(echantillon)) stopifnot(identical(collecte[[nom]], echantillon[[nom]][indices]))
questionnaire_brut <- collecte[variables_livrees]
# Ne pas livrer les paramètres latents ou les vérités d'injection en attributs.
attributes(questionnaire_brut) <- list(names = variables_livrees,
  row.names = attr(collecte, "row.names"), class = "data.frame")
attr(questionnaire_brut, "avertissement") <- config$projet$avertissement
attr(questionnaire_brut, "provenance") <- list(source = config$imperfections$sortie,
  script = "R/04_questionnaire_brut.R", traitement = "Assemblage sans nettoyage ni imputation",
  perimetre = "Questionnaires commencés ; non-répondants totaux conservés dans le fichier de suivi séparé")
# Identité cellule par cellule, y compris NA, durées et questionnaires abandonnés.
for (nom in variables_livrees) stopifnot(identical(questionnaire_brut[[nom]], collecte[[nom]]))
stopifnot(nrow(questionnaire_brut) == nrow(collecte),
  identical(unname(is.na(questionnaire_brut[variables_questionnaire])), unname(is.na(collecte[variables_questionnaire]))),
  !any(grepl("^(latent_|SCORE_|SCORE_PROV_|GAP_|flag_.*_simule)|_reverse$|^prob_reponse_theorique$", names(questionnaire_brut))))
sauver_simulation_validee(questionnaire_brut, config$questionnaire_brut$sortie)
cat(config$projet$avertissement, "\n")
cat("Base brute sauvegardée et relue :", config$questionnaire_brut$sortie, "\n")
cat("Dimensions :", dim(questionnaire_brut), "\n")
cat("Réponses manquantes conservées :", sum(is.na(questionnaire_brut[variables_questionnaire])), "\n")
cat("Identifiants dupliqués :", anyDuplicated(questionnaire_brut$id_enseignant), "\n")
print(table(questionnaire_brut$statut_questionnaire))
cat("Toutes les colonnes livrées sont identiques à la collecte source. Aucun tirage aléatoire.\n")
