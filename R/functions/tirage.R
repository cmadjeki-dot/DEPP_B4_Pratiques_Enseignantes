# Tirage aléatoire simple sans remise, indépendant dans chaque strate.
tirer_echantillon_stratifie <- function(population, allocation, graine) {
  stopifnot(is.data.frame(population), is.data.frame(allocation),
            all(c("id_enseignant", "strate_sondage") %in% names(population)),
            all(c("strate_sondage", "N_h", "n_h", "pi_h", "poids_base") %in% names(allocation)),
            !anyNA(population), !anyNA(allocation),
            !anyDuplicated(population$id_enseignant),
            !anyDuplicated(allocation$strate_sondage),
            setequal(population$strate_sondage, allocation$strate_sondage),
            length(graine) == 1L, is.finite(graine), graine >= 0,
            graine <= .Machine$integer.max, graine == floor(graine))
  tailles_reelles <- vapply(allocation$strate_sondage,
    function(s) sum(population$strate_sondage == s), integer(1))
  allocation_attendue <- calculer_allocation(
    data.frame(strate_sondage = allocation$strate_sondage, N_h = unname(tailles_reelles)),
    setNames(allocation$n_h, allocation$strate_sondage), sum(allocation$n_h)
  )
  stopifnot(isTRUE(all.equal(allocation, allocation_attendue, check.attributes = FALSE)))
  # Fixer aussi les algorithmes pour ne pas dépendre de l'état RNG de la session.
  set.seed(graine, kind = "Mersenne-Twister", normal.kind = "Inversion", sample.kind = "Rejection")
  indices <- unlist(lapply(seq_len(nrow(allocation)), function(h) {
    eligibles <- which(population$strate_sondage == allocation$strate_sondage[h])
    # sample.int évite le comportement spécial de sample() sur un entier isolé.
    eligibles[sample.int(length(eligibles), size = allocation$n_h[h], replace = FALSE)]
  }), use.names = FALSE)
  echantillon <- population[indices, , drop = FALSE]
  rownames(echantillon) <- NULL
  correspondance <- match(echantillon$strate_sondage, allocation$strate_sondage)
  for (nom in c("N_h", "n_h", "pi_h", "poids_base")) {
    echantillon[[nom]] <- allocation[[nom]][correspondance]
  }
  attr(echantillon, "graine_tirage") <- graine
  attr(echantillon, "plan_sondage") <- "Aléatoire simple stratifié sans remise, tailles fixées"
  attr(echantillon, "allocation") <- allocation
  verifier_echantillon(echantillon, population, allocation)
  echantillon
}

verifier_echantillon <- function(echantillon, population, allocation) {
  stopifnot(nrow(echantillon) == sum(allocation$n_h), !anyNA(echantillon),
            !anyDuplicated(echantillon$id_enseignant),
            all(echantillon$id_enseignant %in% population$id_enseignant),
            all(is.finite(echantillon$poids_base)), all(echantillon$poids_base > 0),
            all(is.finite(echantillon$pi_h)),
            all(echantillon$pi_h > 0 & echantillon$pi_h <= 1))
  # Vérifier toutes les caractéristiques des enseignants après sélection.
  origines <- match(echantillon$id_enseignant, population$id_enseignant)
  for (nom in names(population)) {
    stopifnot(identical(echantillon[[nom]], population[[nom]][origines]))
  }
  correspondance <- match(echantillon$strate_sondage, allocation$strate_sondage)
  stopifnot(!anyNA(correspondance))
  for (nom in c("N_h", "n_h", "pi_h", "poids_base")) {
    stopifnot(identical(echantillon[[nom]], allocation[[nom]][correspondance]))
  }
  controle <- allocation
  controle$n_observe <- vapply(allocation$strate_sondage,
    function(s) sum(echantillon$strate_sondage == s), integer(1))
  controle$ecart <- controle$n_observe - controle$n_h
  controle$somme_poids <- vapply(allocation$strate_sondage,
    function(s) sum(echantillon$poids_base[echantillon$strate_sondage == s]), numeric(1))
  stopifnot(all(controle$ecart == 0),
            all(abs(controle$somme_poids - controle$N_h) < 1e-8),
            abs(sum(echantillon$poids_base) - nrow(population)) < 1e-8)
  controle$statut <- "OK"
  controle
}
