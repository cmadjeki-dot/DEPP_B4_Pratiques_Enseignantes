# DEPP_B4_Pratiques_Enseignantes

Démonstrateur professionnel de statistique publique, de méthodologie d'enquête
et de psychométrie consacré aux pratiques enseignantes déclarées. Ce projet
personnel vise à illustrer les compétences mobilisées dans les études sur ces
pratiques ; il ne constitue pas une publication institutionnelle.

> Données simulées à des fins de démonstration méthodologique. Les résultats
> présentés ne constituent pas des résultats officiels de la DEPP et ne décrivent
> pas la population réelle des enseignants.

## Question et périmètre

Quels profils de pratiques professionnelles peut-on identifier parmi les
enseignants à partir de leurs pratiques déclarées ?

La population cible du démonstrateur comprend **100 000 enseignants fictifs**,
avec un **échantillon tiré de 2 000 enseignants** avant non-réponse. Le périmètre
couvre le premier degré et le collège, le public et le privé sous contrat,
les contextes hors éducation prioritaire, REP et REP+, ainsi que les territoires
urbains, périurbains et ruraux. Les combinaisons admissibles et les répartitions
seront précisées dans le protocole ; elles ne seront pas des estimations réelles.

Le questionnaire prévu comporte huit dimensions de six items : EXP (enseignement
explicite), DIF (différenciation), EVA (évaluation formative et feedback), GCL
(gestion de classe), COL (collaboration), NUM (numérique), DEV (développement
professionnel) et REL (relations éducatives). Les 48 items vont de 1 « Jamais »
à 5 « Très souvent ». S'y ajoutent huit indicateurs de faisabilité `FAIS_*`, huit
de priorité `PRIO_*` et quatre contrôles `CTRL01` à `CTRL04`.

Les 68 variables sont documentées dans
[le dictionnaire](metadata/dictionnaire_variables.csv), avec leurs libellés,
modalités, bornes et conventions de score. Les
[conventions du questionnaire](questionnaire/conventions_dictionnaire.md)
précisent les périodes de référence et le statut non validé de cet instrument
de démonstration. Les 48 réponses principales sont désormais simulées. Les quatre contrôles
sont exclus des scores ; une anomalie isolée ne justifie pas une exclusion.

Le [questionnaire complet](questionnaire/questionnaire_complet.md) présente les
68 questions avec consignes et cases à cocher. L'ordre de présentation est
enregistré dans [ordre_passation.csv](questionnaire/ordre_passation.csv).
Le contrôle de lecture et l'autoévaluation CTRL02 sont espacés, et les questions de retour sur la
passation figurent à la fin. Ce document vierge n'enregistre aucune réponse.

Pour régénérer ces deux documents à partir du dictionnaire, depuis la racine :

```powershell
Rscript.exe --vanilla questionnaire/generer_questionnaire.R
```

Ce générateur utilise uniquement R de base ; `--vanilla` évite ici l'activation
de renv, sans incidence sur la mise en forme déterministe. Il contrôle les
68 codes, les libellés, les modalités et la relecture des sorties.

## Démarche prévue

Le socle de simulation des traits continus est désormais disponible dans
`R/04_questionnaire_simulation.R` : voir la
[note sur les dimensions latentes](docs/dimensions_latentes.md).
Le [mécanisme de non-réponse](docs/non_reponse.md), implémenté dans
`R/03_nonresponse.R`, identifie désormais les répondants simulés par un modèle
logistique puis un tirage de Bernoulli. Le taux attendu est 75 %, sans quota
sur le taux réalisé. Le script 04 conserve les traits attribués initialement
et sélectionne les répondants par identifiant.
Le script introduit ensuite des effets contextuels modérés et génère les 48
items ordinaux : voir la [méthode de simulation](docs/simulation_items.md).
Les variables FAIS et PRIO ainsi que les scores moyens provisoires et les GAP
exploratoires sont décrits dans [la note dédiée](docs/faisabilite_priorite.md).
Les quatre contrôles et les deux recodages inverses sont également simulés :
voir [leurs conventions et limites](docs/controles.md).
Une [version imparfaite de la collecte](docs/donnees_imparfaites.md) est créée
par `R/04_donnees_imparfaites.R` pour tester ultérieurement les contrôles qualité.
La [livraison brute](docs/questionnaire_brut.md), créée par
`R/04_questionnaire_brut.R`, constitue l'entrée du futur contrôle qualité.
Le [contrôle qualité](docs/controle_qualite.md) est désormais implémenté dans
`R/05_quality.R`, avec 30 règles et des diagnostics séparés de la base source.
Le [nettoyage traçable](docs/nettoyage.md), dans `R/06_cleaning.R`, conserve
toutes les décisions et produit des bases incluses et exclues distinctes.
La [pondération](docs/ponderation.md) corrige la non-réponse analytique par
strate puis calibre les poids sur des totaux synthétiques connus.
La [synthèse qualité et pondération](docs/qualite_et_ponderation.md) documente
les diagnostics, le plan `design_depp` et la sensibilité aux poids.
Les [descriptifs pondérés](docs/analyses_descriptives.md) sont produits par
`R/08_descriptive.R` : Table 1, items, huit graphiques et comparaisons exploratoires.

1. Cadrer l'étude, le protocole, le questionnaire et les métadonnées.
2. Construire la population synthétique, le plan de sondage et l'échantillon.
3. Simuler réponses et non-réponse, puis contrôler et nettoyer les données.
4. Calculer les poids de sondage, corriger la non-réponse et calibrer les poids.
5. Produire des descriptifs et des intervalles tenant compte du plan de sondage.
6. Examiner les échelles (alpha, oméga, corrélations polychorïques, KMO,
   Bartlett, analyse parallèle et analyse factorielle exploratoire).
7. Identifier des profils par classification, ajuster des modèles et étudier
   la sensibilité des résultats aux choix méthodologiques.
8. Produire les tableaux, graphiques, rapport scientifique et note de synthèse.

La simulation reposera sur des variables latentes corrélées, des effets
contextuels modérés et du bruit. Aucun alpha précis ne sera imposé ; aucun item
ne sera retenu ou supprimé sur le seul critère de l'alpha. Les associations
simulées ne permettront pas de conclure à des effets causaux réels.

## Organisation

| Chemin | Rôle |
|---|---|
| `config/`, `metadata/`, `questionnaire/` | Paramètres, dictionnaire, allocation, contrôles et instrument |
| `R/00_packages.R` | Vérification, installation des absents et chargement des packages |
| `R/01_population.R` à `R/13_outputs.R` | Étapes de traitement, à développer |
| `R/functions/`, `tests/testthat/` | Fonctions réutilisables et tests |
| `data/raw/`, `data/simulated/`, `data/interim/`, `data/processed/` | Données locales, exclues de Git |
| `outputs/figures/`, `outputs/tables/`, `outputs/models/` | Sorties reproductibles, exclues de Git |
| `reports/`, `presentation/`, `docs/` | Sources des rapports, présentation et publication future |

Les fichiers `.gitkeep` préservent les dossiers vides. Toutes les données
individuelles, y compris celles éventuellement placées dans `data/raw/`, sont
simulées. Aucun fichier de données réelles n'est attendu.

## Environnement R reproductible

**Initialisation validée** : renv 1.2.3 est actif et `renv.lock` a été généré.
Les quinze packages prévus ont été chargés par `R/00_packages.R`, sans installation
supplémentaire après préparation de la bibliothèque. `renv::status()` confirme
la cohérence du projet. Les packages déjà disponibles ont été réutilisés ; les
absents de la bibliothèque du projet et leurs dépendances ont été installés.

Lors du test sous R 4.6.0, les neuf packages directs nouvellement installés ont
signalé avoir été construits sous R 4.6.1. Leur chargement a réussi, mais cela
ne remplace pas les tests des futures analyses. Cet avertissement de version est
conservé explicitement ; aucune mise à jour de R n'a été effectuée.

Environnement de référence : Windows, R 4.6.0 et Quarto 1.10.18.
`renv.lock` enregistre les versions des packages et de R ; il n'installe pas R,
Git ou Quarto. La configuration `.vscode/settings.json` contient des chemins
Windows locaux à adapter sur une autre machine.

Depuis la racine du projet, dans un nouveau terminal PowerShell de VS Code :

```powershell
Rscript.exe -e 'renv::restore(prompt = FALSE)'
Rscript.exe R/00_packages.R
Rscript.exe -e 'renv::status()'
```

Le fichier `.Rprofile` active renv au démarrage. Ne pas utiliser `--vanilla`
pour les commandes ordinaires du projet : cette option désactive cette activation.
Sur une nouvelle machine, l'amorçage de renv et la restauration peuvent nécessiter
un accès réseau. `restore()` permet de retrouver les versions verrouillées.

Le script déclare les quinze packages prévus et, par défaut, les vérifie et les
charge tous. Seuls les absents sont installés, avec leurs dépendances requises.
Pour une étape ciblée, dans R :

```r
options(depp.packages = c("survey", "srvyr"))
source("R/00_packages.R", encoding = "UTF-8")
```

Les masquages de fonctions entre packages sont possibles : privilégier les appels
explicites comme `dplyr::filter()` dans les traitements. `knitr` et `rmarkdown`
sont également conservés pour les rapports Quarto.

Après un changement intentionnel des dépendances et validation du code :

```r
renv::snapshot()
renv::status()
```

Le mode de snapshot `all` enregistre la bibliothèque isolée du projet, afin
de couvrir les chargements dynamiques du script. N'y installer que les packages
utiles au projet. Versionner `.Rprofile`, `renv/activate.R`, `renv/settings.json`
et `renv.lock`, mais pas les bibliothèques locales.

## État du projet et règles de travail

L'architecture, le `.gitignore`, renv et la génération de la population sont en
place. Le script 02 construit les huit strates, leur allocation et tire les 2 000 enseignants ;
Le questionnaire, la non-réponse et la simulation des 48 items principaux sont
également disponibles. Les variables complémentaires, les étapes de qualité
et d'analyse et les rapports restent à développer.

### Générer la population synthétique

Depuis la racine du projet :

```powershell
Rscript.exe R/01_population.R
```

Pour exécuter les tests depuis une console R ouverte à la racine :

```r
testthat::test_dir("tests/testthat", stop_on_failure = TRUE)
```

`config/config.yml` contient la taille (100 000), la graine (20260909), le chemin
de sortie et les paramètres des distributions. Ces paramètres sont des choix
de démonstration et ne proviennent pas de statistiques officielles. La taille
de l'échantillon est fixée à 2 000 ; son tirage est réalisé par le script 02.

Les contextes d'exercice dépendent du degré. Dans le public, l'éducation
prioritaire dépend du territoire ; le privé sous contrat est toujours hors EP.
L'âge est tiré dans une loi normale arrondie et tronquée entre 23 et 65 ans.
L'ancienneté dépend d'un âge d'entrée et d'interruptions simulées. L'effectif
de classe dépend du degré, de l'EP, du territoire et du secteur, avec du bruit
et des bornes de 12 à 35 élèves. Formation et équipement comportent des
associations contextuelles modérées. Ces choix n'ont aucune portée causale.

| Variable | Définition dans cette simulation |
|---|---|
| `id_enseignant` | Identifiant unique fictif, préfixé par `ENS` |
| `degre`, `secteur`, `education_prioritaire`, `territoire` | Contexte d'exercice et variables du plan de sondage |
| `sexe` | Modalité simulée Femme/Homme ; codage limité retenu pour le démonstrateur |
| `age` | Âge entier en années |
| `anciennete` | Années d'exercice, hors interruptions simulées |
| `anciennete_classe` | Années dans le niveau de classe principalement enseigné, et non avec une même cohorte d'élèves |
| `effectif_classe` | Effectif du groupe ou de la classe principalement enseignée, pas le total des élèves suivis au collège |
| `statut` | Statut simulé, avec des libellés distincts pour le public et le privé |
| `formation_continue` | Nombre entier de jours de formation sur les douze derniers mois, de 0 à 20 |
| `equipement_numerique` | Niveau d'équipement pédagogique disponible : Faible, Moyen ou Bon |
| `discipline` | Polyvalence au premier degré ; discipline principale parmi dix modalités au collège |
| `strate` | Croisement degré × secteur × EP × territoire, soit 24 combinaisons admissibles |

La population contrôlée est enregistrée dans
`data/simulated/population_enseignants.rds`, ignoré par Git. Le RDS conserve en
attributs l'avertissement, la graine et les paramètres de simulation. Le script
affiche les répartitions et résumés demandés et vérifie la relecture du RDS.
Une relance identique conserve le fichier ; une configuration produisant une
population différente impose un nouveau nom de sortie pour éviter d'écraser
un résultat antérieur. Les tests couvrent la reproductibilité et le rejet
d'anomalies : doublons, valeurs impossibles, modalités et incohérences métier.

### Auditer la population enregistrée

```powershell
Rscript.exe R/01_audit_population.R
```

L'audit lit le RDS, contrôle le schéma, les types, les distributions, les bornes,
les cohérences et les strates, puis compare toutes les données et leurs attributs
avec une nouvelle génération en mémoire. Il ne modifie ni le RDS ni le plan de
sondage. Il produit `outputs/tables/audit_population.md` et cinq tableaux CSV
UTF-8 (`controles`, `variables`, `bornes`, `categories`, `strates`), ignorés par Git.

L'audit initial donne 26 contrôles OK et un point de vigilance : deux strates
REP+ rurales comptent moins de 200 enseignants fictifs (70 au collège et 119
au premier degré). Les seuils de 100 et 200 sont des repères descriptifs pour
l'audit, sans valeur normative. Ces petits effectifs ne justifient pas une
correction de la population ; ils seront à examiner lors de la future allocation.

### Construire les huit strates opérationnelles

```powershell
Rscript.exe R/02_sampling.R
```

Le script conserve les 24 strates descriptives dans `strate` et ajoute en mémoire
`strate_sondage` à l'objet `population_sondage`. Les territoires sont regroupés
pour former huit strates : `P1_PUBLIC_HEP`, `P1_PUBLIC_REP`, `P1_PUBLIC_REPPLUS`,
`P1_PRIVE`, `COL_PUBLIC_HEP`, `COL_PUBLIC_REP`, `COL_PUBLIC_REPPLUS`, `COL_PRIVE`.
Le RDS source n'est pas réécrit. Chaque enseignant doit satisfaire exactement
une des huit règles d'appartenance.

`metadata/taille_strates.csv` contient les effectifs simulés `N_h` et les parts
`part_population = N_h / N` (proportions entre 0 et 1, pas pourcentages).
Le CSV est en UTF-8, avec virgule comme séparateur et point décimal ; le lire
avec `read.csv("metadata/taille_strates.csv")`. Il est destiné à être versionné.
Ces données sont simulées à des fins de démonstration méthodologique et ne sont
pas des statistiques officielles de la DEPP.

La plus petite strate opérationnelle compte 2 036 enseignants, soit davantage
que la taille totale prévue de l'échantillon (2 000). La capacité est donc
suffisante pour l'allocation retenue, vérifiée avant le tirage.

### Allocation et poids de base

`echantillon.allocation` dans `config/config.yml` fixe les effectifs :
620, 130, 100 et 150 pour les quatre strates du premier degré ;
600, 150, 100 et 150 pour celles du collège, dans l'ordre présenté ci-dessus.
Le total est de 2 000, dont 1 000 par degré. Cette allocation fixée pour le
démonstrateur est disproportionnée par rapport aux effectifs de population.

Le même script `R/02_sampling.R` produit `metadata/allocation_echantillon.csv` :
`strate_sondage`, `N_h`, `n_h`, `pi_h = n_h / N_h` et `poids_base = 1 / pi_h`.
Les probabilités correspondent au tirage aléatoire simple sans remise
à taille fixe dans chaque strate. Les poids sont antérieurs aux corrections
de non-réponse et de calibration. Les valeurs sont exportées sans arrondi
d'affichage, en CSV UTF-8 avec virgule comme séparateur et point décimal.

Les contrôles vérifient les codes uniques, la concordance des strates, les
effectifs entiers positifs, le total fixé, `n_h <= N_h`, `0 < pi_h <= 1`,
des poids finis positifs et `sum(n_h * poids_base) = sum(N_h)`.
Le CSV est relu et comparé au tableau calculé avant de terminer le script.

### Tirage stratifié sans remise

Le script `R/02_sampling.R` poursuit avec le tirage de 2 000 enseignants à l'aide
de `sample.int(..., replace = FALSE)` dans chaque strate. La graine dédiée
`echantillon.graine = 20260910` figure dans `config/config.yml`. Les algorithmes
aléatoires sont explicitement fixés (Mersenne-Twister, Inversion, Rejection).

L'objet `echantillon` conserve les caractéristiques de la population, `strate`,
`strate_sondage`, `N_h`, `n_h`, `pi_h` et `poids_base` (20 colonnes). Il est
sauvegardé dans `data/simulated/echantillon_initial.rds`, avec les paramètres du
tirage et l'avertissement sur les données simulées dans ses attributs.
Le tableau `outputs/tables/controle_tirage_stratifie.csv` compare les effectifs
prévus et observés, et vérifie les sommes de poids par strate. Les deux sorties
sont ignorées par Git et peuvent être régénérées depuis les sources.

Les contrôles bloquent toute sauvegarde si les effectifs, l'unicité des
identifiants, les probabilités, les poids ou les caractéristiques conservées
ne sont pas conformes. Deux tirages avec la même graine doivent être strictement
identiques ; le RDS sauvegardé est ensuite relu et contrôlé. Un fichier existant
identique est conservé ; un échantillon différent impose un nouveau nom de sortie.
La somme des poids de base est de 100 000 avant toute non-réponse.

### Vérifier les poids avant non-réponse

```powershell
Rscript.exe R/02_audit_poids.R
```

Cet audit lit l'échantillon initial, recalcule les tailles depuis la population
et compare l'allocation CSV à la configuration. Il vérifie chaque probabilité
et chaque poids, puis calcule les effectifs, les poids moyens et les sommes par
strate dans `outputs/tables/controle_poids_strates.csv` et le contrôle global
dans `outputs/tables/controle_poids_total.csv`.

Pour un tirage aléatoire simple sans remise de taille fixe dans une strate :

\[
\pi_h = \frac{n_h}{N_h}, \qquad w_h = \frac{1}{\pi_h} = \frac{N_h}{n_h}.
\]

Chaque unité de la strate a la même probabilité d'inclusion. Ainsi,
\(\sum_{i\in s_h}w_i = n_h(N_h/n_h)=N_h\), et
\(\sum_{i\in s}w_i=\sum_h N_h=100\,000\).
Cette égalité vient du plan de sondage ; aucun recalage artificiel n'est appliqué.
Le poids moyen global vaut 50, mais les poids individuels varient entre strates.

L'audit valide les huit strates et le total, avec un écart numérique maximal
de l'ordre de 3,64 × 10⁻¹² par strate (tolérance absolue : 10⁻⁸).
La population, l'échantillon et l'allocation restent inchangés. Ce contrôle
porte sur l'échantillon initial complet : après non-réponse, les seuls poids
de base des répondants ne sommeront pas nécessairement à la population totale.

Les futurs traitements utiliseront des chemins relatifs, des graines aléatoires
explicites et paramétrées, ainsi que des contrôles des dimensions, doublons,
valeurs manquantes, modalités et valeurs impossibles. Les scripts s'arrêteront
sur les erreurs ; chaque transformation sera vérifiée. Aucun tirage aléatoire
n'est nécessaire pour la préparation des packages.

### Exécuter tous les tests automatiques

```powershell
Rscript.exe tests/run_tests.R
```

Les RDS de population et d'échantillon et le CSV d'allocation doivent déjà
exister : si nécessaire, lancer les scripts 01 et 02 au préalable. Les tests
ne régénèrent pas silencieusement les données qu'ils doivent vérifier.
`tests/testthat/test_sampling.R` contient neuf blocs de tests d'intégration :
tailles imposées de 100 000 et 2 000, identifiants, strates, bornes des
probabilités, poids, allocation et restitution pondérée de la population.
Les effectifs par strate sont aussi recomptés depuis la population enregistrée.

Le lanceur affiche le nombre de blocs `test_that` réussis, échoués et ignorés,
ainsi que les vérifications individuelles. Il renvoie un code de sortie non nul
en cas d'échec ou de suite incomplète. Validation initiale : **16 blocs réussis,
0 échoué, 0 ignoré ; 131 vérifications réussies**, dont 9 blocs dans
`test_sampling.R`. Aucun commit ne doit être effectué après un échec non corrigé.

### Psychométrie exploratoire (prompts 61 à 69)

Après le nettoyage, exécuter `Rscript.exe R/09_psychometrics.R`, puis
`Rscript.exe tests/run_tests.R`. Les paramètres figurent dans
`config/psychometrie.yml` et les choix méthodologiques dans
[docs/psychometrie.md](docs/psychometrie.md).
Cette étape produit les diagnostics des 48 items, les matrices polychorïques,
alpha, oméga, item-total, KMO/Bartlett et huit analyses parallèles ordinales.
Elle compare aussi quatre scénarios de qualité dans
`outputs/tables/sensibilite_psychometrie.csv` et documente les décisions dans
`outputs/tables/decision_items.csv`. La liste versionnée des items retenus est
`metadata/items_retenus_scores.yml`, distincte du questionnaire original.
Les analyses sont exploratoires, non pondérées, sans suppression d'item ni
validation automatique des scores. Les sorties générées restent ignorées par Git.

### Structure factorielle globale et scores

`Rscript.exe R/10_factor_analysis.R` étudie les items retenus par analyse
parallèle ordinale et AFE minres avec rotation oblimin. Les méthodes et limites
sont détaillées dans [docs/analyse_factorielle.md](docs/analyse_factorielle.md).
Les scores 1–5 et leurs Z sont destinés à une base enrichie distincte ; les
réponses originales restent préservées. Le premier calcul global de 100
permutations peut prendre plusieurs minutes ; un cache vérifié permet les
réexécutions avec les mêmes entrées et paramètres.

Le même script construit `data/processed/base_analytique.rds`, avec les poids
calibrés, les GAP priorité–pratique et les contraintes `5 - FAIS`.
Le schéma est documenté dans `metadata/dictionnaire_base_analytique.csv` et
les règles dans [docs/base_analytique.md](docs/base_analytique.md).

### Classification exploratoire

`Rscript.exe R/11_clustering.R` produit l'ACP, les CAH de deux à six classes,
la stabilité par sous-échantillonnage, la comparaison k-means et les descriptions
des profils. Les choix et limites sont dans [docs/classification.md](docs/classification.md).
La partition retenue à deux groupes reste faiblement séparée et instable ; ses
étiquettes neutres ne représentent pas une typologie validée d'enseignants.
La base enrichie distincte est `data/processed/base_analytique_profils.rds`.
Le script ajoute également `CLUSTER_ID` et `PROFIL_PRATIQUES` à la base analytique
et actualise son dictionnaire. Les noms relatifs décrivent un gradient de fréquence
déclarée. La composition pondérée, les écarts déclarés priorité–pratique et les quatre
figures de profils sont documentés dans [la méthodologie de la typologie](docs/methodologie_typologie.md).

La publication GitHub est une étape ultérieure, soumise à une demande explicite.

## Modèles associatifs et sorties pour Quarto

Exécuter `Rscript.exe R/12_models.R`, puis `Rscript.exe R/13_outputs.R` et
`Rscript.exe tests/run_tests.R`. Les modèles utilisent le plan survey calibré,
des spécifications progressives et des sensibilités de pondération et de qualité.
Ils ne permettent aucune interprétation causale. Le modèle de profil reste
conditionnel à une classification faiblement stable.

Les décisions méthodologiques sont dans [docs/modelisation.md](docs/modelisation.md).
Les sorties comprennent `modeles_finaux.html`, `interpretation_modeles.md`, le
catalogue des indicateurs et `outputs/models/resultats_quarto.rds`. Le manifeste
des sorties distingue les figures finales homogènes des explorations antérieures.
Le script de sorties charge les résultats existants et ne réestime pas les modèles.

## Rapport scientifique Quarto

Le site comprend l’accueil, le rapport scientifique, ses annexes et la note décideur. Après exécution
du pipeline jusqu’à `R/13_outputs.R`, lancer `quarto render` depuis la racine.
Les HTML sont générés dans `_site/` ; `docs/` conserve la documentation source.
Le rendu vérifie les empreintes des sorties avant de charger les chiffres.
La note décideur figure dans la navigation ; elle reprend huit indicateurs prioritaires
et cinq messages générés depuis les résultats calculés. Son rendu produit également
`outputs/tables/messages_cles_decideur.md` et `outputs/figures/synthese_decideur.png`.

Sur cette installation Windows, le lanceur Quarto nécessite un chemin sans espaces :

```powershell
$env:LC_ALL = 'French_France.utf8'
$env:LANG = 'French_France.utf8'
$env:QUARTO_R = 'C:\PROGRA~1\R\R-4.6.0\bin'
& 'C:\PROGRA~1\Quarto\bin\quarto.cmd' render
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tests/audit_rapport.ps1
```

La configuration active uniquement HTML. Un format PDF pourra être ajouté après
vérification d’un moteur LaTeX ; aucune dépendance PDF n’est installée ici.

La note dispose aussi d’un PDF de trois pages dans `outputs/tables/note_decideur.pdf`,
produit par impression de son HTML avec Edge déjà installé. Sa feuille de style
prévoit des pages A4 ; pour le reproduire, imprimer la note HTML en PDF sans
en-têtes ni pieds de page du navigateur. Aucun moteur LaTeX n’a été installé.

Références techniques : [initialisation renv](https://pkgs.rstudio.com/renv/reference/init.html),
[verrouillage des dépendances](https://rstudio.github.io/renv/reference/snapshot.html).
