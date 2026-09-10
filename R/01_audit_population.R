# Audit en lecture seule du RDS ; aucune correction directe des données.
# Exécution depuis la racine : Rscript.exe R/01_audit_population.R
if (!file.exists("config/config.yml")) stop("Exécuter depuis la racine du projet.")
if (!requireNamespace("yaml", quietly = TRUE)) stop("Restaurer les dépendances renv.")
config_audit <- yaml::read_yaml("config/config.yml")
p <- config_audit$population
source("R/functions/population.R", encoding = "UTF-8")
verifier_configuration_population(config_audit)
population_audit <- readRDS(p$sortie)
empreinte_avant <- unname(tools::md5sum(p$sortie))
message(config_audit$projet$avertissement)

# 1. Schéma attendu, indépendant du tableau effectivement lu.
numeriques <- c("age", "anciennete", "anciennete_classe", "effectif_classe", "formation_continue")
colonnes_attendues <- c("id_enseignant", "degre", "sexe", "age", "anciennete",
                       "anciennete_classe", "secteur", "education_prioritaire", "territoire",
                       "effectif_classe", "statut", "formation_continue",
                       "equipement_numerique", "discipline", "strate")
controles <- data.frame(controle = character(), statut = character(), detail = character())
ajouter_controle <- function(nom, ok, detail, vigilance = FALSE) {
  controles[nrow(controles) + 1L, ] <<- list(
    nom, if (isTRUE(ok)) "OK" else if (vigilance) "VIGILANCE" else "ERREUR", detail
  )
}
ajouter_controle("Dimensions", is.data.frame(population_audit) &&
                   nrow(population_audit) == p$taille && ncol(population_audit) == 15L,
                 paste(nrow(population_audit), "lignes ;", ncol(population_audit), "colonnes"))
schema_ok <- identical(names(population_audit), colonnes_attendues)
ajouter_controle("Noms et ordre des variables", schema_ok, paste(names(population_audit), collapse = ", "))
if (!schema_ok || !is.data.frame(population_audit)) {
  print(controles, row.names = FALSE)
  stop("Schéma non conforme : corriger le générateur avant de régénérer.")
}
types_attendus <- ifelse(names(population_audit) %in% numeriques, "integer", "character")
types_observes <- vapply(population_audit, typeof, character(1))
variables <- data.frame(
  variable = names(population_audit), type_attendu = types_attendus,
  type_observe = unname(types_observes),
  valeurs_manquantes = vapply(population_audit, function(x) sum(is.na(x)), integer(1)),
  valeurs_distinctes = vapply(population_audit, function(x) length(unique(x)), integer(1)),
  row.names = NULL
)
ajouter_controle("Types", all(types_observes == types_attendus), "Attendus : 5 entiers et 10 chaînes de caractères")
ajouter_controle("Valeurs manquantes", !anyNA(population_audit),
                 paste(sum(is.na(population_audit)), "cellules manquantes"))
vides <- sum(vapply(population_audit[vapply(population_audit, is.character, logical(1))],
                    function(x) sum(!is.na(x) & trimws(x) == ""), integer(1)))
ajouter_controle("Chaînes vides", vides == 0L, paste(vides, "chaînes vides ou blanches"))
doublons_id <- sum(duplicated(population_audit$id_enseignant))
doublons_lignes <- sum(duplicated(population_audit))
ajouter_controle("Doublons", doublons_id == 0L && doublons_lignes == 0L,
                 paste(doublons_id, "identifiants ;", doublons_lignes, "lignes complètes"))
ajouter_controle("Format des identifiants", identical(population_audit$id_enseignant,
                   sprintf("ENS%06d", seq_len(p$taille))), "Séquence ENS unique et complète")

# 2. Bornes et cohérences numériques, sans remplacer ni tronquer aucune valeur.
bornes_min <- c(p$age$minimum, 0, 0, p$effectif_classe$minimum, 0)
bornes_max <- c(p$age$maximum, p$age$maximum - p$anciennete$age_entree_minimum,
                p$age$maximum - p$anciennete$age_entree_minimum,
                p$effectif_classe$maximum, p$formation_continue$maximum_jours)
bornes <- do.call(rbind, lapply(seq_along(numeriques), function(i) {
  x <- population_audit[[numeriques[i]]]
  if (!is.numeric(x)) stop("Type numérique invalide : ", numeriques[i])
  data.frame(variable = numeriques[i], minimum_attendu = bornes_min[i],
             maximum_attendu = bornes_max[i], minimum = min(x, na.rm = TRUE),
             q1 = unname(quantile(x, 0.25, na.rm = TRUE)), mediane = median(x, na.rm = TRUE),
             moyenne = mean(x, na.rm = TRUE),
             q3 = unname(quantile(x, 0.75, na.rm = TRUE)), maximum = max(x, na.rm = TRUE),
             anomalies = sum(!is.finite(x) | x < bornes_min[i] | x > bornes_max[i] |
                               x != floor(x), na.rm = TRUE))
}))
ajouter_controle("Bornes et nombres entiers", sum(bornes$anomalies) == 0L,
                 paste(sum(bornes$anomalies), "valeurs numériques impossibles"))
incoherences_age <- with(population_audit, sum(anciennete < 0 |
  anciennete > age - p$anciennete$age_entree_minimum, na.rm = TRUE))
incoherences_niveau <- with(population_audit, sum(anciennete_classe < 0 |
  anciennete_classe > anciennete, na.rm = TRUE))
ajouter_controle("Âge / ancienneté", incoherences_age == 0L, paste(incoherences_age, "incohérences"))
ajouter_controle("Ancienneté dans le niveau", incoherences_niveau == 0L,
                 paste(incoherences_niveau, "incohérences avec l'ancienneté totale"))

# 3. Modalités autorisées et distributions, y compris les effectifs nuls.
modalites <- list(degre = p$degres, sexe = p$sexes, secteur = p$secteurs,
  education_prioritaire = p$education_prioritaire, territoire = p$territoires,
  statut = c(p$statut$public, p$statut$prive),
  equipement_numerique = p$equipement_numerique$modalites,
  discipline = c(p$disciplines$premier, p$disciplines$college))
distributions <- do.call(rbind, lapply(names(modalites), function(nom) {
  x <- population_audit[[nom]]
  inattendues <- setdiff(unique(x), modalites[[nom]])
  ajouter_controle(paste("Modalités", nom), length(inattendues) == 0L,
                   if (length(inattendues)) paste(inattendues, collapse = ", ") else "Aucune modalité inattendue")
  etiquettes <- unique(c(modalites[[nom]], x[!is.na(x)]))
  effectifs <- vapply(etiquettes, function(m) sum(x == m, na.rm = TRUE), integer(1))
  data.frame(variable = nom, modalite = etiquettes, effectif = effectifs,
             pourcentage = 100 * effectifs / nrow(population_audit), row.names = NULL)
}))
prive <- population_audit$secteur == "Privé sous contrat"
premier <- population_audit$degre == "Premier degré"
college <- population_audit$degre == "Collège"
erreurs_prive <- sum(prive & population_audit$education_prioritaire != "Hors EP", na.rm = TRUE)
erreurs_discipline <- sum(premier & population_audit$discipline != p$disciplines$premier, na.rm = TRUE) +
  sum(college & !population_audit$discipline %in% p$disciplines$college, na.rm = TRUE)
erreurs_statut <- sum(prive & !population_audit$statut %in% p$statut$prive, na.rm = TRUE) +
  sum(!prive & !population_audit$statut %in% p$statut$public, na.rm = TRUE)
ajouter_controle("Privé / éducation prioritaire", erreurs_prive == 0L, paste(erreurs_prive, "incohérences"))
ajouter_controle("Degré / discipline", erreurs_discipline == 0L, paste(erreurs_discipline, "incohérences"))
ajouter_controle("Secteur / statut", erreurs_statut == 0L, paste(erreurs_statut, "incohérences"))

# 4. Reconstituer les strates admissibles indépendamment des strates observées.
grille <- expand.grid(degre = p$degres, secteur = p$secteurs,
                     education_prioritaire = p$education_prioritaire,
                     territoire = p$territoires, stringsAsFactors = FALSE)
grille <- grille[grille$secteur == "Public" | grille$education_prioritaire == "Hors EP", ]
grille$strate <- with(grille, paste(degre, secteur, education_prioritaire, territoire, sep = " | "))
strates_recalculees <- with(population_audit, paste(degre, secteur, education_prioritaire, territoire, sep = " | "))
ajouter_controle("Codage des strates", identical(population_audit$strate, strates_recalculees) &&
                   all(population_audit$strate %in% grille$strate), "Croisement degré × secteur × EP × territoire")
grille$effectif <- vapply(grille$strate, function(s) sum(population_audit$strate == s, na.rm = TRUE), integer(1))
grille$pourcentage <- 100 * grille$effectif / nrow(population_audit)
# Seuils descriptifs de vigilance choisis pour cet audit, sans valeur normative.
seuil_tres_petite <- 100L
seuil_petite <- 200L
grille$vigilance <- ifelse(grille$effectif == 0, "Vide",
  ifelse(grille$effectif < seuil_tres_petite, "Très petite (<100)",
         ifelse(grille$effectif < seuil_petite, "Petite (<200)", "RAS")))
grille <- grille[order(grille$effectif, grille$strate), ]
ajouter_controle("Strates admissibles présentes", all(grille$effectif > 0),
                 paste(sum(grille$effectif > 0), "sur", nrow(grille), "strates"))
ajouter_controle("Petites strates", all(grille$effectif >= seuil_petite),
                 paste(sum(grille$effectif < seuil_tres_petite), "strate(s) <100 ;",
                       sum(grille$effectif < seuil_petite), "strate(s) <200 ; minimum", min(grille$effectif)),
                 vigilance = TRUE)

# 5. Vérifier les métadonnées et comparer avec une génération indépendante en mémoire.
ajouter_controle("Paramètres embarqués", identical(attr(population_audit, "configuration_simulation"), p) &&
                   identical(attr(population_audit, "graine"), p$graine) &&
                   identical(attr(population_audit, "avertissement"), config_audit$projet$avertissement),
                 paste("Graine", p$graine, "; configuration et avertissement comparés"))
population_regeneree <- generer_population(config_audit)
ajouter_controle("Reproductibilité intégrale", identical(population_audit, population_regeneree),
                 "Comparaison de toutes les valeurs, de l'ordre, des types et des attributs")
ajouter_controle("RDS non modifié", identical(empreinte_avant, unname(tools::md5sum(p$sortie))),
                 "Empreinte identique avant/après ; aucune écriture du RDS")

# 6. Sauvegarder les seuls résultats d'audit, accompagnés de l'avertissement.
dossier_audit <- "outputs/tables"
if (!dir.exists(dossier_audit)) stop("Dossier outputs/tables absent.")
tables <- list(controles = controles, variables = variables, bornes = bornes,
               categories = distributions, strates = grille)
for (nom in names(tables)) {
  tableau <- tables[[nom]]
  tableau$avertissement <- config_audit$projet$avertissement
  write.csv2(tableau, file.path(dossier_audit, paste0("audit_population_", nom, ".csv")),
             row.names = FALSE, fileEncoding = "UTF-8")
}
rapport <- c("# Audit de la population simulée", "", config_audit$projet$avertissement, "",
  "## Contrôles", "", "| Contrôle | Statut | Détail |", "|---|---|---|",
  paste0("| ", controles$controle, " | ", controles$statut, " | ",
         gsub("|", "/", controles$detail, fixed = TRUE), " |"), "",
  "## Petites strates", "",
  "Seuils descriptifs de l'audit : moins de 100 (très petite), moins de 200 (petite).",
  "Ce sont des points de vigilance pour la future allocation, pas des erreurs de population.", "",
  paste0("- ", grille$strate[grille$effectif < seuil_petite], " : ",
         grille$effectif[grille$effectif < seuil_petite], " enseignants fictifs."), "",
  "Le plan de sondage n'a pas été modifié. Aucun RDS n'a été réécrit.",
  "Les distributions sont auditées par rapport aux hypothèses du générateur,",
  "sans validation de leur représentativité de la population enseignante réelle.")
writeLines(enc2utf8(rapport), file.path(dossier_audit, "audit_population.md"), useBytes = TRUE)
print(controles, row.names = FALSE)
cat("\nTypes et valeurs manquantes :\n")
print(variables, row.names = FALSE)
cat("\nBornes et résumés numériques :\n")
print(bornes, row.names = FALSE)
cat("\nDistributions catégorielles simulées :\n")
print(distributions, row.names = FALSE)
cat("\nStrates, de la plus petite à la plus grande :\n")
print(grille[c("strate", "effectif", "pourcentage", "vigilance")], row.names = FALSE)
if (any(controles$statut == "ERREUR")) {
  stop("Audit non conforme : consulter le tableau, corriger le script source puis régénérer.")
}
message("Audit terminé : ", sum(controles$statut == "OK"), " contrôles OK ; ",
        sum(controles$statut == "VIGILANCE"), " point(s) de vigilance ; reproductibilité vérifiée.")
