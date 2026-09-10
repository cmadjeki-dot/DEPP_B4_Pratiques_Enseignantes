# Faisabilité, préférences professionnelles et écarts uniquement exploratoires.
simuler_faisabilite_priorite <- function(reponses, traits, reference, dimensions, p) {
  stopifnot(length(dimensions) == 8L, !anyDuplicated(dimensions),
    identical(reponses$id_enseignant, traits$id_enseignant),
    !anyDuplicated(reponses$id_enseignant), !anyDuplicated(reference$id_enseignant),
    all(reponses$id_enseignant %in% reference$id_enseignant),
    length(p$seuils) == 4L, all(diff(p$seuils) > 0),
    abs(p$lien_preference_pratique) < 1, p$loading_priorite > 0,
    p$loading_priorite < 1, p$sd_faisabilite_commun >= 0, p$sd_faisabilite_item > 0)
  for (nom in c("decalages", "effet_equipement", "effet_effectif", "effet_formation")) {
    stopifnot(length(p[[nom]]) == length(dimensions), all(is.finite(p[[nom]])))
  }
  # Standardisation sur l'échantillon initial : référence indépendante de la réponse.
  contexte <- data.frame(equipement = match(reference$equipement_numerique,
    c("Faible", "Moyen", "Bon")) - 1, effectif = reference$effectif_classe,
    formation = log1p(reference$formation_continue))
  stopifnot(!anyNA(contexte), all(vapply(contexte, sd, numeric(1)) > 0))
  contexte <- scale(contexte)
  x <- contexte[match(reponses$id_enseignant, reference$id_enseignant), , drop = FALSE]
  n <- nrow(reponses)
  resultat <- reponses
  set.seed(p$graine, kind = "Mersenne-Twister", normal.kind = "Inversion", sample.kind = "Rejection")
  # Contrainte individuelle commune et erreurs propres à chaque dimension.
  bruit_commun <- rnorm(n, sd = p$sd_faisabilite_commun)
  for (j in seq_along(dimensions)) {
    d <- dimensions[j]
    pratique <- traits[[paste0("latent_", d)]]
    stopifnot(length(pratique) == n, all(is.finite(pratique)))
    fais <- x[, "equipement"] * p$effet_equipement[j] +
      x[, "effectif"] * p$effet_effectif[j] + x[, "formation"] * p$effet_formation[j] +
      bruit_commun + rnorm(n, sd = p$sd_faisabilite_item)
    # Préférence spécifique : composante liée aux pratiques et composante autonome majoritaire.
    preference <- p$lien_preference_pratique * pratique +
      sqrt(1 - p$lien_preference_pratique^2) * rnorm(n)
    priorite <- p$loading_priorite * preference + sqrt(1 - p$loading_priorite^2) * rnorm(n)
    seuils <- c(-Inf, p$seuils + p$decalages[j], Inf)
    resultat[[paste0("FAIS_", d)]] <- as.integer(cut(fais, seuils, labels = FALSE))
    resultat[[paste0("PRIO_", d)]] <- as.integer(cut(priorite, seuils, labels = FALSE))
    items <- paste0(d, sprintf("%02d", 1:6))
    stopifnot(all(items %in% names(reponses)), !anyNA(reponses[items]),
      all(as.matrix(reponses[items]) %in% 1:5))
    # Six réponses exigées ; aucune imputation et aucun score définitif.
    resultat[[paste0("SCORE_PROV_", d)]] <- rowMeans(reponses[items])
    resultat[[paste0("GAP_", d)]] <- resultat[[paste0("PRIO_", d)]] - resultat[[paste0("SCORE_PROV_", d)]]
  }
  codes <- c(paste0("FAIS_", dimensions), paste0("PRIO_", dimensions))
  stopifnot(nrow(resultat) == n, ncol(resultat) == ncol(reponses) + 32L,
    !anyNA(resultat), all(as.matrix(resultat[codes]) %in% 1:5),
    all(vapply(resultat[codes], is.integer, logical(1))),
    all(abs(as.matrix(resultat[paste0("GAP_", dimensions)])) <= 4))
  for (nom in names(reponses)) stopifnot(identical(resultat[[nom]], reponses[[nom]]))
  attr(resultat, "simulation_faisabilite_priorite") <- list(parametres = p, dimensions = dimensions,
    centre = attr(contexte, "scaled:center"), echelle = attr(contexte, "scaled:scale"),
    statut_scores = "Moyennes provisoires des six items complets ; écarts exploratoires non validés")
  resultat
}
