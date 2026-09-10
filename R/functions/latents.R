# Matrice théorique et simulation normale multivariée, sans items ordinaux.
verifier_correlation_latente <- function(matrice) {
  stopifnot(is.matrix(matrice), is.numeric(matrice), nrow(matrice) == ncol(matrice),
            !anyNA(matrice), all(is.finite(matrice)),
            identical(rownames(matrice), colnames(matrice)),
            !is.null(colnames(matrice)), !anyDuplicated(colnames(matrice)),
            max(abs(matrice - t(matrice))) < 1e-12,
            all(abs(diag(matrice) - 1) < 1e-12),
            all(abs(matrice[row(matrice) != col(matrice)]) <= 0.70))
  valeurs_propres <- eigen(matrice, symmetric = TRUE, only.values = TRUE)$values
  if (min(valeurs_propres) <= 1e-10) stop("La matrice théorique n'est pas définie positive.")
  # Aucune réparation automatique : modifier les hypothèses si la matrice est invalide.
  stopifnot(max(abs(crossprod(chol(matrice)) - matrice)) < 1e-12)
  valeurs_propres
}

construire_correlation_latente <- function(parametres) {
  dimensions <- parametres$dimensions
  stopifnot(identical(dimensions, c("EXP", "DIF", "EVA", "GCL", "COL", "NUM", "DEV", "REL")),
            length(parametres$correlation_commune) == 1L)
  matrice <- matrix(parametres$correlation_commune, length(dimensions), length(dimensions),
                    dimnames = list(dimensions, dimensions))
  diag(matrice) <- 1
  for (paire in names(parametres$correlations_specifiques)) {
    codes <- strsplit(paire, "_", fixed = TRUE)[[1]]
    valeur <- parametres$correlations_specifiques[[paire]]
    stopifnot(length(codes) == 2L, all(codes %in% dimensions), codes[1] != codes[2],
              is.numeric(valeur), length(valeur) == 1L, is.finite(valeur))
    matrice[codes[1], codes[2]] <- valeur
    matrice[codes[2], codes[1]] <- valeur
  }
  verifier_correlation_latente(matrice)
  matrice
}

simuler_traits_latents <- function(identifiants, matrice, graine) {
  verifier_correlation_latente(matrice)
  stopifnot(is.character(identifiants), length(identifiants) > 3L,
            !anyNA(identifiants), all(nzchar(identifiants)), !anyDuplicated(identifiants),
            length(graine) == 1L, is.finite(graine), graine >= 0,
            graine == floor(graine), graine <= .Machine$integer.max)
  set.seed(graine, kind = "Mersenne-Twister", normal.kind = "Inversion", sample.kind = "Rejection")
  z <- matrix(rnorm(length(identifiants) * ncol(matrice)), nrow = length(identifiants))
  # R = U' U ; chaque ligne de Z U suit N_8(0, R).
  valeurs <- z %*% chol(matrice)
  colnames(valeurs) <- paste0("latent_", colnames(matrice))
  resultat <- data.frame(id_enseignant = identifiants, valeurs, row.names = NULL)
  stopifnot(nrow(resultat) == length(identifiants), ncol(resultat) == 9L,
            !anyNA(resultat), all(is.finite(valeurs)),
            !anyDuplicated(resultat$id_enseignant))
  # Ne pas recentrer/réduire l'échantillon ni forcer ses corrélations empiriques.
  resultat
}
