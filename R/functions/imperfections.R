# Injection traçable ; ces vérités de simulation ne sont pas des diagnostics qualité.
introduire_imperfections <- function(base, ordre, p) {
  codes <- ordre$variable
  principaux <- codes[ordre$bloc == "PRATIQUES"]
  n <- nrow(base)
  stopifnot(n > 0, length(codes) == 68L, !anyDuplicated(codes),
    identical(ordre$ordre, seq_along(codes)), length(principaux) == 48L,
    all(codes %in% names(base)), !anyNA(base[codes]), !anyDuplicated(base$id_enseignant),
    p$nombre_partiels + p$nombre_abandons <= n,
    p$nombre_straightlining <= n, p$nombre_rapides <= n,
    p$nombre_items_constants <= length(principaux),
    p$nombre_items_fin > 0, p$nombre_items_fin < length(codes),
    p$taux_manquant_aleatoire >= 0, p$taux_manquant_aleatoire < 1,
    p$taux_manquant_fin >= 0, p$taux_manquant_fin < 1,
    p$nombre_trous_partiel > 0, p$nombre_trous_partiel < length(codes),
    all(p$abandon_position > 0 & p$abandon_position < length(codes)))
  # Extraire la collecte brute : les dérivées restent dans la référence complète.
  derives <- grepl("^(SCORE_PROV_|GAP_)|^CTRL0[24]_reverse$", names(base))
  x <- base[, !derives, drop = FALSE]
  set.seed(p$graine, kind = "Mersenne-Twister", normal.kind = "Inversion", sample.kind = "Rejection")
  groupes <- sample.int(n, p$nombre_partiels + p$nombre_abandons)
  partiels <- head(groupes, p$nombre_partiels)
  abandons <- tail(groupes, p$nombre_abandons)
  constants <- sample.int(n, p$nombre_straightlining)
  rapides <- sample.int(n, p$nombre_rapides)
  journal <- list()
  enregistrer <- function(i, variable, cause, avant, apres) {
    journal[[length(journal) + 1L]] <<- data.frame(id_enseignant = x$id_enseignant[i],
      variable = variable, cause = cause, avant = as.character(avant), apres = as.character(apres))
  }
  # Réponse quasi constante sur 46 des 48 items, avant la non-réponse partielle.
  for (i in constants) {
    modalite <- sample.int(5L, 1L)
    selection <- principaux[sample.int(length(principaux), p$nombre_items_constants)]
    for (nom in selection) {
      enregistrer(i, nom, "straightlining", x[[nom]][i], modalite)
      x[[nom]][i] <- modalite
    }
  }
  # Chaque cellule manquante reçoit une seule cause, selon l'ordre d'injection.
  masquer <- function(i, noms, cause) {
    for (nom in noms) if (!is.na(x[[nom]][i])) {
      enregistrer(i, nom, cause, x[[nom]][i], NA_integer_)
      x[[nom]][i] <<- NA_integer_
    }
  }
  for (i in abandons) {
    position <- sample(seq.int(p$abandon_position[1], p$abandon_position[2]), 1L)
    masquer(i, codes[seq.int(position + 1L, length(codes))], "abandon")
  }
  for (i in partiels) masquer(i, codes[sample.int(length(codes), p$nombre_trous_partiel)], "partiel")
  for (nom in codes) {
    indices <- which(runif(n) < p$taux_manquant_aleatoire & !is.na(x[[nom]]))
    for (i in indices) masquer(i, nom, "manquant_aleatoire")
  }
  for (nom in tail(codes, p$nombre_items_fin)) {
    indices <- which(runif(n) < p$taux_manquant_fin & !is.na(x[[nom]]))
    for (i in indices) masquer(i, nom, "manquant_fin")
  }
  x$taux_completion <- rowMeans(!is.na(x[codes]))
  x$statut_questionnaire <- ifelse(x$taux_completion == 1, "Complet", "Partiel")
  x$statut_questionnaire[abandons] <- "Abandon"
  x$flag_straightlining_simule <- seq_len(n) %in% constants
  x$flag_rapide_simule <- seq_len(n) %in% rapides
  x$duree_secondes <- as.integer(round(pmax(p$duree_min_normale,
    rlnorm(n, log(p$duree_mediane), p$duree_sdlog) * x$taux_completion)))
  for (i in rapides) {
    duree <- sample(seq.int(p$duree_rapide[1], p$duree_rapide[2]), 1L)
    enregistrer(i, "duree_secondes", "rapide", x$duree_secondes[i], duree)
    x$duree_secondes[i] <- duree
  }
  # Date de dernière activité, y compris pour les abandons ; aucun horodatage réel.
  x$date_reponse_simulee <- as.Date(p$date_debut) + sample.int(p$nombre_jours, n, replace = TRUE) - 1L
  registre <- do.call(rbind, journal)
  registre$modification_effective <- is.na(registre$apres) | registre$avant != registre$apres
  causes <- unique(registre$cause)
  bilan <- do.call(rbind, lapply(causes, function(cause) {
    z <- registre[registre$cause == cause, ]
    data.frame(cause = cause, enseignants = length(unique(z$id_enseignant)),
      cellules_ciblees = nrow(z), cellules_modifiees = sum(z$modification_effective))
  }))
  stopifnot(nrow(x) == n, !anyDuplicated(x$id_enseignant),
    sum(is.na(x[codes])) == sum(is.na(registre$apres)),
    all(x$taux_completion >= 0 & x$taux_completion <= 1),
    sum(x$flag_straightlining_simule) == p$nombre_straightlining,
    sum(x$flag_rapide_simule) == p$nombre_rapides,
    sum(x$statut_questionnaire == "Abandon") == p$nombre_abandons,
    !anyNA(x$duree_secondes), all(x$duree_secondes > 0), !anyNA(x$date_reponse_simulee))
  attr(x, "imperfections") <- p
  list(donnees = x, registre = registre, bilan = bilan)
}
