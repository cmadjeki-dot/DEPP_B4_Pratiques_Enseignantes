# Sélection éditoriale fixée, puis chiffres chargés sans réestimation.
preparer_note_decideur <- function(r) {
  source("R/functions/theme_depp_demo.R",encoding="UTF-8")
  dimensions <- c(EXP="Enseignement explicite",DIF="Différenciation",EVA="Évaluation formative",GCL="Gestion de classe",COL="Collaboration",NUM="Numérique pédagogique",DEV="Développement professionnel",REL="Relations éducatives")
  scores <- r$scores[grepl("^SCORE_",r$scores$indicateur),]
  stopifnot(nrow(scores)==8,all(scores$moyenne_ponderee>=1 & scores$moyenne_ponderee<=5))
  scores$libelle <- factor(paste0(scores$dimension," — ",dimensions[scores$dimension]),levels=rev(paste0(names(dimensions)," — ",dimensions)))
  graphique <- ggplot2::ggplot(scores,ggplot2::aes(moyenne_ponderee,libelle)) +
    ggplot2::geom_errorbar(ggplot2::aes(xmin=ic95_inf,xmax=ic95_sup),orientation="y",width=.15,colour="#2166AC") +
    ggplot2::geom_point(size=2.4,colour="#2166AC") +
    ggplot2::scale_x_continuous(limits=c(1,5),breaks=1:5) +
    ggplot2::labs(title="Huit dimensions de pratiques déclarées",subtitle="Moyennes pondérées ; traits horizontaux : intervalles à 95 %",x="Fréquence déclarée : de 1 (jamais) à 5 (très souvent)",y=NULL)
  sauver_figure_demo(graphique,"synthese_decideur",9,4.3)
  valeur <- function(code) { t <- r$scores[r$scores$indicateur==code,]; stopifnot(nrow(t)==1); t }
  gcl <- valeur("SCORE_GCL"); num <- valeur("SCORE_NUM"); gap <- valeur("GAP_DIF")
  effet <- r$modeles[r$modeles$modele=="mod_num_final" & r$modeles$terme=="equipement_numeriqueBon",]
  part <- r$profils$proportion_ponderee[r$profils$profil_pratiques=="PROFIL_2"]
  messages <- c(
    sprintf("Dans les données simulées, **%s** des enseignants sélectionnés participent. **Constat :** la collecte simulée comporte des non-répondants. **Interprétation :** la pondération doit tenir compte de cette sélection. **Limite :** ce taux est produit par un mécanisme choisi, non observé sur le terrain.",pct(r$qualite$taux_reponse,2)),
    sprintf("Dans les données simulées, la gestion de classe atteint **%s/5**, contre **%s/5** pour le numérique. **Constat :** les fréquences moyennes diffèrent (IC à 95 %% : %s–%s et %s–%s). **Interprétation :** les dimensions décrivent des pratiques distinctes. **Limite :** leurs contenus et difficultés simulées diffèrent ; ce n’est pas un classement de qualité.",fmt(gcl$moyenne_ponderee),fmt(num$moyenne_ponderee),fmt(gcl$ic95_inf),fmt(gcl$ic95_sup),fmt(num$ic95_inf),fmt(num$ic95_sup)),
    sprintf("Dans les données simulées, l’écart priorité–pratique en différenciation est de **%s point**, IC à 95 %% [%s ; %s]. **Constat :** les deux déclarations ne coïncident pas exactement. **Interprétation :** l’écart invite à examiner conjointement priorité et conditions de mise en œuvre. **Limite :** il ne prouve pas un besoin de formation.",fmt(gap$moyenne_ponderee),fmt(gap$ic95_inf),fmt(gap$ic95_sup)),
    sprintf("Dans les données simulées, le profil aux pratiques déclarées plus fréquentes représente **%s** des enseignants classés, après pondération. **Constat :** la classification distingue deux groupes relatifs. **Interprétation :** elle résume un gradient de déclaration. **Limite :** les groupes sont peu stables et ne constituent pas des catégories naturelles.",pct(part)),
    sprintf("Dans les données simulées, un bon équipement est associé à **%s point** de score numérique supplémentaire par rapport à un équipement faible, IC à 95 %% [%s ; %s]. **Constat :** l’association persiste après ajustement sur les caractéristiques retenues. **Interprétation :** contexte et pratique peuvent être étudiés ensemble. **Limite :** cela ne prouve pas que l’équipement cause cette différence.",fmt(effet$effet),fmt(effet$effet_ic95_inf),fmt(effet$effet_ic95_sup)))
  writeLines(c("# Messages clés — note décideur","",paste0(seq_along(messages),". ",messages)),"outputs/tables/messages_cles_decideur.md",useBytes=TRUE)
  choix <- c("TAUX_REPONSE","SCORE_GCL","SCORE_NUM","GAP_DIF","GAP_COL","GAP_NUM","PART_PROFIL_2")
  indicateurs <- r$catalogue[match(choix,r$catalogue$code_indicateur),c("code_indicateur","valeur","definition")]
  indicateurs <- rbind(indicateurs,data.frame(code_indicateur="ASSOCIATION_EQUIPEMENT_NUM",valeur=effet$effet,definition="Coefficient ajusté Bon versus Faible, score NUM ; association simulée"))
  stopifnot(nrow(indicateurs)<=8,!anyNA(indicateurs$code_indicateur),length(messages)==5)
  write.csv(indicateurs,"outputs/tables/indicateurs_cles_decideur.csv",row.names=FALSE,fileEncoding="UTF-8")
  list(messages=messages,dimensions=dimensions)
}
