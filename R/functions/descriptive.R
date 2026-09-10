# Statistiques sur le plan calibré ; dénominateurs propres aux réponses observées.
resumer_continue <- function(design, valeurs) {
  d <- design; d$variables$.valeur_desc <- as.numeric(valeurs)
  present <- !is.na(valeurs); n <- sum(present)
  stopifnot(n>=2,all(is.finite(valeurs[present])))
  m <- survey::svymean(~.valeur_desc,d,na.rm=TRUE)
  moyenne <- as.numeric(coef(m)); se <- sqrt(as.numeric(vcov(m)))
  ddl <- survey::degf(d); stopifnot(ddl>0)
  ci <- moyenne+c(-1,1)*qt(.975,ddl)*se
  med <- as.numeric(coef(survey::svyquantile(~.valeur_desc,d,quantiles=.5,ci=FALSE,na.rm=TRUE)))
  data.frame(n=n,n_manquants=sum(!present),taux_reponse=n/length(valeurs),
    taux_reponse_pondere=sum(weights(d)[present])/sum(weights(d)),
    moyenne_ponderee=moyenne,ecart_type_pondere=sqrt(as.numeric(coef(survey::svyvar(~.valeur_desc,d,na.rm=TRUE)))),
    mediane_ponderee=med,ic95_inf=ci[1],ic95_sup=ci[2],denominateur_pondere=sum(weights(d)[present]))
}

resumer_modalites <- function(design,valeurs,modalites) {
  present <- !is.na(valeurs); stopifnot(sum(present)>0)
  do.call(rbind,lapply(modalites,function(g) {
    indicateur <- ifelse(present,as.numeric(valeurs==g),NA_real_)
    d <- design; d$variables$.indic_desc <- indicateur
    m <- survey::svymean(~.indic_desc,d,na.rm=TRUE)
    p <- as.numeric(coef(m)); se <- sqrt(as.numeric(vcov(m)))
    # IC logit par méthode delta ; proportions 0/1 sans IC calculable.
    ci <- c(NA_real_,NA_real_); methode <- "Non estimable : proportion extrême"
    if(p>0 && p<1) {
      ci <- plogis(qlogis(p)+c(-1,1)*qt(.975,survey::degf(d))*se/(p*(1-p)))
      methode <- if(se<1e-10) "Marge contrainte par calibration" else "Logit delta, plan calibré"
    }
    data.frame(modalite=as.character(g),n_non_pondere=sum(valeurs[present]==g),n_observes=sum(present),
      n_manquants=sum(!present),pourcentage_non_pondere=100*mean(valeurs[present]==g),
      pourcentage_pondere=100*p,ic95_inf=100*ci[1],ic95_sup=100*ci[2],methode_ic=methode,
      denominateur_pondere=sum(weights(d)[present]))
  }))
}
