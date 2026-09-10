# Analyses descriptives pondérées et scores provisoires

> Données simulées à des fins de démonstration méthodologique. Les résultats présentés ne constituent pas des résultats officiels de la DEPP et ne décrivent pas la population réelle des enseignants.

`R/08_descriptive.R` lit la base nettoyée et le plan calibré `design_depp`.
Il vérifie les identifiants et les 68 réponses entre les deux fichiers, conserve
leurs empreintes et ne les modifie pas. Les statistiques principales utilisent
les poids finaux ; n et les pourcentages non pondérés documentent les observations.

## Table 1 et intervalles

`table1_echantillon.csv` couvre degré, sexe, ancienneté, statut, secteur, EP,
territoire, formation et équipement. La formation apparaît en jours et en
participation (au moins un jour). Les catégories présentent n, pourcentages
non pondérés et pondérés, manquants et IC 95 %. Les lignes continues présentent
n, moyenne pondérée, écart-type pondéré, médiane pondérée et IC de la moyenne.
Les IC des lignes catégorielles sont en pourcentage, ceux des lignes continues
dans l'unité de la variable : la colonne type permet de les distinguer.

Les moyennes utilisent `svymean`, la dispersion `svyvar` et les médianes
`svyquantile` (règle par défaut, sans IC de médiane). Les IC de moyenne utilisent
Student avec les degrés de liberté du plan. Les proportions utilisent la
transformation logit et une variance obtenue par méthode delta depuis `svymean`.
Les proportions exactement 0/1 ont un IC non calculable, laissé NA. Une marge
fixée par calibration peut avoir une variance conditionnelle quasi nulle :
elle est signalée dans `methode_ic`. Voir les références de
[survey pour les résumés](https://r-survey.r-forge.r-project.org/pkgdown/docs/reference/surveysummary.html)
et [les quantiles](https://r-survey.r-forge.r-project.org/pkgdown/docs/reference/svyquantile.html).

Ces IC restent ceux du plan de travail documenté dans
[qualite_et_ponderation.md](qualite_et_ponderation.md) : l'incertitude de la
correction NR et de la sélection analytique n'est pas entièrement propagée.
Ils ne sont pas des intervalles de résultats officiels sur les enseignants.

## Items et distributions

`descriptif_items.csv` contient exactement 48 lignes. Chaque item a son n
observé, ses taux de réponse brut et pondéré, moyenne, médiane, écart-type,
IC descriptif, effectifs 1–5 et proportions pondérées 1–5. Les modalités NA
ne sont jamais assimilées à une fréquence nulle. Le dénominateur pondéré est
la somme des poids des réponses présentes à cet item.

Le seuil exploratoire plancher/plafond est de 15 % de réponses au code 1/5.
Il attire l'attention sur une concentration à une borne, sans diagnostic
automatique de mauvais item. Le flag de faible dispersion est déclenché si
une modalité concentre au moins 80 % des réponses pondérées ou si l'écart-type
des codes est inférieur à 0,5. Ces conventions ne mesurent pas la discrimination
factorielle et seront réexaminées lors de la psychométrie ; aucun item n'est retiré.

Les distributions détaillées sont dans `frequences_items_ponderees.csv`.
Huit graphiques `outputs/figures/distribution_items_DIM.png` montrent les six
items de chaque dimension en barres empilées à 100 %, hors manquants et sans score.

## Pratique, faisabilité, priorité et écarts

Les scores `score_provisoire_EXP` à `score_provisoire_REL` sont les moyennes
des six items de pratiques, uniquement quand les six réponses sont présentes.
Sinon le score est NA. Les GAP sont calculés au niveau individuel, sur les
paires disponibles : `GAP_DIM = PRIO_DIM - score_provisoire_DIM`.
Leur moyenne n'est pas calculée par différence de deux moyennes reposant sur
des personnes différentes. Aucun recodage ou score définitif n'est introduit.

`comparaison_pratique_faisabilite_priorite.csv` contient quatre lignes par
dimension : pratique provisoire, faisabilité, priorité et GAP provisoire, avec
n, dénominateurs et IC. `distributions_faisabilite_priorite.csv` fournit les
cinq catégories de chacune des 16 variables, avec IC des proportions.
`scores_provisoires_et_gaps.csv` conserve les valeurs individuelles exploratoires,
séparées de la base nettoyée et ignorées par Git.

Un GAP positif signifie que le code de priorité dépasse la moyenne des codes
de fréquence dans la convention retenue. Il peut suggérer une priorité déclarée
plus élevée que la fréquence déclarée, mais les ancrages diffèrent : ce n'est
ni une mesure validée de besoin, ni un déficit établi. Les intervalles des
dimensions ne constituent pas des tests de différences appariées ; aucune
hiérarchie significative n'est affirmée sur leur seule inspection.

Toutes les estimations avec manquants décrivent les réponses disponibles sous
les poids de questionnaire. Elles ne corrigent pas à elles seules la non-réponse
partielle. Les distributions ordinales doivent accompagner les moyennes, dont
l'interprétation suppose conventionnellement des distances égales entre codes.

## Comparaisons par degré et contexte

`comparaison_scores_degre.csv` utilise `svyglm` avec un indicateur de collège :
le modèle saturé à deux groupes estime la différence collège moins premier
degré, sans ajustement des caractéristiques. L'IC et le test bilatéral utilisent
la covariance survey et les degrés de liberté résiduels. Les huit p-valeurs
sont accompagnées de leur correction de Holm. L'importance pratique ne découle
pas d'un seuil de significativité ; aucun seuil pédagogique minimal n'est validé.
La différence standardisée est divisée par l'écart-type global pondéré du score,
et n'est pas un d de Cohen corrigé.

`scores_par_contexte.csv` présente les moyennes et IC par secteur, EP,
territoire, équipement, ancienneté (0–9, 10–19, 20–29, 30 ans ou plus) et
formation (0, 1–4, au moins 5 jours). Les sous-populations sont obtenues depuis
le plan survey ; les poids ne sont pas recalculés par groupe. Ces comparaisons
restent descriptives et n'isolent pas des effets propres.

Six figures numérotées 01 à 06 présentent distributions et moyennes. Les axes
des scores vont de 1 à 5 ; les distributions de scores utilisent des classes
de largeur 0,5. Les titres, sources et mentions de simulation figurent sur
chaque graphique. `synthese_descriptive.md` est générée après calcul et contient
sept constats, chacun accompagné d'une interprétation prudente et d'une limite.
