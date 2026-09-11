# Scores construits uniquement après revue explicite des facteurs et du contenu.
verifier_reference_charges <- function(actuel, reference, tolerance=1e-10) {
  if (!identical(names(actuel),names(reference)) || nrow(actuel)!=nrow(reference))
    stop("Structure des charges différente de la référence validée.")
  facteurs <- grep("^F[0-9]+$",names(reference),value=TRUE)
  if (!length(facteurs) || !identical(actuel[setdiff(names(actuel),facteurs)],
                                    reference[setdiff(names(reference),facteurs)]))
    stop("Items, facteurs ou libellés différents de la référence validée.")
  a <- as.matrix(actuel[facteurs]); b <- as.matrix(reference[facteurs])
  if (!is.numeric(a) || !is.numeric(b) || any(!is.finite(a)) || any(!is.finite(b)))
    stop("Charges non numériques ou non finies.")
  ecart <- max(abs(a-b))
  if (ecart > tolerance) stop("Charges modifiées : écart maximal = ",ecart,
    ". Réexaminer la revue factorielle avant les scores.")
  message("Référence factorielle : écart maximal = ",format(ecart,scientific=TRUE),
          " ; tolérance numérique = ",tolerance)
  invisible(ecart)
}

construire_scores_definitifs <- function(base,retenus,dimensions,cfg,exporter) {
  revue <- read.csv("metadata/revue_facteurs.csv",fileEncoding="UTF-8")
  stopifnot(all(c("facteur","dimension_theorique","interpretation","coherence","commentaire","score_autorise","empreinte_loadings") %in% names(revue)),
    !anyDuplicated(revue$facteur))
  l <- read.csv("outputs/tables/loadings_efa.csv",fileEncoding="UTF-8",check.names=FALSE)
  if(!all(revue$empreinte_loadings==unname(tools::md5sum("outputs/tables/loadings_efa.csv")))) {
    reference <- "metadata/loadings_efa_reference.csv"
    if (!file.exists(reference) || !all(revue$empreinte_loadings==unname(tools::md5sum(reference))))
      stop("Référence validée absente ou modifiée : réexaminer la revue factorielle.")
    verifier_reference_charges(l,read.csv(reference,fileEncoding="UTF-8",check.names=FALSE))
  }
  colonnes <- grep("^F[0-9]+$",names(l),value=TRUE)
  stopifnot(setequal(revue$facteur,colonnes))
  dict <- read.csv("metadata/dictionnaire_variables.csv",fileEncoding="UTF-8")
  interpretation <- revue[c("facteur","dimension_theorique","interpretation","coherence","commentaire")]
  interpretation$items_principaux <- vapply(revue$facteur,function(f) {
    i <- abs(l[[f]])>=cfg$charge_principale
    paste(paste0(l$item[i]," : ",dict$libelle[match(l$item[i],dict$variable)]),collapse=" | ")
  },character(1))
  exporter(interpretation,"interpretation_facteurs")
  scores <- base; desc <- regles <- list(); noms <- character()
  for(d in dimensions) {
    validation <- revue[revue$dimension_theorique==d & revue$score_autorise,,drop=FALSE]
    if(nrow(validation)!=1L) next
    it <- retenus[[d]]; stopifnot(length(it)>=3,all(it %in% names(base)))
    # Éviter qu'un arrondi numérique de 2/3 transforme quatre sur six en cinq sur six.
    minimum <- ceiling(length(it)*cfg$fraction_items_minimum-1e-8)
    n <- rowSums(!is.na(base[it])); v <- rowMeans(base[it],na.rm=TRUE)
    v[n<minimum] <- NA_real_; stopifnot(all(is.na(v) | (v>=1 & v<=5)))
    moyenne <- mean(v,na.rm=TRUE); ecart_type <- sd(v,na.rm=TRUE)
    stopifnot(is.finite(ecart_type),ecart_type>0)
    nom <- paste0("SCORE_",d); noms <- c(noms,nom)
    scores[[nom]] <- v; scores[[paste0("Z_",d)]] <- (v-moyenne)/ecart_type
    scores[[paste0("NB_ITEMS_",d)]] <- n
    regles[[d]] <- data.frame(dimension=d,items=paste(it,collapse="|"),nb_items=length(it),
      minimum_reponses=minimum,moyenne_standardisation=moyenne,ecart_type_standardisation=ecart_type,
      portee="Score retenu pour démonstration ; validation externe non établie")
    y <- v[!is.na(v)]
    desc[[d]] <- data.frame(score=nom,n=length(y),missing=sum(is.na(v)),taux_missing=mean(is.na(v)),
      moyenne=mean(y),mediane=median(y),ecart_type=sd(y),minimum=min(y),maximum=max(y),
      Q1=unname(quantile(y,.25)),Q3=unname(quantile(y,.75)))
  }
  if(!length(noms)) stop("Aucune dimension suffisamment étayée pour produire un score.")
  stopifnot(identical(scores$id_enseignant,base$id_enseignant),!anyDuplicated(scores$id_enseignant))
  exporter(do.call(rbind,desc),"descriptif_scores_definitifs")
  exporter(do.call(rbind,regles),"regles_scores_definitifs")
  r <- cor(scores[noms],use="pairwise.complete.obs")
  effectifs <- crossprod(!is.na(as.matrix(scores[noms])))
  exporter(data.frame(score=rownames(r),r,check.names=FALSE),"correlations_scores_definitifs")
  exporter(data.frame(score=rownames(effectifs),effectifs,check.names=FALSE),"effectifs_correlations_scores")
  saveRDS(r,"outputs/models/correlations_scores_definitifs.rds")
  saveRDS(scores,"data/processed/questionnaire_scores.rds")
  stopifnot(identical(scores,readRDS("data/processed/questionnaire_scores.rds")))
  print(do.call(rbind,desc),row.names=FALSE)
}
