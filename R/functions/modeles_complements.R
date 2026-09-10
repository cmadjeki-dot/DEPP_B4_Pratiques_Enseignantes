# Comparaisons ciblées, prédictions et sensibilité ; pas de recherche automatique.
completer_modeles <- function(modeles,finaux,b,design,masques,cfg,exporter) {
  comparaisons <- list(); alternatives <- list()
  for(n in finaux) {
    m <- modeles[[n]]; y <- all.vars(formula(m))[1]
    ajouts <- "I(anciennete_10^2)"
    if("effectif_5" %in% all.vars(formula(m))) ajouts <- c(ajouts,"I(effectif_5^2)")
    f <- update(formula(m),paste(". ~ . +",paste(ajouts,collapse=" + ")))
    alt <- ajuster_demo(f,design,masques[[y]],m$family)
    alternatives[[paste0(n,"_quadratique")]] <- alt
    test <- survey::regTermTest(alt,as.formula(paste("~",paste(ajouts,collapse=" + "))))
    comparaisons[[n]] <- data.frame(modele=n,alternative="Quadratique centrée",p_wald=as.numeric(test$p),
      ecart_prediction_RMS=sqrt(mean((fitted(alt)-fitted(m))^2)),
      decision="Spécification linéaire de référence ; quadratique conservée en sensibilité, à examiner avec les courbes")
  }
  # Hypothèse ciblée : l'association équipement/usage varie-t-elle selon le degré ?
  m <- modeles$mod_num_final
  alt <- ajuster_demo(update(formula(m),. ~ . + equipement_numerique:degre),design,masques$SCORE_NUM)
  alternatives$mod_num_interaction <- alt
  comparaisons$interaction <- data.frame(modele="mod_num_final",alternative="Équipement x degré",p_wald=as.numeric(survey::regTermTest(alt,~equipement_numerique:degre)$p),
    ecart_prediction_RMS=sqrt(mean((fitted(alt)-fitted(m))^2)),decision="Interaction exploratoire ; modèle additif principal par parcimonie, décision substantielle documentée après exécution")
  exporter(do.call(rbind,comparaisons),"comparaison_formes_modeles")
  exporter(do.call(rbind,lapply(names(alternatives),function(n) table_coefficients(alternatives[[n]],n))),"modeles_alternatifs")
  saveRDS(alternatives,"outputs/models/modeles_alternatifs.rds")

  # Prédictions moyennes standardisées sur les covariables observées des classés.
  m <- modeles$mod_profil_final; population <- b[masques$profil_2,]
  w <- population$poids_final/sum(population$poids_final)
  scenarios <- expand.grid(equipement=levels(b$equipement_numerique),jours=c(0,cfg$jours_scenario_formation),stringsAsFactors=FALSE)
  predictions <- do.call(rbind,lapply(seq_len(nrow(scenarios)),function(i) {
    nouveau <- population
    nouveau$equipement_numerique <- factor(scenarios$equipement[i],levels=levels(b$equipement_numerique))
    nouveau$formation_continue <- scenarios$jours[i]
    x <- model.matrix(delete.response(terms(m)),nouveau,contrasts.arg=m$contrasts,xlev=m$xlevels)
    pp <- plogis(drop(x %*% coef(m))); moyenne <- sum(w*pp)
    gradient <- colSums(x*(w*pp*(1-pp)))
    se <- sqrt(drop(t(gradient)%*%vcov(m)%*%gradient))
    ci <- plogis(qlogis(moyenne)+c(-1,1)*qt(.975,m$df.residual)*se/(moyenne*(1-moyenne)))
    support <- sum(population$equipement_numerique==scenarios$equipement[i] & population$formation_continue==scenarios$jours[i])
    stopifnot(support>0,all(is.finite(pp)),all(pp>0 & pp<1))
    data.frame(equipement=scenarios$equipement[i],jours_formation=scenarios$jours[i],
      probabilite_profil_2=moyenne,probabilite_profil_1=1-moyenne,erreur_standard=se,ic95_inf=ci[1],ic95_sup=ci[2],
      n_standardisation=nrow(population),n_support_configuration=support,
      methode="Moyenne des prédictions, covariables observées fixes ; IC delta logit, covariance survey ; association, pas intervention")
  }))
  exporter(predictions,"predicted_probabilities_profiles")
  predictions$equipement <- factor(predictions$equipement,levels=c("Faible","Moyen","Bon"))
  graphique <- ggplot2::ggplot(predictions,ggplot2::aes(equipement,probabilite_profil_2,colour=factor(jours_formation),group=factor(jours_formation))) +
    ggplot2::geom_pointrange(ggplot2::aes(ymin=ic95_inf,ymax=ic95_sup),position=ggplot2::position_dodge(.25)) +
    ggplot2::scale_y_continuous(limits=c(0,1)) + ggplot2::scale_colour_manual(values=c("#2166AC","#B35806")) + ggplot2::labs(title="Probabilité ajustée d’appartenir au profil 2",subtitle="Standardisation pondérée ; classes exploratoires faiblement stables",x="Équipement numérique",y="Probabilité prédite et IC 95 %",colour="Jours de formation")
  sauver_figure_demo(graphique,"predicted_profiles")

  # Plan indépendant à poids unitaires : SE sandwich pour la comparaison non pondérée.
  nonpondere <- survey::svydesign(ids=~1,weights=~1,data=b)
  sensibilite <- list(); robustesse <- list()
  for(n in finaux) {
    ref <- modeles[[n]]; y <- all.vars(formula(ref))[1]
    jeux <- list(pondere_principal=ref,
      non_pondere_principal=ajuster_demo(formula(ref),nonpondere,masques[[y]],ref$family),
      pondere_strict=ajuster_demo(formula(ref),design,masques[[y]] & b$flag_analyse_sensibilite,ref$family),
      non_pondere_strict=ajuster_demo(formula(ref),nonpondere,masques[[y]] & b$flag_analyse_sensibilite,ref$family))
    for(s in names(jeux)) {
      t <- table_coefficients(jeux[[s]],n,if(grepl("^non_",s)) "Poids unitaires, SE sandwich indépendantes" else "Poids finaux calibrés non recalibrés après restriction")
      t$scenario <- s; t$delta_coefficient <- t$coefficient-coef(ref)
      t$delta_en_se_reference <- abs(t$delta_coefficient)/sqrt(diag(vcov(ref)))
      sensibilite[[paste(n,s)]] <- t
    }
    co <- sapply(jeux,coef); se <- sqrt(diag(vcov(ref)))
    delta <- apply(abs(sweep(co,1,coef(ref),"-"))/se,1,max)
    inversion <- apply(sign(co)!=sign(coef(ref)),1,any) & abs(coef(ref))>se
    statut <- ifelse(inversion | delta>cfg$sensibilite$ecart_sensible_se,"SENSIBLE",
      ifelse(delta>cfg$sensibilite$ecart_modere_se,"MODEREMENT_ROBUSTE","ROBUSTE"))
    robustesse[[n]] <- data.frame(modele=n,terme=names(coef(ref)),delta_max_se=delta,inversion_signe_marquee=inversion,conclusion=statut,
      limite="Robustesse aux quatre variantes seulement ; ne valide ni causalité, ni typologie, ni absence de biais")
  }
  sens <- do.call(rbind,sensibilite); rob <- do.call(rbind,robustesse)
  sens$conclusion <- rob$conclusion[match(paste(sens$modele,sens$terme),paste(rob$modele,rob$terme))]
  exporter(sens,"sensibilite_modeles"); exporter(rob,"robustesse_modeles")
}
