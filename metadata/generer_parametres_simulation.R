# Export documentaire déterministe ; la configuration YAML reste la source.
if (!file.exists("config/config.yml")) stop("Exécuter depuis la racine du projet.")
if (!requireNamespace("yaml", quietly = TRUE)) stop("Restaurer les dépendances renv.")
config <- yaml::read_yaml("config/config.yml")
aplatir <- function(x, chemin = "") {
  if (is.list(x)) {
    noms <- names(x)
    if (is.null(noms)) noms <- as.character(seq_along(x))
    return(do.call(rbind, lapply(seq_along(x), function(i)
      aplatir(x[[i]], paste(c(chemin[nzchar(chemin)], noms[i]), collapse = ".")))))
  }
  data.frame(parametre = chemin, position = seq_along(x), valeur = as.character(x),
    type = typeof(x), source = "config/config.yml", stringsAsFactors = FALSE)
}
tableau <- aplatir(config)
tableau$avertissement <- config$projet$avertissement
stopifnot(nrow(tableau) > 0, !anyNA(tableau), !anyDuplicated(tableau[c("parametre", "position")]))
chemin <- "metadata/parametres_simulation.csv"
write.csv(tableau, chemin, row.names = FALSE, fileEncoding = "UTF-8")
stopifnot(isTRUE(all.equal(tableau, read.csv(chemin, fileEncoding = "UTF-8",
  colClasses = c("character", "integer", "character", "character", "character", "character")), check.attributes = FALSE)))
cat(nrow(tableau), "valeurs de configuration exportées et relues :", chemin, "\n")
