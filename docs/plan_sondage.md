# Plan de sondage — DEPP_B4_Pratiques_Enseignantes

Version du 9 septembre 2026 — documentation de l'échantillon initial, avant non-réponse.

> Données simulées à des fins de démonstration méthodologique. Les résultats présentés ne constituent pas des résultats officiels de la DEPP et ne décrivent pas la population réelle des enseignants.

## 1. Objet et population cible

Ce démonstrateur personnel vise à reproduire une chaîne d'enquête sur les
pratiques professionnelles déclarées des enseignants : enseignement explicite,
différenciation, évaluation formative, gestion de classe, collaboration,
numérique, développement professionnel et relations éducatives. Il ne s'agit
pas d'une enquête menée ou commanditée par la DEPP.

Le périmètre conceptuel couvre les enseignants du premier degré et du collège,
dans le secteur public et le privé sous contrat, en territoires urbains,
périurbains et ruraux. Le public distingue les contextes hors éducation
prioritaire, REP et REP+. Le lycée, l'enseignement supérieur et le privé hors
contrat ne font pas partie du périmètre simulé.

Aucune année scolaire, base administrative réelle ou couverture géographique
effective n'est revendiquée. Les estimations issues de ce plan porteront sur la
population synthétique définie ci-dessous, sans extrapolation aux enseignants réels.

## 2. Population synthétique et unité statistique

La base de sondage est une population finie de **N = 100 000 enseignants fictifs**.
Elle est générée intégralement par simulation ; elle ne contient ni données
individuelles réelles ni enregistrements pseudonymisés provenant d'une enquête.

L'unité statistique, l'unité de tirage et l'unité de réponse prévue sont
l'enseignant. Chaque unité possède un identifiant unique `id_enseignant`.
Il n'y a pas de tirage préalable d'établissements ni de plan en grappes : le
plan comporte un seul degré de tirage, directement dans la liste des enseignants.

La population comprend 57 882 enseignants du premier degré et 42 118 du collège.
Les répartitions, l'âge, l'ancienneté et les caractéristiques d'exercice résultent
d'hypothèses paramétrées, et non d'un calage sur des statistiques officielles.
Les contrôles de génération garantissent notamment des identifiants uniques,
l'absence de valeurs manquantes et la cohérence des variables nécessaires au tirage.

Le premier degré est associé à la discipline « Polyvalent premier degré » ;
dix disciplines principales sont distinguées au collège. Par convention du
démonstrateur, tous les enseignants du privé sous contrat sont classés hors EP.

## 3. Stratification opérationnelle

Les strates de sondage sont définies avant le tirage par le croisement du degré,
du secteur et, dans le public, de l'éducation prioritaire. Elles constituent
une partition exhaustive et mutuellement exclusive : chaque enseignant
appartient à exactement une des huit strates.

| Code `strate_sondage` | Définition |
|---|---|
| P1_PUBLIC_HEP | Premier degré, public, hors EP |
| P1_PUBLIC_REP | Premier degré, public, REP |
| P1_PUBLIC_REPPLUS | Premier degré, public, REP+ |
| P1_PRIVE | Premier degré, privé sous contrat, hors EP par convention |
| COL_PUBLIC_HEP | Collège, public, hors EP |
| COL_PUBLIC_REP | Collège, public, REP |
| COL_PUBLIC_REPPLUS | Collège, public, REP+ |
| COL_PRIVE | Collège, privé sous contrat, hors EP par convention |

La variable descriptive `strate` conserve un croisement plus fin intégrant le
territoire, soit 24 catégories. Elle ne doit pas être confondue avec
`strate_sondage`, qui pilote le tirage et le calcul des poids.

Le territoire n'impose donc aucun effectif d'échantillon : ses effectifs tirés
peuvent varier au sein de chaque strate opérationnelle. Les deux catégories
descriptives REP+ rurales de 70 et 119 enseignants ne sont pas tirées séparément.
Leur regroupement ne garantit pas des effectifs suffisants pour publier des
résultats à cette finesse. La plus petite strate opérationnelle compte 2 036 unités.

## 4. Allocation de l'échantillon initial

L'échantillon initial a une taille fixée de **n = 2 000 enseignants**, avant
toute non-réponse, avec 1 000 unités par degré. L'allocation est fixée pour le
démonstrateur ; elle n'est ni proportionnelle aux effectifs de population ni
une allocation optimale calculée à partir de variances connues.

Elle donne davantage de place au collège et aux contextes REP+ que ne le ferait
une allocation strictement proportionnelle. Cela permet d'illustrer l'intérêt
des poids inégaux et des analyses par domaine, sans garantir un niveau de
précision particulier pour chaque indicateur.

Dans le tableau suivant, **N_h** désigne l'effectif de population de la strate h,
et **n_h** son effectif fixé dans l'échantillon. Les probabilités et les poids
sont arrondis uniquement pour la présentation.

| Strate | N_h | n_h | pi_h | Poids de base |
|---|---:|---:|---:|---:|
| P1_PUBLIC_HEP | 40 078 | 620 | 0,015469834 | 64,641935 |
| P1_PUBLIC_REP | 7 011 | 130 | 0,018542291 | 53,930769 |
| P1_PUBLIC_REPPLUS | 2 659 | 100 | 0,037608123 | 26,590000 |
| P1_PRIVE | 8 134 | 150 | 0,018441111 | 54,226667 |
| COL_PUBLIC_HEP | 26 267 | 600 | 0,022842350 | 43,778333 |
| COL_PUBLIC_REP | 4 871 | 150 | 0,030794498 | 32,473333 |
| COL_PUBLIC_REPPLUS | 2 036 | 100 | 0,049115914 | 20,360000 |
| COL_PRIVE | 8 944 | 150 | 0,016771020 | 59,626667 |
| **Total** | **100 000** | **2 000** | — | — |

Toutes les allocations sont strictement positives et inférieures à l'effectif
de leur strate. La fraction de sondage globale vaut 2 %, mais les probabilités
individuelles varient entre strates : elles ne sont pas toutes égales à 0,02.

## 5. Mécanisme de tirage et probabilités d'inclusion

Dans chaque strate, le tirage est **aléatoire simple sans remise**, à effectif
fixé n_h. Chaque sous-ensemble de n_h enseignants parmi les N_h unités éligibles
a la même probabilité d'être sélectionné. Les tirages sont réalisés séparément
dans les huit strates ; une unité ne peut être sélectionnée plusieurs fois.

Pour tout enseignant i de la strate h, la probabilité d'inclusion de premier
ordre est :

\[
\pi_i = \pi_h = \frac{n_h}{N_h}.
\]

En notation textuelle : **pi_h = n_h / N_h**.

Les unités d'une même strate ont la même probabilité marginale d'inclusion.
Elles ne sont toutefois pas sélectionnées indépendamment les unes des autres
à l'intérieur de cette strate, puisque le tirage est sans remise à taille fixe.

## 6. Poids de base et estimation

Le poids de base de chaque unité sélectionnée est l'inverse de sa probabilité
d'inclusion :

\[
w_i = w_h = \frac{1}{\pi_h} = \frac{N_h}{n_h}.
\]

En notation textuelle : **w_h = 1 / pi_h**.

Par exemple, un enseignant de la strate P1_PUBLIC_HEP reçoit un poids d'environ
64,64 ; un enseignant de COL_PUBLIC_REPPLUS reçoit un poids de 20,36. Ces poids
traduisent les fractions de sondage différentes et ne mesurent pas une importance
individuelle ou une qualité de réponse.

Pour l'échantillon initial complet, les identités suivantes découlent du plan :

\[
\sum_{i\in s_h} w_i = n_h\frac{N_h}{n_h}=N_h,
\qquad
\sum_{i\in s} w_i = \sum_{h=1}^{8}N_h=100\,000.
\]

Le poids moyen global vaut 50, sans que tous les enseignants aient ce poids.
Aucune normalisation artificielle n'est appliquée pour obtenir 100 000.

Pour une variable y observée sur tout l'échantillon initial, un estimateur du
total de la population synthétique est la somme pondérée
\(\widehat{T}_y=\sum_{i\in s}w_i y_i\). La moyenne correspondante est
\(\widehat{T}_y/N\). Les calculs de variance devront tenir compte des huit
strates et du tirage sans remise, notamment de la correction de population
finie liée à la fraction n_h/N_h.

Ces poids précèdent la correction de non-réponse et la calibration. Après
non-réponse, la somme des seuls poids de base des répondants n'a aucune raison
de rester égale à 100 000. Une correction devra alors reposer sur des hypothèses
et une méthode explicites ; les poids initiaux doivent rester disponibles.

## 7. Contrôles et reproductibilité

Les contrôles exécutés vérifient :

- 100 000 unités dans la population et 2 000 dans l'échantillon initial ;
- l'unicité des identifiants et l'appartenance des unités tirées à la population ;
- une seule strate opérationnelle renseignée par enseignant ;
- des effectifs tirés exactement égaux aux huit allocations ;
- des probabilités finies dans ]0 ; 1] et des poids finis strictement positifs ;
- la conformité de chaque poids au rapport N_h/n_h ;
- les sommes de poids par strate et au total, avec une tolérance absolue de 10⁻⁸.

L'audit des poids a trouvé un écart absolu maximal par strate d'environ
3,64 × 10⁻¹² et un écart total nul, compatibles avec les arrondis numériques.

La population est générée avec la graine **20260909** ; le tirage utilise la
graine distincte **20260910**. Le tirage fixe les algorithmes Mersenne-Twister,
Inversion et Rejection. Sa reproductibilité a été vérifiée par comparaison
intégrale de deux tirages, puis par relecture du fichier sauvegardé. Elle suppose
la conservation des données d'entrée, de leur ordre, de l'allocation et du code.
Les dépendances R sont enregistrées dans `renv.lock` ; R 4.6.0 constitue
l'environnement de référence.

## 8. Limites du démonstrateur

La cohérence interne des données ne démontre pas leur représentativité réelle.
La population et les associations entre ses caractéristiques sont construites
par le générateur. Les résultats futurs dépendront de ces choix.

La base synthétique est complète par construction. Les erreurs de couverture,
les doublons administratifs et les problèmes de mise à jour d'une base réelle
ne sont pas reproduits. Aucun effet d'établissement ou de grappe n'est intégré
au plan. Les disciplines et les territoires ne font pas l'objet d'une allocation
contrainte ; les analyses à ces niveaux nécessiteront un examen de leur précision.

La taille initiale de 2 000 ne garantit ni 2 000 répondants, ni l'absence de biais
de non-réponse, ni une précision uniforme. Le présent document décrit le plan
initial ; la non-réponse, les réponses au questionnaire, les ajustements de poids
et les estimations finales sont des étapes ultérieures.

## 9. Fichiers de référence

Les chemins ci-dessous sont relatifs à la racine du projet.

| Fichier | Contenu |
|---|---|
| `config/config.yml` | Paramètres, graines et allocation fixée |
| `data/simulated/population_enseignants.rds` | Population synthétique de 100 000 unités |
| `metadata/taille_strates.csv` | Effectifs N_h et parts de population des huit strates |
| `metadata/allocation_echantillon.csv` | N_h, n_h, probabilités et poids, sans arrondi de présentation |
| `data/simulated/echantillon_initial.rds` | 2 000 unités, caractéristiques, strates et paramètres de sondage |
| `outputs/tables/controle_tirage_stratifie.csv` | Effectifs prévus et tirés, écarts et sommes de poids |
| `outputs/tables/controle_poids_strates.csv` | Audit individuel agrégé des poids par strate |
| `outputs/tables/controle_poids_total.csv` | Contrôle de la somme totale des poids |
| `tests/run_tests.R` | Exécution des tests et bilan des réussites et échecs |

Les RDS et les tableaux générés sous `outputs/` sont exclus de Git. Les sources,
la configuration, les métadonnées CSV et ce document sont versionnables. Toute
modification ultérieure de la population ou de l'allocation devra être répercutée
dans cette documentation.
