# Nettoyage traçable : la base brute reste intacte, toutes les décisions sont sauvegardées.
if (!file.exists("config/config.yml")) stop("Exécuter depuis la racine du projet.")
if (!requireNamespace("yaml",quietly=TRUE)) stop("Restaurer renv.")
config <- yaml::read_yaml("config/config.yml")
source("R/functions/quality.R",encoding="UTF-8")
source("R/functions/cleaning.R",encoding="UTF-8")
source_brute <- config$questionnaire_brut$sortie
empreinte <- tools::md5sum(source_brute)
base <- readRDS(source_brute)
flags <- read.csv("outputs/tables/qualite_flags.csv",fileEncoding="UTF-8",colClasses=c(id_enseignant="character"))
synthese <- read.csv("outputs/tables/qualite_synthese.csv",fileEncoding="UTF-8")
d <- read.csv("metadata/dictionnaire_variables.csv",fileEncoding="UTF-8")
population <- readRDS(config$population$sortie)
# Recalcul indépendant : refuser des diagnostics périmés ou modifiés avant toute correction.
actuel <- auditer_qualite(base,readRDS(config$echantillon$sortie),readRDS(config$non_reponse$sortie_complete),
  population,d,read.csv("questionnaire/ordre_passation.csv",fileEncoding="UTF-8"),
  read.csv("metadata/plan_controles.csv",fileEncoding="UTF-8"))
for (nom in names(actuel$flags)) if (!isTRUE(all.equal(unname(flags[[nom]]),unname(actuel$flags[[nom]]),check.attributes=FALSE))) stop("Flags périmés : relancer R/05_quality.R ; ",nom)
stopifnot(identical(synthese$id_controle,actuel$synthese$id_controle),
  identical(synthese$resultat,actuel$synthese$resultat),length(actuel$details)>0)
resultat <- nettoyer_questionnaire(base,actuel$flags,d,population,config$nettoyage)
# Exporter le journal avant les bases corrigées ; ne pas écraser une sortie différente.
for (nom in c("journal","doublons")) {
  tableau <- resultat[[nom]]
  tableau$avertissement <- rep(config$projet$avertissement,nrow(tableau))
  chemin <- if(nom=="journal") "outputs/tables/journal_corrections.csv" else "outputs/tables/traitement_doublons.csv"
  write.csv(tableau,chemin,row.names=FALSE,fileEncoding="UTF-8")
  stopifnot(nrow(read.csv(chemin,fileEncoding="UTF-8"))==nrow(tableau))
}
chemins <- c(toutes=config$nettoyage$sortie_decisions,clean=config$nettoyage$sortie_clean,exclus=config$nettoyage$sortie_exclus)
for(nom in names(chemins)) {
  objet <- resultat[[nom]]; attr(objet,"empreinte_source") <- unname(empreinte)
  chemin <- chemins[[nom]]
  if(file.exists(chemin)) {
    if(!identical(readRDS(chemin),objet)) stop("Une sortie différente existe : choisir un nouveau nom/version : ",chemin)
  } else saveRDS(objet,chemin,compress="gzip",version=3)
  stopifnot(identical(objet,readRDS(chemin)))
}
stopifnot(nrow(resultat$clean)+nrow(resultat$exclus)==nrow(base),
  identical(base,readRDS(source_brute)),identical(empreinte,tools::md5sum(source_brute)))
cat(config$projet$avertissement,"\n")
print(table(resultat$toutes$statut_analyse))
cat("Brut :",nrow(base),"; inclus :",nrow(resultat$clean),"; exclus :",nrow(resultat$exclus),
  "; conservés (%) :",100*nrow(resultat$clean)/nrow(base),"\n")
cat("Sensibilité :",sum(resultat$toutes$flag_analyse_sensibilite),"; corrections :",nrow(resultat$journal),
  "; lignes en groupes de doublons :",nrow(resultat$doublons),"\n")
