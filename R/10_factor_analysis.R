# Structure globale ordinale, sans imposer huit facteurs.
if(!file.exists("config/factorielle.yml")) stop("Exécuter depuis la racine.")
for(p in c("psych","GPArotation","yaml")) if(!requireNamespace(p,quietly=TRUE)) stop("Package absent : ",p)
cfg <- yaml::read_yaml("config/factorielle.yml")
config <- yaml::read_yaml("config/config.yml")
sources <- c(config$nettoyage$sortie_clean,"metadata/items_retenus_scores.yml","config/factorielle.yml")
empreintes <- tools::md5sum(sources)
base <- readRDS(sources[1]); retenus <- yaml::read_yaml(sources[2])$items
dimensions <- config$dimensions_latentes$dimensions
items <- unlist(retenus[dimensions],use.names=FALSE)
stopifnot(!anyDuplicated(items),all(items %in% names(base)),!anyDuplicated(base$id_enseignant))
x <- base[items]; z <- x[complete.cases(x),,drop=FALSE]
stopifnot(nrow(z)>ncol(z),all(as.matrix(z) %in% 1:5))
exporter <- function(x,nom) {
  rownames(x) <- NULL; x$avertissement <- rep(config$projet$avertissement,nrow(x))
  write.csv(x,paste0("outputs/tables/",nom,".csv"),row.names=FALSE,fileEncoding="UTF-8")
}
# Cache vérifié pour ne pas répéter les permutations lorsque seules les sorties évoluent.
cle <- list(empreintes=empreintes,psych=as.character(packageVersion("psych")),
            R=as.character(getRversion()),methode="poly-minres-SMCfalse-v1")
cache <- "outputs/models/cache_parallel_global.rds"
ancien <- if(file.exists(cache)) readRDS(cache) else NULL
if(!is.null(ancien) && identical(ancien$cle,cle)) {
  r <- ancien$r; pa <- ancien$pa
  cat("Analyse parallèle reprise du cache : entrées, paramètres et versions identiques.\n")
} else {
  set.seed(cfg$graine); options(mc.cores=1)
  r <- psych::polychoric(z,smooth=FALSE,correct=.5,progress=FALSE)$rho
  stopifnot(min(eigen(r,symmetric=TRUE)$values)>0)
  cat("Analyse parallèle globale :",nrow(z),"cas complets ;",ncol(z),"items ;",cfg$iterations_parallel,"réplications.\n")
  pa <- psych::fa.parallel(z,cor="poly",fa="fa",fm="minres",SMC=FALSE,sim=FALSE,
    n.iter=cfg$iterations_parallel,quant=cfg$quantile_parallel,plot=FALSE)
  saveRDS(list(cle=cle,r=r,pa=pa),cache)
}
saveRDS(pa,"outputs/models/parallel_global.rds")
saveRDS(r,"outputs/models/correlations_polychoric_items_retenus.rds")
source("R/functions/figures_parallel.R",encoding="UTF-8")
dessiner_parallel("global",cfg$quantile_parallel)
k <- pa$nfact
stopifnot(is.finite(k),k>=1,k<ncol(z))
exporter(data.frame(n_complets=nrow(z),nb_items=ncol(z),facteurs_theoriques=length(dimensions),
  facteurs_suggeres=k,commentaire=if(k==length(dimensions)) "Concordance numérique ; contenu et charges à examiner" else "Divergence : ne pas imposer le modèle théorique"),"parallel_global")
set.seed(cfg$graine+1L)
modeles <- list()
for(nf in unique(c(k,length(dimensions)))) {
  f <- psych::fa(r,nfactors=nf,n.obs=nrow(z),fm="minres",rotate=if(nf>1) "oblimin" else "none",scores="none")
  modeles[[as.character(nf)]] <- f
}
f <- modeles[[as.character(k)]]
saveRDS(modeles,"outputs/models/modeles_efa.rds")
l <- unclass(f$loadings); colnames(l) <- paste0("F",seq_len(k))
phi <- if(k>1) f$Phi else matrix(1,1,1)
# Orienter chaque facteur pour rendre positive sa plus forte charge ; transformer Phi de même.
signes <- vapply(seq_len(k),function(j)sign(l[which.max(abs(l[,j])),j]),numeric(1))
l <- sweep(l,2,signes,"*"); phi <- phi*outer(signes,signes)
dimnames(phi) <- list(colnames(l),colnames(l))
stopifnot(all(is.finite(l)),all(f$uniquenesses>0),all(f$communality>=0 & f$communality<=1))
exporter(data.frame(item=items,dimension_theorique=sub("[0-9]+$","",items),l,check.names=FALSE),"loadings_efa")
exporter(data.frame(item=items,communalite=f$communality,unicite=f$uniquenesses),"communalities_efa")
exporter(data.frame(facteur=rownames(phi),phi,check.names=FALSE),"factor_correlations")
variance <- f$Vaccounted
colnames(variance) <- colnames(l)
exporter(data.frame(indicateur=rownames(variance),variance,check.names=FALSE),"variance_expliquee_efa")
exporter(do.call(rbind,lapply(names(modeles),function(nf) {
  m <- modeles[[nf]]; data.frame(nb_facteurs=as.integer(nf),RMSR=m$rms,commun_min=min(m$communality),
    origine=if(as.integer(nf)==k) "Solution suggérée par analyse parallèle" else "Comparateur théorique")
})),"comparaison_modeles_efa")
rang <- t(apply(abs(l),1,order,decreasing=TRUE))
premier <- rang[,1]; second <- if(k>1) rang[,2] else rep(NA_integer_,nrow(l))
v1 <- l[cbind(seq_len(nrow(l)),premier)]
v2 <- if(k>1) l[cbind(seq_len(nrow(l)),second)] else rep(0,nrow(l))
ecart <- abs(v1)-abs(v2)
alerte <- abs(v2)>=cfg$charge_secondaire | (abs(v1)>=cfg$charge_principale & ecart<cfg$ecart_charges)
cross <- data.frame(item=items,facteur_1=paste0("F",premier),loading_1=v1,
  facteur_2=if(k>1) paste0("F",second) else NA_character_,loading_2=v2,ecart=ecart,
  decision=ifelse(alerte,"REVOIR","CONSERVER"))
exporter(cross,"diagnostic_charges_efa")
exporter(cross[alerte,,drop=FALSE],"cross_loadings")
print(table(sub("[0-9]+$","",items),premier))
print(cross[alerte,,drop=FALSE])
cat("Facteurs suggérés :",k,"; RMSR :",f$rms,"\n")
source("R/functions/scores_definitifs.R",encoding="UTF-8")
construire_scores_definitifs(base,retenus,dimensions,cfg,exporter)
source("R/functions/base_analytique.R",encoding="UTF-8")
construire_base_analytique(dimensions,config)
stopifnot(identical(empreintes,tools::md5sum(sources)))
