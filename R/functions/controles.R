# Contrôles auxiliaires : aucun ajout aux scores de pratiques.
simuler_controles <- function(reponses, p) {
  stopifnot(nrow(reponses) > 0, !anyDuplicated(reponses$id_enseignant),
    !anyNA(reponses$id_enseignant), !any(grepl("^CTRL", names(reponses))),
    length(p$seuils) == 4L, all(is.finite(p$seuils)), all(diff(p$seuils) > 0),
    p$loading_difficulte > 0, p$loading_difficulte < 1,
    p$probabilite_lecture > 0, p$probabilite_lecture < 1,
    p$probabilite_champ > 0, p$probabilite_champ < 1)
  set.seed(p$graine, kind = "Mersenne-Twister", normal.kind = "Inversion", sample.kind = "Rejection")
  n <- nrow(reponses)
  resultat <- reponses
  # Erreur explicite de lecture ; aucun statut de mauvaise qualité n'est attribué.
  lecture <- rbinom(n, 1, p$probabilite_lecture)
  resultat$CTRL01 <- ifelse(lecture == 1L, 3L, c(1L, 2L, 4L, 5L)[sample.int(4L, n, replace = TRUE)])
  # Difficulté commune aux deux autoévaluations, indépendante des pratiques.
  difficulte <- rnorm(n)
  continu02 <- p$loading_difficulte * difficulte + sqrt(1 - p$loading_difficulte^2) * rnorm(n)
  continu04 <- p$loading_difficulte * difficulte + sqrt(1 - p$loading_difficulte^2) * rnorm(n)
  resultat$CTRL02 <- as.integer(cut(continu02, c(-Inf, p$seuils, Inf), labels = FALSE))
  resultat$CTRL03 <- rbinom(n, 1, p$probabilite_champ)
  resultat$CTRL04 <- as.integer(cut(continu04, c(-Inf, p$seuils + p$decalage_ctrl04, Inf), labels = FALSE))
  resultat$CTRL02_reverse <- 6L - resultat$CTRL02
  resultat$CTRL04_reverse <- 6L - resultat$CTRL04
  ordinaux <- c("CTRL01", "CTRL02", "CTRL04", "CTRL02_reverse", "CTRL04_reverse")
  stopifnot(ncol(resultat) == ncol(reponses) + 6L, !anyNA(resultat[ordinaux]),
    all(as.matrix(resultat[ordinaux]) %in% 1:5), all(resultat$CTRL03 %in% 0:1))
  for (nom in names(reponses)) stopifnot(identical(resultat[[nom]], reponses[[nom]]))
  attr(resultat, "simulation_controles") <- p
  resultat
}
