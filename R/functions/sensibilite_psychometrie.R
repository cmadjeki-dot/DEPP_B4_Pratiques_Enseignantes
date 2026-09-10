# Sensibilité à des exclusions analytiques temporaires ; aucune écriture dans la base.
sensibilite_psychometrie <- function(base,dimensions,cfg,config,exporter) {
  stopifnot(all(c("flag_straightlining","taux_completion_clean") %in% names(base)))
  severe <- !is.na(base$flag_straightlining) & base$flag_straightlining
  complet <- !is.na(base$taux_completion_clean) & base$taux_completion_clean>=config$nettoyage$completion_sensibilite
  scenarios <- list(TOUS=rep(TRUE,nrow(base)),SANS_STRAIGHTLINING=!severe,
                    COMPLETION_80=complet,SANS_STRAIGHTLINING_ET_COMPLETION_80=!severe & complet)
  resultats <- charges <- list()
  for(d in dimensions) {
    noms <- paste0(d,sprintf("%02d",1:6)); reference <- NULL
    for(s in names(scenarios)) {
      z <- base[scenarios[[s]],noms,drop=FALSE]; z <- z[complete.cases(z),,drop=FALSE]
      stopifnot(nrow(z)>ncol(z)+2,all(vapply(z,function(v)length(unique(v))==5,logical(1))))
      r <- psych::polychoric(z,smooth=FALSE,correct=.5,progress=FALSE)$rho
      ev <- eigen(r,symmetric=TRUE)$values; stopifnot(min(ev)>0)
      a <- psych::alpha(z,check.keys=FALSE)
      f <- psych::fa(r,nfactors=1,n.obs=nrow(z),fm="minres",rotate="none",scores="none")
      l <- as.numeric(f$loadings[,1]); if(sum(l)<0) l <- -l
      admissible <- all(f$uniquenesses>0 & f$uniquenesses<=1)
      omega <- if(admissible) sum(l)^2/(sum(l)^2+sum(f$uniquenesses)) else NA_real_
      if(is.null(reference)) reference <- list(r=r,l=l,alpha=a$total$raw_alpha,omega=omega)
      correlations <- r[lower.tri(r)]
      residus <- (r-tcrossprod(l))[lower.tri(r)]
      resultats[[paste(d,s)]] <- data.frame(dimension=d,scenario=s,n_retenus=sum(scenarios[[s]]),
        n_exclus=nrow(base)-sum(scenarios[[s]]),n_complets=nrow(z),
        n_straightlining_non_evaluable=sum(is.na(base$flag_straightlining)),
        alpha=a$total$raw_alpha,omega=omega,modele_admissible=admissible,
        correlation_min=min(correlations),correlation_mediane=median(correlations),correlation_moyenne=mean(correlations),
        correlation_max=max(correlations),nb_correlations_negatives=sum(correlations<0),
        charge_min=min(l),charge_max=max(l),communalite_min=min(f$communality),
        RMSR=sqrt(mean(residus^2)),valeur_propre_1=ev[1],valeur_propre_2=ev[2],
        congruence_charges=sum(l*reference$l)/sqrt(sum(l^2)*sum(reference$l^2)),
        delta_alpha=a$total$raw_alpha-reference$alpha,delta_omega=omega-reference$omega,
        delta_correlation_max=max(abs(r-reference$r)),delta_charge_max=max(abs(l-reference$l)),
        methode_structure="Modèle un facteur fixé : charges, communalités, résidus et spectre ; PA non répétée")
      charges[[paste(d,s)]] <- data.frame(dimension=d,scenario=s,variable=noms,loading=l,communalite=f$communality)
    }
  }
  tableau <- do.call(rbind,resultats)
  exporter(tableau,"sensibilite_psychometrie")
  exporter(do.call(rbind,charges),"sensibilite_charges_factorielles")
  # Décisions transparentes : aucune exclusion automatique sur un coefficient isolé.
  it <- read.csv("outputs/tables/item_total_analysis.csv",fileEncoding="UTF-8")
  diag <- read.csv("outputs/tables/diagnostic_items_psychometrie.csv",fileEncoding="UTF-8")
  reserves <- c(EXP06="Vérification de compréhension : recouvrement conceptuel possible avec EVA.",
    NUM06="Évaluation de la fiabilité informationnelle : facette distincte des usages instrumentaux du numérique.",
    REL05="Relations avec les familles : destinataire distinct des autres items centrés sur les élèves.")
  decision <- data.frame(variable=it$variable,dimension=it$dimension,contenu=it$libelle,
    missing=diag$taux_missing[match(it$variable,diag$variable)],item_total=it$item_total_corrige,
    loading=it$charge,communalite=it$communalite,alpha_si_supprime=it$alpha_si_supprime,msa=it$MSA,
    decision="CONSERVER",justification="Liaisons, charges et communalités compatibles avec le bloc ; aucune preuve convergente justifiant une exclusion.")
  for(i in seq_len(nrow(decision))) {
    v <- decision$variable[i]
    if(it$decision_preliminaire[i]=="A_EXAMINER" || v %in% names(reserves)) {
      decision$decision[i] <- "CONSERVER_AVEC_RESERVE"
      decision$justification[i] <- paste(if(v %in% names(reserves)) reserves[[v]] else it$raison[i],
        "Conservation pour préserver la couverture du contenu ; examiner les charges croisées avant validation définitive.")
    }
  }
  exporter(decision,"decision_items")
  retenus <- split(decision$variable[decision$decision %in% c("CONSERVER","CONSERVER_AVEC_RESERVE")],
                    decision$dimension[decision$decision %in% c("CONSERVER","CONSERVER_AVEC_RESERVE")])
  # Liste versionnable distincte du questionnaire ; aucune règle de score définitif implicite.
  yaml::write_yaml(list(statut="Items retenus à ce stade ; scores non définitivement validés",items=retenus),
                   "metadata/items_retenus_scores.yml")
  print(tableau[c("dimension","scenario","n_complets","alpha","omega","delta_alpha","delta_omega","congruence_charges")],row.names=FALSE)
  invisible(tableau)
}
