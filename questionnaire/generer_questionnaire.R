# Mise en forme uniquement, à partir du dictionnaire ; aucune réponse simulée.
# R de base suffit : Rscript.exe --vanilla questionnaire/generer_questionnaire.R
# Exécuter depuis la racine du projet.
chemin_dictionnaire <- "metadata/dictionnaire_variables.csv"
if (!file.exists(chemin_dictionnaire)) stop("Exécuter depuis la racine du projet.")
dictionnaire <- read.csv(chemin_dictionnaire, fileEncoding = "UTF-8",
                         stringsAsFactors = FALSE)
dimensions <- c("EXP", "DIF", "EVA", "GCL", "COL", "NUM", "DEV", "REL")
titres <- c("Enseignement explicite", "Différenciation pédagogique",
             "Évaluation formative et feedback", "Gestion de classe",
             "Collaboration professionnelle", "Usage pédagogique du numérique",
             "Développement professionnel", "Relations éducatives")
codes_attendus <- c(unlist(lapply(dimensions, function(d) paste0(d, sprintf("%02d", 1:6)))),
                    paste0("FAIS_", dimensions), paste0("PRIO_", dimensions), sprintf("CTRL%02d", 1:4))
stopifnot(nrow(dictionnaire) == 68L, !anyNA(dictionnaire),
          !anyDuplicated(dictionnaire$variable),
          setequal(dictionnaire$variable, codes_attendus))
avertissement <- paste(
  "Données simulées à des fins de démonstration méthodologique. Les résultats présentés",
  "ne constituent pas des résultats officiels de la DEPP et ne décrivent pas la population réelle des enseignants."
)

# Les libellés et les réponses sont repris sans réécriture ni recodage.
ordre <- character()
formater_question <- function(code) {
  ligne <- dictionnaire[match(code, dictionnaire$variable), ]
  stopifnot(nrow(ligne) == 1L, !anyNA(ligne))
  choix <- strsplit(ligne$modalites, " | ", fixed = TRUE)[[1]]
  choix <- sub("=", " — ", choix, fixed = TRUE)
  ordre <<- c(ordre, code)
  c(paste0("**", code, ".** ", ligne$libelle), "",
    paste(paste0("☐ ", choix), collapse = " · "), "")
}
texte <- c(
  "# Questionnaire sur les pratiques enseignantes", "",
  "**Version de travail pour démonstration méthodologique — instrument à prétester.**", "",
  paste0("> ", avertissement), "",
  "Ce document présente un questionnaire vierge. Il ne correspond pas à une collecte en cours.", "",
  "## Avant de répondre", "",
  "Ce questionnaire porte sur vos pratiques habituelles d'enseignement, vos conditions",
  "d'exercice et vos priorités de développement professionnel. Il ne vise pas à évaluer",
  "votre performance individuelle. Pour les questions de pratiques, répondez selon",
  "ce que vous faites, plutôt que selon ce que vous souhaiteriez faire.", "",
  "- Référez-vous aux **trois derniers mois effectivement enseignés** pour les questions de pratiques.",
  "- Pensez au **niveau de classe que vous enseignez principalement**. Si vous intervenez",
  "  dans plusieurs niveaux, retenez celui auquel vous consacrez le plus de temps ;",
  "  en cas d'égalité, choisissez-en un et conservez-le comme référence.",
  "- Cochez **une seule réponse par question**. Toutes les questions sont facultatives :",
  "  vous pouvez laisser une question sans réponse si vous ne pouvez pas ou ne souhaitez pas répondre.",
  "- Une absence de réponse est différente de « Jamais » ou de « Non ».",
  "- Une vérification de lecture et une question sur votre manière de répondre sont intercalées dans le document.", "",
  "Le questionnaire comprend 68 questions. La durée de passation sera évaluée lors du prétest.", "",
  "## A. Vos pratiques habituelles", "",
  "Pour chaque affirmation, indiquez à quelle fréquence vous mettez en œuvre la pratique",
  "décrite pendant la période de référence. Les mêmes cinq réponses sont proposées",
  "dans cette partie : Jamais, Rarement, Parfois, Souvent et Très souvent.", ""
)
for (i in seq_along(dimensions)) {
  texte <- c(texte, paste0("### A.", i, ". ", titres[i]), "")
  for (j in 1:6) texte <- c(texte, formater_question(paste0(dimensions[i], sprintf("%02d", j))))
  # Espacer le contrôle de lecture et l'autoévaluation de dix-huit questions.
  if (i == 3L) texte <- c(texte, "### Vérification de lecture", "", formater_question("CTRL01"))
  if (i == 6L) texte <- c(texte, "### Votre manière de répondre", "", formater_question("CTRL02"))
}
texte <- c(texte, "## B. Faisabilité dans vos conditions actuelles", "",
  "Pour chaque dimension présentée dans la partie A, indiquez dans quelle mesure",
  "vous pouvez mettre en œuvre ces pratiques **dans vos conditions actuelles d'exercice**.",
  "Il s'agit ici de leur faisabilité, et non de leur fréquence. Choisissez une réponse par question.", "")
for (d in dimensions) texte <- c(texte, formater_question(paste0("FAIS_", d)))
texte <- c(texte, "## C. Vos priorités de développement", "",
  "Pour chaque dimension, indiquez la priorité que vous accordez au développement",
  "de vos pratiques **au cours des douze prochains mois**. Vous pouvez accorder",
  "la même priorité à plusieurs dimensions : il ne s'agit pas de les classer.", "")
for (d in dimensions) texte <- c(texte, formater_question(paste0("PRIO_", d)))
texte <- c(texte, "## D. Retour sur vos réponses", "",
  "Ces dernières questions portent sur la manière dont vous avez répondu au questionnaire.", "",
  formater_question("CTRL03"), formater_question("CTRL04"),
  "---", "", "**Fin du questionnaire. Merci pour le temps consacré à vos réponses.**", "")

# Vérifier l'exhaustivité, l'unicité, les libellés et les modalités avant écriture.
stopifnot(length(ordre) == 68L, !anyDuplicated(ordre), setequal(ordre, codes_attendus))
for (i in seq_len(nrow(dictionnaire))) {
  entete <- paste0("**", dictionnaire$variable[i], ".** ", dictionnaire$libelle[i])
  emplacement <- which(texte == entete)
  choix <- paste(paste0("☐ ", sub("=", " — ",
    strsplit(dictionnaire$modalites[i], " | ", fixed = TRUE)[[1]], fixed = TRUE)), collapse = " · ")
  stopifnot(length(emplacement) == 1L, identical(texte[emplacement + 2L], choix))
}
stopifnot(match("CTRL02", ordre) - match("CTRL01", ordre) == 19L,
          identical(tail(ordre, 2), c("CTRL03", "CTRL04")))
sortie <- "questionnaire/questionnaire_complet.md"
ordre_passation <- data.frame(ordre = seq_along(ordre),
  dictionnaire[match(ordre, dictionnaire$variable), c("variable", "bloc", "dimension")],
  row.names = NULL)
writeLines(enc2utf8(texte), sortie, useBytes = TRUE)
write.csv(ordre_passation, "questionnaire/ordre_passation.csv", row.names = FALSE, fileEncoding = "UTF-8")
stopifnot(identical(readLines(sortie, encoding = "UTF-8", warn = FALSE), texte),
          isTRUE(all.equal(ordre_passation,
            read.csv("questionnaire/ordre_passation.csv", stringsAsFactors = FALSE, fileEncoding = "UTF-8"))))
cat("Questionnaire généré et relu :", sortie, "\n")
print(table(factor(ordre_passation$bloc, levels = c("PRATIQUES", "FAISABILITE", "PRIORITE", "CONTROLE"))))
cat("68 codes uniques ; libellés et modalités identiques au dictionnaire.\n",
    "CTRL01 et CTRL02 séparés par 18 questions ; CTRL03 et CTRL04 en fin de questionnaire.\n",
    "Aucune réponse simulée.\n", sep = "")
