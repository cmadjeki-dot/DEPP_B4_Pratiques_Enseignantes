# Profils multivariés exploratoires

Données simulées à des fins de démonstration méthodologique. Les résultats présentés ne constituent pas des résultats officiels de la DEPP et ne décrivent pas la population réelle des enseignants.

## Sélection et variables

`R/11_clustering.R` utilise la base analytique inchangée et seulement les dimensions autorisées par `metadata/revue_facteurs.csv`. Un enseignant est éligible lorsque tous les Z retenus sont disponibles et finis. Aucune imputation n'est réalisée. Les exclusions pour scores manquants sont tracées ; elles peuvent modifier la composition de la base analysée.

Une valeur absolue de Z supérieure à 3 signale une atypie marginale. Ce seuil exploratoire ne prouve pas une erreur : les scores sont bornés et les réponses extrêmes peuvent être cohérentes. Les cas signalés restent dans la classification principale ; leur influence est examinée dans une solution complémentaire. Ce signal ne constitue pas une détection exhaustive des atypies multivariées.

Les corrélations et variances sont calculées sur les cas complets utilisés pour les distances. Un |r| ≥0,85 signale une redondance à examiner ; aucune dimension n'est automatiquement supprimée. Les Z conservent les paramètres de standardisation de la base analytique ; leurs variances peuvent donc légèrement différer de 1 après sélection.

## ACP et CAH

L'ACP recentre les Z des cas complets, sans nouvelle mise à l'échelle. Elle décrit la variance totale des scores agrégés pour visualiser les individus et les dimensions. Elle ne modélise pas l'erreur de mesure et ne remplace pas l'AFE psychométrique des items ordinaux. Les contributions sont 100 fois les carrés des coefficients normalisés des axes ; le cercle représente les corrélations entre scores et composantes.

La CAH porte sur les huit Z retenus, non sur les seuls deux axes dessinés. La distance est euclidienne, avec `hclust(method="ward.D2")`. Les solutions k=2 à 6 sont comparées par silhouette, inertie intra-classe (somme des distances au carré aux centres), tailles, stabilité et contenu des centres. L'inertie diminue mécaniquement avec k ; elle ne suffit pas à sélectionner k. La hauteur Ward du dendrogramme n'est pas présentée comme une inertie intra-classe.

La stabilité utilise 30 sous-échantillons aléatoires de 80 % sans remise. Une nouvelle CAH est comparée à la partition complète restreinte aux mêmes individus, par indice de Rand ajusté (ARI), invariant aux noms des classes. Cette mesure décrit la stabilité de partition sous perturbation de l'échantillon ; ce n'est ni un IC de sondage ni une validation externe. Les tirages utilisent une graine fixée dans `config/clustering.yml`.

La construction des groupes est non pondérée : les poids de sondage ne sont pas des masses dans Ward ou k-means. Les descriptions pondérées ultérieures utilisent le plan calibré existant, en conservant ses informations de calibration. Elles restent conditionnelles à une partition estimée ; leur variance ne prend pas en compte l'incertitude de la construction des profils.

## Interprétation

Les centres par dimension permettent de distinguer une simple gradation générale des pratiques de contrastes de contenu. La décision doit combiner ces informations avec les indices et la parcimonie. Une partition peut être utile pour décrire un continuum sans identifier des groupes naturels. Les huit traits simulés n'ont pas été construits à partir de classes latentes : aucune typologie ne doit être présentée comme une vérité empirique sur les enseignants.

## Résultats et choix retenu

La sélection conserve 1 463 personnes et en laisse 46 non classées pour scores manquants. Quatre cas signalés par |Z|>3 sont conservés dans la solution principale. Aucune corrélation n'atteint le seuil de redondance ; les huit dimensions sont maintenues. Les deux premiers axes de l'ACP représentent environ 31,9 % et 12,5 % de la variance : la projection n'épuise pas l'information utilisée pour la CAH.

La décision examinée est enregistrée dans `metadata/decision_clustering.yml`. k=2 est retenu comme résumé parcimonieux : silhouette 0,142, classes de 915 et 548 individus, centres globalement de part et d'autre de la moyenne pour les huit dimensions. Les solutions plus complexes ajoutent notamment des contrastes EXP/EVA contre NUM/DEV, puis DIF/EVA contre COL, mais leurs silhouettes sont plus basses et leur stabilité moyenne diminue. La meilleure stabilité relative à k=2 reste faible (ARI moyen 0,290 ; dixième percentile 0,078). Ce choix ne valide pas deux catégories distinctes d'enseignants.

Le k-means à deux groupes utilise 100 initialisations et une graine distincte fixée. Son ARI avec la CAH vaut 0,466 et sa silhouette 0,173 : il améliore légèrement la séparation mesurée mais confirme une dépendance aux choix algorithmiques. La CAH refaite sans les quatre atypies donne un ARI de 0,706 sur les 1 459 individus communs. On ne conclut donc pas à une typologie fortement robuste.

`PROFIL_1` (915) et `PROFIL_2` (548) sont des identifiants neutres. Les 46 autres personnes gardent un profil NA et un motif explicite dans `data/processed/base_analytique_profils.rds`. La base analytique source n'est pas modifiée. `profils_scores.csv` présente, pour chaque groupe et dimension, SCORE, FAIS, PRIO et GAP avec moyenne non pondérée, estimation pondérée, IC et dénominateurs. `taille_profils.csv` décrit les proportions parmi les personnes classées, pas parmi l'ensemble des enseignants réels.

Les descriptions par profil sont des domaines du plan calibré. Celui-ci peut conserver des observations extérieures au domaine avec poids nul : elles sont exclues des dénominateurs descriptifs et ne sont pas comptées comme des non-réponses du profil. Ce contrôle s'applique aussi aux autres descriptifs continus par sous-groupe.

Références : [CAH et Ward.D2 dans R](https://www.stat.ethz.ch/R-manual/R-devel/library/stats/html/hclust.html), [silhouette dans cluster](https://stat.ethz.ch/R-manual/R-devel/library/cluster/html/silhouette.html).
