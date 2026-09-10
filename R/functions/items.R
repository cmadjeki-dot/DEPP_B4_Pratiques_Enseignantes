# Fonctions de génération des traits contextualisés et des items ordinaux.
contextualiser_traits <- function(traits, repondants, reference, effets) {
  noms_latents <- grep("^latent_", names(traits), value = TRUE)
  stopifnot(length(noms_latents) == 8L, !anyDuplicated(traits$id_enseignant),
            !anyDuplicated(reference$id_enseignant),
            identical(traits$id_enseignant, repondants$id_enseignant),
            all(traits$id_enseignant %in% reference$id_enseignant))
  # Référence fixée sur l'échantillon initial, avant la sélection des répondants.
  # log1p traduit une association croissante avec rendements décroissants.
  x <- data.frame(formation = log1p(reference$formation_continue),
    equipement = match(reference$equipement_numerique, c("Faible", "Moyen", "Bon")) - 1,
    experience = log1p(reference$anciennete))
  stopifnot(!anyNA(x), all(is.finite(as.matrix(x))), all(vapply(x, sd, numeric(1)) > 0),
            setequal(names(effets), names(x)))
  centre <- colMeans(x)
  echelle <- vapply(x, sd, numeric(1))
  x_standard <- sweep(sweep(as.matrix(x), 2, centre, "-"), 2, echelle, "/")
  beta <- matrix(0, ncol(x), 8, dimnames = list(names(x), sub("latent_", "", noms_latents)))
  for (nom in names(effets)) {
    valeurs <- unlist(effets[[nom]])
    stopifnot(all(names(valeurs) %in% colnames(beta)), all(is.finite(valeurs)),
              all(abs(valeurs) <= 0.40))
    beta[nom, names(valeurs)] <- valeurs
  }
  delta <- x_standard[match(traits$id_enseignant, reference$id_enseignant), , drop = FALSE] %*% beta
  resultat <- traits
  resultat[noms_latents] <- as.data.frame(as.matrix(traits[noms_latents]) + delta)
  names(resultat) <- names(traits)
  attr(resultat, "effets_contextuels") <- list(coefficients = beta, centre = centre, echelle = echelle,
    reference = "Échantillon initial avant non-réponse", transformations = c("log1p(formation)", "équipement 0/1/2", "log1p(ancienneté)"))
  stopifnot(!anyNA(resultat), all(is.finite(as.matrix(resultat[noms_latents]))))
  diagnostic <- data.frame(dimension = colnames(beta),
    moyenne_avant = colMeans(traits[noms_latents]), moyenne_apres = colMeans(resultat[noms_latents]),
    sd_avant = vapply(traits[noms_latents], sd, numeric(1)),
    sd_apres = vapply(resultat[noms_latents], sd, numeric(1)),
    sd_effet = apply(delta, 2, sd), row.names = NULL)
  list(traits = resultat, diagnostic = diagnostic)
}

parametrer_items <- function(dictionnaire, parametres) {
  items <- dictionnaire[dictionnaire$bloc == "PRATIQUES", ]
  stopifnot(nrow(items) == 48L, !anyDuplicated(items$variable),
            all(table(items$dimension) == 6L), !any(items$item_inverse),
            all(items$minimum == 1 & items$maximum == 5),
            length(parametres$seuils_base) == 4L, all(diff(parametres$seuils_base) > 0),
            all(parametres$loading >= 0.50 & parametres$loading <= 0.80),
            length(parametres$loading) == 2L, diff(parametres$loading) > 0,
            all(parametres$multiplicateur_erreur > 0),
            parametres$amplitude_jitter_seuils >= 0)
  set.seed(parametres$graine_parametres, kind = "Mersenne-Twister", normal.kind = "Inversion", sample.kind = "Rejection")
  loading <- runif(48, parametres$loading[1], parametres$loading[2])
  facteur <- runif(48, parametres$multiplicateur_erreur[1], parametres$multiplicateur_erreur[2])
  difficulte <- runif(48, parametres$difficulte[1], parametres$difficulte[2])
  decalages <- unlist(parametres$decalage_dimension)[items$dimension]
  seuils <- matrix(rep(parametres$seuils_base, each = 48), nrow = 48) +
    difficulte + decalages + matrix(runif(48 * 4, -parametres$amplitude_jitter_seuils,
                                         parametres$amplitude_jitter_seuils), nrow = 48)
  colnames(seuils) <- paste0("seuil_", 1:4)
  resultat <- data.frame(variable = items$variable, dimension = items$dimension,
    loading = loading, sd_erreur = sqrt(1 - loading^2) * facteur,
    variance_erreur = (1 - loading^2) * facteur^2,
    difficulte = difficulte, decalage_dimension = unname(decalages), seuils, row.names = NULL)
  stopifnot(!anyNA(resultat), all(apply(seuils, 1, function(x) all(diff(x) > 0))),
            !anyDuplicated(as.data.frame(seuils)))
  resultat
}

simuler_items_ordinaux <- function(traits, parametres_items, graine) {
  stopifnot(nrow(parametres_items) == 48L, !anyNA(traits), !anyNA(parametres_items),
            !anyDuplicated(traits$id_enseignant), !anyDuplicated(parametres_items$variable),
            all(paste0("latent_", parametres_items$dimension) %in% names(traits)),
            all(parametres_items$sd_erreur > 0),
            all(parametres_items$loading >= 0.50 & parametres_items$loading <= 0.80))
  set.seed(graine, kind = "Mersenne-Twister", normal.kind = "Inversion", sample.kind = "Rejection")
  reponses <- data.frame(id_enseignant = traits$id_enseignant)
  for (j in seq_len(nrow(parametres_items))) {
    p <- parametres_items[j, ]
    seuils <- unlist(p[paste0("seuil_", 1:4)], use.names = FALSE)
    stopifnot(all(is.finite(seuils)), all(diff(seuils) > 0))
    erreur <- rnorm(nrow(traits), mean = 0, sd = p$sd_erreur)
    # Soustraire une erreur normale centrée équivaut en loi à l'ajouter.
    continu <- p$loading * traits[[paste0("latent_", p$dimension)]] - erreur
    # Catégorie k si seuil_(k-1) < continu <= seuil_k ; bornes infinies aux extrêmes.
    reponses[[p$variable]] <- as.integer(cut(continu, breaks = c(-Inf, seuils, Inf), labels = FALSE, right = TRUE))
  }
  stopifnot(nrow(reponses) == nrow(traits), ncol(reponses) == 49L,
            !anyNA(reponses), all(vapply(reponses[-1], is.integer, logical(1))),
            all(as.matrix(reponses[-1]) %in% 1:5))
  reponses
}

sauver_simulation_validee <- function(objet, chemin) {
  stopifnot(length(chemin) == 1L, grepl("^data/simulated/[[:alnum:]_-]+[.]rds$", chemin))
  if (file.exists(chemin)) {
    if (!identical(readRDS(chemin), objet)) stop("Une sortie différente existe : choisir un nouveau nom pour ", chemin)
  } else saveRDS(objet, chemin, compress = "gzip", version = 3)
  stopifnot(identical(readRDS(chemin), objet))
}
