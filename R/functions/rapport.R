# Objets partagés par les pages Quarto ; arrêter sur une sortie absente ou périmée.
charger_rapport <- function() {
  lire <- function(n) read.csv(paste0("outputs/tables/",n,".csv"),fileEncoding="UTF-8",check.names=FALSE)
  objets <- readRDS("outputs/models/resultats_quarto.rds")
  stopifnot(identical(unname(tools::md5sum(objets$manifeste$fichier)),objets$manifeste$md5))
  provenance <- readRDS("outputs/models/provenance_modeles.rds")
  stopifnot(identical(provenance,tools::md5sum(names(provenance))))
  base <- readRDS("data/processed/base_analytique.rds")
  allocation <- read.csv("metadata/allocation_echantillon.csv",fileEncoding="UTF-8")
  alpha <- lire("alpha_cronbach"); omega <- lire("omega_mcdonald")
  psycho <- merge(alpha[c("dimension","n_complets","alpha_brut")],omega[c("dimension","omega_total_ordinal")],by="dimension",sort=FALSE)
  list(base=base,allocation=allocation,qualite=lire("dashboard_qualite"),psycho=psycho,
    parallel=lire("parallel_global"),scores=lire("gap_pratique_priorite"),profils=lire("taille_profils"),
    interpretations=lire("interpretation_profils"),clusters=lire("comparaison_clusters"),
    robustesse=lire("robustesse_clusters"),modeles=lire("modeles_finaux"),diagnostics=lire("diagnostic_modeles"),
    catalogue=objets$catalogue,table1=lire("table1_echantillon"),regles=lire("regles_scores_definitifs"))
}
fmt <- function(x,d=2) formatC(x,format="f",digits=d,decimal.mark=",",big.mark=" ")
pct <- function(x,d=1) paste0(fmt(100*x,d)," %")
ic <- function(x,bas,haut,d=2) paste0(fmt(x,d)," [",fmt(bas,d)," ; ",fmt(haut,d),"]")
table_rapport <- function(t) {
  t <- t[setdiff(names(t),"avertissement")]
  for(n in names(t)) if(is.numeric(t[[n]])) t[[n]] <- ifelse(is.na(t[[n]]),"—",fmt(t[[n]],if(all(t[[n]]==round(t[[n]]),na.rm=TRUE)) 0 else 3))
  knitr::kable(t,format="html",escape=TRUE,row.names=FALSE)
}
table_fichier <- function(n,colonnes=NULL) {
  t <- read.csv(paste0("outputs/tables/",n,".csv"),fileEncoding="UTF-8",check.names=FALSE)
  if(!is.null(colonnes)) t <- t[colonnes]
  table_rapport(t)
}
association <- function(r,modele,terme) {
  t <- r$modeles[r$modeles$modele==modele & r$modeles$terme==terme,]
  stopifnot(nrow(t)==1)
  ic(t$effet,t$effet_ic95_inf,t$effet_ic95_sup,3)
}
