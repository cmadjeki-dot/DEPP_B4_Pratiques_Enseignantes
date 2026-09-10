# Pondération des questionnaires inclus ; correction par cellules puis calibration.
ponderer_questionnaire <- function(base, initial, suivi, population, p) {
  stopifnot(!anyDuplicated(base$id_enseignant), !anyDuplicated(initial$id_enseignant),
    all(base$id_enseignant %in% initial$id_enseignant), all(base$flag_analyse_principale))
  indice <- match(base$id_enseignant,initial$id_enseignant)
  for(nom in c("poids_base","strate_sondage","degre","secteur","education_prioritaire","sexe","anciennete_classe")) {
    stopifnot(identical(base[[nom]],initial[[nom]][indice]))
  }
  codes <- sort(unique(initial$strate_sondage))
  correction <- do.call(rbind,lapply(codes,function(s) {
    ni <- sum(initial$strate_sondage==s); nr <- sum(base$strate_sondage==s)
    collecte <- sum(suivi$repondant[suivi$strate_sondage==s])
    data.frame(cellule=s,n_selectionnes=ni,n_repondants=nr,taux_reponse=nr/ni,
      facteur_nr=if(nr>0) ni/nr else Inf,n_participants_collecte=collecte,
      n_exclus_analytiques=collecte-nr,definition_repondant="Inclus dans analyse principale")
  }))
  if(any(correction$n_selectionnes<p$minimum_selectionnes | correction$n_repondants<p$minimum_repondants)) {
    stop("Cellule insuffisante : regroupement à documenter avant reprise ; aucun regroupement automatique.")
  }
  x <- base
  x$cellule_nr <- x$strate_sondage
  x$facteur_nr <- correction$facteur_nr[match(x$cellule_nr,correction$cellule)]
  x$poids_nr <- x$poids_base*x$facteur_nr
  x$poids_final <- x$poids_nr
  stopifnot(all(is.finite(x$poids_nr)),all(x$poids_nr>0),abs(sum(x$poids_nr)-nrow(population))<1e-6)
  # Même codage et mêmes contrastes dans les deux matrices de calibration.
  xp <- population; xr <- x
  for(nom in c("strate_sondage","sexe")) {
    niveaux <- sort(unique(population[[nom]]))
    xp[[nom]] <- factor(xp[[nom]],levels=niveaux)
    xr[[nom]] <- factor(xr[[nom]],levels=niveaux)
    contrasts(xp[[nom]]) <- contrasts(xr[[nom]]) <- contr.treatment(length(niveaux))
  }
  formule <- ~strate_sondage+sexe+anciennete_classe
  mp <- model.matrix(formule,xp); mr <- model.matrix(formule,xr)
  stopifnot(nrow(mp)==nrow(xp),nrow(mr)==nrow(xr),identical(colnames(mp),colnames(mr)),qr(mr)$rank==ncol(mr))
  totaux <- colSums(mp)
  # Plan de travail sans FPC : ne pas traiter l'effectif final comme le tirage initial fixe.
  plan <- survey::svydesign(ids=~1,strata=~strate_sondage,weights=~poids_nr,data=xr)
  calibre <- survey::calibrate(plan,formula=formule,population=totaux,calfun="logit",
    bounds=p$bornes_calibration,epsilon=p$tolerance,maxit=100,force=FALSE)
  x$poids_final <- as.numeric(stats::weights(calibre))
  x$facteur_calibration <- x$poids_final/x$poids_nr
  residus <- colSums(mr*x$poids_final)-totaux
  stopifnot(all(is.finite(x$poids_final)),all(x$poids_final>0),
    all(x$facteur_calibration>=p$bornes_calibration[1]-1e-8),
    all(x$facteur_calibration<=p$bornes_calibration[2]+1e-8),
    max(abs(residus)/pmax(1,abs(totaux)))<p$tolerance*10)
  marges <- data.frame(contrainte=names(totaux),total_population=unname(totaux),
    total_calibre=unname(colSums(mr*x$poids_final)),ecart=unname(residus))
  diagnostics <- do.call(rbind,lapply(c("poids_base","poids_nr","poids_final"),function(nom) {
    w <- x[[nom]]
    data.frame(poids=nom,n=length(w),somme=sum(w),minimum=min(w),q01=unname(quantile(w,.01)),
      mediane=median(w),moyenne=mean(w),q99=unname(quantile(w,.99)),maximum=max(w),
      cv=sd(w)/mean(w),effectif_kish=sum(w)^2/sum(w^2))
  }))
  comparaison <- do.call(rbind,lapply(c("strate_sondage","degre","secteur","education_prioritaire","sexe"),function(nom) {
    do.call(rbind,lapply(sort(unique(population[[nom]])),function(g) {
      i <- x[[nom]]==g
      data.frame(variable=nom,modalite=g,population_synthetique=sum(population[[nom]]==g),
        echantillon_initial_non_pondere=sum(initial[[nom]]==g),inclus_non_ponderes=sum(i),
        poids_base=sum(x$poids_base[i]),poids_nr=sum(x$poids_nr[i]),poids_calibres=sum(x$poids_final[i]))
    }))
  }))
  comparaison <- rbind(comparaison,data.frame(variable="anciennete_classe",modalite="TOTAL_ANNEES",
    population_synthetique=sum(population$anciennete_classe),echantillon_initial_non_pondere=sum(initial$anciennete_classe),
    inclus_non_ponderes=sum(x$anciennete_classe),poids_base=sum(x$poids_base*x$anciennete_classe),
    poids_nr=sum(x$poids_nr*x$anciennete_classe),poids_calibres=sum(x$poids_final*x$anciennete_classe)))
  attr(x,"ponderation") <- list(parametres=p,formule=deparse(formule),population=totaux,
    perimetre="Analyse principale ; correction participation et exclusion",methode="Calibration logit bornée")
  list(base=x,correction=correction,marges=marges,diagnostics=diagnostics,comparaison=comparaison,plan=calibre)
}
