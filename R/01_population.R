# À exécuter depuis la racine du projet : Rscript.exe R/01_population.R
# Aucune donnée réelle : tous les paramètres sont des hypothèses de simulation.

# 1. Charger la configuration et les fonctions, sans installation automatique.
if (!file.exists("config/config.yml")) stop("Exécuter le script depuis la racine du projet.")
if (!requireNamespace("yaml", quietly = TRUE)) {
  stop("Le package yaml est absent. Restaurer l'environnement avec renv::restore().")
}
config <- yaml::read_yaml("config/config.yml")
source("R/functions/population.R", encoding = "UTF-8")
verifier_configuration_population(config)
message(config$projet$avertissement)

# 2. Générer la population ; generer_population appelle set.seed(20260909)
# avec la valeur lue dans config.yml. Les fonctions assurent les contrôles métier.
population <- generer_population(config)
stopifnot(nrow(population) == config$population$taille,
          ncol(population) == 15L, !anyNA(population),
          anyDuplicated(population$id_enseignant) == 0L)

# 3. Afficher les principaux contrôles et distributions (non officielles).
cat("\nNombre total d'enseignants fictifs :", nrow(population), "\n")
for (variable in c("degre", "secteur", "education_prioritaire", "territoire", "strate")) {
  cat("\nRépartition simulée par", variable, ":\n")
  repartition <- as.data.frame(table(population[[variable]]), stringsAsFactors = FALSE)
  names(repartition) <- c(variable, "effectif")
  repartition$pourcentage <- round(100 * repartition$effectif / nrow(population), 2)
  stopifnot(sum(repartition$effectif) == nrow(population))
  print(repartition, row.names = FALSE)
}
cat("\nRésumé de l'âge :\n")
print(summary(population$age))
cat("\nRésumé de l'ancienneté (années) :\n")
print(summary(population$anciennete))
cat("\nValeurs manquantes par variable :\n")
print(colSums(is.na(population)))
cat("\nContrôles OK : identifiants uniques, bornes, modalités, disciplines, strates,",
    "compatibilité âge-ancienneté et privé hors EP.\n")

# 4. Sauvegarder uniquement une sortie validée ; protéger un résultat antérieur.
sortie <- config$population$sortie
if (length(sortie) != 1L || !grepl("^data/simulated/[[:alnum:]_-]+[.]rds$", sortie)) {
  stop("La sortie doit être un fichier .rds directement dans data/simulated/.")
}
if (!dir.exists(dirname(sortie))) stop("Le dossier de sortie n'existe pas.")
if (file.exists(sortie)) {
  ancienne_population <- readRDS(sortie)
  if (!identical(ancienne_population, population)) {
    stop("La sortie existante diffère : choisir un nouveau nom dans la configuration.")
  }
  message("Population identique déjà présente : fichier conservé.")
} else {
  saveRDS(population, sortie, compress = "gzip", version = 3)
}
population_relue <- readRDS(sortie)
verifier_population(population_relue, config)
stopifnot(identical(population, population_relue))
message("Population simulée validée et sauvegardée : ", sortie,
        " (", nrow(population_relue), " lignes, ", ncol(population_relue), " colonnes).")
