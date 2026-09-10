# Exécuter depuis la racine après R/04_questionnaire_simulation.R.
if (!file.exists("config/config.yml")) stop("Exécuter depuis la racine du projet.")
if (!requireNamespace("yaml", quietly = TRUE)) stop("Restaurer les dépendances renv.")
config <- yaml::read_yaml("config/config.yml")
source("R/functions/imperfections.R", encoding = "UTF-8")
source("R/functions/items.R", encoding = "UTF-8")
base <- readRDS(config$controles$sortie)
ordre <- read.csv("questionnaire/ordre_passation.csv", fileEncoding = "UTF-8")
resultat <- introduire_imperfections(base, ordre, config$imperfections)
stopifnot(identical(resultat, introduire_imperfections(base, ordre, config$imperfections)))
# Vérifier les modalités non manquantes et la conservation du plan de sondage.
dictionnaire <- read.csv("metadata/dictionnaire_variables.csv", fileEncoding = "UTF-8")
for (j in seq_len(nrow(dictionnaire))) {
  valeurs <- resultat$donnees[[dictionnaire$variable[j]]]
  stopifnot(all(is.na(valeurs) | valeurs %in% seq.int(dictionnaire$minimum[j], dictionnaire$maximum[j])))
}
for (nom in setdiff(names(base), c(ordre$variable, grep("^(SCORE_PROV_|GAP_)|^CTRL0[24]_reverse$", names(base), value = TRUE)))) {
  stopifnot(identical(base[[nom]], resultat$donnees[[nom]]))
}
sauver_simulation_validee(resultat$donnees, config$imperfections$sortie)
for (nom in c("registre", "bilan")) {
  tableau <- resultat[[nom]]
  tableau$avertissement <- config$projet$avertissement
  chemin <- paste0("outputs/tables/", nom, "_imperfections.csv")
  write.csv(tableau, chemin, row.names = FALSE, fileEncoding = "UTF-8")
  classes <- vapply(tableau, function(x) class(x)[1], character(1))
  stopifnot(isTRUE(all.equal(tableau, read.csv(chemin, fileEncoding = "UTF-8", colClasses = classes), check.attributes = FALSE)))
}
cat(config$projet$avertissement, "\n")
print(resultat$bilan, row.names = FALSE)
print(table(resultat$donnees$statut_questionnaire))
cat("Cellules manquantes :", sum(is.na(resultat$donnees[ordre$variable])), "\n")
cat("Dimensions :", dim(resultat$donnees), "; doublons :", anyDuplicated(resultat$donnees$id_enseignant), "\n")
cat("Injection reproductible validée ; aucune anomalie nettoyée.\n")
