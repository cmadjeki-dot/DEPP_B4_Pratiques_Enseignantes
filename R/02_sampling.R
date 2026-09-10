# Construire les huit strates, leur allocation et tirer l'échantillon sans remise.
# Exécution depuis la racine : Rscript.exe R/02_sampling.R
if (!file.exists("config/config.yml")) stop("Exécuter depuis la racine du projet.")
if (!requireNamespace("yaml", quietly = TRUE)) stop("Restaurer les dépendances renv.")
config <- yaml::read_yaml("config/config.yml")
source("R/functions/population.R", encoding = "UTF-8")
source("R/functions/strates.R", encoding = "UTF-8")
source("R/functions/tirage.R", encoding = "UTF-8")
verifier_configuration_population(config)
population <- readRDS(config$population$sortie)
verifier_population(population, config)
message(config$projet$avertissement)

# Conserver la strate descriptive d'origine et ajouter strate_sondage en mémoire.
# Cette transformation est déterministe : aucune graine ni aucun tirage requis.
stratification <- construire_strates_sondage(population)
population_sondage <- stratification$population
taille_strates <- stratification$tailles
stopifnot(nrow(population_sondage) == config$population$taille,
          !anyNA(population_sondage$strate_sondage),
          !anyDuplicated(population_sondage$id_enseignant),
          identical(population_sondage$strate, population$strate),
          nrow(taille_strates) == 8L)

# Au moins deux unités par strate permettent une future estimation de variance.
# La capacité exacte n_h <= N_h est contrôlée dans calculer_allocation ci-dessous.
if (any(taille_strates$N_h < 2L)) stop("Une strate contient moins de deux enseignants.")
if (all(taille_strates$N_h >= config$echantillon$taille)) {
  message("Capacité vérifiée : chaque strate contient au moins les ",
          config$echantillon$taille, " unités prévues au total dans l'échantillon.")
} else {
  message("Strates non vides ; vérification de la capacité par strate ci-dessous.")
}

# Afficher puis sauvegarder les seules tailles ; le RDS source reste inchangé.
cat("\nHuit strates opérationnelles — population entièrement simulée :\n")
print(taille_strates, row.names = FALSE, digits = 7)
sortie_strates <- "metadata/taille_strates.csv"
if (!dir.exists(dirname(sortie_strates))) stop("Dossier metadata absent.")
write.csv(taille_strates, sortie_strates, row.names = FALSE, fileEncoding = "UTF-8")
verification_csv <- read.csv(sortie_strates, stringsAsFactors = FALSE, fileEncoding = "UTF-8")
stopifnot(isTRUE(all.equal(taille_strates, verification_csv, check.attributes = TRUE)),
          sum(verification_csv$N_h) == nrow(population),
          abs(sum(verification_csv$part_population) - 1) < 1e-12)
message("Contrôles OK : partition exhaustive et exclusive ; 8 strates ; ",
        sum(taille_strates$N_h), " enseignants. Tableau enregistré : ", sortie_strates,
        ". Strates prêtes pour le tirage.")

# Allocation fixée dans config.yml : 1 000 enseignants par degré, 2 000 au total.
effectifs_alloues <- unlist(config$echantillon$allocation, use.names = TRUE)
allocation_echantillon <- calculer_allocation(
  taille_strates, effectifs_alloues, config$echantillon$taille
)
stopifnot(nrow(allocation_echantillon) == 8L,
          sum(allocation_echantillon$n_h) == config$echantillon$taille)
cat("\nAllocation finale simulée — probabilités et poids avant non-réponse :\n")
print(allocation_echantillon, row.names = FALSE, digits = 9)
sortie_allocation <- "metadata/allocation_echantillon.csv"
write.csv(allocation_echantillon, sortie_allocation, row.names = FALSE, fileEncoding = "UTF-8")
allocation_relue <- read.csv(sortie_allocation, stringsAsFactors = FALSE, fileEncoding = "UTF-8")
stopifnot(isTRUE(all.equal(allocation_echantillon, allocation_relue)),
          sum(allocation_relue$n_h) == config$echantillon$taille,
          all(allocation_relue$n_h <= allocation_relue$N_h),
          all(allocation_relue$pi_h > 0 & allocation_relue$pi_h <= 1),
          all(allocation_relue$poids_base > 0))
message("Allocation validée et relue : ", sortie_allocation,
        ". Total : ", sum(allocation_relue$n_h), ". Allocation prête pour le tirage.")

# Tirer uniquement après validation de l'allocation et de la population.
echantillon <- tirer_echantillon_stratifie(
  population_sondage, allocation_echantillon, config$echantillon$graine
)
stopifnot(nrow(echantillon) == config$echantillon$taille)
controle_tirage <- verifier_echantillon(echantillon, population_sondage, allocation_echantillon)
# Comparer deux tirages complets avec la même graine, avant toute sauvegarde.
stopifnot(identical(echantillon, tirer_echantillon_stratifie(
  population_sondage, allocation_echantillon, config$echantillon$graine
)))
sortie_echantillon <- config$echantillon$sortie
stopifnot(length(sortie_echantillon) == 1L,
          grepl("^data/simulated/[[:alnum:]_-]+[.]rds$", sortie_echantillon),
          dir.exists(dirname(sortie_echantillon)))
if (file.exists(sortie_echantillon)) {
  if (!identical(readRDS(sortie_echantillon), echantillon)) {
    stop("Un échantillon différent existe déjà : choisir un nouveau nom de sortie.")
  }
  message("Échantillon identique déjà présent : fichier conservé.")
} else {
  saveRDS(echantillon, sortie_echantillon, compress = "gzip", version = 3)
}
echantillon_relu <- readRDS(sortie_echantillon)
stopifnot(identical(echantillon, echantillon_relu))
verifier_echantillon(echantillon_relu, population_sondage, allocation_echantillon)
cat("\nContrôle du tirage stratifié — données simulées :\n")
print(controle_tirage, row.names = FALSE, digits = 8)
controle_tirage$avertissement <- config$projet$avertissement
sortie_controle <- "outputs/tables/controle_tirage_stratifie.csv"
write.csv(controle_tirage, sortie_controle, row.names = FALSE, fileEncoding = "UTF-8")
stopifnot(isTRUE(all.equal(controle_tirage,
  read.csv(sortie_controle, stringsAsFactors = FALSE, fileEncoding = "UTF-8"))))
message("Tirage validé : ", nrow(echantillon), " enseignants uniques ; graine ",
        config$echantillon$graine, ". Reproductibilité et relecture vérifiées. Sortie : ",
        sortie_echantillon)
