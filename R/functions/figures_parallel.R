# Redessiner les résultats archivés sans répéter les permutations.
dessiner_parallel <- function(dimensions, quantile_reference=.95) {
  for(d in dimensions) {
    pa <- readRDS(paste0("outputs/models/parallel_",d,".rds"))
    colonnes <- paste0("F",seq_along(pa$fa.values))
    stopifnot(all(colonnes %in% colnames(pa$values)))
    seuil <- apply(pa$values[,colonnes,drop=FALSE],2,quantile,probs=quantile_reference)
    png(paste0("outputs/figures/parallel_",d,".png"),width=1500,height=1000,res=140)
    par(mar=c(6,5,4,2))
    plot(seq_along(seuil),pa$fa.values,type="b",pch=19,col="#2166ac",
      ylim=range(c(pa$fa.values,seuil)),xlab="Rang du facteur",ylab="Valeur propre factorielle",
      main=paste("Analyse parallèle ordinale —",d))
    lines(seq_along(seuil),seuil,type="b",pch=17,lty=2,col="#b2182b")
    abline(h=0,lty=3,col="grey70")
    legend("topright",legend=c("Données observées",paste0("Permutations : quantile ",100*quantile_reference," %")),
      col=c("#2166ac","#b2182b"),pch=c(19,17),lty=c(1,2),bty="n")
    mtext("Source : données simulées DEPP_B4 — aucun résultat officiel DEPP",side=1,line=4,cex=.75)
    mtext(paste(nrow(pa$values),"permutations ; cas complets non pondérés ; exploration"),side=1,line=5,cex=.75)
    dev.off()
  }
}
