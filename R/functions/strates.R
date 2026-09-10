# Attribution déterministe des huit strates opérationnelles, sans tirage.
construire_strates_sondage <- function(population) {
  colonnes <- c("id_enseignant", "degre", "secteur", "education_prioritaire")
  stopifnot(is.data.frame(population), all(colonnes %in% names(population)),
            nrow(population) > 0L, !anyNA(population[colonnes]),
            !anyDuplicated(population$id_enseignant),
            all(nzchar(population$id_enseignant)),
            all(population$degre %in% c("Premier degré", "Collège")),
            all(population$secteur %in% c("Public", "Privé sous contrat")),
            all(population$education_prioritaire %in% c("Hors EP", "REP", "REP+")))
  prive <- population$secteur == "Privé sous contrat"
  stopifnot(all(population$education_prioritaire[prive] == "Hors EP"))

  # Tester les huit règles séparément pour détecter les chevauchements éventuels.
  premier <- population$degre == "Premier degré"
  college <- population$degre == "Collège"
  public <- population$secteur == "Public"
  hep <- population$education_prioritaire == "Hors EP"
  rep <- population$education_prioritaire == "REP"
  repplus <- population$education_prioritaire == "REP+"
  appartenances <- cbind(
    P1_PUBLIC_HEP = premier & public & hep,
    P1_PUBLIC_REP = premier & public & rep,
    P1_PUBLIC_REPPLUS = premier & public & repplus,
    P1_PRIVE = premier & prive & hep,
    COL_PUBLIC_HEP = college & public & hep,
    COL_PUBLIC_REP = college & public & rep,
    COL_PUBLIC_REPPLUS = college & public & repplus,
    COL_PRIVE = college & prive & hep
  )
  stopifnot(!anyNA(appartenances), all(rowSums(appartenances) == 1L))
  codes <- colnames(appartenances)
  # ties.method = first évite tout appel au générateur aléatoire.
  strate_sondage <- codes[max.col(appartenances, ties.method = "first")]
  stopifnot(!anyNA(strate_sondage), all(nzchar(strate_sondage)))
  resultat <- population
  resultat$strate_sondage <- strate_sondage
  tailles <- data.frame(
    strate_sondage = codes,
    N_h = as.integer(colSums(appartenances)),
    part_population = as.numeric(colSums(appartenances)) / nrow(population),
    stringsAsFactors = FALSE
  )
  stopifnot(sum(tailles$N_h) == nrow(population),
            abs(sum(tailles$part_population) - 1) < 1e-12,
            identical(resultat$id_enseignant, population$id_enseignant))
  list(population = resultat, tailles = tailles)
}

# Apparier par code de strate, jamais par position dans la configuration.
calculer_allocation <- function(tailles, effectifs, taille_totale) {
  stopifnot(is.data.frame(tailles),
            all(c("strate_sondage", "N_h") %in% names(tailles)),
            !anyNA(tailles[c("strate_sondage", "N_h")]),
            !anyDuplicated(tailles$strate_sondage),
            is.numeric(effectifs), !is.null(names(effectifs)),
            !anyNA(effectifs), !anyNA(names(effectifs)),
            !anyDuplicated(names(effectifs)),
            setequal(names(effectifs), tailles$strate_sondage),
            all(is.finite(effectifs)), all(effectifs > 0),
            all(effectifs == floor(effectifs)),
            length(taille_totale) == 1L, is.finite(taille_totale),
            taille_totale > 0, taille_totale == floor(taille_totale),
            sum(effectifs) == taille_totale,
            is.numeric(tailles$N_h), all(is.finite(tailles$N_h)),
            all(tailles$N_h > 0), all(tailles$N_h == floor(tailles$N_h)))
  allocation <- tailles[c("strate_sondage", "N_h")]
  allocation$n_h <- as.integer(effectifs[allocation$strate_sondage])
  stopifnot(all(allocation$n_h <= allocation$N_h))
  # Probabilités de premier ordre pour un futur tirage aléatoire simple sans remise
  # à taille fixe dans chaque strate. Les poids sont antérieurs à la non-réponse.
  allocation$pi_h <- allocation$n_h / allocation$N_h
  allocation$poids_base <- 1 / allocation$pi_h
  stopifnot(sum(allocation$n_h) == taille_totale,
            !anyNA(allocation), all(is.finite(allocation$pi_h)),
            all(allocation$pi_h > 0 & allocation$pi_h <= 1),
            all(is.finite(allocation$poids_base)), all(allocation$poids_base > 0),
            abs(sum(allocation$n_h * allocation$poids_base) - sum(allocation$N_h)) < 1e-8)
  allocation
}
