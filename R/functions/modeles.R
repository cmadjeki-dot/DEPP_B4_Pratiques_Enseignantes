# Outils d'estimation et d'export ; le plan calibré reste intact.
ajuster_demo <- function(formule,design,masque,famille=gaussian()) {
  d <- design; d$variables$.eligible_modele <- masque
  stopifnot(!anyNA(masque),sum(masque)>30)
  # Les plans calibrés gardent parfois les lignes hors domaine avec poids nul.
  # Marquer la réponse hors domaine uniquement dans cette copie de travail
  # force le modèle à omettre ces lignes, sans perdre les contraintes du plan.
  reponse <- all.vars(formule)[1]
  d$variables[[reponse]][!masque] <- NA
  m <- survey::svyglm(formule,design=d,subset=.eligible_modele,family=famille,
    na.action=na.omit,model=TRUE,x=TRUE,y=TRUE)
  stopifnot(m$converged,all(is.finite(coef(m))),all(is.finite(vcov(m))),m$rank==length(coef(m)))
  m$ids_analyse <- d$variables$id_enseignant[masque]
  # survey évalue les NA avant le sous-ensemble ; contrôler les lignes réellement utilisées.
  stopifnot(nrow(m$model)==sum(masque),identical(rownames(m$model),rownames(d$variables)[masque]))
  m
}
table_coefficients <- function(m,nom,ponderation="Poids finaux calibrés") {
  s <- coef(summary(m)); ci <- confint(m)
  logistique <- m$family$family=="quasibinomial"
  data.frame(modele=nom,variable_dependante=all.vars(formula(m))[1],terme=rownames(s),
    coefficient=s[,1],erreur_standard=s[,2],ic95_inf=ci[,1],ic95_sup=ci[,2],p_value=s[,4],
    effet=if(logistique) exp(s[,1]) else s[,1],
    effet_ic95_inf=if(logistique) exp(ci[,1]) else ci[,1],
    effet_ic95_sup=if(logistique) exp(ci[,2]) else ci[,2],
    unite_effet=if(logistique) "Odds ratio (profil 2 versus 1)" else "Point de score par unité du prédicteur",
    n=nrow(m$model),ponderation=ponderation,row.names=NULL)
}
correlation_ponderee <- function(x,y,w) {
  i <- complete.cases(x,y,w) & w>0
  x <- x[i]; y <- y[i]; w <- w[i]/sum(w[i])
  xc <- x-sum(w*x); yc <- y-sum(w*y)
  sum(w*xc*yc)/sqrt(sum(w*xc^2)*sum(w*yc^2))
}
diagnostic_modele <- function(m,nom,exporter) {
  x <- model.matrix(m); w <- m$prior.weights; y <- m$y; fit <- fitted(m)
  residu <- y-fit; logistique <- m$family$family=="quasibinomial"
  # VIF par colonne codée : descriptif, distinct du GVIF par facteur.
  xx <- x[,colnames(x)!="(Intercept)",drop=FALSE]
  vif <- vapply(seq_len(ncol(xx)),function(j) {
    ajuste <- lm.wfit(cbind(1,xx[,-j,drop=FALSE]),xx[,j],w)
    sst <- sum(w*(xx[,j]-weighted.mean(xx[,j],w))^2)
    sst/sum(w*ajuste$residuals^2)
  },numeric(1))
  exporter(data.frame(modele=nom,terme=colnames(xx),VIF_colonne=vif),paste0("colinearite_",nom))
  levier <- hatvalues(m)
  # Contribution approximative au coefficient, standardisée par son SE survey.
  # Ce signal de linéarisation ne constitue pas une mesure exacte de suppression.
  variance <- if(logistique) fit*(1-fit) else rep(1,length(fit))
  pain <- solve(crossprod(x,x*(w*variance)))
  contributions <- (x*(w*residu)) %*% pain
  influence <- apply(abs(sweep(contributions,2,sqrt(diag(vcov(m))),"/")),1,max)
  individuel <- data.frame(modele=nom,id_enseignant=m$ids_analyse,observe=y,predit=fit,
    residu=residu,levier=levier,influence_max_se=influence,
    flag_levier=levier>2*ncol(x)/nrow(x),flag_influence=influence>2/sqrt(nrow(x)))
  exporter(individuel,paste0("residus_",nom))
  q <- unique(quantile(fit,seq(0,1,.2))); groupe <- cut(fit,q,include.lowest=TRUE)
  hetero <- do.call(rbind,lapply(levels(groupe),function(g) {
    i <- groupe==g
    data.frame(modele=nom,groupe_prediction=g,n=sum(i),moyenne_residu=weighted.mean(residu[i],w[i]),
      moyenne_residu_carre=weighted.mean(residu[i]^2,w[i]))
  }))
  exporter(hetero,paste0("heteroscedasticite_",nom))
  graphique <- ggplot2::ggplot(individuel,ggplot2::aes(predit,residu)) + ggplot2::geom_point(alpha=.25,size=.8,colour="#2166AC") +
    ggplot2::geom_hline(yintercept=0,linetype=2) + ggplot2::labs(title=paste("Résidus du modèle",nom),x="Valeur ajustée",y="Résidu observé moins ajusté")
  sauver_figure_demo(graphique,paste0("diagnostic_",nom))
  limites <- if(logistique) c(0,1) else if(all.vars(formula(m))[1]=="GAP_DIF") c(-4,4) else c(1,5)
  data.frame(modele=nom,n=nrow(x),RMSE_ponderee=sqrt(weighted.mean(residu^2,w)),
    R2_descriptif=if(logistique) NA_real_ else 1-sum(w*residu^2)/sum(w*(y-weighted.mean(y,w))^2),
    Brier=if(logistique) weighted.mean(residu^2,w) else NA_real_,
    vif_max=max(vif),nb_leviers_signales=sum(individuel$flag_levier),nb_influences_signalees=sum(individuel$flag_influence),
    prediction_min=min(fit),prediction_max=max(fit),nb_predictions_hors_echelle=sum(fit<limites[1]|fit>limites[2]),
    commentaire="Diagnostics descriptifs pondérés ; SE survey robustes, pas de test OLS mécanique. Aucune exclusion automatique.")
}
