# Typologie descriptive des pratiques simulées

Données simulées à des fins de démonstration méthodologique. Les résultats présentés ne constituent pas des résultats officiels de la DEPP et ne décrivent pas la population réelle des enseignants.

## Variables et population analysée

La classification utilise les huit scores Z EXP, DIF, EVA, GCL, COL, NUM, DEV et REL, autorisés après la psychométrie. Les scores 1–5 restent conservés. La standardisation utilise la moyenne et l’écart-type non pondérés des scores disponibles, enregistrés à l’étape factorielle. Les cas complets sont sélectionnés sans imputation : 1 463 sur 1 509. Les 46 autres enseignants restent dans la base avec un profil manquant. Quatre cas présentant au moins un |Z| > 3 sont conservés, puis examinés en sensibilité. Ce seuil est un signal marginal et non un diagnostic d’erreur.

## ACP et classification

L’ACP recentre les Z sur les cas complets sans nouvelle réduction. Elle sert à visualiser les scores ; elle ne valide pas les items et ne remplace pas l’analyse factorielle psychométrique. Les deux premiers axes expliquent environ 31,9 % et 12,5 % de la variance. La classification utilise les huit Z, pas seulement ces deux axes.

La CAH utilise la distance euclidienne et Ward.D2. Les solutions de deux à six classes sont comparées par silhouette, inertie, tailles, stabilité et lecture des centres. Le choix éditorial figure dans `metadata/decision_clustering.yml`. Deux groupes sont retenus pour leur parcimonie et leur gradient lisible, malgré une silhouette faible (0,142). Les solutions plus détaillées ont des silhouettes encore plus faibles (0,050 à 0,075). Les tailles sont 915 et 548 ; aucune classe n’est vide. Un effectif de moins de 5 % déclenche dans les tests une alerte de taille pour la description, sans constituer une règle statistique universelle de sélection.

## Robustesse : stabilité faible

Trente sous-échantillons aléatoires de 80 % sont reclassés, à échelle des Z fixe. L’ARI compare les partitions sur les individus communs. Pour deux classes, l’ARI moyen est 0,290 et son dixième percentile 0,078 : la stabilité est qualifiée de **faible**, selon une lecture conjointe de ces résultats et de la faible silhouette, sans seuil universel prétendu.

K-means utilise deux centres, 100 initialisations et une graine fixée à 20260923. Sa silhouette vaut 0,173 et sa concordance avec la CAH 0,466. Retirer les quatre atypies marginales donne un ARI de 0,706 avec la CAH initiale sur les individus communs. La moindre sensibilité à ces quatre cas ne compense pas l’instabilité aux sous-échantillonnages. Ces diagnostics restent conditionnels aux scores et au choix de k ; ils ne mesurent pas toute l’incertitude du pipeline.

## Interprétation neutre

- PROFIL_1 : **Pratiques déclarées moins fréquentes, notamment numériques**.
- PROFIL_2 : **Pratiques déclarées plus fréquentes, contraste numérique marqué**.

Ces noms comparent les groupes entre eux, sans jugement sur les enseignants. Le second groupe présente des scores moyens pondérés supérieurs dans les huit dimensions ; le plus grand contraste concerne NUM (environ 0,895 point). Les profils ne correspondent donc pas à des spécialisations pédagogiques clairement distinctes. La gestion de classe a la moyenne brute la plus élevée dans les deux groupes, ce qui ne suffit pas à les distinguer. Les noms sont vérifiés contre ces propriétés à chaque exécution ; un changement de structure bloque la description et demande une nouvelle lecture des résultats.

## Composition et écarts déclarés

`composition_profils.csv` décrit les catégories à l’intérieur de chaque profil : effectifs observés, pourcentages pondérés et IC conditionnels au plan calibré. `composition_profils_continues.csv` présente ancienneté et jours de formation ; la participation à au moins un jour de formation est également décrite. La classification est non pondérée, sa description utilise les poids finaux. Les proportions de profils portent sur les seuls enseignants classés : 61,8 % et 38,2 %. Aucune correction supplémentaire pour les scores manquants n’est appliquée. Les IC ne propagent pas l’incertitude de construction des classes ni celle de la correction de non-réponse. Ces comparaisons sont descriptives et non causales.

`gap_par_profil.csv` estime priorité moins pratique sur les mêmes paires renseignées. La moyenne du GAP ne doit pas être reconstruite par différence de moyennes calculées sur des dénominateurs différents. Une priorité forte est définie explicitement par une réponse 4 ou 5 ; la part réunissant cette condition et un GAP positif est fournie. Dans PROFIL_1, les écarts moyens positifs les plus marqués concernent NUM (0,302), DIF (0,295) et COL (0,222), mais les priorités moyennes n’atteignent pas 4. Dans PROFIL_2, les huit écarts moyens sont négatifs. Il s’agit d’**écarts déclarés**, avec des ancrages de réponse distincts, et non de besoins réels prouvés. Un GAP négatif ne prouve pas une absence de besoin.

À titre descriptif, la participation à au moins un jour de formation représente 61,9 % du profil 1 et 70,4 % du profil 2 ; un bon équipement numérique, respectivement 30,8 % et 37,7 %. Le premier degré représente 57,4 % et 59,7 %. L’ancienneté moyenne est de 15,30 et 15,94 ans. Ces différences observées ne constituent ni des effets causaux ni des preuves de différences importantes en pratique.

## Livrables et reproductibilité

`R/11_clustering.R` produit les tableaux d’interprétation, composition, GAP et stabilité, ainsi que radar, heatmap, projection ACP et tailles. Radar et heatmap utilisent les moyennes pondérées sur une échelle commune 1–5. La projection ACP est non pondérée. Les radars ne doivent pas être comparés par leur aire.

La base analytique reçoit `CLUSTER_ID` (1 ou 2) et `PROFIL_PRATIQUES` (nom descriptif), sans modification des autres colonnes. Le dictionnaire est actualisé. L’étape est réexécutable ; après régénération de la base par R/10, exécuter R/11 pour rétablir les profils. Les tests contrôlent les classes, les dénominateurs, les GAP et la reproductibilité de la CAH, de k-means et du premier sous-échantillonnage.

Les dépendances statistiques intégrées aux données sont des hypothèses de simulation et ne constituent pas des résultats empiriques sur les enseignants. La partition exploratoire ne démontre pas une typologie naturelle ; sa faible stabilité doit accompagner toute présentation.
