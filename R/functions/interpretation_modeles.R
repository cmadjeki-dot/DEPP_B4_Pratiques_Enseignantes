# Rédiger exclusivement à partir des coefficients estimés et de leurs IC.
interpreter_modeles <- function(tab,diagnostics,config) {
  lignes <- c("# Associations estimées dans le démonstrateur", "",config$projet$avertissement,"",
    "Les coefficients décrivent des associations ajustées, sans interprétation causale. Les scores inclus comme prédicteurs sont contemporains des réponses et issus du même questionnaire.","",
    "Unités : formation en jours ; ancienneté par dix années, centrée sur 15 ans ; effectif par cinq élèves, centré sur 24. Les autres scores sont sur 1–5. Les références catégorielles sont dans references_modeles.csv.")
  cibles <- list(mod_dif_final=c("formation_continue","SCORE_COL","SCORE_DEV"),
    mod_eva_final=c("formation_continue","SCORE_EXP","SCORE_DIF"),
    mod_num_final=c("equipement_numeriqueBon","formation_continue"),
    mod_gap_final=c("CONTRAINTE_DIF","SCORE_DEV","SCORE_COL"),
    mod_profil_final=c("formation_continue","equipement_numeriqueBon"))
  for(n in names(cibles)) {
    t <- tab[tab$modele==n & tab$terme %in% cibles[[n]],]
    lignes <- c(lignes,"",paste("##",n),"",paste("Réponse :",t$variable_dependante[1],"; n =",t$n[1],"; poids finaux calibrés."))
    for(i in seq_len(nrow(t))) {
      direction <- if(t$coefficient[i]>0) "positive" else "négative"
      incertitude <- if(t$ic95_inf[i]<=0 & t$ic95_sup[i]>=0) "L’IC inclut une association nulle." else if(n=="mod_profil_final") "L’IC de l’OR exclut 1 ; cela ne prouve pas une importance pratique." else "L’IC exclut zéro ; cela ne prouve pas une importance pratique."
      lignes <- c(lignes,sprintf("- %s : association %s ; %s = %.3f, IC 95 %% [%.3f ; %.3f]. %s",t$terme[i],direction,
        if(n=="mod_profil_final") "OR" else "coefficient",t$effet[i],t$effet_ic95_inf[i],t$effet_ic95_sup[i],incertitude))
    }
    diagnostic <- diagnostics[diagnostics$modele==n,]
    lignes <- c(lignes,if(n=="mod_profil_final") sprintf("Brier pondéré : %.3f ; pouvoir prédictif descriptif à examiner indépendamment de la significativité.",diagnostic$Brier) else sprintf("R² pondéré descriptif : %.3f ; RMSE : %.3f point(s).",diagnostic$R2_descriptif,diagnostic$RMSE_ponderee))
  }
  lignes <- c(lignes,"","## Limites communes","",
    "Les IC survey tiennent compte du plan de travail calibré, mais pas de toute l’incertitude de non-réponse, de validation des scores ou de construction des classes. Les modèles utilisent des cas complets, avec des effectifs variables selon la réponse. Les modèles imbriqués d’une même réponse sont ajustés sur les mêmes cas.",
    "Le GAP est un écart déclaré entre ancrages distincts, non un besoin réel prouvé. La logistique compare le profil 2 au profil 1 ; les classes sont faiblement stables. Les OR ne sont ni des rapports de probabilités ni des effets causaux.",
    "Les diagnostics de résidus, leviers, contributions d’influence et VIF sont descriptifs. Les SE sont robustes au modèle via survey ; aucun test OLS automatique de normalité ou d’homoscédasticité n’est utilisé. Les prédictions linéaires ne sont pas tronquées : toute sortie de l’échelle est comptée dans diagnostic_modeles.csv.",
    "Les variantes quadratiques et l’interaction équipement × degré sont conservées séparément. Leur lecture substantielle est documentée dans docs/modelisation.md. Les catégories ROBUSTE / MODEREMENT_ROBUSTE / SENSIBLE concernent uniquement les variantes de pondération et de qualité testées.")
  writeLines(lignes,"outputs/tables/interpretation_modeles.md",useBytes=TRUE)
}
