# Exécuter depuis la racine, dans une session R neuve avec renv activé.
# Chaque script s'exécute dans son propre processus pour isoler son état.
if (!file.exists("renv.lock")) stop("Exécuter depuis la racine du dépôt.")
dir.create("outputs", showWarnings = FALSE)
journal <- "outputs/pipeline_execution_log.txt"
writeLines(paste("Début", Sys.time()), journal)
scripts <- c("01_population", "01_audit_population", "02_sampling", "02_audit_poids",
             "03_nonresponse", "04_questionnaire_simulation", "04_donnees_imparfaites",
             "04_questionnaire_brut", "05_quality", "06_cleaning", "07_weighting",
             "08_descriptive", "09_psychometrics", "10_factor_analysis",
             "11_clustering", "12_models", "13_outputs")
rscript <- file.path(R.home("bin"), if (.Platform$OS.type == "windows") "Rscript.exe" else "Rscript")
debut <- Sys.time()
for (nom in scripts) {
  fichier <- paste0("R/", nom, ".R")
  if (!file.exists(fichier)) stop("Script absent : ", fichier)
  message("Étape : ", fichier)
  t0 <- Sys.time()
  sortie <- paste0("outputs/", nom, "_execution.log")
  statut <- system2(rscript, shQuote(fichier), stdout = sortie, stderr = sortie)
  secondes <- round(as.numeric(difftime(Sys.time(), t0, units = "secs")), 1)
  cat(fichier, if (statut == 0L) "OK" else "ECHEC", secondes, "secondes\n",
      file = journal, append = TRUE)
  if (statut != 0L) {
    cat(readLines(sortie, warn = FALSE), sep = "\n")
    stop("Échec critique : ", fichier, ". Consulter ", sortie)
  }
}
cat("TOTAL OK", round(as.numeric(difftime(Sys.time(), debut, units = "secs")), 1),
    "secondes\n", file = journal, append = TRUE)
message("Pipeline terminé. Journal : ", journal)
