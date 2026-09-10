# Assembler les résultats existants pour Quarto, sans réestimer les analyses.
for(p in c("ggplot2","yaml","survey")) if(!requireNamespace(p,quietly=TRUE)) stop("Package absent : ",p)
source("R/functions/theme_depp_demo.R",encoding="UTF-8")
config <- yaml::read_yaml("config/config.yml")
dimensions <- config$dimensions_latentes$dimensions
lire <- function(n) read.csv(paste0("outputs/tables/",n,".csv"),fileEncoding="UTF-8")
modeles <- readRDS("outputs/models/modeles_statistiques.rds")
provenance <- readRDS("outputs/models/provenance_modeles.rds")
stopifnot(identical(provenance,tools::md5sum(names(provenance))))
stopifnot(length(modeles)>0,all(vapply(modeles,function(m) all(is.finite(coef(m))) && m$converged,logical(1))))
scores <- lire("gap_pratique_priorite"); profils <- lire("profils_scores")
tailles <- lire("taille_profils"); qualite <- lire("dashboard_qualite")
coefficients <- lire("modeles_finaux"); predictions <- lire("predicted_probabilities_profiles")
stopifnot(nrow(scores)>0,nrow(profils)>0,nrow(coefficients)>0,
  all(is.finite(coefficients$coefficient)),all(predictions$probabilite_profil_2>=0 & predictions$probabilite_profil_2<=1))
catalogue <- data.frame(code_indicateur="TAUX_REPONSE",nom="Taux de réponse à la collecte",
  definition="Enseignants répondants uniques / enseignants sélectionnés, avant exclusions qualité",
  numerateur="Nombre de répondants uniques",denominateur="2000 enseignants sélectionnés",
  population="Échantillon initial synthétique",ponderation="Non pondéré",unite="Proportion 0–1",
  source="outputs/tables/dashboard_qualite.csv",statut_validation="Contrôlé ; simulation",valeur=qualite$taux_reponse)
for(d in dimensions) for(prefixe in c("SCORE_","FAIS_","PRIO_","GAP_")) {
  code <- paste0(prefixe,d); r <- scores[scores$indicateur==code,]
  stopifnot(nrow(r)==1)
  definition <- switch(prefixe,SCORE_="Moyenne des items retenus, avec minimum de réponses documenté",
    FAIS_="Faisabilité déclarée ordinale 1–5",PRIO_="Priorité déclarée ordinale 1–5",GAP_="Priorité moins score de pratique, sur paires disponibles")
  catalogue <- rbind(catalogue,data.frame(code_indicateur=code,nom=code,definition=definition,
    numerateur=paste0("Somme des poids finaux × ",code," parmi les valeurs disponibles"),
    denominateur="Somme des poids finaux parmi les valeurs disponibles",population="Base analytique incluse, valeurs disponibles propres à l’indicateur",
    ponderation="Poids finaux calibrés",unite=if(prefixe=="GAP_") "Points −4 à 4" else "Points 1 à 5",
    source="outputs/tables/gap_pratique_priorite.csv",statut_validation=if(prefixe=="SCORE_") "Score autorisé dans le démonstrateur" else "Descriptif ; ancrages distincts",valeur=r$moyenne_ponderee))
}
for(i in seq_len(nrow(tailles))) catalogue <- rbind(catalogue,data.frame(code_indicateur=paste0("PART_",tailles$profil_pratiques[i]),nom=paste("Part du",tailles$profil_pratiques[i]),
  definition="Part pondérée du profil parmi les enseignants classés",numerateur="Somme des poids finaux du profil",denominateur="Somme des poids finaux des enseignants classés",
  population="Cas complets sur les huit Z ; hors non classés",ponderation="Poids finaux calibrés",unite="Proportion 0–1",source="outputs/tables/taille_profils.csv",
  statut_validation="Exploratoire ; stabilité faible",valeur=tailles$proportion_ponderee[i]))
stopifnot(!anyDuplicated(catalogue$code_indicateur),all(is.finite(catalogue$valeur)))
catalogue$avertissement <- config$projet$avertissement
write.csv(catalogue,"outputs/tables/catalogue_indicateurs.csv",row.names=FALSE,fileEncoding="UTF-8")

# Figures finales homogènes issues des tableaux validés ; pas de réajustement.
t <- scores[grepl("^(SCORE|FAIS|PRIO)_",scores$indicateur),]
t$mesure <- sub("_.*","",t$indicateur)
graph <- ggplot2::ggplot(t,ggplot2::aes(dimension,moyenne_ponderee,colour=mesure)) +
  ggplot2::geom_pointrange(ggplot2::aes(ymin=ic95_inf,ymax=ic95_sup),position=ggplot2::position_dodge(.5)) +
  ggplot2::coord_flip() + ggplot2::scale_y_continuous(limits=c(1,5)) +
  ggplot2::scale_colour_manual(values=c(FAIS="#657786",PRIO="#B35806",SCORE="#2166AC"),labels=c(FAIS="Faisabilité",PRIO="Priorité",SCORE="Pratique")) +
  ggplot2::labs(title="Pratiques, faisabilité et priorité par dimension",subtitle="Moyennes pondérées et IC 95 % ; réponses disponibles propres à chaque mesure",x="Dimension",y="Échelle 1–5",colour="Mesure")
sauver_figure_demo(graph,"final_pratiques_faisabilite_priorite")
t <- profils[grepl("^SCORE_",profils$indicateur),]
graph <- ggplot2::ggplot(t,ggplot2::aes(dimension,moyenne_ponderee,colour=profil_pratiques)) +
  ggplot2::geom_pointrange(ggplot2::aes(ymin=ic95_inf,ymax=ic95_sup),position=ggplot2::position_dodge(.4)) + ggplot2::coord_flip() +
  ggplot2::scale_y_continuous(limits=c(1,5)) + ggplot2::labs(title="Pratiques déclarées selon le profil",subtitle="Description pondérée ; classes exploratoires à stabilité faible",x="Dimension",y="Score moyen et IC 95 %",colour="Profil")
sauver_figure_demo(graph,"final_profils_scores")
t <- lire("gap_par_profil")
graph <- ggplot2::ggplot(t,ggplot2::aes(dimension,moyenne_ponderee,colour=profil)) +
  ggplot2::geom_hline(yintercept=0,linetype=2) + ggplot2::geom_pointrange(ggplot2::aes(ymin=ic95_inf,ymax=ic95_sup),position=ggplot2::position_dodge(.4)) +
  ggplot2::coord_flip() + ggplot2::labs(title="Écarts déclarés priorité–pratique selon le profil",subtitle="Paires disponibles ; aucun besoin réel prouvé",x="Dimension",y="GAP moyen pondéré et IC 95 %",colour="Profil")
sauver_figure_demo(graph,"final_gap_profils")

tables <- c("catalogue_indicateurs","modeles_finaux","diagnostic_modeles","sensibilite_modeles","predicted_probabilities_profiles",
  "gap_pratique_priorite","profils_scores","composition_profils","gap_par_profil","interpretation_profils")
figures <- c("final_pratiques_faisabilite_priorite","final_profils_scores","final_gap_profils","predicted_profiles")
fichiers <- c(paste0("outputs/tables/",tables,".csv"),paste0("outputs/figures/",figures,".png"),
  "outputs/tables/modeles_finaux.html","outputs/tables/interpretation_modeles.md")
stopifnot(all(file.exists(fichiers)),all(file.info(fichiers)$size>0))
manifeste <- data.frame(fichier=fichiers,type=tools::file_ext(fichiers),octets=file.info(fichiers)$size,md5=unname(tools::md5sum(fichiers)),
  usage="Sortie finale pour Quarto",avertissement=config$projet$avertissement)
write.csv(manifeste,"outputs/tables/manifeste_sorties.csv",row.names=FALSE,fileEncoding="UTF-8")
saveRDS(list(catalogue=catalogue,modeles=coefficients,predictions=predictions,manifeste=manifeste,
  avertissement=config$projet$avertissement),"outputs/models/resultats_quarto.rds")
cat("Sorties assemblées sans réestimation :",nrow(catalogue),"indicateurs ;",nrow(manifeste),"livrables.\n")
