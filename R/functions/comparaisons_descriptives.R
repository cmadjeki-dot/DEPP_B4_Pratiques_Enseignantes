# Comparaisons descriptives : covariance et stratification conservées dans le plan.
comparer_scores <- function(design, scores, dimensions) {
  d <- design
  for(nom in names(scores)[-1]) d$variables[[nom]] <- scores[[nom]]
  d$variables$anciennete_groupe <- cut(d$variables$anciennete,c(-Inf,9,19,29,Inf),labels=c("0-9 ans","10-19 ans","20-29 ans","30 ans ou plus"))
  d$variables$formation_groupe <- cut(d$variables$formation_continue,c(-Inf,0,4,Inf),labels=c("0 jour","1-4 jours","5 jours ou plus"))
  groupes <- c("degre","secteur","education_prioritaire","territoire","anciennete_groupe","formation_groupe","equipement_numerique")
  contextes <- list(); degres <- list()
  for(dim in dimensions) {
    nom <- paste0("score_provisoire_",dim)
    for(groupe in groupes) for(g in unique(as.character(d$variables[[groupe]]))) {
      if(is.na(g)) next
      i <- !is.na(d$variables[[groupe]]) & as.character(d$variables[[groupe]])==g
      dd <- d[i,]
      contextes[[paste(dim,groupe,g)]] <- data.frame(dimension=dim,variable=groupe,modalite=g,
        resumer_continue(dd,dd$variables[[nom]]))
    }
    # Un contraste de moyennes via un modèle saturé à deux groupes, sans ajustement causal.
    dd <- d; dd$variables$.score <- dd$variables[[nom]]
    dd$variables$.college <- as.numeric(dd$variables$degre=="Collège")
    modele <- survey::svyglm(.score~.college,design=dd)
    beta <- coef(modele); se <- sqrt(diag(vcov(modele)))
    ddl <- modele$df.residual; stopifnot(ddl>0)
    difference <- unname(beta[2]); ci <- difference+c(-1,1)*qt(.975,ddl)*se[2]
    sd_global <- sqrt(as.numeric(coef(survey::svyvar(~.score,dd,na.rm=TRUE))))
    degres[[dim]] <- data.frame(dimension=dim,premier_degre=unname(beta[1]),college=unname(sum(beta)),
      difference_college_moins_premier=difference,ic95_inf=ci[1],ic95_sup=ci[2],
      p_value=2*pt(-abs(difference/se[2]),ddl),difference_standardisee=difference/sd_global,
      n_premier=sum(!is.na(dd$variables$.score)&dd$variables$.college==0),
      n_college=sum(!is.na(dd$variables$.score)&dd$variables$.college==1))
  }
  degres <- do.call(rbind,degres); degres$p_holm <- p.adjust(degres$p_value,method="holm")
  list(degres=degres,contextes=do.call(rbind,contextes))
}

figures_comparaisons <- function(design, scores, comparaison, contextes, dimensions) {
  couleurs <- c("#2166ac","#b2182b","#238b45","#756bb1")
  ouvrir <- function(nom,titre) {
    png(paste0("outputs/figures/",nom,".png"),width=1800,height=1250,res=150)
    par(oma=c(4,0,3,0),mar=c(5,5,3,1))
  }
  fermer <- function(titre) {
    mtext(titre,outer=TRUE,side=3,line=1,font=2,cex=1.2)
    mtext("Source : démonstrateur DEPP_B4 — données simulées, sans résultat officiel DEPP",outer=TRUE,side=1,line=1,cex=.8)
    mtext("Scores provisoires non validés ; réponses disponibles ; pondération calibrée",outer=TRUE,side=1,line=2.3,cex=.75)
    dev.off()
  }
  ouvrir("01_distribution_dimensions","Distribution des scores provisoires")
  par(mfrow=c(2,4),mar=c(4,4,3,1))
  for(dim in dimensions) {
    v <- scores[[paste0("score_provisoire_",dim)]]; i <- !is.na(v)
    bins <- cut(v[i],seq(1,5,by=.5),include.lowest=TRUE,right=TRUE)
    prop <- tapply(weights(design)[i],bins,sum); prop[is.na(prop)] <- 0
    barplot(100*prop/sum(prop),names.arg=c("1–1,5","1,5–2","2–2,5","2,5–3","3–3,5","3,5–4","4–4,5","4,5–5"),
      las=2,col=couleurs[1],border=NA,main=dim,ylab="% pondéré",ylim=c(0,40),cex.names=.7)
  }
  fermer("Distribution des scores provisoires par dimension")
  ouvrir("02_pratique_faisabilite_priorite","")
  par(mfrow=c(2,4),mar=c(5,4,3,1))
  for(dim in dimensions) {
    z <- comparaison[comparaison$dimension==dim & comparaison$bloc %in% c("pratique_provisoire","faisabilite","priorite"),]
    plot(1:3,z$moyenne_ponderee,ylim=c(1,5),xlim=c(.5,3.5),xaxt="n",xlab="",ylab="Moyenne et IC 95 %",main=dim,pch=19,col=couleurs[1:3])
    axis(1,1:3,c("Pratique","Faisabilité","Priorité"),las=2,cex.axis=.8)
    arrows(1:3,z$ic95_inf,1:3,z$ic95_sup,angle=90,code=3,length=.04,col=couleurs[1:3])
  }
  fermer("Pratique provisoire, faisabilité et priorité")
  panneau <- function(variable,titre) {
    z <- contextes[contextes$variable==variable,]; modalites <- unique(z$modalite)
    plot(1:8,rep(3,8),type="n",ylim=c(1,5),xlim=c(.5,8.5),xaxt="n",xlab="Dimension",ylab="Score provisoire et IC 95 %",main=titre)
    axis(1,1:8,dimensions,cex.axis=.8)
    for(j in seq_along(modalites)) {
      a <- z[z$modalite==modalites[j],]; a <- a[match(dimensions,a$dimension),]
      xx <- 1:8+(j-(length(modalites)+1)/2)*.12
      points(xx,a$moyenne_ponderee,pch=15+j,col=couleurs[j])
      arrows(xx,a$ic95_inf,xx,a$ic95_sup,angle=90,code=3,length=.035,col=couleurs[j])
    }
    legend("bottomleft",legend=modalites,col=couleurs[seq_along(modalites)],pch=16:(15+length(modalites)),bty="n",cex=.75)
  }
  for(spec in list(c("03_scores_par_degre","degre","Scores provisoires selon le degré"),
    c("04_scores_par_anciennete","anciennete_groupe","Scores provisoires selon l'ancienneté"),
    c("05_scores_par_formation","formation_groupe","Scores provisoires selon la formation"))) {
    ouvrir(spec[1],spec[3]); panneau(spec[2],""); fermer(spec[3])
  }
  ouvrir("06_scores_par_contexte",""); par(mfrow=c(2,2))
  for(v in c("secteur","education_prioritaire","territoire","equipement_numerique")) panneau(v,
    switch(v,secteur="Secteur",education_prioritaire="Éducation prioritaire",territoire="Territoire",equipement_numerique="Équipement numérique"))
  fermer("Scores provisoires selon les contextes d'exercice")
}
