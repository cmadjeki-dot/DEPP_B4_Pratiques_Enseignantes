# Préparer les dépendances depuis la racine du projet, après activation de renv.
# Exemple ciblé : options(depp.packages = c("survey", "srvyr"))
# Sans sélection, vérifier et charger les quinze packages prévus.
packages_prevus <- c(
  "tidyverse", "janitor", "skimr", "psych", "GPArotation",
  "survey", "srvyr", "FactoMineR", "factoextra", "cluster",
  "broom", "modelsummary", "gtsummary", "gt", "testthat"
)

preparer_packages <- function(packages = packages_prevus) {
  # Refuser les noms inconnus et une exécution hors de l'environnement du projet.
  stopifnot(is.character(packages), length(packages) > 0L,
            !anyNA(packages), !anyDuplicated(packages),
            all(packages %in% packages_prevus))
  if (!file.exists("renv/activate.R") || !requireNamespace("renv", quietly = TRUE)) {
    stop("Activer renv depuis la racine du projet avant de lancer ce script.")
  }
  bibliotheque <- renv::paths$library(project = getwd())
  if (normalizePath(.libPaths()[1], winslash = "/", mustWork = TRUE) !=
      normalizePath(bibliotheque, winslash = "/", mustWork = TRUE)) {
    stop("La bibliothèque renv du projet n'est pas la bibliothèque active.")
  }

  # Installer uniquement les absents ; ne pas mettre à jour les présents.
  presents <- rownames(utils::installed.packages())
  manquants <- setdiff(packages, presents)
  if (length(manquants)) {
    message("Packages absents à installer : ", paste(manquants, collapse = ", "))
    renv::install(manquants, prompt = FALSE)
  } else {
    message("Tous les packages sélectionnés sont présents : aucune installation.")
  }

  # Un package présent mais non chargeable constitue une erreur à diagnostiquer.
  for (package in packages) {
    tryCatch(
      library(package, character.only = TRUE),
      error = function(e) stop("Échec du chargement de ", package, " : ",
                               conditionMessage(e), call. = FALSE)
    )
  }
  stopifnot(all(paste0("package:", packages) %in% search()))
  versions <- data.frame(
    package = packages,
    version = vapply(packages, function(x) as.character(utils::packageVersion(x)),
                     character(1)),
    row.names = NULL
  )
  print(versions, row.names = FALSE)
  message("Environnement prêt : ", length(packages),
          " packages chargés ; ", length(manquants), " packages directs installés.")
  invisible(versions)
}

versions_packages <- preparer_packages(getOption("depp.packages", packages_prevus))
