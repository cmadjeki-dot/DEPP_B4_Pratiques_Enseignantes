# Corrections consignées avant application et décisions conservées pour toutes les lignes.
nettoyer_questionnaire <- function(base, flags, dictionnaire, population, p) {
  stopifnot(nrow(base)==nrow(flags), identical(as.character(base$id_enseignant),as.character(flags$id_enseignant)),
    identical(as.integer(flags$ligne_source),seq_len(nrow(base))),
    p$completion_principale>0, p$completion_principale<=p$completion_sensibilite,
    p$completion_sensibilite<=1, p$minimum_pratiques>0)
  x <- base; n <- nrow(x); codes <- dictionnaire$variable
  journal <- data.frame(ligne_source=integer(),id_enseignant=character(),variable=character(),
    ancienne_valeur=character(),nouvelle_valeur=character(),motif=character(),type_correction=character())
  consigner_na <- function(nom, mauvais, motif) {
    indices <- which(!is.na(x[[nom]]) & mauvais)
    if (!length(indices)) return(invisible(NULL))
    journal <<- rbind(journal,data.frame(ligne_source=indices,id_enseignant=as.character(x$id_enseignant[indices]),
      variable=nom,ancienne_valeur=as.character(x[[nom]][indices]),nouvelle_valeur="NA",
      motif=motif,type_correction="HORS_DOMAINE_VERS_NA"))
    # L'événement est inscrit avant le changement dans cette copie de travail.
    x[[nom]][indices] <<- NA
  }
  for (j in seq_len(nrow(dictionnaire))) {
    nom <- codes[j]
    consigner_na(nom,!x[[nom]] %in% seq.int(dictionnaire$minimum[j],dictionnaire$maximum[j]),"Domaine du dictionnaire")
  }
  bornes <- list(age=c(23,65),anciennete=c(0,43),anciennete_classe=c(0,43),effectif_classe=c(12,35),formation_continue=c(0,20))
  for (nom in names(bornes)) {
    z <- x[[nom]]; b <- bornes[[nom]]
    consigner_na(nom,!is.finite(z)|z<b[1]|z>b[2]|z!=floor(z),"Borne ou intégralité impossible")
  }
  consigner_na("anciennete",!is.na(x$age)&x$anciennete>x$age-22,"Ancienneté incompatible avec un début au moins à 22 ans ; âge valide conservé")
  consigner_na("anciennete_classe",!is.na(x$anciennete)&x$anciennete_classe>x$anciennete,"Ancienneté de classe supérieure à ancienneté totale")
  categories <- setdiff(names(population)[vapply(population,is.character,logical(1))],"id_enseignant")
  for (nom in categories) consigner_na(nom,!x[[nom]] %in% unique(population[[nom]]),"Modalité absente du domaine de simulation")
  # Les incohérences entre catégories valides restent signalées : aucune modalité n'est inventée.
  x$ligne_source <- seq_len(n)
  for (nom in setdiff(names(flags),c("ligne_source","id_enseignant","avertissement"))) {
    destination <- if (nom %in% names(x)) paste0(nom,"_diagnostic_brut") else nom
    x[[destination]] <- flags[[nom]]
  }
  x$nb_reponses_valides_clean <- rowSums(!is.na(x[codes]))
  pratiques <- dictionnaire$variable[dictionnaire$bloc=="PRATIQUES"]
  x$nb_pratiques_valides_clean <- rowSums(!is.na(x[pratiques]))
  x$taux_completion_clean <- x$nb_reponses_valides_clean/length(codes)
  ids <- as.character(x$id_enseignant)
  absence_id <- is.na(ids)|trimws(ids)==""
  x$flag_doublon <- !absence_id & (duplicated(ids)|duplicated(ids,fromLast=TRUE))
  x$id_doublon_groupe <- NA_character_
  x$decision_doublon <- "UNIQUE"
  groupes <- sort(unique(ids[x$flag_doublon]))
  for (k in seq_along(groupes)) {
    i <- which(ids==groupes[k])
    # Un même identifiant avec des caractéristiques de sondage contradictoires exige une expertise.
    immuables <- c("degre","secteur","strate_sondage","N_h","n_h","pi_h","poids_base")
    if (any(vapply(base[i,immuables,drop=FALSE],function(z) length(unique(z))>1,logical(1)))) {
      stop("Doublon ambigu avec contexte de sondage contradictoire : ",groupes[k])
    }
    plausible <- !is.na(flags$Q014[i]) & !flags$Q014[i] & !is.na(flags$flag_rapide[i]) & !flags$flag_rapide[i]
    date <- as.numeric(x$date_reponse_simulee[i]); date[is.na(date)] <- -Inf
    classement <- order(-(x$taux_completion_clean[i]==1),-x$taux_completion_clean[i],-plausible,-date,i)
    x$id_doublon_groupe[i] <- sprintf("DUP%05d",k)
    x$decision_doublon[i] <- "EXCLURE_COPIE"
    x$decision_doublon[i[classement[1]]] <- "CONSERVER_REFERENCE"
  }
  vrai <- function(z) !is.na(z)&z
  inexploitable <- absence_id | x$nb_reponses_valides_clean==0 |
    vrai(flags$Q004) | vrai(flags$Q019) | vrai(flags$Q012) | vrai(flags$Q013)
  faible <- x$taux_completion_clean<p$completion_principale | x$nb_pratiques_valides_clean<p$minimum_pratiques
  qualite <- vrai(flags$flag_tres_rapide)&vrai(flags$flag_straightlining)&vrai(flags$Q023)
  doublon <- x$decision_doublon=="EXCLURE_COPIE"
  x$statut_analyse <- ifelse(doublon,"EXCLU_DOUBLON",ifelse(inexploitable,"EXCLU_INEXPLOITABLE",
    ifelse(faible,"EXCLU_COMPLETION",ifelse(qualite,"EXCLU_QUALITE","INCLUS"))))
  x$raison_exclusion <- vapply(seq_len(n),function(i) {
    raisons <- c(if(doublon[i]) "Copie technique non prioritaire",
      if(inexploitable[i]) "Identifiant/contexte de sondage incohérent ou questionnaire vide",
      if(x$taux_completion_clean[i]<p$completion_principale) "Moins de 50 % de réponses valides",
      if(x$nb_pratiques_valides_clean[i]<p$minimum_pratiques) "Moins de 24 pratiques valides",
      if(qualite[i]) "Très rapide ET straightlining ET échec CTRL01")
    paste(raisons,collapse=" ; ")
  },character(1))
  x$flag_analyse_principale <- x$statut_analyse=="INCLUS"
  x$flag_analyse_sensibilite <- x$flag_analyse_principale & x$taux_completion_clean>=p$completion_sensibilite &
    !vrai(flags$flag_tres_rapide) & !(vrai(flags$flag_rapide)&(vrai(flags$flag_straightlining)|vrai(flags$Q023))) &
    !is.na(flags$flag_rapide) & !is.na(flags$flag_straightlining)
  x$raison_hors_sensibilite <- ifelse(x$flag_analyse_sensibilite,"",
    ifelse(!x$flag_analyse_principale,"Exclu de l'analyse principale",
      "Complétion < 80 % ou très rapide ou cumul rapide/constance-lecture ou qualité non évaluable"))
  x$version_regles_nettoyage <- p$version_regles
  attr(x,"regles_nettoyage") <- p
  stopifnot(nrow(x)==nrow(base),all(x$flag_analyse_sensibilite<=x$flag_analyse_principale),
    all(nzchar(x$raison_exclusion[!x$flag_analyse_principale])))
  list(toutes=x,clean=x[x$flag_analyse_principale,,drop=FALSE],exclus=x[!x$flag_analyse_principale,,drop=FALSE],
    journal=journal,doublons=x[x$flag_doublon,c("ligne_source","id_enseignant","flag_doublon","id_doublon_groupe","decision_doublon","taux_completion_clean","duree_secondes","date_reponse_simulee","statut_analyse")])
}
