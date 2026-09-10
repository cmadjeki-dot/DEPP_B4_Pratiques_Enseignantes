# Description conditionnelle aux classes construites ; aucune interprétation causale.
documenter_typologie <- function(b,dims,cfg,exporter) {
  a <- readRDS("data/processed/base_analytique_profils.rds")
  p <- read.csv("outputs/tables/profils_scores.csv",fileEncoding="UTF-8")
  tailles <- read.csv("outputs/tables/taille_profils.csv",fileEncoding="UTF-8")
  groupes <- tailles$profil_pratiques
  stopifnot(identical(groupes,c("PROFIL_1","PROFIL_2")))
  m <- t(vapply(groupes,function(g) {
    sous <- p[p$profil_pratiques==g,]
    sous$moyenne_ponderee[match(paste0("SCORE_",dims),sous$indicateur)]
  },numeric(length(dims))))
  colnames(m) <- dims; rownames(m) <- groupes
  # Les noms sont une décision éditoriale vérifiée contre les résultats courants.
  stopifnot(all(m[2,]>m[1,]),dims[which.max(m[2,]-m[1,])]=="NUM")
  noms <- c("Pratiques déclarées moins fréquentes, notamment numériques",
            "Pratiques déclarées plus fréquentes, contraste numérique marqué")
  interpretation <- data.frame(profil=groupes,nom_descriptif=noms,
    dimensions_dominantes="Gradient commun aux huit dimensions ; contraste interprofils maximal sur NUM",
    score_min=apply(m,1,min),score_max=apply(m,1,max),
    justification=paste("Différence numérique pondérée entre profils :",round(m[2,"NUM"]-m[1,"NUM"],3)),
    limite="Comparaison relative entre groupes ; fréquences déclarées, sans jugement sur la qualité. Séparation faible.")
  exporter(interpretation,"interpretation_profils")
  design <- readRDS("data/processed/design_depp.rds")
  j <- match(design$variables$id_enseignant,a$id_enseignant)
  stopifnot(!anyNA(j),isTRUE(all.equal(as.numeric(weights(design)),a$poids_final[j])))
  composition <- list(); continues <- list(); gaps <- list()
  cats <- c("degre","anciennete_classe","sexe","secteur","education_prioritaire","territoire","equipement_numerique")
  for(g in groupes) {
    dedans <- !is.na(a$profil_pratiques[j]) & a$profil_pratiques[j]==g
    dd <- design[dedans,]; jj <- match(dd$variables$id_enseignant,a$id_enseignant)
    actif <- as.numeric(weights(dd))>0
    for(v in cats) {
      valeurs <- as.character(a[[v]][jj]); valeurs[!actif] <- NA_character_
      tab <- resumer_modalites(dd,valeurs,sort(unique(valeurs[!is.na(valeurs)])))
      tab$n_manquants <- sum(actif & is.na(valeurs))
      composition[[paste(g,v)]] <- data.frame(profil=g,variable=v,tab)
    }
    for(v in c("anciennete","formation_continue")) {
      valeurs <- a[[v]][jj]; valeurs[!actif] <- NA_real_
      continues[[paste(g,v)]] <- data.frame(profil=g,variable=v,resumer_continue(dd,valeurs))
    }
    valeurs <- ifelse(a$formation_continue[jj]>0,"Au moins un jour","Aucun jour"); valeurs[!actif] <- NA_character_
    tab <- resumer_modalites(dd,valeurs,c("Aucun jour","Au moins un jour")); tab$n_manquants <- sum(actif & is.na(valeurs))
    composition[[paste(g,"formation")]] <- data.frame(profil=g,variable="participation_formation",tab)
    for(d in dims) {
      prio <- a[[paste0("PRIO_",d)]][jj]; score <- a[[paste0("SCORE_",d)]][jj]
      paire <- actif & !is.na(prio) & !is.na(score)
      ecart <- prio-score; ecart[!paire] <- NA_real_
      forte <- ifelse(paire,as.numeric(prio>=4 & ecart>0),NA_real_)
      gaps[[paste(g,d)]] <- data.frame(profil=g,dimension=d,resumer_continue(dd,ecart),
        priorite_moyenne_appariee=weighted.mean(prio[paire],weights(dd)[paire]),
        pratique_moyenne_appariee=weighted.mean(score[paire],weights(dd)[paire]),
        part_priorite_4_5_et_gap_positif=resumer_continue(dd,forte)$moyenne_ponderee,
        interpretation="Écart déclaré ; priorité forte définie par 4 ou 5. Ancrages distincts, aucun besoin réel prouvé.")
    }
  }
  exporter(do.call(rbind,composition),"composition_profils")
  exporter(do.call(rbind,continues),"composition_profils_continues")
  exporter(do.call(rbind,gaps),"gap_par_profil")
  couleurs <- c("#2166AC","#B35806")
  ouvrir <- function(n) {png(paste0("outputs/figures/",n,".png"),1600,1200,res=150); par(mar=c(6,6,4,3))}
  fermer <- function() {mtext("Données simulées – démonstration méthodologique",side=1,line=4.5,cex=.85); dev.off()}
  ouvrir("profils_heatmap")
  image(seq_along(dims),1:2,t(m),zlim=c(1,5),col=colorRampPalette(c("white","#2166AC"))(100),axes=FALSE,xlab="Dimensions",ylab="",main="Scores moyens pondérés par profil — échelle 1 à 5")
  axis(1,seq_along(dims),dims); axis(2,1:2,groupes,las=1)
  for(i in 1:2) for(d in seq_along(dims)) text(d,i,sprintf("%.2f",m[i,d]),col=if(m[i,d]>3) "white" else "black")
  fermer()
  ouvrir("profils_radar"); par(mar=c(6,2,4,2))
  ang <- pi/2-2*pi*(seq_along(dims)-1)/length(dims)
  plot(0,0,type="n",xlim=c(-6.5,6.5),ylim=c(-6,6.5),asp=1,axes=FALSE,xlab="",ylab="",main="Profils : moyennes pondérées des pratiques (1–5)")
  for(r in 1:5) {polygon(r*cos(ang),r*sin(ang),border="grey80"); text(.15,r,as.character(r),cex=.7)}
  segments(0,0,5*cos(ang),5*sin(ang),col="grey85"); text(5.6*cos(ang),5.6*sin(ang),dims)
  for(i in 1:2) polygon(m[i,]*cos(ang),m[i,]*sin(ang),border=couleurs[i],lwd=2)
  legend("bottomleft",groupes,col=couleurs,lty=1,bty="n"); fermer()
  acp <- readRDS("outputs/models/acp_scores.rds"); part <- acp$sdev^2/sum(acp$sdev^2)
  g <- match(a$profil_pratiques[!is.na(a$profil_pratiques)],groupes)
  ouvrir("profils_acp"); plot(acp$x[,1:2],col=adjustcolor(couleurs[g],alpha.f=.4),pch=16,cex=.5,
    xlab=sprintf("Axe 1 (%.1f %%)",100*part[1]),ylab=sprintf("Axe 2 (%.1f %%)",100*part[2]),main="Profils projetés dans l’ACP — analyse non pondérée")
  legend("topright",groupes,col=couleurs,pch=16,bty="n"); fermer()
  ouvrir("taille_profils"); positions <- barplot(100*tailles$proportion_ponderee,names.arg=groupes,col=couleurs,ylim=c(0,100),ylab="Part pondérée parmi les enseignants classés (%)",main=paste("Taille des profils —",sum(is.na(a$profil_pratiques)),"enseignants non classés"))
  text(positions,100*tailles$proportion_ponderee+5,paste0(round(100*tailles$proportion_ponderee,1)," % ; n = ",tailles$n)); fermer()
  # Ajout idempotent ; aucune autre colonne de la base analytique n'est modifiée.
  b$CLUSTER_ID <- match(a$profil_pratiques,groupes)
  b$PROFIL_PRATIQUES <- noms[b$CLUSTER_ID]
  meta <- read.csv("metadata/dictionnaire_base_analytique.csv",fileEncoding="UTF-8")
  meta <- meta[!meta$variable %in% c("CLUSTER_ID","PROFIL_PRATIQUES"),]
  for(v in c("CLUSTER_ID","PROFIL_PRATIQUES")) meta <- rbind(meta,data.frame(variable=v,libelle=v,dimension=NA_character_,type=class(b[[v]])[1],origine="R/11_clustering.R",minimum=if(v=="CLUSTER_ID") 1 else NA,maximum=if(v=="CLUSTER_ID") 2 else NA,
    modalites_observees=paste(sort(unique(na.omit(b[[v]]))),collapse=" | "),n_manquants=sum(is.na(b[[v]])),
    description="CAH exploratoire sur huit Z complets ; NA si non classé. Nom relatif, non évaluatif ; stabilité faible."))
  meta <- meta[match(names(b),meta$variable),]; stopifnot(identical(meta$variable,names(b)))
  saveRDS(b,"data/processed/base_analytique.rds")
  a$CLUSTER_ID <- b$CLUSTER_ID; a$PROFIL_PRATIQUES <- b$PROFIL_PRATIQUES
  saveRDS(a,"data/processed/base_analytique_profils.rds")
  write.csv(meta,"metadata/dictionnaire_base_analytique.csv",row.names=FALSE,fileEncoding="UTF-8")
}
