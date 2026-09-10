# Diagnostics uniquement : toutes les transformations restent dans des objets dérivés.
auditer_qualite <- function(base, echantillon, suivi, population, dictionnaire, ordre, plan) {
  attendus <- c(names(echantillon), dictionnaire$variable, "repondant", "statut_questionnaire",
    "duree_secondes", "date_reponse_simulee", "taux_completion")
  stopifnot(!anyDuplicated(plan$id_controle), !anyDuplicated(echantillon$id_enseignant))
  synthese <- list(); flags <- data.frame(ligne_source = seq_len(nrow(base)))
  ajouter <- function(id, signal, unite = "questionnaire") {
    # NA = non évaluable ; jamais assimilé à une absence d'anomalie.
    synthese[[id]] <<- data.frame(id_controle = id, unite = unite,
      n_examines = length(signal), n_anomalies = sum(signal, na.rm = TRUE),
      n_non_evaluables = sum(is.na(signal)),
      resultat = if (any(signal, na.rm = TRUE)) "ANOMALIE" else if (anyNA(signal)) "NON_EVALUABLE" else "OK")
    if (unite == "questionnaire") flags[[id]] <<- signal
  }
  seuil <- function(id) as.numeric(plan$seuil[match(id, plan$id_controle)])
  absentes <- setdiff(attendus, names(base)); supplementaires <- setdiff(names(base), attendus)
  ajouter("Q001", nrow(base) < 1 | nrow(base) > seuil("Q001"), "base")
  ajouter("Q002", length(absentes) > 0 | length(supplementaires) > 0 |
    ncol(base) != seuil("Q002") | anyDuplicated(names(base)) > 0, "base")
  types_attendus <- c(vapply(echantillon, function(x) class(x)[1], character(1)),
    setNames(rep("integer", nrow(dictionnaire)), dictionnaire$variable),
    repondant = "integer", statut_questionnaire = "character", duree_secondes = "integer",
    date_reponse_simulee = "Date", taux_completion = "numeric")
  communes <- intersect(names(types_attendus), names(base))
  types <- data.frame(variable = communes, attendu = types_attendus[communes],
    observe = vapply(base[communes], function(x) class(x)[1], character(1)), row.names = NULL)
  ajouter("Q025", types$attendu != types$observe, "variable")
  terminer <- function(details = list()) {
    non_faits <- setdiff(plan$id_controle, names(synthese))
    for (id in non_faits) ajouter(id, NA, "controle")
    bilan <- do.call(rbind, synthese); rownames(bilan) <- NULL
    bilan <- merge(plan, bilan, by = "id_controle", sort = FALSE)
    bilan <- bilan[match(plan$id_controle, bilan$id_controle), ]
    list(synthese = bilan, flags = flags, variables_absentes = data.frame(variable = absentes),
      variables_supplementaires = data.frame(variable = supplementaires), types = types, details = details)
  }
  if (length(absentes) || anyDuplicated(names(base)) || any(types$attendu != types$observe) || !nrow(base)) return(terminer())
  flags$id_enseignant <- base$id_enseignant
  codes <- dictionnaire$variable; principaux <- ordre$variable[ordre$bloc == "PRATIQUES"]
  id_absent <- is.na(base$id_enseignant) | trimws(base$id_enseignant) == ""
  ajouter("Q003", id_absent)
  ajouter("Q004", !id_absent & !base$id_enseignant %in% echantillon$id_enseignant)
  ajouter("Q005", !id_absent & (duplicated(base$id_enseignant) | duplicated(base$id_enseignant, fromLast = TRUE)))
  ajouter("Q006", duplicated(base) | duplicated(base, fromLast = TRUE))
  manquants <- data.frame(variable = names(base), nombre = colSums(is.na(base)),
    taux = colMeans(is.na(base)), row.names = NULL)
  completion <- rowMeans(!is.na(base[codes]))
  flags$completion_calculee <- unname(completion)
  ajouter("Q007", completion < 1); ajouter("Q008", completion < seuil("Q008"))
  invalides <- matrix(FALSE, nrow(base), length(codes), dimnames = list(NULL, codes))
  valide <- base[codes]
  for (j in seq_along(codes)) {
    z <- base[[codes[j]]]
    invalides[, j] <- !is.na(z) & !z %in% seq.int(dictionnaire$minimum[j], dictionnaire$maximum[j])
    # Copie diagnostique exclusivement : les valeurs invalides ne participent pas aux corrélations.
    valide[[j]][invalides[, j]] <- NA_integer_
  }
  ajouter("Q009", rowSums(invalides) > 0)
  cellules <- which(invalides, arr.ind = TRUE)
  cellules <- data.frame(ligne_source = cellules[, 1], variable = codes[cellules[, 2]])
  ajouter("Q010", is.na(base$age) | base$age < 23 | base$age > 65)
  ajouter("Q011", is.na(base$anciennete) | is.na(base$anciennete_classe) | is.na(base$age) |
    base$anciennete < 0 | base$anciennete > base$age - 22 |
    base$anciennete_classe < 0 | base$anciennete_classe > base$anciennete)
  ajouter("Q012", base$secteur == "Privé sous contrat" & base$education_prioritaire != "Hors EP")
  ajouter("Q013", (base$degre == "Premier degré" & base$discipline != "Polyvalent premier degré") |
    (base$degre == "Collège" & base$discipline == "Polyvalent premier degré"))
  duree_invalide <- !is.finite(base$duree_secondes) | base$duree_secondes <= 0
  ajouter("Q014", duree_invalide)
  mat <- as.matrix(valide[principaux]); nb <- rowSums(!is.na(mat))
  part <- apply(mat, 1, function(z) if (all(is.na(z))) NA_real_ else max(table(z)) / sum(!is.na(z)))
  serie <- apply(mat, 1, function(z) {
    z[is.na(z)] <- -seq_along(z)[is.na(z)]
    r <- rle(z); max(c(0L, r$lengths[r$values > 0]))
  })
  flags$nb_pratiques_valides <- nb; flags$part_modale <- part; flags$longueur_serie <- serie
  ajouter("Q016", ifelse(nb < 24, NA, part >= seuil("Q016")))
  ajouter("Q017", ifelse(nb < seuil("Q017"), NA, serie >= seuil("Q017")))
  ajouter("Q018", base$statut_questionnaire == "Abandon")
  index <- match(base$id_enseignant, echantillon$id_enseignant)
  mauvais <- is.na(index)
  for (nom in c("strate_sondage", "N_h", "n_h", "pi_h", "poids_base")) {
    a <- base[[nom]]; b <- echantillon[[nom]][index]
    ecart <- if (is.numeric(a)) abs(a - b) > 1e-10 else a != b
    mauvais <- mauvais | is.na(a) | is.na(b) | ecart
  }
  ajouter("Q019", mauvais | !is.finite(base$pi_h) | base$pi_h <= 0 | base$pi_h > 1 |
    !is.finite(base$poids_base) | base$poids_base <= 0)
  ajouter("Q020", !is.finite(base$taux_completion) | abs(base$taux_completion - completion) > 1e-10)
  items <- data.frame(variable = principaux,
    n_valides = vapply(valide[principaux], function(z) sum(!is.na(z)), integer(1)),
    variance = vapply(valide[principaux], var, numeric(1), na.rm = TRUE), row.names = NULL)
  ajouter("Q021", items$n_valides < 2 | !is.finite(items$variance) | items$variance == 0, "item")
  dimensions <- unique(dictionnaire$dimension[dictionnaire$bloc == "PRATIQUES"])
  correlations <- do.call(rbind, lapply(dimensions, function(d) {
    m <- tryCatch(suppressWarnings(cor(valide[paste0(d, sprintf("%02d", 1:6))], method = "spearman", use = "pairwise.complete.obs")),
      error = function(e) matrix(NA_real_, 6, 6))
    p <- m[upper.tri(m)]
    data.frame(dimension = d, paires_valides = sum(is.finite(p)),
      moyenne = if (all(is.finite(p))) mean(p) else NA_real_)
  }))
  ajouter("Q022", correlations$moyenne <= 0, "dimension")
  ajouter("Q023", valide$CTRL01 != 3); ajouter("Q024", valide$CTRL03 == 0)
  contextes <- names(population)[vapply(population, is.character, logical(1))]
  contextes <- setdiff(contextes, "id_enseignant")
  modalites_contexte <- sapply(contextes, function(nom) is.na(base[[nom]]) | !base[[nom]] %in% unique(population[[nom]]))
  ajouter("Q026", rowSums(modalites_contexte) > 0)
  ajouter("Q027", is.na(base$effectif_classe) | base$effectif_classe < 12 | base$effectif_classe > 35 |
    is.na(base$formation_continue) | base$formation_continue < 0 | base$formation_continue > 20)
  statut <- base$statut_questionnaire
  ajouter("Q028", is.na(statut) | !statut %in% c("Complet", "Partiel", "Abandon") |
    (statut == "Complet" & completion < 1) | (statut %in% c("Partiel", "Abandon") & completion == 1))
  ajouter("Q029", !setequal(base$id_enseignant, suivi$id_enseignant[suivi$repondant == 1]) |
    anyNA(base$repondant) | any(base$repondant != 1, na.rm = TRUE), "base")
  frequences <- do.call(rbind, lapply(codes, function(nom) {
    z <- as.data.frame(table(base[[nom]], useNA = "always"), stringsAsFactors = FALSE)
    names(z) <- c("modalite", "effectif"); data.frame(variable = nom, z)
  }))
  taux <- do.call(rbind, lapply(c("strate_sondage", "degre", "secteur"), function(nom) {
    do.call(rbind, lapply(sort(unique(echantillon[[nom]])), function(g) {
      ids <- echantillon$id_enseignant[echantillon[[nom]] == g]
      recus <- length(intersect(ids, base$id_enseignant))
      data.frame(ventilation = nom, modalite = g, tires = length(ids), recus_uniques = recus,
        taux_participation = recus / length(ids))
    }))
  }))
  complements <- diagnostiquer_comportements(base, valide, principaux, seuil("Q008"), seuil("Q016"))
  ajouter("Q015", complements$individus$flag_rapide)
  ajouter("Q030", complements$individus$flag_tres_rapide)
  for (nom in setdiff(names(complements$individus), "ligne_source")) flags[[nom]] <- complements$individus[[nom]]
  flags$nb_signaux <- rowSums(flags[intersect(plan$id_controle, names(flags))], na.rm = TRUE)
  flags$nb_non_evaluables <- rowSums(is.na(flags[intersect(plan$id_controle, names(flags))]))
  terminer(list(manquants = manquants, cellules_invalides = cellules, items = items,
    correlations = correlations, frequences = frequences, taux_reponse = taux,
    completion = complements$completion, durees = complements$durees,
    distribution_straightlining = complements$distribution, sensibilite = complements$sensibilite))
}

# Seuils exploratoires : charge de réponse et distribution, sans décision d'exclusion.
diagnostiquer_comportements <- function(base, valide, principaux, seuil_completion = .8, seuil_constance = .9) {
  n <- nrow(base); attendus <- ncol(valide)
  repondus <- rowSums(!is.na(base[names(valide)]))
  taux <- repondus / attendus
  m <- as.matrix(valide[principaux]); nb <- rowSums(!is.na(m))
  modes <- apply(m, 1, function(z) length(unique(z[!is.na(z)])))
  part <- apply(m, 1, function(z) if (all(is.na(z))) NA_real_ else max(table(z)) / sum(!is.na(z)))
  variance <- apply(m, 1, function(z) if (sum(!is.na(z)) < 2) NA_real_ else var(z, na.rm = TRUE))
  longueur <- apply(m, 1, function(z) {
    z[is.na(z)] <- -seq_along(z)[is.na(z)]
    r <- rle(z); max(c(0L, r$lengths[r$values > 0]))
  })
  statut <- ifelse(taux == 1, "COMPLET", ifelse(taux >= seuil_completion, "PARTIEL_ACCEPTABLE", "PARTIEL_FAIBLE"))
  # Le statut terrain est prioritaire ; ne pas inventer un abandon à partir de NA seuls.
  statut[!is.na(base$statut_questionnaire) & base$statut_questionnaire == "Abandon"] <- "ABANDON"
  statut[is.na(base$statut_questionnaire)] <- NA_character_
  duree <- base$duree_secondes
  valide_duree <- is.finite(duree) & duree > 0
  reference <- valide_duree & taux >= seuil_completion & !is.na(base$statut_questionnaire) & base$statut_questionnaire != "Abandon"
  mediane_reference <- if (sum(reference) >= 30) median(duree[reference]) else NA_real_
  # Trois secondes par réponse ET moins du tiers de la médiane de référence.
  seuil_rapide <- pmin(3 * repondus, mediane_reference / 3)
  # Moins d'une seconde par réponse, plafonné à une minute et au seuil rapide.
  seuil_tres <- pmin(repondus, 60, seuil_rapide)
  evaluable <- valide_duree & repondus > 0 & is.finite(mediane_reference)
  individus <- data.frame(ligne_source = seq_len(n), nb_modalites_utilisees = modes,
    proportion_modalite_dominante = part, variance_intra_repondant = variance,
    longueur_max_sequence = longueur, flag_straightlining = ifelse(nb >= 24, part >= seuil_constance, NA),
    seuil_rapide_secondes = seuil_rapide, seuil_tres_rapide_secondes = seuil_tres,
    flag_rapide = ifelse(evaluable, duree < seuil_rapide, NA),
    flag_tres_rapide = ifelse(evaluable, duree < seuil_tres, NA),
    nb_items_attendus = attendus, nb_items_repondus = repondus,
    nb_items_manquants = attendus - repondus, taux_completion = taux, statut_completion = statut,
    row.names = NULL)
  niveaux <- c("COMPLET", "PARTIEL_ACCEPTABLE", "PARTIEL_FAIBLE", "ABANDON")
  completion <- data.frame(statut_completion = c(niveaux, "NON_EVALUABLE"),
    effectif = c(as.integer(table(factor(statut, levels = niveaux))), sum(is.na(statut))))
  completion$proportion <- completion$effectif / n
  probs <- c(0,.01,.05,.10,.25,.5,.75,.90,.95,.99,1)
  quantiles <- if (any(valide_duree)) quantile(duree[valide_duree], probs, names = FALSE) else rep(NA_real_, length(probs))
  durees <- data.frame(indicateur = c("minimum","q01","q05","q10","Q1","mediane","Q3","q90","q95","q99","maximum","moyenne","mediane_reference","effectif_reference"),
    valeur = c(quantiles, if (any(valide_duree)) mean(duree[valide_duree]) else NA_real_, mediane_reference, sum(reference)))
  distribution <- do.call(rbind, lapply(c("nb_modalites_utilisees", "proportion_modalite_dominante", "variance_intra_repondant", "longueur_max_sequence"), function(nom) {
    z <- individus[[nom]]; z <- z[is.finite(z)]
    data.frame(indicateur = nom, quantile = c(0,.25,.5,.75,.95,.99,1),
      valeur = if (length(z)) quantile(z,c(0,.25,.5,.75,.95,.99,1),names=FALSE) else rep(NA_real_,7))
  }))
  sensibilite <- data.frame(indicateur = c(rep("part_modale_au_moins_24",3),rep("duree_fixe_secondes",4)),
    seuil = c(.8,.9,.95,60,120,180,300),
    effectif = c(vapply(c(.8,.9,.95), function(s) sum(nb >= 24 & part >= s, na.rm=TRUE), integer(1)),
      vapply(c(60,120,180,300),function(s) sum(valide_duree & duree<s),integer(1))))
  list(individus=individus, completion=completion, durees=durees, distribution=distribution, sensibilite=sensibilite)
}
