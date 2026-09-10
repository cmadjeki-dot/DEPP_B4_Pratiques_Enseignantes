# Non-réponse totale : modèle logistique conditionnel aux variables de la base.
simuler_non_reponse <- function(echantillon, parametres) {
  colonnes <- c("id_enseignant", "degre", "secteur", "education_prioritaire",
                "formation_continue", "equipement_numerique", "anciennete", "effectif_classe")
  stopifnot(is.data.frame(echantillon), nrow(echantillon) > 0L,
            all(colonnes %in% names(echantillon)), !anyNA(echantillon[colonnes]),
            !anyDuplicated(echantillon$id_enseignant),
            length(parametres$taux_reponse_attendu) == 1L,
            is.finite(parametres$taux_reponse_attendu),
            parametres$taux_reponse_attendu > 0 & parametres$taux_reponse_attendu < 1,
            length(parametres$graine) == 1L, is.finite(parametres$graine),
            parametres$graine >= 0, parametres$graine <= .Machine$integer.max,
            parametres$graine == floor(parametres$graine),
            all(echantillon$degre %in% c("Premier degré", "Collège")),
            all(echantillon$secteur %in% c("Public", "Privé sous contrat")),
            all(echantillon$education_prioritaire %in% c("Hors EP", "REP", "REP+")),
            all(echantillon$equipement_numerique %in% c("Faible", "Moyen", "Bon")))
  x <- with(echantillon, cbind(
    college = as.numeric(degre == "Collège"), prive = as.numeric(secteur == "Privé sous contrat"),
    rep = as.numeric(education_prioritaire == "REP"), repplus = as.numeric(education_prioritaire == "REP+"),
    formation_par_5_jours = formation_continue / 5,
    equipement_bon = as.numeric(equipement_numerique == "Bon"),
    anciennete_par_10_ans = anciennete / 10, effectif_par_5_eleves = effectif_classe / 5))
  beta <- unlist(parametres$coefficients)
  stopifnot(is.numeric(beta), !anyDuplicated(names(beta)),
            setequal(names(beta), colnames(x)), all(is.finite(beta)), all(is.finite(x)))
  score <- as.vector(x %*% beta[colnames(x)])
  # Régler seulement l'espérance du taux non pondéré ; ne jamais forcer le nombre réalisé.
  intercept <- uniroot(function(a) mean(plogis(a + score)) - parametres$taux_reponse_attendu,
    interval = c(-40 - max(score), 40 - min(score)), tol = 1e-12)$root
  probabilite <- plogis(intercept + score)
  stopifnot(all(is.finite(probabilite)), all(probabilite > 0 & probabilite < 1),
            abs(mean(probabilite) - parametres$taux_reponse_attendu) < 1e-9)
  set.seed(parametres$graine, kind = "Mersenne-Twister", normal.kind = "Inversion", sample.kind = "Rejection")
  resultat <- echantillon
  resultat$prob_reponse_theorique <- probabilite
  resultat$repondant <- as.integer(rbinom(nrow(echantillon), size = 1, prob = probabilite))
  attr(resultat, "non_reponse") <- list(parametres = parametres, intercept = intercept,
    mecanisme = "Bernoulli indépendant conditionnel aux caractéristiques observées")
  stopifnot(nrow(resultat) == nrow(echantillon), !anyNA(resultat),
            all(resultat$repondant %in% 0:1))
  for (nom in names(echantillon)) stopifnot(identical(resultat[[nom]], echantillon[[nom]]))
  resultat
}
