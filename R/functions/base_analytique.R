# Base analytique : appariement explicite des scores et des poids, sans imputation.
construire_base_analytique <- function(dimensions,config) {
  if(!requireNamespace("survey",quietly=TRUE)) stop("Package survey absent : restaurer renv.")
  chemins <- c("data/processed/questionnaire_scores.rds","data/processed/questionnaire_weighted.rds","data/processed/design_depp.rds")
  empreintes <- tools::md5sum(chemins)
  s <- readRDS(chemins[1]); p <- readRDS(chemins[2]); design <- readRDS(chemins[3])
  for(b in list(s,p,design$variables)) stopifnot(!anyNA(b$id_enseignant),!anyDuplicated(b$id_enseignant))
  stopifnot(setequal(s$id_enseignant,p$id_enseignant),setequal(s$id_enseignant,design$variables$id_enseignant))
  p <- p[match(s$id_enseignant,p$id_enseignant),,drop=FALSE]
  # Refuser un mélange de générations incompatibles du pipeline.
  communs <- intersect(names(s),names(p))
  stopifnot(all(vapply(communs,function(n) identical(s[[n]],p[[n]]),logical(1))))
  identite <- c("id_enseignant","degre","sexe","age","anciennete","anciennete_classe","secteur",
    "education_prioritaire","territoire","effectif_classe","statut","formation_continue","equipement_numerique","discipline")
  sondage <- c("strate_sondage","N_h","n_h","pi_h","poids_base")
  ponderation <- c("cellule_nr","facteur_nr","poids_nr","facteur_calibration","poids_final")
  qualite <- c("statut_analyse","flag_analyse_principale","flag_analyse_sensibilite","flag_straightlining",
    "flag_rapide","flag_tres_rapide","flag_doublon","taux_completion_clean","statut_questionnaire","duree_secondes")
  mesures <- unlist(lapply(c("SCORE_","Z_","NB_ITEMS_","FAIS_","PRIO_"),paste0,dimensions))
  stopifnot(all(c(identite,sondage,qualite,mesures) %in% names(s)),all(ponderation %in% names(p)))
  a <- s[c(identite,sondage,qualite,mesures)]
  for(n in ponderation) a[[n]] <- p[[n]]
  stopifnot(all(is.finite(a$poids_final)),all(a$poids_final>0))
  j <- match(design$variables$id_enseignant,a$id_enseignant)
  stopifnot(isTRUE(all.equal(as.numeric(weights(design)),a$poids_final[j])))
  source("R/functions/descriptive.R",encoding="UTF-8")
  tables <- list()
  for(d in dimensions) {
    a[[paste0("GAP_",d)]] <- a[[paste0("PRIO_",d)]]-a[[paste0("SCORE_",d)]]
    a[[paste0("CONTRAINTE_",d)]] <- 5-a[[paste0("FAIS_",d)]]
    for(prefixe in c("SCORE_","FAIS_","PRIO_","GAP_","CONTRAINTE_")) {
      nom <- paste0(prefixe,d)
      tables[[nom]] <- data.frame(dimension=d,indicateur=nom,resumer_continue(design,a[[nom]][j]))
    }
  }
  table <- do.call(rbind,tables); rownames(table) <- NULL
  table$avertissement <- config$projet$avertissement
  write.csv(table,"outputs/tables/gap_pratique_priorite.csv",row.names=FALSE,fileEncoding="UTF-8")
  # Une variable documentée par colonne ; les domaines observés ne prétendent pas être exhaustifs.
  dictionnaire <- read.csv("metadata/dictionnaire_variables.csv",fileEncoding="UTF-8")
  libelles <- c(id_enseignant="Identifiant unique de l'enseignant fictif",degre="Degré d'enseignement",sexe="Sexe simulé",
    age="Âge en années",anciennete="Ancienneté professionnelle en années",anciennete_classe="Classe d'ancienneté",
    secteur="Secteur d'enseignement",education_prioritaire="Éducation prioritaire",territoire="Type de territoire",
    effectif_classe="Effectif de la classe",statut="Statut professionnel",formation_continue="Jours de formation continue",
    equipement_numerique="Niveau d'équipement numérique",discipline="Discipline enseignée",strate_sondage="Strate opérationnelle",
    N_h="Effectif de population dans la strate",n_h="Allocation initiale de la strate",pi_h="Probabilité d'inclusion initiale",
    poids_base="Poids de sondage initial",cellule_nr="Cellule de correction de non-réponse",facteur_nr="Facteur de correction de non-réponse",
    poids_nr="Poids corrigé de non-réponse",facteur_calibration="Multiplicateur de calibration",poids_final="Poids final calibré",
    statut_analyse="Décision d'inclusion analytique",flag_analyse_principale="Inclusion dans l'analyse principale",
    flag_analyse_sensibilite="Éligibilité à l'analyse de sensibilité stricte",flag_straightlining="Signal de réponse uniforme",
    flag_rapide="Signal de réponse rapide",flag_tres_rapide="Signal de réponse très rapide",flag_doublon="Appartenance à un groupe de doublons",
    taux_completion_clean="Proportion de réponses valides après nettoyage",statut_questionnaire="Statut déclaré de collecte",
    duree_secondes="Durée de réponse en secondes")
  regles <- read.csv("outputs/tables/regles_scores_definitifs.csv",fileEncoding="UTF-8")
  meta <- do.call(rbind,lapply(names(a),function(n) {
    dim <- if(grepl("^(SCORE|Z|NB_ITEMS|FAIS|PRIO|GAP|CONTRAINTE)_",n)) sub("^.*_","",n) else NA_character_
    lib <- if(n %in% names(libelles)) libelles[[n]] else n
    description <- "Variable conservée sans transformation ; données simulées."
    minimum <- maximum <- NA_real_
    origine <- if(n %in% ponderation) "questionnaire_weighted.rds" else "questionnaire_scores.rds"
    if(n %in% dictionnaire$variable) { i <- match(n,dictionnaire$variable); lib <- dictionnaire$libelle[i]; description <- dictionnaire$description[i]; minimum <- 1; maximum <- 5 }
    if(grepl("^SCORE_",n)) {
      r <- regles[regles$dimension==dim,]; lib <- paste("Score de pratique",dim)
      description <- paste("Moyenne des items",r$items,"; au moins",r$minimum_reponses,"réponses ; sinon NA. Score du démonstrateur.")
      minimum <- 1; maximum <- 5
    }
    if(grepl("^Z_",n)) {lib <- paste("Score standardisé",dim); description <- "(SCORE - moyenne non pondérée disponible) / écart-type ; paramètres dans regles_scores_definitifs.csv."}
    if(grepl("^NB_ITEMS_",n)) {lib <- paste("Nombre d'items renseignés",dim); minimum <- 0; maximum <- regles$nb_items[match(dim,regles$dimension)]}
    if(grepl("^GAP_",n)) {lib <- paste("Écart priorité moins pratique",dim); description <- paste0("PRIO_",dim," - SCORE_",dim," ; NA si l'un manque. Différence exploratoire d'ancrages distincts."); minimum <- -4; maximum <- 4; origine <- "Calcul analytique"}
    if(grepl("^CONTRAINTE_",n)) {lib <- paste("Contrainte perçue dérivée de la faisabilité",dim); description <- paste0("5 - FAIS_",dim," ; de 0 (faisabilité maximale) à 4 ; NA propagé. Indicateur dérivé, pas une échelle validée de contraintes."); minimum <- 0; maximum <- 4; origine <- "Calcul analytique"}
    v <- a[[n]]
    data.frame(variable=n,libelle=lib,dimension=dim,type=class(v)[1],origine=origine,minimum=minimum,maximum=maximum,
      modalites_observees=if(is.character(v)||is.factor(v)||is.logical(v)) paste(sort(unique(v[!is.na(v)])),collapse=" | ") else NA_character_,
      n_manquants=sum(is.na(v)),description=description)
  }))
  stopifnot(identical(meta$variable,names(a)),!anyDuplicated(names(a)),nrow(a)==nrow(s))
  numeriques <- a[vapply(a,is.numeric,logical(1))]
  stopifnot(!any(vapply(numeriques,function(v)any(is.infinite(v)|is.nan(v)),logical(1))))
  attr(a,"avertissement") <- config$projet$avertissement
  attr(a,"provenance_analytique") <- empreintes
  saveRDS(a,"data/processed/base_analytique.rds")
  write.csv(meta,"metadata/dictionnaire_base_analytique.csv",row.names=FALSE,fileEncoding="UTF-8")
  stopifnot(identical(a,readRDS("data/processed/base_analytique.rds")),identical(empreintes,tools::md5sum(chemins)))
  cat("Base analytique :",nrow(a),"lignes ;",ncol(a),"colonnes.\n")
}
