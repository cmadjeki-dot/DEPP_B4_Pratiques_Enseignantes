# Tables descriptives non pondérées, sans imputation ni changement de la collecte.
construire_dashboard_qualite <- function(base, echantillon, dictionnaire, ordre, audit) {
  codes <- dictionnaire$variable
  stopifnot(all(codes %in% names(base)), nrow(audit$flags) == nrow(base))
  masque <- is.na(base[codes]); n <- nrow(base)
  par_variable <- data.frame(variable = names(base),
    bloc = dictionnaire$bloc[match(names(base), codes)],
    position_questionnaire = ordre$ordre[match(names(base), ordre$variable)],
    nb_observations = n, nb_manquants = colSums(is.na(base)),
    taux_missing = colMeans(is.na(base)), row.names = NULL)
  par_variable$bloc[is.na(par_variable$bloc)] <- "HORS_QUESTIONNAIRE"
  par_bloc <- do.call(rbind, lapply(unique(dictionnaire$bloc), function(b) {
    z <- masque[, dictionnaire$bloc == b, drop = FALSE]
    data.frame(bloc = b, nb_variables = ncol(z), nb_cellules = length(z),
      nb_manquants = sum(z), taux_missing = mean(z), nb_repondants_concernes = sum(rowSums(z) > 0))
  }))
  par_repondant <- data.frame(ligne_source = seq_len(n), id_enseignant = base$id_enseignant,
    nb_items_attendus = length(codes), nb_items_repondus = rowSums(!masque),
    nb_items_manquants = rowSums(masque), taux_missing = rowMeans(masque),
    statut_completion = audit$flags$statut_completion, row.names = NULL)
  # Distinguer une traîne finale de NA et les trous précédant la dernière réponse.
  sequence <- is.na(base[ordre$variable])
  traines <- apply(sequence, 1, function(z) {
    presents <- which(!z); if (!length(presents)) length(z) else length(z) - max(presents)
  })
  par_repondant$nb_manquants_fin_consecutive <- traines
  par_repondant$nb_manquants_avant_derniere_reponse <- rowSums(masque) - traines
  profils <- base[c("degre", "secteur", "strate_sondage", "territoire", "equipement_numerique", "statut_questionnaire")]
  profils$age_groupe <- as.character(cut(base$age, c(-Inf,34,49,Inf), labels=c("<=34","35-49",">=50")))
  profils$formation_groupe <- ifelse(base$formation_continue == 0, "Aucune", "Au moins un jour")
  profils$duree_groupe <- as.character(cut(base$duree_secondes, c(-Inf,120,600,1200,Inf),
    right=FALSE, labels=c("<120 s","120-599 s","600-1199 s",">=1200 s")))
  par_profil <- do.call(rbind, lapply(names(profils), function(nom) {
    g <- profils[[nom]]; g[is.na(g)] <- "MANQUANT"
    do.call(rbind, lapply(sort(unique(g)), function(modalite) {
      i <- which(g == modalite)
      data.frame(ventilation=nom, modalite=modalite, nb_repondants=length(i),
        nb_manquants=sum(masque[i,,drop=FALSE]), nb_cellules=length(i)*length(codes),
        taux_missing=mean(masque[i,,drop=FALSE]), proportion_incomplets=mean(rowSums(masque[i,,drop=FALSE])>0),
        nb_abandons=sum(base$statut_questionnaire[i]=="Abandon",na.rm=TRUE))
    }))
  }))
  fin <- tail(ordre$variable, 10)
  position <- data.frame(groupe=c("58 premières questions","10 dernières questions"),
    nb_cellules=c(n*58,n*10), nb_manquants=c(sum(is.na(base[setdiff(codes,fin)])),sum(is.na(base[fin]))))
  position$taux_missing <- position$nb_manquants/position$nb_cellules
  cor_duree <- function(i) {
    i <- i & is.finite(base$duree_secondes)
    if (sum(i)<3 || length(unique(base$duree_secondes[i]))<2 || length(unique(par_repondant$taux_missing[i]))<2) return(NA_real_)
    cor(base$duree_secondes[i], par_repondant$taux_missing[i], method="spearman")
  }
  lien_duree <- data.frame(perimetre=c("Tous les reçus","Hors abandons"),
    rho_spearman=c(cor_duree(rep(TRUE,n)),cor_duree(!is.na(base$statut_questionnaire)&base$statut_questionnaire!="Abandon")))
  statuts <- audit$flags$statut_completion
  dashboard <- data.frame(nb_selectionnes=nrow(echantillon), nb_repondants=length(unique(base$id_enseignant[!is.na(base$id_enseignant)])),
    nb_questionnaires_complets=sum(statuts=="COMPLET",na.rm=TRUE),
    nb_partiels=sum(statuts %in% c("PARTIEL_ACCEPTABLE","PARTIEL_FAIBLE")), nb_abandons=sum(statuts=="ABANDON",na.rm=TRUE),
    taux_reponse=length(intersect(echantillon$id_enseignant,base$id_enseignant))/nrow(echantillon),
    taux_completion_median=median(audit$flags$taux_completion,na.rm=TRUE),
    nb_doublons=sum(duplicated(base$id_enseignant[!is.na(base$id_enseignant)])),
    nb_reponses_rapides=sum(audit$flags$flag_rapide,na.rm=TRUE),
    nb_straightlining=sum(audit$flags$flag_straightlining,na.rm=TRUE),
    taux_missing_global=mean(masque), nb_valeurs_hors_bornes=nrow(audit$details$cellules_invalides),
    nb_tres_rapides=sum(audit$flags$flag_tres_rapide,na.rm=TRUE),
    nb_straightlining_non_evaluables=sum(is.na(audit$flags$flag_straightlining)),
    nb_lignes=n, nb_cellules_questionnaire=length(masque), nb_manquants=sum(masque))
  stopifnot(sum(par_bloc$nb_manquants)==sum(par_repondant$nb_items_manquants),
    sum(par_variable$nb_manquants[par_variable$variable %in% codes])==dashboard$nb_manquants)
  list(missing_par_variable=par_variable, missing_par_bloc=par_bloc,
    missing_par_repondant=par_repondant, missing_par_profil=par_profil,
    missing_par_position=position, missing_lien_duree=lien_duree, dashboard_qualite=dashboard)
}
