# Finalisation après lecture conjointe des indices et des centres.
finaliser_profils <- function(b,x,solutions,selection,dims,cfg,exporter) {
  decision <- yaml::read_yaml("metadata/decision_clustering.yml")
  k <- decision$k_retenu; stopifnot(as.character(k) %in% names(solutions))
  g <- solutions[[as.character(k)]]
  set.seed(cfg$graine+1L)
  km <- kmeans(x,centers=k,nstart=cfg$kmeans_nstart,iter.max=100)
  stopifnot(km$ifault==0L)
  concordance <- data.frame(comparaison="CAH / k-means",n=nrow(x),k=k,ARI=rand_ajuste(g,km$cluster),
    silhouette=mean(cluster::silhouette(km$cluster,dist(x))[,"sil_width"]),
    commentaire="Silhouette de k-means ; concordance corrigée du hasard, sans appariement des noms de groupes")
  atyp <- selection$flag_atypique[selection$inclus_clustering]
  if(sum(!atyp)>k && any(atyp)) {
    h <- hclust(dist(x[!atyp,,drop=FALSE]),method="ward.D2"); alt <- cutree(h,k)
    concordance <- rbind(concordance,data.frame(comparaison="CAH complète / CAH sans atypies marginales",n=sum(!atyp),k=k,
      ARI=rand_ajuste(g[!atyp],alt),silhouette=mean(cluster::silhouette(alt,dist(x[!atyp,,drop=FALSE]))[,"sil_width"]),
      commentaire="Comparaison sur les mêmes individus non atypiques ; même échelle des Z"))
  }
  exporter(concordance,"robustesse_clusters")
  exporter(as.data.frame(table(classe_CAH=g,classe_kmeans=km$cluster)),"concordance_cah_kmeans")
  saveRDS(km,"outputs/models/kmeans_scores.rds")
  a <- b; a$profil_pratiques <- NA_character_
  a$profil_pratiques[selection$inclus_clustering] <- paste0("PROFIL_",g)
  a$flag_atypique_clustering <- selection$flag_atypique
  a$statut_clustering <- selection$raison
  saveRDS(a,"data/processed/base_analytique_profils.rds")
  stopifnot(identical(a$id_enseignant,b$id_enseignant),identical(is.na(a$profil_pratiques),!selection$inclus_clustering))
  source("R/functions/descriptive.R",encoding="UTF-8")
  design <- readRDS("data/processed/design_depp.rds")
  j <- match(design$variables$id_enseignant,a$id_enseignant)
  stopifnot(!anyNA(j),setequal(design$variables$id_enseignant,a$id_enseignant),
    isTRUE(all.equal(as.numeric(weights(design)),a$poids_final[j])))
  design$variables$profil_pratiques <- a$profil_pratiques[j]
  profils <- list(); tailles <- list()
  for(pr in paste0("PROFIL_",seq_len(k))) {
    i <- !is.na(design$variables$profil_pratiques)&design$variables$profil_pratiques==pr
    dd <- design[i,]
    tailles[[pr]] <- data.frame(profil_pratiques=pr,n=sum(i),proportion_non_ponderee=sum(i)/sum(selection$inclus_clustering),
      proportion_ponderee=sum(weights(design)[i])/sum(weights(design)[!is.na(design$variables$profil_pratiques)]))
    for(d in dims) for(prefixe in c("SCORE_","FAIS_","PRIO_","GAP_")) {
      nom <- paste0(prefixe,d)
      # Un plan calibré peut conserver les lignes hors domaine avec un poids nul.
      v <- a[[nom]][match(dd$variables$id_enseignant,a$id_enseignant)]
      hors <- is.na(dd$variables$profil_pratiques) | dd$variables$profil_pratiques!=pr
      v[hors] <- NA_real_
      profils[[paste(pr,nom)]] <- data.frame(profil_pratiques=pr,dimension=d,indicateur=nom,
        moyenne_non_ponderee=mean(v,na.rm=TRUE),resumer_continue(dd,v))
    }
  }
  exporter(do.call(rbind,profils),"profils_scores"); exporter(do.call(rbind,tailles),"taille_profils")
  print(concordance,row.names=FALSE)
}
