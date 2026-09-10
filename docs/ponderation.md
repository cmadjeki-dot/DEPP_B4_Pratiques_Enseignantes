# Non-réponse et calibration des poids

> Données simulées à des fins de démonstration méthodologique. Les résultats présentés ne constituent pas des résultats officiels de la DEPP et ne décrivent pas la population réelle des enseignants.

Les dépendances statistiques intégrées aux données sont des hypothèses de simulation et ne constituent pas des résultats empiriques sur les enseignants.

## Participation et réponse analytique

Le script 03 conserve son mécanisme logistique conditionnel aux caractéristiques
du tirage : la participation n'est pas complètement aléatoire. Il produit
`outputs/tables/taux_reponse.csv` par degré, secteur, EP, territoire, strate,
ancienneté (0–9, 10–19, 20–29, 30 ans ou plus) et formation (0, 1–4, 5 jours
ou plus). Le dénominateur est toujours le tirage initial, avant non-réponse.
Le taux attendu est une information du générateur, pas une estimation empirique.
Voir le [modèle de non-réponse](non_reponse.md) pour les coefficients.

Le script 07 travaille sur les inclus de l'analyse principale. La correction
porte donc sur la participation ET l'exclusion analytique : 1 509 retenus sur
2 000 sélectionnés, et non seulement les 1 521 questionnaires commencés. Le
tableau de correction distingue les participants à la collecte des inclus.
Cette définition évite d'appliquer aux 1 509 inclus un facteur calculé pour
1 521 personnes. Une analyse de sensibilité sur une autre sélection nécessitera
ses propres facteurs et sa propre calibration.

## Première correction

Les cellules sont les huit strates opérationnelles, dans lesquelles les poids
de base sont constants. Le seuil de stabilité exige au moins 50 sélectionnés
et 30 inclus par cellule. Ce sont des conventions prudentes de démonstration,
pas des garanties de précision. Si une cellule est insuffisante, le programme
s'arrête pour permettre un regroupement documenté ; il ne fusionne pas des
strates implicitement et ne continue pas avec une cellule sans répondants.

Pour chaque cellule h :

\[
\widehat r_h=\frac{n_{h,\mathrm{inclus}}}{n_{h,\mathrm{selectionnes}}},\quad
f_{h,NR}=\frac{1}{\widehat r_h},\quad
w_{i,NR}=w_{i,base}f_{h,NR}.
\]

Le tableau `metadata/correction_non_reponse.csv` donne ces effectifs, taux et
facteurs. La somme des poids NR retrouve la population de chaque strate par
construction ; aucune remise à l'échelle arbitraire n'est appliquée.
L'hypothèse opérationnelle est une représentativité des inclus au sein de
chaque cellule. Le générateur dépend également d'autres caractéristiques :
cette correction simple ne garantit donc pas la suppression de tout biais.

## Calibration bornée

La méthode est `survey::calibrate`, fonction de distance logit, avec facteurs
multiplicatifs de calibration bornés entre 0,5 et 2, et tolérance relative
de 10^-8. La convergence est exigée (`force = FALSE`) ; aucune calibration
approximative n'est acceptée silencieusement. La documentation officielle
décrit [les fonctions et bornes de calibration](https://r-survey.r-forge.r-project.org/pkgdown/docs/reference/calibrate.html).

La formule est `~ strate_sondage + sexe + anciennete_classe`. Elle représente
dix contraintes indépendantes : huit effectifs de strates, une marge de sexe
supplémentaire et le total des années d'ancienneté dans le niveau de classe.
Conserver les totaux de strates préserve aussi les marges degré, secteur et EP,
sans ajouter des colonnes redondantes au modèle. L'ancienneté est calibrée
comme total continu ; sa distribution complète n'est pas imposée. Elle concerne
le niveau de classe et ne doit pas être confondue avec l'ancienneté de carrière.

Ces auxiliaires sont connus pour toute la population synthétique. Les strates
représentent le plan ; sexe et ancienneté ajoutent deux caractéristiques de
composition sans croisements multiples. Le choix n'est pas optimisé sur les
résultats du questionnaire. Les facteurs sont codés avec les mêmes niveaux
et contrastes dans la population et chez les inclus ; le rang est vérifié.

`poids_final` vaut d'abord `poids_nr`, puis reçoit les poids calibrés une fois
la convergence et les marges validées. `facteur_nr`, `poids_base`, `poids_nr`,
`poids_final` et `facteur_calibration` sont conservés. Les poids antérieurs
et les sources nettoyées restent inchangés.

## Comparaisons et sorties

- `outputs/tables/ponderation_comparaison.csv` : population synthétique,
  échantillon initial non pondéré, inclus non pondérés, poids de base, NR et
  calibrés, pour les marges explicites et les marges degré/secteur/EP.
- `ponderation_marges.csv` : contraintes, totaux calibrés et écarts.
- `ponderation_diagnostics.csv` : somme, extrêmes, quantiles, moyenne, médiane,
  coefficient de variation et effectif de Kish pour chaque système de poids.
- `data/processed/questionnaire_weighted.rds` : base pondérée distincte.
- `outputs/models/plan_calibre.rds` : objet survey de travail.

Les effectifs non pondérés et les totaux pondérés n'ont pas la même échelle ;
la colonne population fournit les cibles. L'effectif de Kish décrit uniquement
la dispersion des poids et ne constitue pas un effectif effectif complet
tenant compte de la stratification et de la variable analysée.

Le plan survey de travail utilise des unités individuelles et les strates,
sans correction de population finie. L'effectif final ne doit pas être traité
comme un tirage aléatoire simple initial de taille fixe. Les futurs intervalles
devront examiner le plan initial et l'estimation des facteurs de non-réponse :
la variance conditionnelle de cet objet ne suffit pas à valider toute la
chaîne d'incertitude. Les valeurs manquantes aux items persistent ; les poids
de questionnaire ne corrigent pas automatiquement la non-réponse par item.

```powershell
Rscript.exe R/03_nonresponse.R
Rscript.exe R/07_weighting.R
Rscript.exe tests/run_tests.R
```

## Résultats de la réalisation de référence

Les cellules comptent de 69 à 494 inclus, sur 100 à 620 sélectionnés. Aucun
regroupement n'est nécessaire. Les facteurs NR vont de 1,2551 à 1,4493.
La somme des poids de base des 1 509 inclus est 76 012,06 ; elle devient
100 000 après correction puis reste 100 000 après calibration. Les poids
finaux vont de 28,9740 à 86,5577 ; leurs facteurs de calibration vont de
0,9813 à 1,0563. L'écart maximal aux contraintes est de 1,17 × 10^-10 environ.
Ces contrôles valident la restitution numérique des marges, pas l'absence
de biais pour toutes les variables du questionnaire.
