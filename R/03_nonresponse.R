# Simuler la non-réponse totale sans toucher aux poids de sondage.
# Exécution : Rscript.exe R/03_nonresponse.R, depuis la racine du projet.
if (!file.exists("config/config.yml")) stop("Exécuter depuis la racine du projet.")
if (!requireNamespace("yaml", quietly = TRUE)) stop("Restaurer les dépendances renv.")
config <- yaml::read_yaml("config/config.yml")
source("R/functions/nonresponse.R", encoding = "UTF-8")
echantillon_initial <- readRDS(config$echantillon$sortie)
stopifnot(nrow(echantillon_initial) == config$echantillon$taille)
message(config$projet$avertissement)
echantillon_nonreponse <- simuler_non_reponse(echantillon_initial, config$non_reponse)
stopifnot(identical(echantillon_nonreponse,
                   simuler_non_reponse(echantillon_initial, config$non_reponse)))
repondants <- echantillon_nonreponse[echantillon_nonreponse$repondant == 1L, , drop = FALSE]
rownames(repondants) <- NULL
stopifnot(nrow(repondants) > 3L, nrow(repondants) < nrow(echantillon_initial),
          !anyDuplicated(repondants$id_enseignant), !anyNA(repondants),
          all(repondants$repondant == 1L), all(repondants$poids_base > 0))
codes <- names(config$echantillon$allocation)
controle_nonreponse <- do.call(rbind, lapply(codes, function(s) {
  x <- echantillon_nonreponse[echantillon_nonreponse$strate_sondage == s, ]
  data.frame(strate_sondage = s, n_initial = nrow(x), n_repondants = sum(x$repondant),
    n_nonrepondants = sum(x$repondant == 0L), taux_attendu = mean(x$prob_reponse_theorique),
    taux_observe = mean(x$repondant),
    somme_poids_repondants = sum(x$poids_base[x$repondant == 1L]))
}))
stopifnot(sum(controle_nonreponse$n_initial) == config$echantillon$taille,
          sum(controle_nonreponse$n_repondants) == nrow(repondants),
          all(controle_nonreponse$n_repondants >= 2L))
print(controle_nonreponse, row.names = FALSE, digits = 5)
cat("\nRépondants :", nrow(repondants), "; non-répondants :",
    sum(echantillon_nonreponse$repondant == 0L),
    "; taux observé :", mean(echantillon_nonreponse$repondant),
    "; taux attendu :", mean(echantillon_nonreponse$prob_reponse_theorique), "\n")
cat("Plage des probabilités :", range(echantillon_nonreponse$prob_reponse_theorique), "\n")
cat("Intercept logistique :", attr(echantillon_nonreponse, "non_reponse")$intercept, "\n")
cat("Somme des poids de base des répondants :", sum(repondants$poids_base), "\n")

# Valider les deux destinations avant écriture ; préserver toute sortie différente.
objets <- list(echantillon_nonreponse, repondants)
sorties <- c(config$non_reponse$sortie_complete, config$non_reponse$sortie_repondants)
stopifnot(length(sorties) == 2L, !anyDuplicated(sorties),
          all(grepl("^data/simulated/[[:alnum:]_-]+[.]rds$", sorties)))
for (i in seq_along(sorties)) {
  if (file.exists(sorties[i]) && !identical(readRDS(sorties[i]), objets[[i]])) {
    stop("Une sortie différente existe : choisir un nouveau chemin pour ", sorties[i])
  }
}
for (i in seq_along(sorties)) {
  if (!file.exists(sorties[i])) saveRDS(objets[[i]], sorties[i], compress = "gzip", version = 3)
  stopifnot(identical(readRDS(sorties[i]), objets[[i]]))
}
controle_nonreponse$avertissement <- config$projet$avertissement
write.csv(controle_nonreponse, "outputs/tables/controle_nonreponse.csv",
           row.names = FALSE, fileEncoding = "UTF-8")
message("Non-réponse totale validée et reproductible ; poids de base inchangés ; aucune réponse ordinale simulée.")

# Participation par caractéristiques du tirage, avant exclusions analytiques.
groupes <- echantillon_nonreponse[c("degre","secteur","education_prioritaire","territoire","strate_sondage")]
groupes$anciennete <- as.character(cut(echantillon_nonreponse$anciennete,c(-Inf,9,19,29,Inf),labels=c("0-9 ans","10-19 ans","20-29 ans","30 ans ou plus")))
groupes$formation_continue <- as.character(cut(echantillon_nonreponse$formation_continue,c(-Inf,0,4,Inf),labels=c("0 jour","1-4 jours","5 jours ou plus")))
taux_reponse <- do.call(rbind,lapply(names(groupes),function(nom) {
  do.call(rbind,lapply(sort(unique(groupes[[nom]])),function(g) {
    i <- which(groupes[[nom]]==g)
    data.frame(variable=nom,modalite=g,n_selectionnes=length(i),n_repondants=sum(echantillon_nonreponse$repondant[i]),
      taux_reponse=mean(echantillon_nonreponse$repondant[i]),taux_attendu_simulation=mean(echantillon_nonreponse$prob_reponse_theorique[i]))
  }))
}))
taux_reponse$avertissement <- config$projet$avertissement
write.csv(taux_reponse,"outputs/tables/taux_reponse.csv",row.names=FALSE,fileEncoding="UTF-8")
stopifnot(isTRUE(all.equal(taux_reponse,read.csv("outputs/tables/taux_reponse.csv",fileEncoding="UTF-8"),check.attributes=FALSE)))
print(taux_reponse[1:6],row.names=FALSE)
