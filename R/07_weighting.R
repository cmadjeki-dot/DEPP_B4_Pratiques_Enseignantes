# Pondération puis calibration sur des totaux synthétiques connus.
if(!file.exists("config/config.yml")) stop("Exécuter depuis la racine du projet.")
for(pkg in c("yaml","survey")) if(!requireNamespace(pkg,quietly=TRUE)) stop("Package absent : ",pkg," ; restaurer renv avant reprise.")
config <- yaml::read_yaml("config/config.yml")
source("R/functions/strates.R",encoding="UTF-8")
source("R/functions/weighting.R",encoding="UTF-8")
chemins_source <- c(config$nettoyage$sortie_clean,config$echantillon$sortie,config$non_reponse$sortie_complete,config$population$sortie)
empreintes <- tools::md5sum(chemins_source)
base <- readRDS(chemins_source[1]); initial <- readRDS(chemins_source[2]); suivi <- readRDS(chemins_source[3])
stopifnot(identical(initial$id_enseignant,suivi$id_enseignant),all(base$id_enseignant %in% suivi$id_enseignant[suivi$repondant==1]))
population <- construire_strates_sondage(readRDS(chemins_source[4]))$population
z <- ponderer_questionnaire(base,initial,suivi,population,config$ponderation)
for(nom in c("correction","marges","diagnostics","comparaison")) {
  tab <- z[[nom]]; tab$avertissement <- config$projet$avertissement
  chemin <- if(nom=="correction") "metadata/correction_non_reponse.csv" else paste0("outputs/tables/ponderation_",nom,".csv")
  write.csv(tab,chemin,row.names=FALSE,fileEncoding="UTF-8")
  stopifnot(isTRUE(all.equal(tab,read.csv(chemin,fileEncoding="UTF-8"),check.attributes=FALSE)))
}
sortie <- config$ponderation$sortie
if(file.exists(sortie)) {
  if(!identical(readRDS(sortie),z$base)) stop("Sortie différente existante : choisir une version distincte.")
} else saveRDS(z$base,sortie,compress="gzip",version=3)
stopifnot(identical(readRDS(sortie),z$base),identical(empreintes,tools::md5sum(chemins_source)))
saveRDS(z$plan,"outputs/models/plan_calibre.rds",compress="gzip",version=3)
cat(config$projet$avertissement,"\n")
print(z$correction,row.names=FALSE); print(z$diagnostics,row.names=FALSE)
cat("Facteurs de calibration :",range(z$base$facteur_calibration),"\n")
cat("Écart maximal de marge :",max(abs(z$marges$ecart)),"\n")

# Conserver la structure de calibration : ne pas reconstruire un plan à poids fixes.
design_depp <- z$plan
design_depp$variables$poids_final <- z$base$poids_final
design_depp$variables$facteur_nr <- z$base$facteur_nr
design_depp$variables$facteur_calibration <- z$base$facteur_calibration
attr(design_depp,"avertissement") <- config$projet$avertissement
attr(design_depp,"limite_variance") <- "Plan stratifié calibré de travail ; incertitude des facteurs NR non intégralement propagée, sans FPC."
stopifnot(isTRUE(all.equal(as.numeric(weights(design_depp)),z$base$poids_final)),
  identical(design_depp$variables$id_enseignant,z$base$id_enseignant))
verification <- do.call(rbind,lapply(c("strate_sondage","degre","secteur","education_prioritaire","sexe"),function(nom) {
  do.call(rbind,lapply(sort(unique(population[[nom]])),function(g) {
    dsg <- design_depp
    dsg$variables$indicateur_verification <- as.numeric(dsg$variables[[nom]]==g)
    estime <- as.numeric(coef(survey::svymean(~indicateur_verification,dsg)))
    cible <- mean(population[[nom]]==g)
    data.frame(variable=nom,modalite=g,proportion_population=cible,proportion_survey=estime,ecart=estime-cible)
  }))
}))
stopifnot(max(abs(verification$ecart))<1e-7)
saveRDS(design_depp,"data/processed/design_depp.rds",compress="gzip",version=3)
relu <- readRDS("data/processed/design_depp.rds")
stopifnot(identical(as.numeric(weights(relu)),as.numeric(weights(design_depp))),
  identical(relu$variables,design_depp$variables),length(relu$postStrata)>0)
source("R/functions/diagnostic_weights.R",encoding="UTF-8")
tables <- c(diagnostiquer_poids(z$base),list(sensibilite_ponderation=sensibilite_poids(z$base,population),verification_design=verification))
for(nom in names(tables)) {
  tab <- tables[[nom]]; rownames(tab) <- NULL
  tab$avertissement <- config$projet$avertissement
  chemin <- paste0("outputs/tables/",nom,".csv")
  write.csv(tab,chemin,row.names=FALSE,fileEncoding="UTF-8")
  stopifnot(isTRUE(all.equal(tab,read.csv(chemin,fileEncoding="UTF-8"),check.attributes=FALSE)))
}
print(tables$diagnostic_poids,row.names=FALSE)
print(tables$sensibilite_ponderation[c("indicateur","ponderation","estimation","cible_population")],row.names=FALSE)
stopifnot(identical(empreintes,tools::md5sum(chemins_source)))
