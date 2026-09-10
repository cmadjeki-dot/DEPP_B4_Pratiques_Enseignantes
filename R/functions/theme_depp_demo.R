# Présentation du démonstrateur, indépendante d'une charte officielle.
mention_demo <- "Données simulées à des fins de démonstration méthodologique."
theme_depp_demo <- function(base_size=11) {
  ggplot2::theme_minimal(base_size=base_size) + ggplot2::theme(
    panel.grid.minor=ggplot2::element_blank(),
    plot.title=ggplot2::element_text(face="bold",colour="#243746"),
    plot.caption=ggplot2::element_text(hjust=0,size=8),legend.position="bottom")
}
sauver_figure_demo <- function(graphique,nom,largeur=10,hauteur=7) {
  graphique <- graphique + theme_depp_demo() + ggplot2::labs(caption=mention_demo)
  ggplot2::ggsave(paste0("outputs/figures/",nom,".png"),graphique,width=largeur,height=hauteur,dpi=160,bg="white")
  invisible(graphique)
}
