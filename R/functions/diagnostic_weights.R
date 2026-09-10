# Diagnostics descriptifs des poids ; aucune troncature.
diagnostiquer_poids <- function(x) {
  noms <- c("poids_base","poids_nr","poids_final")
  diagnostics <- list(); extremes <- list()
  for(nom in noms) {
    w <- x[[nom]]; stopifnot(length(w)>1,all(is.finite(w)),all(w>0))
    q <- quantile(w,c(.25,.5,.75),names=FALSE)
    # CV avec variance de population pour l'identité exacte de Kish.
    cv <- sqrt(mean((w-mean(w))^2))/mean(w)
    deff <- length(w)*sum(w^2)/sum(w)^2
    borne <- q[3]+1.5*(q[3]-q[1])
    relatif <- w>4*median(w)
    tukey <- w>borne | w<q[1]-1.5*(q[3]-q[1])
    diagnostics[[nom]] <- data.frame(poids=nom,minimum=min(w),Q1=q[1],mediane=q[2],moyenne=mean(w),Q3=q[3],maximum=max(w),
      coefficient_variation=cv,design_effect_kish=deff,effective_sample_size=sum(w)^2/sum(w^2),
      nb_extremes_tukey=sum(tukey),nb_superieurs_4_medianes=sum(relatif),seuil_superieur_tukey=borne)
    extremes[[nom]] <- data.frame(id_enseignant=x$id_enseignant,strate_sondage=x$strate_sondage,
      poids=nom,valeur=w,ratio_mediane=w/median(w),part_poids=w/sum(w),flag_tukey=tukey,flag_4_medianes=relatif)
  }
  list(diagnostic_poids=do.call(rbind,diagnostics),poids_extremes=do.call(rbind,extremes))
}

sensibilite_poids <- function(x,population) {
  valeurs <- list(proportion_premier_degre=as.numeric(x$degre=="Premier degré"),
    proportion_rep_repplus=as.numeric(x$education_prioritaire %in% c("REP","REP+")),
    participation_formation=as.numeric(x$formation_continue>0),
    moyenne_EXP01=x$EXP01,moyenne_DIF01=x$DIF01,moyenne_EVA01=x$EVA01)
  cibles <- c(mean(population$degre=="Premier degré"),mean(population$education_prioritaire %in% c("REP","REP+")),
    mean(population$formation_continue>0),NA,NA,NA)
  poids <- list(non_pondere=rep(1,nrow(x)),poids_base=x$poids_base,poids_nr=x$poids_nr,poids_final=x$poids_final)
  do.call(rbind,lapply(seq_along(valeurs),function(j) {
    v <- valeurs[[j]]; i <- !is.na(v)
    do.call(rbind,lapply(names(poids),function(nom) {
      w <- poids[[nom]]
      data.frame(indicateur=names(valeurs)[j],ponderation=nom,estimation=weighted.mean(v[i],w[i]),
        n_observes=sum(i),n_manquants=sum(!i),denominateur_pondere=sum(w[i]),
        taux_missing_pondere=sum(w[!i])/sum(w),cible_population=cibles[j])
    }))
  }))
}
