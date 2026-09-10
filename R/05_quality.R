# Contrôle qualité en lecture seule ; aucune décision de nettoyage.
if (!file.exists("config/config.yml")) stop("Exécuter depuis la racine du projet.")
if (!requireNamespace("yaml", quietly = TRUE)) stop("Restaurer les dépendances renv.")
config <- yaml::read_yaml("config/config.yml")
source("R/functions/quality.R", encoding = "UTF-8")
chemin <- config$questionnaire_brut$sortie
empreinte <- tools::md5sum(chemin)
base <- readRDS(chemin)
plan <- read.csv("metadata/plan_controles.csv", stringsAsFactors = FALSE, fileEncoding = "UTF-8")
stopifnot(nrow(plan) == 30L, !anyDuplicated(plan$id_controle),
  all(c("id_controle", "categorie", "variable", "description", "regle", "niveau_gravite", "action_prevue") %in% names(plan)))
resultat <- auditer_qualite(base, readRDS(config$echantillon$sortie),
  readRDS(config$non_reponse$sortie_complete), readRDS(config$population$sortie),
  read.csv("metadata/dictionnaire_variables.csv", fileEncoding = "UTF-8"),
  read.csv("questionnaire/ordre_passation.csv", fileEncoding = "UTF-8"), plan)
sorties <- c(resultat[setdiff(names(resultat), "details")], resultat$details)
for (nom in names(sorties)) {
  tableau <- sorties[[nom]]
  tableau$avertissement <- rep(config$projet$avertissement, nrow(tableau))
  sortie <- paste0("outputs/tables/qualite_", nom, ".csv")
  write.csv(tableau, sortie, row.names = FALSE, fileEncoding = "UTF-8")
  relu <- read.csv(sortie, fileEncoding = "UTF-8", colClasses = vapply(tableau, function(z) class(z)[1], character(1)))
  stopifnot(isTRUE(all.equal(tableau, relu, check.attributes = FALSE)))
}
stopifnot(identical(base, readRDS(chemin)), identical(empreinte, tools::md5sum(chemin)))
cat(config$projet$avertissement, "\n")
print(resultat$synthese[c("id_controle", "categorie", "n_anomalies", "n_non_evaluables", "resultat")], row.names = FALSE)
cat("Base brute conservée à l'identique ; sorties dans outputs/tables/qualite_*.csv\n")
if (length(resultat$details)) {
  print(resultat$details$completion, row.names = FALSE)
  print(resultat$details$durees, row.names = FALSE)
  print(resultat$details$distribution_straightlining, row.names = FALSE)
  for (nom in c("flag_straightlining", "flag_rapide", "flag_tres_rapide")) {
    z <- resultat$flags[[nom]]
    cat(nom, ":", sum(z, na.rm = TRUE), "sur", length(z),
      "soit", round(100 * sum(z, na.rm = TRUE) / length(z), 2),
      "% des reçus ; non évaluables :", sum(is.na(z)), "\n")
  }
}
source("R/functions/dashboard_quality.R", encoding = "UTF-8")
texte <- c(config$projet$avertissement, "", "SYNTHÈSE DU CONTRÔLE QUALITÉ")
for (gravite in c("CRITIQUE", "MAJEUR", "MINEUR")) {
  z <- resultat$synthese[resultat$synthese$niveau_gravite == gravite, ]
  texte <- c(texte, "", gravite, paste0(z$id_controle, " : ", z$description,
    " — ", z$resultat, " ; anomalies = ", z$n_anomalies,
    " ; non évaluables = ", z$n_non_evaluables, " ; unité = ", z$unite))
}
if (length(resultat$details)) {
  tableaux <- construire_dashboard_qualite(base, readRDS(config$echantillon$sortie),
    read.csv("metadata/dictionnaire_variables.csv",fileEncoding="UTF-8"),
    read.csv("questionnaire/ordre_passation.csv",fileEncoding="UTF-8"),resultat)
  for (nom in names(tableaux)) {
    z <- tableaux[[nom]]; z$avertissement <- rep(config$projet$avertissement,nrow(z))
    chemin_sortie <- paste0("outputs/tables/",nom,".csv")
    write.csv(z,chemin_sortie,row.names=FALSE,fileEncoding="UTF-8")
    stopifnot(isTRUE(all.equal(z,read.csv(chemin_sortie,fileEncoding="UTF-8",
      colClasses=vapply(z,function(v) class(v)[1],character(1))),check.attributes=FALSE)))
  }
  db <- tableaux$dashboard_qualite
  texte <- c(texte,"","INFORMATIF",capture.output(print(db,row.names=FALSE)),
    "Valeurs manquantes par bloc :",capture.output(print(tableaux$missing_par_bloc,row.names=FALSE)),
    "Position dans le questionnaire :",capture.output(print(tableaux$missing_par_position,row.names=FALSE)),
    "Association descriptive avec la durée :",capture.output(print(tableaux$missing_lien_duree,row.names=FALSE)),
    "Profils : voir missing_par_profil.csv (degré, secteur, strate, territoire, équipement, âge, formation et durée).",
    "Les associations sont non pondérées, sans interprétation causale ni identification du mécanisme MCAR/MAR/MNAR.",
    "La durée peut refléter la complétion ou l'abandon ; les effectifs et les mélanges de profils doivent être examinés.",
    "Les anomalies métier sont des signaux attendus : aucune exclusion ni imputation. Un contrôle critique non satisfait bloque la suite.",
    "Une erreur technique (lecture, schéma, calcul ou export impossible) ne doit pas être assimilée à une anomalie métier attendue.")
  print(db,row.names=FALSE)
} else texte <- c(texte,"","INFORMATIF","Tableau de bord non calculable : schéma incompatible. Consulter les contrôles structurels.")
writeLines(enc2utf8(texte),"outputs/tables/synthese_qualite.txt",useBytes=TRUE)
stopifnot(identical(readLines("outputs/tables/synthese_qualite.txt",encoding="UTF-8"),texte),
  identical(base,readRDS(chemin)),identical(empreinte,tools::md5sum(chemin)))
if (any(resultat$synthese$niveau_gravite == "CRITIQUE" & resultat$synthese$resultat != "OK")) {
  stop("Contrôle critique non satisfait : diagnostics sauvegardés ; examiner avant analyse.")
}
