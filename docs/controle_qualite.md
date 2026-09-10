# Référentiel et exécution du contrôle qualité

> Données simulées à des fins de démonstration méthodologique. Les résultats présentés ne constituent pas des résultats officiels de la DEPP et ne décrivent pas la population réelle des enseignants.

Le référentiel [`plan_controles.csv`](../metadata/plan_controles.csv) contient
30 contrôles couvrant les douze familles demandées. Chaque ligne précise
l'identifiant, le champ, la règle, la gravité et l'action envisagée. Les actions
de nettoyage sont des propositions ultérieures, jamais exécutées par le script 05.
La colonne supplémentaire `seuil` paramètre les principaux seuils numériques.
Les modifications des règles doivent être répercutées dans les fonctions et tests.

```powershell
Rscript.exe R/05_quality.R
Rscript.exe tests/run_tests.R
```

Le script lit la base brute, l'échantillon, le suivi, la population synthétique,
le dictionnaire et l'ordre de passation. Les fichiers d'anomalies injectées
ne sont pas des entrées du détecteur. Les 93 colonnes attendues et leurs types
sont vérifiés avant les contrôles dépendants. Si des variables sont absentes
ou de type incompatible, ces contrôles sont NON_EVALUABLE ; aucun recodage
automatique ne tente de réparer le schéma.

## Interpréter les résultats

- `OK` : aucune anomalie parmi les éléments examinés, tous évaluables.
- `ANOMALIE` : au moins un signal ; le nombre non évaluable reste présenté.
- `NON_EVALUABLE` : aucun signal établi mais des informations insuffisantes.

Les indicateurs Qxxx prennent TRUE, FALSE ou NA. Ils sont enregistrés dans
un tableau distinct, avec le numéro de ligne source et l'identifiant. Le numéro
de ligne évite une jointure ambiguë si des identifiants sont dupliqués. Toutes
les occurrences des doublons sont signalées. Les comptes de signaux ne sont
pas des scores validés de qualité et leurs cumuls ne déterminent pas une exclusion.

Un échec critique entraîne un arrêt avec un code de sortie non nul, après
export des diagnostics. Les anomalies majeures ou mineures sont affichées et
conservées sans suppression de ligne. La base est relue et son empreinte vérifiée
pour garantir l'absence de modification.

## Principales conventions

La complétion est la proportion des 68 réponses présentes ; les réponses
invalides sont signalées séparément et ne sont pas assimilées à des absences.
Les modalités sont vérifiées selon le dictionnaire : 1 à 5, sauf CTRL03 binaire.
Le seuil de faible complétion est 80 %. Les seuils de durée combinent la charge
de réponse et une médiane de référence ; une durée invalide rend le diagnostic
non évaluable. Leur justification figure ci-dessous.

Le straightlining est recherché sur les 48 pratiques : part modale au moins
0,90 avec au moins 24 réponses valides, ou série d'au moins 20 réponses identiques.
Les valeurs absentes ou invalides rompent les séries. Les seuils sont exploratoires
et doivent être confrontés à la complétion, au statut et aux autres contrôles.

Les calculs psychométriques préliminaires utilisent seulement des copies
diagnostiques des valeurs valides : variance par item et corrélations de Spearman
par paires disponibles. Une dimension est non évaluable si ses 15 corrélations
ne sont pas toutes calculables. Ce filtrage de calcul ne modifie aucune cellule
source. Aucun alpha, score principal ou recodage définitif n'est produit.

Les taux de participation utilisent les enseignants uniques reçus, y compris
les abandons, rapportés au tirage initial. Un doublon n'augmente donc pas le taux.
Les ventilations par strate, degré et secteur utilisent les groupes du tirage.
Les poids sont comparés à leur référence ; ils ne sont pas recalés à 100 000.

## Sorties et validation initiale

Tous les tableaux sont dans `outputs/tables/qualite_*.csv` : synthèse des
30 contrôles, flags individuels, variables absentes/supplémentaires, types,
manquants, cellules invalides, variances, corrélations, fréquences et taux de
participation. Les sorties portent la mention de simulation et sont relues.
Elles sont ignorées par Git, comme les données individuelles.

L'exécution de référence signale 927 incomplets, 65 complétions faibles,
25 durées rapides, 30 fortes parts modales (3 non évaluables), 27 longues séries,
25 abandons, 55 écarts à CTRL01 (11 non évaluables) et 68 réponses Non à CTRL03
(134 non évaluables). Aucun contrôle critique n'échoue. Ces comptes se recouvrent.

Les tests vérifient aussi des anomalies ajoutées uniquement en mémoire : codes
invalides, identifiants répétés, durée absente, colonne manquante et mauvais type.
Ils ne modifient pas la base brute. `R/06_cleaning.R` reste une étape distincte.

## Indicateurs de straightlining

Le fichier `qualite_flags.csv` contient `nb_modalites_utilisees`,
`proportion_modalite_dominante`, `variance_intra_repondant`,
`longueur_max_sequence` et `flag_straightlining`. Les calculs utilisent les
48 pratiques valides, jamais les autres blocs. Les NA ou codes invalides
rompent une série ; ils ne sont pas supprimés de la séquence pour rapprocher
artificiellement deux réponses identiques. La variance est celle des codes
ordinaux : c'est un diagnostic descriptif, pas une distance psychométrique validée.

Le seuil de 90 % autorise au plus quatre réponses différentes sur 48 réponses
présentes. Le minimum de 24 réponses exige au moins la moitié du bloc ; sinon
le flag vaut NA. Ce compromis vise la quasi-constance plutôt qu'une simple
préférence pour une modalité. Il reste une convention exploratoire. Sur la
réalisation actuelle, les seuils 80 %, 90 % et 95 % signalent chacun 30 cas :
la sensibilité est faible dans ce scénario, sans garantir une robustesse réelle.
La part modale médiane vaut 33,33 %, le 95e percentile 45,83 % et le 99e 95,83 %.
Les distributions sont dans `qualite_distribution_straightlining.csv`.

## Rapidité : alerte et présomption forte

La médiane de référence est calculée parmi les durées strictement positives
et finies, pour les questionnaires non abandonnés remplis à au moins 80 %.
Au moins 30 observations sont exigées ; sinon les deux flags sont non évaluables.
Cette référence ne sélectionne pas les observations à partir de leurs flags.
Elle vaut ici 885,5 secondes sur 1 456 questionnaires.

`flag_rapide` vaut TRUE lorsque la durée est inférieure à la fois à trois
secondes par réponse renseignée et au tiers de cette médiane. Pour 68 réponses,
le seuil est min(204 ; 295,17), soit 204 secondes. Il diminue avec la complétion
pour ne pas pénaliser de la même manière un questionnaire court et un complet.
Le temps de lecture des questions laissées vides n'est pas connu : cette
approximation de charge doit être interprétée avec prudence.

`flag_tres_rapide` exige une durée inférieure au minimum d'une seconde par
réponse renseignée, de 60 secondes et du seuil rapide. Pour un questionnaire
complet, il s'agit de moins d'une minute pour 68 questions. C'est une présomption
forte d'un temps incompatible avec une lecture attentive de toutes les questions,
mais pas une preuve : chronométrage incomplet, reprise de session ou contexte
de passation doivent être examinés. Une durée invalide ou zéro réponse rend
ces flags non évaluables. Un cas très rapide est toujours aussi rapide.

Les facteurs 3 secondes, un tiers de médiane et 1 seconde sont des conventions
de vigilance argumentées par la charge et la distribution ; aucun prétest
n'a établi de temps minimal de lecture. Les comparaisons aux seuils fixes
60/120/180/300 secondes sont conservées dans `qualite_sensibilite.csv`.
La distribution complète demandée est dans `qualite_durees.csv`, sur les
durées valides sans exclusion des cas signalés. Les résultats sont 25 rapides
(1,64 % des reçus) et 16 très rapides (1,05 %).

## Statuts de complétion

Les indicateurs individuels sont `nb_items_attendus` (68), `nb_items_repondus`,
`nb_items_manquants`, `taux_completion` recalculé et `statut_completion`.
Le taux recalculé est exporté dans les diagnostics, sans remplacer le taux source.
Une réponse présente mais invalide compte comme renseignée ; sa validité est
traitée séparément par Q009. Toutes les questions sont attendues, sans filtre.

| Statut | Règle | Effectif actuel |
|---|---|---:|
| ABANDON | Statut de terrain Abandon, prioritaire | 25 |
| COMPLET | 68 réponses présentes, hors abandon | 594 |
| PARTIEL_ACCEPTABLE | Au moins 80 % et moins de 100 %, hors abandon | 862 |
| PARTIEL_FAIBLE | Moins de 80 %, hors abandon | 40 |

80 % exige au moins 55 réponses sur 68 et tolère au plus 13 absences. C'est
un seuil de suivi global provisoire, pas une règle de calcul des échelles :
les absences peuvent être concentrées dans une dimension. Le qualificatif
ACCEPTABLE n'autorise donc ni analyse automatique ni score définitif. Un statut
terrain manquant rend le classement non évaluable ; une incohérence de statut
reste signalée par Q028. Le tableau `qualite_completion.csv` inclut les quatre
catégories et une ligne NON_EVALUABLE, avec effectifs et proportions des reçus.

## Valeurs manquantes et tableau de bord

`missing_par_variable.csv` couvre les 93 colonnes et précise leur bloc et leur
position éventuelle. `missing_par_bloc.csv` couvre les 68 questions uniquement.
`missing_par_repondant.csv` conserve une ligne par questionnaire et distingue
les NA consécutifs terminaux des trous antérieurs à la dernière réponse.
Les totaux sont vérifiés entre les trois niveaux. Aucune valeur invalide
présente n'est assimilée à un NA dans ces tableaux.

La réalisation contient 988 NA terminaux consécutifs et 1 920 autres trous :
les absences sont donc à la fois dispersées et concentrées en fin de passation.
Les dix dernières questions ont 8,48 % de manquants contre 1,83 % pour les
58 premières. La position et le contenu étant liés, ce contraste ne démontre
pas à lui seul un effet causal de fatigue.

`missing_par_profil.csv` compare les taux de cellules manquantes par degré,
secteur, strate, territoire, équipement, statut, âge, formation et durée.
Il présente les dénominateurs et les abandons par groupe. Les taux sont de
3,11 % au collège contre 2,53 % au premier degré, et de 2,98 % dans le privé
contre 2,78 % dans le public. Selon la strate, ils vont de 2,19 % (P1 public
REP+) à 4,47 % (collège public REP+). Ces différences descriptives n'établissent
pas une dépendance systématique au profil ; elles peuvent refléter le tirage
des anomalies et la présence de quelques abandons dans de petits groupes.

La corrélation de Spearman entre durée et proportion individuelle de manquants
vaut −0,111, et −0,070 hors abandons (`missing_lien_duree.csv`). L'association
est faible et en partie liée aux abandons. Le groupe de 120 à 599 secondes a
10,60 % de manquants et 21 abandons ; les durées inférieures à 120 secondes
ont 2,71 % de manquants sans abandon. On ne peut donc assimiler durée courte
et forte non-réponse. Ces diagnostics non pondérés n'identifient pas à eux
seuls un mécanisme MCAR, MAR ou MNAR.

`dashboard_qualite.csv` contient une ligne avec les indicateurs demandés.
Le taux de réponse utilise les identifiants reçus présents dans l'échantillon
rapportés aux sélectionnés ; le taux global de manquants porte sur les 68
questions. `nb_partiels` exclut les abandons ; `nb_doublons` compte les
occurrences excédentaires d'identifiants non manquants (les flags de doublons
signalent quant à eux toutes les occurrences). `nb_valeurs_hors_bornes`
compte les cellules questionnaire hors domaine, non les personnes ; les
bornes contextuelles figurent séparément dans les contrôles Q010/Q011/Q027.

`synthese_qualite.txt` présente CRITIQUE, MAJEUR, MINEUR et INFORMATIF. Les
comptes de contrôles ne s'additionnent pas en personnes distinctes. Les NA,
rapidités ou constances volontairement injectés sont des anomalies métier
attendues : leur détection constitue une réussite du test, pas un échec.
Une erreur technique empêche un calcul fiable ; une incohérence critique du
contrat de livraison bloque également la suite après export des diagnostics.

`tests/testthat/test_quality.R` vérifie les contrats de données et la cohérence
du tableau de bord. Les tests complémentaires de `test-quality.R` éprouvent le
détecteur sur des copies altérées en mémoire. Aucune imputation n'est réalisée.
