# Base analytique et écarts priorité–pratique

Données simulées à des fins de démonstration méthodologique. Les résultats présentés ne constituent pas des résultats officiels de la DEPP et ne décrivent pas la population réelle des enseignants.

`R/10_factor_analysis.R` crée `data/processed/base_analytique.rds` après les scores. Le fichier réunit `questionnaire_scores.rds` et `questionnaire_weighted.rds` par `id_enseignant`, avec vérification de l'unicité, de l'égalité des ensembles d'identifiants et de toutes les colonnes communes. Un décalage entre générations du pipeline provoque un arrêt. Les poids sont également comparés à ceux du plan calibré `design_depp.rds`.

La base conserve les 1 509 observations incluses, sans nouvelle exclusion et sans imputation. Une liste explicite de colonnes retient les caractéristiques individuelles et professionnelles, le contexte, les strates opérationnelles, probabilités d'inclusion, poids de base/corrigés/calibrés et facteurs associés, les principaux flags qualité, la complétion, les scores, Z, nombres d'items renseignés, faisabilité et priorité. Les 48 réponses originales, CTRL, codes Qxxx, doublons d'indicateurs de qualité et dates techniques ne sont pas recopiés : ils restent accessibles dans les sources inchangées.

Pour chaque dimension :

- `GAP = PRIO - SCORE` : domaine −4 à 4 ; NA si l'une des deux mesures manque.
- `CONTRAINTE = 5 - FAIS` : domaine 0 à 4 ; 0 correspond à la faisabilité maximale, et non à la modalité 1 d'un item inversé. Un FAIS manquant reste manquant.
- `SCORE`, `Z` et `NB_ITEMS` sont repris des scores vérifiés, sans nouvelle standardisation après appariement. Les Z restent centrés sur les scores disponibles non pondérés, pas sur la population pondérée.

`outputs/tables/gap_pratique_priorite.csv` contient cinq indicateurs pour chacune des huit dimensions : pratique, faisabilité, priorité, GAP et contrainte. Les moyennes, médianes, écarts-types et IC sont calculés avec le plan calibré existant ; les effectifs et taux de réponse non pondérés sont aussi présents. Les dénominateurs disponibles peuvent varier entre indicateurs. La moyenne du GAP est une moyenne de différences appariées et ne doit pas être remplacée par la différence de deux moyennes calculées sur des ensembles différents.

Ces opérations arithmétiques rapprochent des ancrages distincts : un GAP positif n'est pas une mesure validée de besoin, et la contrainte dérivée n'est pas une échelle validée de contraintes professionnelles. Les IC restent conditionnels au plan calibré de travail et ne propagent pas toute l'incertitude de la correction de non-réponse ou de la mesure psychométrique.

`metadata/dictionnaire_base_analytique.csv` documente chaque colonne : libellé, type, origine, dimension, règle, bornes explicites pour les mesures dérivées, modalités observées et nombre de manquants. Les modalités observées ne sont pas des listes exhaustives de modalités admissibles. Les règles détaillées du score et les paramètres des Z restent dans `regles_scores_definitifs.csv`.

Pour des analyses pondérées ultérieures, réutiliser le plan `design_depp.rds` et lui adjoindre les nouvelles variables par identifiant : reconstruire uniquement un plan à partir des poids finaux ferait perdre les informations de calibration utilisées pour la variance.
