# Contrôler les poids de base avant non-réponse, sans modifier aucune donnée.
# Exécution depuis la racine : Rscript.exe R/02_audit_poids.R
if (!file.exists("config/config.yml")) stop("Exécuter depuis la racine du projet.")
if (!requireNamespace("yaml", quietly = TRUE)) stop("Restaurer les dépendances renv.")
config_poids <- yaml::read_yaml("config/config.yml")
source("R/functions/population.R", encoding = "UTF-8")
source("R/functions/strates.R", encoding = "UTF-8")
population_poids <- readRDS(config_poids$population$sortie)
echantillon_poids <- readRDS(config_poids$echantillon$sortie)
allocation_csv <- read.csv("metadata/allocation_echantillon.csv", stringsAsFactors = FALSE)
message(config_poids$projet$avertissement)

# Recalculer N_h à partir de la population et n_h à partir de la configuration.
# Ne pas faire confiance aux seules colonnes embarquées dans l'échantillon.
verifier_population(population_poids, config_poids)
strates_poids <- construire_strates_sondage(population_poids)
plan_attendu <- calculer_allocation(strates_poids$tailles,
  unlist(config_poids$echantillon$allocation), config_poids$echantillon$taille)
if (!isTRUE(all.equal(allocation_csv, plan_attendu))) {
  stop("Allocation CSV incohérente avec la population/configuration : examiner R/02_sampling.R.")
}
colonnes <- c("id_enseignant", "strate_sondage", "N_h", "n_h", "pi_h", "poids_base")
stopifnot(all(colonnes %in% names(echantillon_poids)),
          !anyNA(echantillon_poids[colonnes]),
          !anyDuplicated(echantillon_poids$id_enseignant),
          nrow(echantillon_poids) == config_poids$echantillon$taille,
          setequal(echantillon_poids$strate_sondage, plan_attendu$strate_sondage),
          all(echantillon_poids$id_enseignant %in% population_poids$id_enseignant))
origines <- match(echantillon_poids$id_enseignant, strates_poids$population$id_enseignant)
stopifnot(identical(echantillon_poids$strate_sondage,
                   strates_poids$population$strate_sondage[origines]))
for (nom in c("N_h", "n_h", "pi_h", "poids_base")) {
  if (!is.numeric(echantillon_poids[[nom]])) stop("Type incorrect pour ", nom)
}

# Tolérance absolue pour les seules erreurs d'arrondi en virgule flottante.
# Aucun coefficient de normalisation ou de recalage n'est appliqué.
tolerance <- 1e-8
controle_poids <- do.call(rbind, lapply(seq_len(nrow(plan_attendu)), function(h) {
  attendu <- plan_attendu[h, ]
  x <- echantillon_poids[echantillon_poids$strate_sondage == attendu$strate_sondage, ]
  anomalies <- sum(!is.finite(x$poids_base) | x$poids_base <= 0 |
    !is.finite(x$pi_h) | x$pi_h <= 0 | x$pi_h > 1 |
    x$N_h != attendu$N_h | x$n_h != attendu$n_h |
    abs(x$pi_h - attendu$pi_h) > tolerance |
    abs(x$poids_base - attendu$poids_base) > tolerance)
  ecart <- sum(x$poids_base) - attendu$N_h
  conforme <- anomalies == 0L && nrow(x) == attendu$n_h &&
    is.finite(ecart) && abs(ecart) <= tolerance
  data.frame(strate_sondage = attendu$strate_sondage, n_h = nrow(x),
    n_prevu = attendu$n_h, N_h = attendu$N_h, pi_h = attendu$pi_h,
    poids_theorique = attendu$poids_base, poids_moyen = mean(x$poids_base),
    poids_minimum = min(x$poids_base), poids_maximum = max(x$poids_base),
    somme_poids = sum(x$poids_base), ecart = ecart, anomalies = anomalies,
    statut = if (conforme) "OK" else "ERREUR")
}))
somme_totale <- sum(echantillon_poids$poids_base)
ecart_total <- somme_totale - nrow(population_poids)
controle_total <- data.frame(n_h = nrow(echantillon_poids), N_h = nrow(population_poids),
  poids_moyen = mean(echantillon_poids$poids_base), somme_poids = somme_totale,
  ecart = ecart_total, tolerance = tolerance,
  statut = if (is.finite(ecart_total) && abs(ecart_total) <= tolerance &&
                 all(controle_poids$statut == "OK")) "OK" else "ERREUR")
cat("\nContrôle des poids de sondage par strate :\n")
print(controle_poids, row.names = FALSE, digits = 10)
cat("\nContrôle total :\n")
print(controle_total, row.names = FALSE, digits = 12)
controle_poids$avertissement <- config_poids$projet$avertissement
controle_total$avertissement <- config_poids$projet$avertissement
write.csv(controle_poids, "outputs/tables/controle_poids_strates.csv", row.names = FALSE,
           fileEncoding = "UTF-8")
write.csv(controle_total, "outputs/tables/controle_poids_total.csv", row.names = FALSE,
           fileEncoding = "UTF-8")
stopifnot(isTRUE(all.equal(controle_poids,
  read.csv("outputs/tables/controle_poids_strates.csv", stringsAsFactors = FALSE,
           fileEncoding = "UTF-8"))))
if (controle_total$statut != "OK") {
  stop("Incohérence détectée : examiner l'allocation et le tirage ; aucun poids modifié.")
}
message("Poids validés sans modification : somme totale = ", somme_totale,
        "; écart absolu maximal par strate = ", max(abs(controle_poids$ecart)), ".")
