# Lancer depuis la racine : Rscript.exe tests/run_tests.R
if (!dir.exists("tests/testthat")) stop("Exécuter depuis la racine du projet.")
if (!requireNamespace("testthat", quietly = TRUE)) stop("Restaurer les dépendances renv.")
# Collecter tous les résultats pour afficher le bilan avant un éventuel arrêt.
resultats <- testthat::test_dir("tests/testthat", reporter = "summary", stop_on_failure = FALSE)
bilan <- as.data.frame(resultats)
stopifnot(nrow(bilan) > 0L)
echecs <- bilan$failed > 0 | bilan$error
reussis <- !echecs & !bilan$skipped & bilan$passed > 0
cat("\nBILAN DES BLOCS test_that\n")
cat("Tests réussis :", sum(reussis), "\n")
cat("Tests échoués (erreurs comprises) :", sum(echecs), "\n")
cat("Tests ignorés :", sum(bilan$skipped), "\n")
cat("Vérifications réussies :", sum(bilan$passed), "\n")
cat("Vérifications échouées :", sum(bilan$failed), "\n")
selection_sampling <- bilan$file == "test_sampling.R"
cat("Dont test_sampling.R :", sum(reussis & selection_sampling), "tests réussis ;",
    sum(echecs & selection_sampling), "tests échoués.\n")
if (any(echecs)) stop("Tests échoués : corriger avant le prochain commit.")
if (any(bilan$skipped) || any(!reussis)) stop("Suite incomplète : examiner les tests non exécutés.")
message("Tous les tests ont réussi.")
