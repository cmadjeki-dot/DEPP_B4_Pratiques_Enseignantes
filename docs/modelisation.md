# Modèles associatifs et sorties finales

Données simulées à des fins de démonstration méthodologique. Les résultats présentés ne constituent pas des résultats officiels de la DEPP et ne décrivent pas la population réelle des enseignants.

## Population, prédicteurs et spécifications

`R/12_models.R` charge la base analytique et enrichit en mémoire les variables du plan calibré, après appariement unique des identifiants et vérification des poids. Aucune valeur source n’est modifiée. Les analyses sont associatives, sans ordre temporel établi. Les dépendances statistiques intégrées aux données sont des hypothèses de simulation et ne constituent pas des résultats empiriques sur les enseignants.

L’âge et l’ancienneté sont corrélés à 0,934 : l’ancienneté est retenue, pas les deux simultanément. `anciennete_classe` est une durée entière générée entre zéro et l’ancienneté professionnelle, et non une tranche catégorielle : elle est explorée comme variable numérique et n’est pas ajoutée aux modèles principaux. Le statut est étroitement lié au secteur ; les catégories privées de statut ne sont pas ajoutées aux modèles comprenant déjà le secteur. La discipline est décrite et étudiée en bivarié au collège seulement ; les disciplines à moins de 30 observations sont signalées sans regroupement automatique. Le sexe figure dans l’audit et les bivariées, mais n’est pas ajouté systématiquement aux spécifications centrées sur les hypothèses techniques du démonstrateur. Ce choix de portée n’établit pas une absence d’association avec le sexe. Aucun prédicteur n’est sélectionné seulement sur p < 0,05.

Les références sont Premier degré, Public, Hors EP, Urbain et équipement Faible. Une association REP ou REP+ est estimée avec le public Hors EP comme comparaison pertinente ; les croisements privé/EP inexistants ne sont pas inventés. Les modèles additifs imposent néanmoins des hypothèses d’homogénéité des associations et ne justifient aucune extrapolation au privé en EP.

L’ancienneté est centrée sur 15 ans et exprimée par dix ans ; l’effectif de classe est centré sur 24 et exprimé par cinq élèves. La formation continue est un nombre de jours. Les scores prédicteurs conservent leur échelle 1–5. Les transformations sont définies dans `config/modeles.yml`. L’audit couvre valeurs manquantes, modalités rares, quasi-constance (part dominante ≥ 98 %) et corrélations numériques.

## Régressions principales

- DIF : formation seule, puis contexte ajusté, puis ajout de COL et DEV.
- EVA : formation seule, puis ancienneté, degré et EP, puis ajout de EXP, DIF, DEV et COL.
- NUM : équipement seul puis formation, ancienneté, degré, territoire et secteur.
- GAP_DIF : contrainte déclarée, effectif, EP, formation, ancienneté, degré, DEV et COL.
- Profil : logistique du profil 2 contre le profil 1, selon degré, ancienneté, secteur, EP, territoire, formation et équipement.

Les scores contemporains ajoutés aux modèles DIF/EVA modifient l’association visée : les coefficients de contexte deviennent des associations conditionnelles à d’autres pratiques déclarées. Ils ne mesurent pas des effets directs identifiés. GAP_DIF est retenu en raison de son intérêt pédagogique et de l’écart descriptif positif du profil 1 ; il n’est pas choisi en recherchant la p-value la plus faible.

Les modèles utilisent `survey::svyglm`, famille gaussienne pour les scores et GAP, quasibinomiale pour le profil. Les poids finaux et la stratification sont préservés, ainsi que les informations de calibration. Les SE sont robustes au modèle et tiennent compte du plan de travail. L’incertitude supplémentaire des corrections de non-réponse, des scores et des classes n’est pas intégralement propagée. Les modèles de profil sont particulièrement exploratoires puisque la classification est faiblement stable.

Les tests globaux bivariés sont accompagnés d’une correction de Benjamini–Hochberg sur les couples score/prédicteur, sans compter plusieurs fois les modalités d’un même test. Les autres tests restent exploratoires et ne définissent pas une recherche confirmatoire préenregistrée. Un IC excluant zéro ne suffit pas à conclure à une importance pratique.

Chaque réponse a son masque de cas complets, fondé sur les variables de sa spécification finale. Les modèles progressifs de cette réponse utilisent exactement les mêmes individus, contrôlés par identifiant. Les effectifs et exclusions pour missing sont exportés. Aucune imputation ou suppression supplémentaire de la base n’est effectuée.

## Formes fonctionnelles et diagnostics

Les relations quantitatives sont visualisées avec une droite et une courbe quadratique pondérées. Les bivariées incluent des tests de courbure pour âge, ancienneté, effectif et formation. Pour les modèles ajustés, des termes quadratiques centrés d’ancienneté et, lorsqu’il est présent, d’effectif sont comparés sur les mêmes cas. Une seule interaction est explorée : équipement × degré pour NUM, afin d’examiner une hétérogénéité plausible entre premier degré et collège. Le modèle principal est additif et linéaire ; les variantes sont conservées et la décision doit être lue avec leurs écarts de prédiction, pas seulement leurs p-values. Les quadratiques sont une exploration parcimonieuse sur le support observé, sans extrapolation aux âges ou anciennetés hors de la base.

Chaque modèle final exporte résidus, leviers, contributions linéarisées d’influence, VIF par colonne du modèle, RMSE et diagnostics d’ajustement. Le R² pondéré des modèles gaussiens est descriptif ; le Brier est fourni pour la logistique. Les VIF par indicatrice ne sont pas des GVIF par facteur. Le seuil de signalement d’influence 2/√n et celui de levier 2p/n sont des heuristiques ; aucune ligne n’est exclue sur cette seule base. Les contributions linéarisées ne sont pas des mesures exactes de suppression d’observation. Les moyennes des résidus carrés par groupe de prédiction servent à examiner l’hétéroscédasticité, sans appliquer un test OLS supposant un échantillonnage indépendant non pondéré. Les prédictions linéaires hors de l’échelle sont comptées, jamais tronquées.

## Prédictions et sensibilités

Les probabilités de profil sont moyennées sur les covariables observées des enseignants classés, avec les poids finaux, pour trois équipements et 0 ou 3 jours de formation. Chaque combinaison dispose d’observations dans la base ; les effectifs de support sont fournis. Cette standardisation est une description ajustée du modèle, pas une intervention identifiée. Les IC utilisent la méthode delta avec covariance survey et transformation logit ; ils conditionnent sur la distribution empirique des covariables et sur les classes fixées.

Quatre variantes sont comparées : pondéré principal, non pondéré principal, pondéré avec qualité stricte et non pondéré avec qualité stricte. Les variantes non pondérées utilisent un plan indépendant à poids unitaires avec SE sandwich, distinct d’OLS homoscédastique. La restriction stricte reprend `flag_analyse_sensibilite` ; les poids ne sont pas recalibrés et les classes ne sont pas réestimées. Cette comparaison ne résout donc pas un éventuel biais de sélection.

La robustesse est qualifiée par terme, en unités de SE du modèle pondéré principal : ROBUSTE si l’écart maximal est ≤ 0,5 SE ; MODEREMENT_ROBUSTE jusqu’à 1 SE ; SENSIBLE au-delà, ou si le signe s’inverse alors que le coefficient principal dépasse une SE en valeur absolue. Ces seuils explicites sont des conventions de lecture, pas une certification. Les tableaux conservent les coefficients, IC, p-values et signes pour une lecture indépendante. Un terme proche de zéro peut être ROBUSTE au sens de faible variation tout en restant très incertain.

## Sorties et reproduction

### Lecture des résultats de cette exécution

Les effectifs des modèles finaux sont 1 484 (DIF), 1 476 (EVA), 1 498 (NUM), 1 372 (GAP_DIF) et 1 463 (profil). Les VIF maximaux par colonne vont de 1,42 à 1,91 : aucune colinéarité forte n’est détectée dans ces spécifications. Aucun ajustement principal observé ne sort de l’échelle de sa réponse. Les R² descriptifs sont respectivement 0,139, 0,222, 0,078 et 0,021 pour les modèles gaussiens ; le modèle du GAP a notamment une faible capacité descriptive.

Les écarts quadratiques moyens entre prédictions linéaires et quadratiques sont 0,014 point pour DIF, 0,005 pour EVA, 0,025 pour NUM, 0,038 pour GAP_DIF et 0,010 en probabilité pour le profil. L’interaction équipement × degré modifie les prédictions de NUM d’environ 0,024 point en RMS (p de Wald 0,537). La faible amplitude de ces différences, la lisibilité et l’absence d’argument substantiel fort supplémentaire conduisent à conserver les modèles additifs linéaires. Ce choix ne démontre pas une linéarité exacte.

La contrainte déclarée est associée à +0,043 point de GAP_DIF par unité, IC 95 % [−0,017 ; 0,103] : l’hypothèse n’est pas étayée de manière concluante dans cette réalisation. Le bon équipement est associé à +0,666 point de NUM par rapport à un équipement faible, IC [0,542 ; 0,790]. Ces résultats sont des associations simulées, non des effets établis sur les enseignants.

La sensibilité de pondération et de qualité classe 50 termes (intercepts compris) ROBUSTE et 4 MODEREMENT_ROBUSTE selon les conventions annoncées. Cela ne compense pas la faible stabilité des classes. Les nombreux signaux d’influence issus du maximum sur plusieurs coefficients sont des alertes volontairement sensibles, pas un décompte d’observations invalides ; aucune exclusion n’en découle.

`R/13_outputs.R` charge les tableaux et objets déjà estimés, vérifie les coefficients et les fichiers, produit un catalogue de 35 indicateurs, trois figures finales homogènes et un manifeste avec empreintes MD5. Il ne réestime aucun modèle. `outputs/models/resultats_quarto.rds` contient catalogue, coefficients, prédictions et manifeste pour les rapports. Les anciennes figures des étapes exploratoires restent disponibles ; le manifeste identifie explicitement les figures finales destinées à Quarto. Toutes les figures de cette étape utilisent `R/functions/theme_depp_demo.R` et la mention complète de simulation.

Le tableau HTML utilise `gt` pour préserver exactement les SE et IC survey, sans étoiles de significativité. Pour la logistique, l’effet présenté est l’OR avec son IC exponentié ; la SE reste celle du coefficient log-odds, explicitement indiquée. Les interprétations sont générées à partir des coefficients effectivement calculés.

Commandes depuis la racine : `Rscript.exe R/12_models.R`, `Rscript.exe R/13_outputs.R`, puis `Rscript.exe tests/run_tests.R`. Aucun package n’est installé par ces scripts.

Références : [modèles survey et erreurs standards robustes](https://r-survey.r-forge.r-project.org/pkgdown/docs/reference/svyglm.html) ; [tests de Wald de groupes de termes](https://r-survey.r-forge.r-project.org/pkgdown/docs/reference/regTermTest.html).
