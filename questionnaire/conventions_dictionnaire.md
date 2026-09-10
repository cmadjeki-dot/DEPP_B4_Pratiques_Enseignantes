# Conventions du dictionnaire du questionnaire

> Données simulées à des fins de démonstration méthodologique. Les résultats présentés ne constituent pas des résultats officiels de la DEPP et ne décrivent pas la population réelle des enseignants.

Le fichier `metadata/dictionnaire_variables.csv` décrit 68 variables du futur
questionnaire : 48 items de pratiques, 8 de faisabilité, 8 de priorité et
4 contrôles. Il ne contient aucune réponse. Les variables de population et
de sondage seront intégrées au dictionnaire général dans une étape ultérieure.

## Statut scientifique

Les libellés sont des propositions originales pour le démonstrateur ; ils ne
proviennent pas d'un instrument officiel et ne constituent pas des échelles
validées. Un examen de contenu et un prétest cognitif seraient nécessaires
avant une collecte réelle, notamment pour vérifier leur pertinence aux deux
degrés. Les pratiques n'ont pas toutes les mêmes occasions de survenue :
formation, relations avec les familles et usages numériques exigent notamment
une interprétation contextualisée des fréquences.

## Référence des réponses

Les 48 items de pratiques portent sur les trois derniers mois effectivement
enseignés et sur le niveau de classe principalement enseigné. Cette consigne
sera présentée en tête du questionnaire. La faisabilité porte sur les conditions
actuelles d'exercice ; la priorité sur les douze prochains mois.

Les huit dimensions sont EXP (enseignement explicite), DIF (différenciation),
EVA (évaluation formative et feedback), GCL (gestion de classe), COL
(collaboration), NUM (numérique), DEV (développement professionnel) et REL
(relations éducatives). Chaque dimension comporte exactement six items.

## Codage et scores

- `PRATIQUES` : 1 Jamais, 2 Rarement, 3 Parfois, 4 Souvent, 5 Très souvent.
- `FAISABILITE` : 1 Pas du tout faisable à 5 Tout à fait faisable.
- `PRIORITE` : 1 Pas prioritaire à 5 Très prioritaire.
- `type` décrit le stockage entier et le caractère ordinal ou binaire ; une
  échelle ordinale ne suppose pas des distances égales entre modalités.
- `minimum` et `maximum` sont les bornes des codes admissibles, pas des valeurs
  observées. La colonne `modalites` énumère tous les codes et leurs libellés.
- `score_associe = SCORE_EXP` (ou autre dimension) désigne un score envisagé,
  encore non calculé. Ses règles de calcul, de complétude et de validation
  psychométrique restent à définir. Les variables FAIS, PRIO et CTRL portent
  `AUCUN` : elles ne sont pas incorporées aux scores de pratiques.
- Les items principaux restent directs ; CTRL02 et CTRL04 sont inversés
  (`item_inverse = TRUE`). Hors de ces deux contrôles, un code élevé signifie
  une fréquence, une faisabilité ou une priorité plus élevée selon le bloc,
  sans être à lui seul une mesure d'efficacité pédagogique.
- `obligatoire = FALSE` pour toutes les questions : une réponse est sollicitée,
  mais aucune saisie ne sera forcée. Dans les futures données, l'absence de
  réponse sera `NA`, sans code numérique de substitution. La non-réponse
  partielle reste distincte de la non-réponse totale à l'enquête.

## Contrôles proposés

CTRL01 est un contrôle explicite de lecture, avec réponse attendue 3.
CTRL02 mesure la fréquence déclarée de réponses sans lecture complète ; il
remplace la seconde consigne de lecture initialement prévue. CTRL03 vérifie
le champ de référence déclaré (0 Non, 1 Oui, attendu 1 selon la consigne).
CTRL04 recueille les difficultés déclarées de précision, sans valeur attendue
ni seuil fixé. Les recodages sont `CTRL02_reverse = 6 - CTRL02` et
`CTRL04_reverse = 6 - CTRL04` : une valeur recodée élevée indique moins de
difficultés déclarées. Les réponses brutes sont conservées. Les contrôles et
leurs recodages n'entrent dans aucune échelle principale. Voir
[la documentation des contrôles](../docs/controles.md).

Un contrôle échoué ne justifie pas, à lui seul, l'exclusion d'un répondant.
L'évaluation de la qualité combinera les contrôles avec les autres informations
disponibles ; elle devra aussi envisager une ambiguïté ou une inadéquation de la
consigne. Les règles seront définies dans le plan de contrôles ultérieur.

## Format et vérification

CSV UTF-8, séparateur virgule, textes entre guillemets, indicateurs booléens
`TRUE`/`FALSE`. Les valeurs `AUCUN` et `AUCUNE` signifient « sans score » et
« sans dimension de pratiques », et non une valeur manquante.

```r
dictionnaire <- read.csv("metadata/dictionnaire_variables.csv",
                         fileEncoding = "UTF-8", stringsAsFactors = FALSE)
table(dictionnaire$bloc)
```

Les tests de `tests/testthat/test-dictionnaire.R` contrôlent le schéma, les
68 codes uniques, les effectifs par bloc, les modalités, les bornes et les
conventions de score. Aucune réponse n'est simulée à cette étape.

## Document de passation

Le [questionnaire complet](questionnaire_complet.md) reprend les libellés et
modalités du dictionnaire sans modification. Les huit dimensions de pratiques
sont suivies de la faisabilité, de la priorité et du retour sur la passation.
CTRL01 est placé après EVA, CTRL02 après NUM ; dix-huit questions les séparent.
CTRL03 et CTRL04 terminent le questionnaire. Les règles de contrôle et les scores
ne sont pas affichés dans le formulaire de réponse.

Le fichier [ordre_passation.csv](ordre_passation.csv) documente les positions
des 68 questions. Le générateur `questionnaire/generer_questionnaire.R` permet
de reconstruire les deux documents après un changement du dictionnaire.
Ne pas éditer directement les libellés dans le document généré : toute révision
doit d'abord être portée dans le dictionnaire, puis répercutée par le générateur.
