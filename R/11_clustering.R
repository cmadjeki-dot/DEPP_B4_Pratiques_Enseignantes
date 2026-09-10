# Profils exploratoires non pondérés : aucune classe supposée réelle ou naturelle.
for(p in c("yaml","cluster","survey")) if(!requireNamespace(p,quietly=TRUE)) stop("Package absent : ",p)
cfg <- yaml::read_yaml("config/clustering.yml")
config <- yaml::read_yaml("config/config.yml")
source("R/functions/clustering.R",encoding="UTF-8")
set.seed(cfg$graine)
chemin <- "data/processed/base_analytique.rds"; empreinte <- tools::md5sum(chemin)
b <- readRDS(chemin)
revue <- read.csv("metadata/revue_facteurs.csv",fileEncoding="UTF-8")
dims <- config$dimensions_latentes$dimensions
dims <- dims[dims %in% revue$dimension_theorique[revue$score_autorise]]
stopifnot(length(dims)>=2,!anyDuplicated(b$id_enseignant))
zcols <- paste0("Z_",dims); stopifnot(all(zcols %in% names(b)))
exporter <- function(t,nom) {
  rownames(t) <- NULL; t$avertissement <- rep(config$projet$avertissement,nrow(t))
  write.csv(t,paste0("outputs/tables/",nom,".csv"),row.names=FALSE,fileEncoding="UTF-8")
}
valide <- complete.cases(b[zcols])
stopifnot(all(vapply(b[zcols],function(v)all(is.na(v)|is.finite(v)),logical(1))))
# Atypie marginale descriptive : on conserve ces cas, puis on teste leur influence.
atypique <- rowSums(abs(as.matrix(b[zcols]))>cfg$seuil_z_atypique,na.rm=TRUE)>0
selection <- data.frame(id_enseignant=b$id_enseignant,inclus_clustering=valide,
  flag_atypique=atypique,raison=ifelse(valide,"INCLUS","SCORES_MANQUANTS"))
exporter(selection,"selection_clustering")
x <- as.matrix(b[valide,zcols]); stopifnot(nrow(x)>max(cfg$k),all(apply(x,2,var)>0))
correlations <- cor(x)
exporter(data.frame(dimension=dims,correlations,check.names=FALSE),"correlation_scores")
exporter(data.frame(dimension=dims,n=nrow(x),moyenne=colMeans(x),variance=apply(x,2,var)),"variance_scores_clustering")
redondants <- which(abs(correlations)>=cfg$seuil_redondance & upper.tri(correlations),arr.ind=TRUE)
exporter(data.frame(dimension_1=dims[redondants[,1]],dimension_2=dims[redondants[,2]],
  correlation=correlations[redondants]),"redondance_scores")
ouvrir <- function(nom) {png(paste0("outputs/figures/",nom,".png"),width=1500,height=1100,res=140); par(mar=c(6,5,4,2))}
fermer <- function() {mtext("Source : données simulées DEPP_B4 — aucun résultat officiel DEPP ; analyse non pondérée",side=1,line=4.5,cex=.7); dev.off()}
ouvrir("correlation_scores")
par(mar=c(7,6,4,2)); image(seq_along(dims),seq_along(dims),correlations,zlim=c(-1,1),
  col=colorRampPalette(c("#2166ac","white","#b2182b"))(101),axes=FALSE,xlab="",ylab="",main="Corrélations entre scores — cas complets")
axis(1,seq_along(dims),dims); axis(2,seq_along(dims),dims,las=1)
for(i in seq_along(dims)) for(j in seq_along(dims)) text(i,j,sprintf("%.2f",correlations[i,j]))
fermer()
# ACP recentrée sur les cas complets, sans modifier l'échelle des Z de référence.
acp <- prcomp(x,center=TRUE,scale.=FALSE)
part <- acp$sdev^2/sum(acp$sdev^2)
exporter(data.frame(axe=seq_along(part),variance=acp$sdev^2,proportion=part,cumul=cumsum(part)),"acp_variance")
exporter(data.frame(dimension=dims,100*acp$rotation^2,check.names=FALSE),"acp_contributions")
exporter(data.frame(id_enseignant=b$id_enseignant[valide],acp$x,check.names=FALSE),"acp_coordonnees_individuelles")
cercle <- cor(x,acp$x)
exporter(data.frame(dimension=dims,cercle,check.names=FALSE),"acp_correlations_variables")
saveRDS(acp,"outputs/models/acp_scores.rds")
ouvrir("acp_variance"); barplot(100*part,names.arg=seq_along(part),col="#2166ac",ylab="Variance expliquée (%)",xlab="Axe",main="ACP des scores : variance expliquée"); fermer()
ouvrir("acp_variables"); plot(0,0,type="n",xlim=c(-1.15,1.15),ylim=c(-1.15,1.15),asp=1,
  xlab=paste0("Axe 1 (",round(100*part[1],1)," %)"),ylab=paste0("Axe 2 (",round(100*part[2],1)," %)"),main="ACP : cercle des corrélations")
theta <- seq(0,2*pi,length.out=300); lines(cos(theta),sin(theta),col="grey60"); abline(h=0,v=0,col="grey85")
arrows(0,0,cercle[,1],cercle[,2],length=.07,col="#2166ac")
etiquettes_y <- cercle[,2]*1.1; ordre <- order(etiquettes_y)
for(j in 2:length(ordre)) etiquettes_y[ordre[j]] <- max(etiquettes_y[ordre[j]],etiquettes_y[ordre[j-1]]+.11)
segments(cercle[,1],cercle[,2],cercle[,1]*1.2,etiquettes_y,col="grey65")
text(cercle[,1]*1.2,etiquettes_y,dims,cex=.8); fermer()
ouvrir("acp_individus"); plot(acp$x[,1:2],pch=16,cex=.45,col=adjustcolor("#2166ac",alpha.f=.3),
  xlab=paste0("Axe 1 (",round(100*part[1],1)," %)"),ylab=paste0("Axe 2 (",round(100*part[2],1)," %)"),main="ACP : enseignants simulés, cas complets"); fermer()
distance <- dist(x); cah <- hclust(distance,method="ward.D2")
saveRDS(cah,"outputs/models/cah_scores.rds")
ouvrir("dendrogramme_clusters"); plot(cah,labels=FALSE,hang=-1,main="CAH de Ward : enseignants simulés",xlab="Enseignants — feuilles non étiquetées",sub="",ylab="Hauteur de fusion (Ward.D2)"); fermer()
solutions <- lapply(cfg$k,function(k) cutree(cah,k)); names(solutions) <- as.character(cfg$k)
stabilite <- matrix(NA_real_,cfg$repetitions_stabilite,length(cfg$k))
for(rep in seq_len(cfg$repetitions_stabilite)) {
  i <- sort(sample.int(nrow(x),floor(cfg$fraction_sous_echantillon*nrow(x))))
  sous <- hclust(dist(x[i,,drop=FALSE]),method="ward.D2")
  for(j in seq_along(cfg$k)) stabilite[rep,j] <- rand_ajuste(solutions[[j]][i],cutree(sous,cfg$k[j]))
}
centres <- list()
comparaison <- do.call(rbind,lapply(seq_along(cfg$k),function(j) {
  k <- cfg$k[j]; g <- solutions[[j]]; tailles <- table(g)
  centres[[as.character(k)]] <<- do.call(rbind,lapply(seq_len(k),function(gr)
    data.frame(k=k,classe=gr,n=sum(g==gr),dimension=dims,moyenne_z=colMeans(x[g==gr,,drop=FALSE]))))
  data.frame(k=k,silhouette_moyenne=mean(cluster::silhouette(g,distance)[,"sil_width"]),
    taille_min=min(tailles),taille_max=max(tailles),inertie_intra=inertie_classes(x,g),
    stabilite_ARI_moyenne=mean(stabilite[,j]),stabilite_ARI_Q10=unname(quantile(stabilite[,j],.1)),
    interpretabilite="Lire les centres par dimension avant décision ; aucune typologie naturelle supposée")
}))
exporter(comparaison,"comparaison_clusters"); exporter(do.call(rbind,centres),"centres_solutions_clusters")
exporter(data.frame(repetition=rep(seq_len(nrow(stabilite)),times=ncol(stabilite)),k=rep(cfg$k,each=nrow(stabilite)),ARI=as.vector(stabilite)),"stabilite_clusters")
saveRDS(list(x=x,solutions=solutions,selection=selection,dimensions=dims,comparaison=comparaison),"outputs/models/comparaison_clustering.rds")
print(comparaison,row.names=FALSE)
decision <- yaml::read_yaml("metadata/decision_clustering.yml")
comparaison$interpretabilite <- vapply(as.character(comparaison$k),function(k) decision$interpretations[[k]],character(1))
comparaison$retenue <- comparaison$k==decision$k_retenu
exporter(comparaison,"comparaison_clusters")
source("R/functions/profils.R",encoding="UTF-8")
finaliser_profils(b,x,solutions,selection,dims,cfg,exporter)
stopifnot(identical(empreinte,tools::md5sum(chemin)))
source("R/functions/typologie.R",encoding="UTF-8")
documenter_typologie(b,dims,cfg,exporter)
