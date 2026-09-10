# Qualité et pondération — synthèse méthodologique

> Données simulées à des fins de démonstration méthodologique. Les résultats présentés ne constituent pas des résultats officiels de la DEPP et ne décrivent pas la population réelle des enseignants.

Les dépendances statistiques intégrées aux données sont des hypothèses de simulation et ne constituent pas des résultats empiriques sur les enseignants.

## Qualité de la collecte

Le [référentiel qualité](../metadata/plan_controles.csv) comprend 30 contrôles
sur la structure, les identifiants, les domaines, la cohérence, le sondage,
les manquants, les durées et la constance. Le script 05 conserve la base brute
intacte et exporte diagnostics et flags séparément. Les valeurs non évaluables
ne sont pas assimilées à une absence d'anomalie. Les informations connues
uniquement du simulateur ne sont pas fournies aux détecteurs.

La collecte comprend 1 521 questionnaires, dont 594 complets, 902 partiels
et 25 abandons. Elle présente 2 908 cellules manquantes sur 68 questions,
soit 2,81 %. Les absences sont à la fois dispersées et concentrées en fin de
questionnaire. Les flags signalent 30 profils quasi constants, 25 rapides et
16 très rapides ; ces comptes peuvent se chevaucher et ne sont pas des preuves
d'invalidité. Aucun doublon ni code hors domaine n'est observé.

## Corrections, doublons et inclusion

Le [nettoyage](nettoyage.md) consigne toute correction avant de convertir une
valeur impossible en NA, sans inventer une réponse. Le journal est vide dans
la réalisation courante, mais le traitement est testé sur des copies altérées.
Une contradiction de contexte entre copies d'un identifiant impose un examen.
Pour les vrais doublons techniques, la priorité est : questionnaire complet,
complétion la plus élevée, durée plausible, date récente puis ordre initial.
Toutes les décisions sont conservées, même pour les observations exclues.

La principale exclut les copies non prioritaires, les cas inexploitables,
les questionnaires remplis à moins de 50 % ou avec moins de 24 pratiques
valides, et le cumul très rapide + straightlining + échec CTRL01. Une rapidité
ou une constance isolée n'entraîne pas d'exclusion. Les abandons suffisamment
renseignés peuvent être conservés. La réalisation compte 1 509 inclus et
12 exclus pour complétion ; la sensibilité stricte retient 1 441 individus.
Cette dernière sélection doit faire l'objet d'une pondération propre si elle
est utilisée pour une comparaison d'échantillons analytiques.

## Non-réponse et poids

Le tirage initial est stratifié sans remise : 2 000 enseignants sur une
population synthétique de 100 000. Dans la strate h, pi_h = n_h/N_h et
poids_base = N_h/n_h. La non-réponse est simulée par un modèle logistique
conditionnel au contexte ; elle ne constitue pas un tirage complètement
aléatoire. Les taux selon les caractéristiques sont documentés dans
`outputs/tables/taux_reponse.csv`.

La correction porte sur les 1 509 inclus : facteur_nr = sélectionnés/inclus
dans chacune des huit strates, puis poids_nr = poids_base × facteur_nr.
Elle couvre non-participation et exclusions analytiques. Chaque cellule
contient au moins 69 inclus ; aucun regroupement n'est nécessaire. L'hypothèse
de représentativité au sein de chaque cellule demeure une approximation.

La [calibration](ponderation.md) utilise `survey::calibrate`, distance logit
et facteurs bornés entre 0,5 et 2. Elle conserve les huit totaux de strates,
donc les marges degré/secteur/EP, et ajoute sexe et total d'ancienneté dans
le niveau de classe. Il n'y a ni croisement supplémentaire ni score de pratique
dans les contraintes. Les ajustements observés sont modestes (0,981 à 1,056).
Les sommes NR et finale valent 100 000 ; les poids finaux vont de 28,974 à 86,558.
La documentation de [survey](https://r-survey.r-forge.r-project.org/pkgdown/docs/reference/calibrate.html)
décrit la conservation de l'information de calibration pour les calculs de variance.

## Diagnostic des poids

`outputs/tables/diagnostic_poids.csv` présente minimum, quartiles, médiane,
moyenne, maximum et coefficient de variation pour les trois poids.
Le CV utilise ici l'écart-type avec diviseur n, afin d'obtenir exactement :

\[
DEFF_{Kish}=n\frac{\sum_i w_i^2}{(\sum_i w_i)^2}=1+CV^2,
\qquad n_{eff}=\frac{(\sum_i w_i)^2}{\sum_i w_i^2}.
\]

Cette convention diffère légèrement du CV calculé avec `sd()` dans les
diagnostics antérieurs (diviseur n−1). Le DEFF de Kish mesure la dispersion
des poids uniquement : ce n'est pas l'effet de plan complet d'une estimation,
qui dépend aussi de la stratification, de la calibration et de la variable.
L'effectif effectif n'est donc pas un substitut universel au nombre de répondants.

Les extrêmes sont examinés par bornes de Tukey (Q1−1,5 IQR et Q3+1,5 IQR) et
par le seuil supérieur de quatre médianes. `poids_extremes.csv` conserve pour
chaque poids sa valeur, son ratio à la médiane, sa contribution au total et
les deux flags. Ces seuils descriptifs appellent un examen par strate, pas une
troncature automatique. Aucun poids n'est tronqué.

## Plan survey destiné aux analyses

`design_depp`, enregistré dans `data/processed/design_depp.rds`, conserve le
plan stratifié calibré et ses informations de calibration. Il n'est pas recréé
comme un simple plan à poids finaux fixes. Ses poids effectifs sont vérifiés
contre `poids_final` et les proportions sont recalculées avec `svymean` pour
chaque strate et pour degré, secteur, EP et sexe. Les écarts figurent dans
`verification_design.csv`. Seules les contraintes calibrées sont garanties :
les autres distributions ne doivent pas être artificiellement forcées.

Le plan utilise des unités individuelles, huit strates et aucune correction
de population finie. Il s'agit d'un plan analytique de travail : l'incertitude
de l'estimation des facteurs NR et de la sélection après qualité n'est pas
intégralement propagée. Les futurs intervalles devront expliciter cette limite,
voire utiliser une méthode de variance tenant compte des différentes phases.

## Sensibilité à la pondération

`sensibilite_ponderation.csv` compare, sur les mêmes 1 509 inclus, absence de
pondération, poids de base, NR et finaux. Les indicateurs sont les proportions
de premier degré, de REP/REP+ et de participation à la formation, puis les
moyennes des codes EXP01, DIF01 et EVA01. Ce sont des moyennes exploratoires
d'items ordinaux, pas des scores psychométriques validés.

Les moyennes par item utilisent les seules réponses présentes. Les effectifs,
sommes de poids au dénominateur et taux de manquants pondérés sont fournis.
Les cibles synthétiques sont connues pour les caractéristiques ; les réponses
aux items n'ont pas été générées sur toute la population, donc aucune cible
de population n'est inventée pour elles. Le redressement de la composition
ne corrige pas automatiquement la non-réponse aux items ni les biais de déclaration.

La comparaison décrit l'effet des pondérations sur une réalisation. Elle
ne prouve pas leur supériorité générale ; des scénarios et répétitions Monte-Carlo
seraient nécessaires. Les résultats n'autorisent aucune généralisation aux
enseignants réels et ne constituent pas une publication officielle de la DEPP.

## Résultats de référence

Le DEFF de Kish est de 1,0716 pour les poids de base, 1,0601 après NR et
1,0603 après calibration. Les effectifs de Kish correspondants sont 1 408,15,
1 423,48 et 1 423,23 pour 1 509 inclus. Aucun poids ne dépasse les bornes de
Tukey ou quatre médianes dans les trois systèmes. Aucun poids n'est tronqué.

| Indicateur | Non pondéré | Base | NR | Final | Population synthétique |
|---|---:|---:|---:|---:|---:|
| Premier degré (%) | 51,82 | 59,68 | 57,88 | 57,88 | 57,88 |
| REP/REP+ (%) | 23,46 | 16,07 | 16,58 | 16,58 | 16,58 |
| Formation, au moins un jour (%) | 65,14 | 64,93 | 64,89 | 64,85 | 64,55 |
| Moyenne EXP01 | 3,504 | 3,504 | 3,505 | 3,505 | Non disponible |
| Moyenne DIF01 | 2,977 | 2,974 | 2,974 | 2,974 | Non disponible |
| Moyenne EVA01 | 2,745 | 2,736 | 2,736 | 2,736 | Non disponible |

La correction NR restitue déjà degré et EP car leurs totaux sont des sommes
de cellules. La calibration les conserve. La formation n'est pas une contrainte :
son écart résiduel à la population illustre la limite d'un redressement sur
quelques marges. Les moyennes d'items changent peu dans cette réalisation,
sans que cela démontre l'inutilité de la pondération.
