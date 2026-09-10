# Descriptifs pondérés et scores provisoires ; aucune validation psychométrique implicite.
if(!file.exists("config/config.yml")) stop("Exécuter depuis la racine du projet.")
for(pkg in c("yaml","survey")) if(!requireNamespace(pkg,quietly=TRUE)) stop("Restaurer le package : ",pkg)
config <- yaml::read_yaml("config/config.yml")
source("R/functions/descriptive.R",encoding="UTF-8")
sources <- c(config$nettoyage$sortie_clean,"data/processed/design_depp.rds")
empreintes <- tools::md5sum(sources)
base <- readRDS(sources[1]); design <- readRDS(sources[2])
stopifnot(identical(base$id_enseignant,design$variables$id_enseignant),!anyDuplicated(base$id_enseignant),
  all(is.finite(weights(design))),all(weights(design)>0))
dict <- read.csv("metadata/dictionnaire_variables.csv",fileEncoding="UTF-8")
for(nom in dict$variable) stopifnot(identical(base[[nom]],design$variables[[nom]]))
exporter <- function(z,nom) {
  rownames(z) <- NULL; z$avertissement <- rep(config$projet$avertissement,nrow(z))
  chemin <- paste0("outputs/tables/",nom,".csv")
  write.csv(z,chemin,row.names=FALSE,fileEncoding="UTF-8")
  stopifnot(isTRUE(all.equal(z,read.csv(chemin,fileEncoding="UTF-8",colClasses=vapply(z,function(v)class(v)[1],character(1))),check.attributes=FALSE)))
}
# Table 1 : catégories et continus réunis dans un schéma explicite.
categories <- c("degre","sexe","statut","secteur","education_prioritaire","territoire","equipement_numerique")
table1 <- do.call(rbind,lapply(categories,function(nom) data.frame(variable=nom,type="categorielle",resumer_modalites(design,base[[nom]],sort(unique(base[[nom]][!is.na(base[[nom]])]))))))
formation <- ifelse(is.na(base$formation_continue),NA,ifelse(base$formation_continue>0,"Au moins un jour","Aucune"))
table1 <- rbind(table1,data.frame(variable="participation_formation",type="categorielle",resumer_modalites(design,formation,c("Aucune","Au moins un jour"))))
for(nom in c("moyenne_ponderee","ecart_type_pondere","mediane_ponderee")) table1[[nom]] <- NA_real_
for(nom in c("anciennete","formation_continue")) {
  r <- resumer_continue(design,base[[nom]])
  ligne <- table1[1,,drop=FALSE]; ligne[1,] <- NA
  ligne$variable <- nom; ligne$type <- "continue"; ligne$modalite <- "Ensemble"
  ligne$n_non_pondere <- r$n; ligne$n_observes <- r$n; ligne$n_manquants <- r$n_manquants
  for(v in c("moyenne_ponderee","ecart_type_pondere","mediane_ponderee","ic95_inf","ic95_sup","denominateur_pondere")) ligne[[v]] <- r[[v]]
  ligne$methode_ic <- "Moyenne : Student, plan calibré"
  table1 <- rbind(table1,ligne)
}
exporter(table1,"table1_echantillon")
# Descriptifs des items : seuils de vigilance fixés avant examen (15 % et 80 %).
items <- dict$variable[dict$bloc=="PRATIQUES"]
stopifnot(length(items)==48L)
frequences <- do.call(rbind,lapply(items,function(nom) data.frame(variable=nom,dimension=sub("[0-9]+$","",nom),resumer_modalites(design,base[[nom]],1:5))))
descriptif <- do.call(rbind,lapply(items,function(nom) {
  f <- frequences[frequences$variable==nom,]
  r <- data.frame(variable=nom,dimension=sub("[0-9]+$","",nom),resumer_continue(design,base[[nom]]))
  for(k in 1:5) { r[[paste0("n_",k)]] <- f$n_non_pondere[k]; r[[paste0("proportion_",k)]] <- f$pourcentage_pondere[k]/100 }
  r$flag_plancher <- r$proportion_1>=.15; r$flag_plafond <- r$proportion_5>=.15
  r$flag_faible_dispersion <- max(f$pourcentage_pondere)>=80 | r$ecart_type_pondere<.5
  r
}))
exporter(descriptif,"descriptif_items"); exporter(frequences,"frequences_items_ponderees")
dimensions <- config$dimensions_latentes$dimensions
provisoire <- data.frame(id_enseignant=base$id_enseignant)
comparaison <- list(); distributions <- list()
for(d in dimensions) {
  colonnes <- paste0(d,sprintf("%02d",1:6))
  score <- rowMeans(base[colonnes]) # NA si un seul des six items manque.
  nomscore <- paste0("score_provisoire_",d); nomgap <- paste0("GAP_",d)
  provisoire[[nomscore]] <- score
  provisoire[[nomgap]] <- base[[paste0("PRIO_",d)]]-score
  for(bloc in c("pratique_provisoire","faisabilite","priorite","GAP_provisoire")) {
    v <- switch(bloc,pratique_provisoire=score,faisabilite=base[[paste0("FAIS_",d)]],priorite=base[[paste0("PRIO_",d)]],GAP_provisoire=provisoire[[nomgap]])
    comparaison[[paste(d,bloc)]] <- data.frame(dimension=d,bloc=bloc,resumer_continue(design,v))
  }
  for(prefixe in c("FAIS_","PRIO_")) {
    nom <- paste0(prefixe,d)
    distributions[[nom]] <- data.frame(variable=nom,dimension=d,resumer_modalites(design,base[[nom]],1:5))
  }
  # Six barres empilées : chaque item a son propre dénominateur observé.
  f <- frequences[frequences$dimension==d,]
  m <- matrix(f$pourcentage_pondere,nrow=5,dimnames=list(1:5,colonnes))
  png(paste0("outputs/figures/distribution_items_",d,".png"),width=1500,height=1000,res=140)
  par(mar=c(6,6,4,2))
  barplot(m,horiz=TRUE,las=1,col=c("#b2182b","#ef8a62","#fddbc7","#67a9cf","#2166ac"),
    xlim=c(0,100),xlab="Pourcentage pondéré des réponses observées",main=paste("Dimension",d,"— six items"))
  legend("top",inset=c(0,-.055),xpd=TRUE,horiz=TRUE,bty="n",fill=c("#b2182b","#ef8a62","#fddbc7","#67a9cf","#2166ac"),
    legend=c("1 Jamais","2 Rarement","3 Parfois","4 Souvent","5 Très souvent"),cex=.8)
  mtext("Données simulées — démonstration méthodologique, sans résultat officiel DEPP",side=1,line=4.7,cex=.7)
  dev.off()
}
comparaison <- do.call(rbind,comparaison)
exporter(comparaison,"comparaison_pratique_faisabilite_priorite")
exporter(do.call(rbind,distributions),"distributions_faisabilite_priorite")
exporter(provisoire,"scores_provisoires_et_gaps")
stopifnot(nrow(descriptif)==48L,nrow(frequences)==240L,nrow(comparaison)==32L,
  all(abs(tapply(frequences$pourcentage_pondere,frequences$variable,sum)-100)<1e-7),
  all(as.matrix(provisoire[grep("^score",names(provisoire))])>=1 | is.na(as.matrix(provisoire[grep("^score",names(provisoire))]))),
  identical(empreintes,tools::md5sum(sources)))
cat(config$projet$avertissement,"\n")
print(comparaison[c("dimension","bloc","n","moyenne_ponderee","ic95_inf","ic95_sup")],row.names=FALSE)
cat("Table 1 :",nrow(table1),"lignes ; 48 items ; 8 graphiques. Sources inchangées.\n")

source("R/functions/comparaisons_descriptives.R",encoding="UTF-8")
groupes <- comparer_scores(design,provisoire,dimensions)
exporter(groupes$degres,"comparaison_scores_degre")
exporter(groupes$contextes,"scores_par_contexte")
figures_comparaisons(design,provisoire,comparaison,groupes$contextes,dimensions)
print(groupes$degres,row.names=FALSE)
fmt <- function(x) formatC(x,digits=3,format="f",decimal.mark=",")
prat <- comparaison[comparaison$bloc=="pratique_provisoire",]
dg <- groupes$degres; ctx <- groupes$contextes
formation_dev <- ctx[ctx$variable=="formation_groupe" & ctx$dimension=="DEV",]
gaps <- comparaison[comparaison$bloc=="GAP_provisoire",]
texte <- c("# Première synthèse descriptive", "", config$projet$avertissement, "",
  "Les scores et GAP sont provisoires, non validés psychométriquement. Les IC restent conditionnels au plan calibré de travail.", "",
  "1. **Base analysée.** Résultat : 1 509 enseignants inclus ; les scores complets par dimension reposent sur ",
  paste0("   ",min(prat$n)," à ",max(prat$n)," réponses. Interprétation : les dénominateurs varient. Limite : les manquants aux items ne sont pas corrigés par les seuls poids de questionnaire."), "",
  paste0("2. **Niveaux descriptifs.** Résultat : moyennes provisoires de ",fmt(min(prat$moyenne_ponderee))," (",prat$dimension[which.min(prat$moyenne_ponderee)],") à ",fmt(max(prat$moyenne_ponderee))," (",prat$dimension[which.max(prat$moyenne_ponderee)],"). Interprétation : les fréquences codées diffèrent entre dimensions. Limite : contenus et seuils diffèrent ; ce n'est pas un classement de qualité pédagogique."), "",
  paste0("3. **Degré.** Résultat : différences collège moins premier degré entre ",fmt(min(dg$difference_college_moins_premier))," et ",fmt(max(dg$difference_college_moins_premier))," point ; ",sum(dg$p_holm<.05)," des huit tests restent sous 5 % après Holm. Interprétation : ces écarts décrivent une association avec le degré. Limite : aucun ajustement des contextes ; significativité ne signifie pas importance pratique."), "",
  paste0("4. **Amplitude des écarts par degré.** Résultat : différence standardisée absolue maximale de ",fmt(max(abs(dg$difference_standardisee)))," écart-type global pondéré. Interprétation : cette unité complète les points de score. Limite : ce n'est pas un d de Cohen corrigé ni un seuil validé d'importance pédagogique."), "",
  paste0("5. **Formation et DEV.** Résultat : ",paste(paste0(formation_dev$modalite," : ",fmt(formation_dev$moyenne_ponderee)),collapse=" ; "),". Interprétation : la formation déclarée est associée à des niveaux descriptifs de DEV. Limite : association en partie inscrite dans le générateur, non preuve d'effet causal."), "",
  paste0("6. **Écarts priorité-pratique.** Résultat : les GAP moyens appariés vont de ",fmt(min(gaps$moyenne_ponderee))," à ",fmt(max(gaps$moyenne_ponderee)),". Interprétation : un signe positif indique un code de priorité supérieur au score de fréquence. Limite : ancrages différents, aucune mesure validée de besoin."), "",
  paste0("7. **Distribution des items.** Résultat : ",sum(descriptif$flag_plancher)," signaux plancher et ",sum(descriptif$flag_plafond)," signaux plafond au seuil descriptif de 15 %. Interprétation : examiner les distributions et le contenu. Limite : ce seuil n'autorise aucune suppression d'item."))
writeLines(enc2utf8(texte),"outputs/tables/synthese_descriptive.md",useBytes=TRUE)
stopifnot(identical(readLines("outputs/tables/synthese_descriptive.md",encoding="UTF-8"),texte))
stopifnot(identical(empreintes,tools::md5sum(sources)))
