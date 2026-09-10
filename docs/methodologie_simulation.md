# Méthodologie de simulation — DEPP_B4_Pratiques_Enseignantes

Version du 10 septembre 2026. Cette note décrit le générateur actuellement
implémenté, jusqu'à la livraison brute et ses tests, avant nettoyage et analyse
psychométrique. Les paramètres détaillés figurent dans
[`config/config.yml`](../config/config.yml). Un inventaire tabulaire est fourni
dans [`metadata/parametres_simulation.csv`](../metadata/parametres_simulation.csv),
régénérable depuis la racine avec
`Rscript.exe metadata/generer_parametres_simulation.R`. Le YAML reste la source
des paramètres ; les valeurs de vecteurs sont repérées par leur position.

> Données simulées à des fins de démonstration méthodologique. Les résultats présentés ne constituent pas des résultats officiels de la DEPP et ne décrivent pas la population réelle des enseignants.

**Les dépendances statistiques intégrées aux données sont des hypothèses de simulation et ne constituent pas des résultats empiriques sur les enseignants.**

## 1. Pourquoi utiliser des données simulées ?

Le projet est un démonstrateur personnel de méthodologie d'enquête : il permet
de construire et vérifier une chaîne de traitements sans disposer de réponses
individuelles réelles. Les enseignants sont fictifs ; aucune base administrative
ou enquête réelle n'a été pseudonymisée pour produire ces données.

La simulation permet de connaître le plan de sondage, les mécanismes générateurs
et les anomalies injectées. Ces références servent à tester les programmes et,
ultérieurement, à évaluer certaines méthodes. Elles doivent être distinguées
des informations disponibles pour un statisticien recevant une collecte.
La plausibilité des distributions est un choix de construction et non une
validation empirique de leur représentativité.

## 2. Population synthétique

`R/01_population.R` construit une population finie de 100 000 enseignants,
avec un identifiant unique par personne. Le périmètre comprend le premier
degré et le collège, le public et le privé sous contrat, les contextes hors EP,
REP et REP+, et les territoires urbains, périurbains et ruraux.

Les caractéristiques sont générées conditionnellement les unes aux autres :

- Le degré suit des probabilités de 0,58 pour le premier degré et 0,42 pour
  le collège. Sexe, secteur et territoire ont des distributions dépendant du
  degré. Ces probabilités ne proviennent pas d'un calage officiel.
- L'éducation prioritaire dépend du territoire dans le public. Le privé est
  toujours hors EP par convention de simulation.
- L'âge suit une normale arrondie, avec rejet des valeurs hors de 23 à 65 ans.
  Les moyennes paramétrées sont 43 et 44 ans selon le degré, avec un écart-type
  de 10 ans. Le rejet évite de rabattre les valeurs extrêmes sur les bornes.
- L'ancienneté tient compte d'un âge d'entrée dans le métier et d'interruptions
  simulées. Elle reste non négative et compatible avec l'âge. L'ancienneté
  dans le niveau de classe est une fraction de l'ancienneté totale, obtenue
  à partir d'une loi bêta.
- L'effectif de classe dépend du degré, de l'EP, du territoire et du secteur,
  avec un bruit normal et des bornes de 12 à 35 élèves.
- Statut, formation continue et équipement numérique suivent des mécanismes
  conditionnels paramétrés. La formation est exprimée en jours, bornés de 0 à
  20 ; l'équipement prend les modalités Faible, Moyen et Bon.
- La discipline du premier degré est « Polyvalent premier degré ». Dix
  disciplines principales sont possibles au collège.

Les contrôles vérifient les dimensions, les identifiants, les modalités, les
bornes, les valeurs manquantes et les cohérences entre variables. La réalisation
de référence comprend 57 882 enseignants du premier degré et 42 118 du collège.
La base est enregistrée dans `data/simulated/population_enseignants.rds`.

## 3. Sondage stratifié

`R/02_sampling.R` réalise un tirage aléatoire simple sans remise dans chacune
des huit strates opérationnelles, soit 2 000 enseignants au total. L'unité de
tirage est directement l'enseignant : aucun établissement n'est tiré au préalable
et aucune structure en grappes n'est modélisée.

| Strate | Population N_h | Allocation n_h |
|---|---:|---:|
| P1_PUBLIC_HEP | 40 078 | 620 |
| P1_PUBLIC_REP | 7 011 | 130 |
| P1_PUBLIC_REPPLUS | 2 659 | 100 |
| P1_PRIVE | 8 134 | 150 |
| COL_PUBLIC_HEP | 26 267 | 600 |
| COL_PUBLIC_REP | 4 871 | 150 |
| COL_PUBLIC_REPPLUS | 2 036 | 100 |
| COL_PRIVE | 8 944 | 150 |
| Total | 100 000 | 2 000 |

Les strates constituent une partition exhaustive et exclusive. L'allocation
est fixée et non proportionnelle ; elle assure des effectifs dans les petits
groupes. La variable descriptive `strate`, qui inclut le territoire, reste
distincte de `strate_sondage` utilisée pour le tirage.

Pour chaque enseignant de la strate h :

\[
\pi_h = \frac{n_h}{N_h},\qquad
w_h = \frac{1}{\pi_h} = \frac{N_h}{n_h}.
\]

Avant non-réponse, la somme des poids de chaque strate vaut N_h et la somme
totale vaut 100 000, à l'arrondi numérique près. Cette égalité résulte du
plan, sans modification arbitraire des poids. Voir le [plan de sondage](plan_sondage.md).

## 4. Non-réponse totale

`R/03_nonresponse.R` définit une probabilité individuelle de participation
par un modèle logistique dépendant du degré, du secteur, de l'EP, de la
formation, de l'équipement, de l'ancienneté et de l'effectif de classe.
L'intercept est résolu pour que la moyenne des probabilités sur les 2 000
enseignants soit 0,75. Une indicatrice de réponse est ensuite tirée selon une
Bernoulli, indépendamment entre enseignants conditionnellement au contexte.

Le taux réalisé n'est pas imposé : la référence compte 1 521 participants et
479 non-répondants totaux, soit 76,05 %. Le mécanisme dépend de caractéristiques
disponibles pour toutes les unités tirées ; il relève d'une hypothèse MAR
conditionnellement à ces caractéristiques pour les réponses au questionnaire.
Il n'intègre pas de dépendance directe à des réponses inobservées.

Les poids de base restent inchangés. Leur somme chez les seuls participants
n'est pas forcée à 100 000. Aucune correction de non-réponse n'est encore
appliquée. Voir le [mécanisme de non-réponse](non_reponse.md).

## 5. Dimensions latentes continues

Le script 04 attribue un vecteur de huit traits à chaque enseignant de
l'échantillon initial, puis sélectionne les participants par identifiant.
Le changement du nombre de participants ne redistribue donc pas les traits.
Les dimensions sont EXP, DIF, EVA, GCL, COL, NUM, DEV et REL.

Le socle suit une loi normale multivariée :

\[
L_i^{(0)} \sim \mathcal N_8(0,R).
\]

La diagonale de R vaut 1. Les corrélations sont de 0,20 sauf pour les paires
EXP–EVA (0,45), DIF–EVA (0,40), DIF–DEV (0,40), COL–DEV (0,45), NUM–DEV (0,25)
et REL–GCL (0,30). La matrice est symétrique et définie positive ; sa plus
petite valeur propre est d'environ 0,42436.

Avec la décomposition de Cholesky R = U' U, une matrice de normales standard
indépendantes Z est transformée en ZU. Les corrélations empiriques ne sont
pas forcées à reproduire exactement R. Elles sont affichées et comparées à
la théorie, avec les écarts dus au tirage fini. Aucune corrélation théorique
ne dépasse 0,70. Voir les [dimensions latentes](dimensions_latentes.md).

## 6. Effets contextuels

Les traits utilisés pour les items sont construits par addition :

\[
L_{id}=L_{id}^{(0)}+X_i\beta_d.
\]

Les prédicteurs sont centrés et réduits sur les 2 000 enseignants avant
non-réponse : log(1 + jours de formation), équipement codé 0/1/2 et
log(1 + ancienneté). L'espacement égal des niveaux d'équipement est une
convention ; le logarithme permet une association non linéaire avec l'ancienneté.

| Prédicteur standardisé | Dimensions et coefficients |
|---|---|
| Formation | DIF : 0,18 ; EVA : 0,15 ; DEV : 0,25 |
| Équipement | NUM : 0,35 |
| Ancienneté | EXP : 0,12 ; GCL : 0,18 ; REL : 0,08 |

Les autres coefficients sont nuls. L'association COL–DEV existe déjà dans
le socle ; aucun effet causal de collaboration n'est ajouté. Les traits
contextuels sont sauvegardés séparément du socle. Leurs moyennes et variances
ne sont pas forcées à 0 et 1 ; les corrélations sont recalculées et contrôlées.

## 7. Génération des 48 items ordinaux

Chaque dimension comporte six items. Pour l'item j rattaché à la dimension d :

\[
Y^*_{ij}=\lambda_j L_{id}-\varepsilon_{ij},\qquad
\varepsilon_{ij}\sim\mathcal N(0,\sigma_j^2).
\]

Les erreurs sont indépendantes des traits et entre items et enseignants.
Soustraire une erreur normale centrée équivaut en loi à l'ajouter. Les items
partagent leurs traits et ne sont donc pas tirés indépendamment marginalement.

Les coefficients lambda_j sont tirés entre 0,50 et 0,80. L'écart-type d'erreur
vaut sqrt(1 − lambda_j²) multiplié par un facteur entre 0,90 et 1,10.
Ces coefficients générateurs ne sont pas exactement des saturations
standardisées après l'ajout des effets contextuels.

Quatre seuils de base (−1,20 ; −0,35 ; 0,40 ; 1,20) reçoivent un décalage propre
à la dimension, une difficulté d'item entre −0,35 et 0,35 et une perturbation
propre à chaque seuil entre −0,10 et 0,10. Ils doivent rester strictement
croissants. Avec les bornes infinies t_j0 et t_j5, Y_ij = k lorsque
t_j(k−1) < Y*_ij ≤ t_jk. Les catégories sont Jamais, Rarement, Parfois,
Souvent et Très souvent, codées de 1 à 5.

Les paramètres précis sont dans [`metadata/parametres_items.csv`](../metadata/parametres_items.csv).
Aucun alpha cible n'est imposé et aucun paramètre n'est ajusté pour obtenir
un résultat psychométrique particulier. Voir la [simulation des items](simulation_items.md).

## 8. Faisabilité, priorité et contrôles

Huit FAIS dépendent de l'équipement, de la taille de classe et de la formation,
avec un bruit individuel commun et des erreurs spécifiques. Huit PRIO reposent
sur des préférences latentes dont la composante autonome est majoritaire,
partiellement associées aux pratiques. Ces réponses sont ordinales de 1 à 5,
mais leurs libellés diffèrent de ceux des fréquences de pratiques.

Des moyennes `SCORE_PROV_*` des six items complets et des écarts
`GAP_* = PRIO_* − SCORE_PROV_*` sont disponibles dans une référence exploratoire.
Ils ne sont pas validés psychométriquement. Une différence entre priorité et
fréquence ne constitue pas une mesure établie de besoin. Aucun score définitif
n'est calculé. Voir [faisabilité et priorité](faisabilite_priorite.md).

CTRL01 est une consigne de lecture, CTRL03 une vérification binaire du champ
de référence. CTRL02 et CTRL04 portent respectivement sur la lecture incomplète
et les difficultés de précision. Leurs recodages sont CTRL02_reverse = 6 − CTRL02
et CTRL04_reverse = 6 − CTRL04. Aucun contrôle n'entre dans les échelles
principales. Ils ne sont pas automatiquement couplés aux anomalies injectées
ensuite. Voir les [contrôles](controles.md).

## 9. Données manquantes et anomalies

`R/04_donnees_imparfaites.R` produit une nouvelle version sans écraser les
réponses complètes. Les opérations sont appliquées dans cet ordre :

1. Trente enseignants reçoivent une même modalité sur 46 des 48 pratiques.
2. Vingt-cinq abandons sont simulés par suppression de toutes les réponses
   après une position tirée entre 20 et 48 dans l'ordre réel des 68 questions.
3. Quarante autres enseignants perdent 18 réponses dispersées.
4. Chaque réponse encore présente a une probabilité de 0,005 d'être masquée.
5. Chaque réponse encore présente des dix dernières questions a une probabilité
   supplémentaire de 0,06 d'être masquée.
6. Vingt-cinq durées sont remplacées par un entier entre 20 et 90 secondes.

Les durées ordinaires proviennent d'une loi lognormale de médiane 900 secondes
et d'écart-type logarithmique 0,30, multipliée par la complétion, avec minimum
300 secondes. Les dates de dernière activité sont tirées du 1er au 10 septembre
2026. Aucun doublon technique n'est injecté dans le scénario courant.

Les groupes partiels et abandons sont disjoints ; les groupes de constance et
de rapidité peuvent les recouper. Chaque valeur manquante reçoit une seule
cause dans le registre, selon l'ordre d'injection. Les masquages ne dépendent
pas directement de la valeur de réponse ; la probabilité varie néanmoins
selon la position et le scénario. Ce mécanisme ne reproduit pas les refus ou
omissions dépendant d'un contenu sensible ou d'une réponse inobservée.

| Injection | Enseignants concernés | Cellules effectivement modifiées |
|---|---:|---:|
| Réponses quasi constantes | 30 | 1 087 |
| Abandons | 25 | 856 |
| Partiels imposés | 40 | 720 |
| Manquants aléatoires | 407 | 475 |
| Manquants supplémentaires de fin | 671 | 857 |
| Durées courtes | 25 | 25 |

Les 1 380 cellules ciblées de constance incluent 293 réponses déjà égales à
la modalité imposée. Les effectifs de personnes ne s'additionnent pas, car
les mécanismes peuvent se chevaucher. La réalisation comporte 2 908 réponses
manquantes, 594 questionnaires complets, 902 partiels et 25 abandons.
Les [imperfections](donnees_imparfaites.md) sont décrites avec un registre
individuel et un bilan agrégé dans `outputs/tables/`.

## 10. Livraison, reproductibilité et contrôles

`R/04_questionnaire_brut.R` assemble une livraison de 1 521 lignes et 93 colonnes
dans `data/simulated/questionnaire_brut.rds`. Elle contient les caractéristiques,
les informations de sondage, les 68 réponses et cinq variables de terrain.
Aucune ligne, réponse ou anomalie n'est corrigée. Les 479 non-répondants totaux
restent dans le suivi séparé.

Les traits, probabilités théoriques de réponse, indicateurs d'injection,
scores provisoires et recodages sont absents de cette livraison. Les vérités
de simulation doivent servir à évaluer les détecteurs, et non leur être
fournies comme variables de décision. Voir la [base brute](questionnaire_brut.md).

| Étape aléatoire | Graine |
|---|---:|
| Population | 20260909 |
| Sondage | 20260910 |
| Socle latent | 20260911 |
| Non-réponse totale | 20260912 |
| Paramètres des items | 20260913 |
| Erreurs des items | 20260914 |
| Faisabilité et priorité | 20260915 |
| Contrôles | 20260916 |
| Imperfections | 20260917 |

Les graines sont fixées par `set.seed()` et les algorithmes aléatoires sont
explicités dans les fonctions. Les chemins sont relatifs ; renv et son fichier
de verrouillage décrivent l'environnement R. Les assemblages et audits sont
déterministes et n'exigent pas de nouvelle graine. Les sauvegardes RDS sont
relues ; une sortie existante différente n'est pas écrasée silencieusement.

Les tests couvrent la taille initiale de 2 000, l'unicité des identifiants,
les modalités, les variances latentes, les corrélations moyennes intra-dimension,
les anomalies et la conservation des données. La dernière validation du code
de simulation compte 43 blocs et 348 vérifications réussis, sans échec.
L'[audit de référence](audit_base_brute.md) décrit les distributions de la
livraison et les seuils exploratoires de vigilance, sans nettoyage.

## 11. Limites d'interprétation

Les proportions, associations, profils, fiabilités et résultats de modèles
calculés ultérieurement décriront d'abord le générateur et sa réalisation.
Ils ne fourniront ni estimations nationales ni preuves causales sur les
enseignants. Le plan permet une inférence vers la population synthétique,
sous les hypothèses nécessaires, mais pas vers une population réelle.

La structure à huit facteurs est introduite dès le départ. Retrouver des
facteurs ou des corrélations cohérentes ne valide donc pas empiriquement le
questionnaire. Les erreurs indépendantes, l'absence d'effets d'établissement,
les seuils fixes entre groupes et le mécanisme simple de déclaration rendent
le problème plus régulier qu'une enquête réelle. Aucun fonctionnement
différentiel des items ni invariance de mesure n'est démontré.

La normalité des traits et les choix de seuils influencent les distributions,
les effets plafond/plancher, les corrélations et les classifications. Un
profil issu d'une classification ne prouvera pas l'existence d'une catégorie
naturelle d'enseignants. Les codes ordinaux ne garantissent pas l'égalité
des distances entre modalités.

Les anomalies sont contrôlées et parfois faciles à détecter, notamment les
durées séparées des durées ordinaires. Les performances d'un détecteur sur
ce scénario ne se transposent pas directement à une collecte réelle. Il
faudra examiner faux positifs, faux négatifs et sensibilité aux seuils, sans
assimiler un signal isolé à une réponse invalide.

Une seule réalisation reproductible ne démontre pas la robustesse d'une
méthode. Des répétitions Monte-Carlo et des scénarios alternatifs seraient
nécessaires pour évaluer biais, précision, couverture des intervalles et
stabilité des résultats. La validation de contenu, le prétest cognitif et
l'analyse psychométrique restent à conduire ; aucun item ne sera supprimé
sur le seul critère de l'alpha de Cronbach.
