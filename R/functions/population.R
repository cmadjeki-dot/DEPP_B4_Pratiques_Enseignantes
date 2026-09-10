# Fonctions de simulation et de contrôle de la population, sans effet de bord.

verifier_configuration_population <- function(config) {
  p <- config$population
  verifier_probabilites <- function(x, taille) {
    stopifnot(is.numeric(x), length(x) == taille, !anyNA(x),
              all(is.finite(x)), all(x >= 0 & x <= 1),
              abs(sum(x) - 1) < 1e-10)
  }
  verifier_entier <- function(x, minimum = 0) {
    stopifnot(is.numeric(x), length(x) == 1L, is.finite(x),
              x >= minimum, x == floor(x))
  }
  verifier_entier(p$taille, 1)
  verifier_entier(p$graine)
  verifier_entier(config$echantillon$taille, 1)
  stopifnot(config$echantillon$taille <= p$taille,
            identical(p$degres, c("Premier degré", "Collège")),
            identical(p$secteurs, c("Public", "Privé sous contrat")),
            identical(p$education_prioritaire, c("Hors EP", "REP", "REP+")),
            identical(p$territoires, c("Urbain", "Périurbain", "Rural")),
            identical(p$sexes, c("Femme", "Homme")))
  verifier_probabilites(p$probabilites_degre, 2)
  for (x in list(p$probabilite_femme, p$probabilite_prive,
                 p$statut$probabilite_temporaire)) {
    stopifnot(length(x) == 2L, !anyNA(x), all(x >= 0 & x <= 1))
  }
  stopifnot(length(p$probabilites_territoire) == 2L,
            length(p$probabilites_ep_public) == 3L)
  for (x in p$probabilites_territoire) verifier_probabilites(x, 3)
  for (x in p$probabilites_ep_public) verifier_probabilites(x, 3)
  verifier_probabilites(p$disciplines$probabilites, length(p$disciplines$college))
  stopifnot(length(p$disciplines$college) > 1L,
            !anyNA(p$disciplines$college), !anyDuplicated(p$disciplines$college),
            !any(p$disciplines$college == ""),
            identical(p$disciplines$premier, "Polyvalent premier degré"),
            !p$disciplines$premier %in% p$disciplines$college)
  a <- p$age
  e <- p$effectif_classe
  for (x in list(a$minimum, a$maximum, e$minimum, e$maximum,
                 p$anciennete$age_entree_minimum,
                 p$anciennete$age_entree_maximum,
                 p$formation_continue$maximum_jours)) verifier_entier(x, 1)
  stopifnot(a$minimum < a$maximum, e$minimum < e$maximum,
            p$anciennete$age_entree_minimum <= a$minimum,
            p$anciennete$age_entree_maximum >= p$anciennete$age_entree_minimum,
            length(a$moyennes) == 2L, length(e$moyennes) == 2L,
            all(a$moyennes > a$minimum & a$moyennes < a$maximum),
            all(e$moyennes > e$minimum & e$moyennes < e$maximum),
            a$ecart_type > 0, e$ecart_type > 0,
            p$anciennete$interruptions_lambda >= 0,
            length(p$anciennete$niveau_beta) == 2L,
            all(p$anciennete$niveau_beta > 0),
            length(e$effets_ep) == 3L, length(e$effets_territoire) == 3L,
            all(is.finite(c(e$effets_ep, e$effets_territoire, e$effet_prive))))
  f <- p$formation_continue
  stopifnot(f$lambda_jours >= 0,
            all(outer(c(0, f$effet_ep), c(0, f$effet_college), "+") +
                  f$probabilite_base >= 0),
            all(outer(c(0, f$effet_ep), c(0, f$effet_college), "+") +
                  f$probabilite_base <= 1),
            length(p$statut$public) == 2L, length(p$statut$prive) == 2L,
            p$statut$surcroit_debut_carriere >= 0,
            all(p$statut$probabilite_temporaire +
                  p$statut$surcroit_debut_carriere <= 1))
  q <- p$equipement_numerique
  stopifnot(identical(q$modalites, c("Faible", "Moyen", "Bon")))
  verifier_probabilites(q$probabilites, 3)
  transferts <- expand.grid(college = c(0, q$transfert_college),
                           rural = c(0, q$transfert_rural),
                           prive = c(0, q$transfert_prive))
  delta <- rowSums(transferts)
  stopifnot(all(q$probabilites[1] - delta >= 0),
            all(q$probabilites[3] + delta >= 0),
            is.character(config$projet$avertissement),
            length(config$projet$avertissement) == 1L,
            nzchar(config$projet$avertissement))
  invisible(TRUE)
}

tirer_normal_entier_borne <- function(moyenne, ecart_type, minimum, maximum) {
  # Tirage par rejet : ne pas accumuler artificiellement les observations aux bornes.
  resultat <- as.integer(round(rnorm(length(moyenne), moyenne, ecart_type)))
  hors_bornes <- which(resultat < minimum | resultat > maximum)
  tentatives <- 0L
  while (length(hors_bornes)) {
    tentatives <- tentatives + 1L
    if (tentatives > 1000L) stop("Rejet excessif : vérifier les paramètres de simulation.")
    resultat[hors_bornes] <- as.integer(round(rnorm(
      length(hors_bornes), moyenne[hors_bornes], ecart_type
    )))
    hors_bornes <- which(resultat < minimum | resultat > maximum)
  }
  resultat
}

construire_strate <- function(population) {
  # Croisement des quatre variables du futur plan de sondage.
  with(population, paste(degre, secteur, education_prioritaire, territoire, sep = " | "))
}

generer_population <- function(config) {
  verifier_configuration_population(config)
  p <- config$population
  n <- as.integer(p$taille)
  # La configuration fixe ici la graine 20260909.
  set.seed(p$graine)

  # Contexte d'exercice : probabilités conditionnelles au degré et au territoire.
  indice_degre <- sample.int(2L, n, replace = TRUE, prob = p$probabilites_degre)
  prive <- runif(n) < p$probabilite_prive[indice_degre]
  indice_territoire <- integer(n)
  for (d in seq_along(p$degres)) {
    lignes <- which(indice_degre == d)
    indice_territoire[lignes] <- sample.int(
      3L, length(lignes), replace = TRUE, prob = p$probabilites_territoire[[d]]
    )
  }
  indice_ep <- rep.int(1L, n)
  for (t in seq_along(p$territoires)) {
    lignes <- which(!prive & indice_territoire == t)
    indice_ep[lignes] <- sample.int(
      3L, length(lignes), replace = TRUE, prob = p$probabilites_ep_public[[t]]
    )
  }

  # Carrière : entrée après l'âge minimal, avec interruptions possibles.
  sexe <- ifelse(runif(n) < p$probabilite_femme[indice_degre], p$sexes[1], p$sexes[2])
  age <- tirer_normal_entier_borne(p$age$moyennes[indice_degre], p$age$ecart_type,
                                  p$age$minimum, p$age$maximum)
  entree_min <- p$anciennete$age_entree_minimum
  entree_max <- pmin(age, p$anciennete$age_entree_maximum)
  age_entree <- entree_min + floor(runif(n) * (entree_max - entree_min + 1L))
  anciennete <- as.integer(pmax(0, age - age_entree -
                                 rpois(n, p$anciennete$interruptions_lambda)))
  anciennete_classe <- as.integer(floor(anciennete * rbeta(
    n, p$anciennete$niveau_beta[1], p$anciennete$niveau_beta[2]
  )))

  # Effectif du groupe ou de la classe principalement enseignée (pas tous les élèves).
  e <- p$effectif_classe
  moyenne_effectif <- e$moyennes[indice_degre] + e$effets_ep[indice_ep] +
    e$effets_territoire[indice_territoire] + e$effet_prive * prive
  effectif_classe <- tirer_normal_entier_borne(moyenne_effectif, e$ecart_type,
                                              e$minimum, e$maximum)
  temporaire <- runif(n) < p$statut$probabilite_temporaire[indice_degre] +
    p$statut$surcroit_debut_carriere * (anciennete <= p$statut$seuil_debut_carriere)
  indice_statut <- 1L + as.integer(temporaire)
  statut <- ifelse(prive, p$statut$prive[indice_statut], p$statut$public[indice_statut])

  # Formation (jours entiers) et équipement : associations contextuelles modérées.
  f <- p$formation_continue
  probabilite_formation <- f$probabilite_base + f$effet_ep * (indice_ep > 1L) +
    f$effet_college * (indice_degre == 2L)
  suit_formation <- runif(n) < probabilite_formation
  formation_continue <- integer(n)
  formation_continue[suit_formation] <- as.integer(pmin(
    f$maximum_jours, 1L + rpois(sum(suit_formation), f$lambda_jours)
  ))
  q <- p$equipement_numerique
  delta <- q$transfert_college * (indice_degre == 2L) +
    q$transfert_rural * (indice_territoire == 3L) + q$transfert_prive * prive
  seuil_faible <- q$probabilites[1] - delta
  tirage_equipement <- runif(n)
  indice_equipement <- 1L + as.integer(tirage_equipement >= seuil_faible) +
    as.integer(tirage_equipement >= seuil_faible + q$probabilites[2])
  discipline <- rep(p$disciplines$premier, n)
  lignes_college <- which(indice_degre == 2L)
  discipline[lignes_college] <- sample(p$disciplines$college, length(lignes_college),
                                      replace = TRUE, prob = p$disciplines$probabilites)

  population <- data.frame(
    id_enseignant = sprintf("ENS%06d", seq_len(n)),
    degre = p$degres[indice_degre], sexe = sexe, age = age,
    anciennete = anciennete, anciennete_classe = anciennete_classe,
    secteur = p$secteurs[1L + as.integer(prive)],
    education_prioritaire = p$education_prioritaire[indice_ep],
    territoire = p$territoires[indice_territoire], effectif_classe = effectif_classe,
    statut = statut, formation_continue = formation_continue,
    equipement_numerique = q$modalites[indice_equipement], discipline = discipline,
    stringsAsFactors = FALSE
  )
  population$strate <- construire_strate(population)
  attr(population, "avertissement") <- config$projet$avertissement
  attr(population, "graine") <- p$graine
  attr(population, "configuration_simulation") <- p
  verifier_population(population, config)
  population
}

verifier_population <- function(population, config) {
  p <- config$population
  colonnes <- c("id_enseignant", "degre", "sexe", "age", "anciennete",
                "anciennete_classe", "secteur", "education_prioritaire", "territoire",
                "effectif_classe", "statut", "formation_continue",
                "equipement_numerique", "discipline", "strate")
  stopifnot(is.data.frame(population), identical(names(population), colonnes),
            nrow(population) == p$taille, !anyNA(population),
            anyDuplicated(population$id_enseignant) == 0L,
            all(nzchar(population$id_enseignant)),
            identical(population$id_enseignant, sprintf("ENS%06d", seq_len(p$taille))))
  for (nom in c("age", "anciennete", "anciennete_classe", "effectif_classe",
                "formation_continue")) {
    x <- population[[nom]]
    stopifnot(is.numeric(x), all(is.finite(x)), all(x == floor(x)))
  }
  stopifnot(all(population$age >= p$age$minimum & population$age <= p$age$maximum),
            all(population$anciennete >= 0),
            all(population$anciennete <= population$age - p$anciennete$age_entree_minimum),
            all(population$anciennete_classe >= 0 &
                  population$anciennete_classe <= population$anciennete),
            all(population$effectif_classe >= p$effectif_classe$minimum &
                  population$effectif_classe <= p$effectif_classe$maximum),
            all(population$formation_continue >= 0 &
                  population$formation_continue <= p$formation_continue$maximum_jours),
            all(population$degre %in% p$degres), all(population$sexe %in% p$sexes),
            all(population$secteur %in% p$secteurs),
            all(population$education_prioritaire %in% p$education_prioritaire),
            all(population$territoire %in% p$territoires),
            all(population$equipement_numerique %in% p$equipement_numerique$modalites),
            all(nzchar(population$strate)),
            identical(population$strate, construire_strate(population)))
  prive <- population$secteur == p$secteurs[2]
  premier <- population$degre == p$degres[1]
  stopifnot(all(population$education_prioritaire[prive] == "Hors EP"),
            all(population$statut[prive] %in% p$statut$prive),
            all(population$statut[!prive] %in% p$statut$public),
            all(population$discipline[premier] == p$disciplines$premier),
            all(population$discipline[!premier] %in% p$disciplines$college),
            all(nzchar(population$discipline)))
  invisible(TRUE)
}
