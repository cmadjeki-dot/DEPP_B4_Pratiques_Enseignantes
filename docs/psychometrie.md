# Analyse psychométrique exploratoire

Données simulées à des fins de démonstration méthodologique. Les résultats présentés ne constituent pas des résultats officiels de la DEPP et ne décrivent pas la population réelle des enseignants.

Les dépendances statistiques intégrées aux données sont des hypothèses de simulation et ne constituent pas des résultats empiriques sur les enseignants.

## Périmètre et observations

Exécuter `Rscript R/09_psychometrics.R` depuis la racine. Le script utilise exclusivement les 48 items de pratiques de `questionnaire_clean.rds`. FAIS, PRIO et CTRL sont exclus. Les scores provisoires ne sont pas utilisés. L'empreinte du fichier source est contrôlée avant et après ; aucune donnée n'est modifiée et aucun item supprimé.

Les descriptifs utilisent toutes les réponses disponibles par item. Les matrices et modèles utilisent les cas complets sur les six items du bloc ; la matrice globale utilise les cas complets sur les 48 items. Les effectifs sont exportés, sans imputation. Cette sélection peut introduire un biais lié aux manquants. La matrice globale n'est donc pas un assemblage des matrices par bloc.

Cette étape étudie la structure de l'instrument dans l'échantillon analytique **sans pondération**. Elle ne fournit ni estimations représentatives de la population ni inférence tenant compte du sondage, de la calibration ou de la non-réponse. Les descriptifs pondérés de R/08 restent la référence du rapport principal. Une sensibilité de la structure aux poids et aux exclusions sera nécessaire avant une validation plus forte.

## Diagnostic et règles de vigilance

Les paramètres sont dans `config/psychometrie.yml`. Moyenne, variance, asymétrie g1 et excès de kurtosis g2 décrivent les codes ordinaux comme approximativement espacés ; ils ne prouvent pas une métrique d'intervalle. g1 et g2 sont calculés par moments centrés non corrigés. Les fréquences et modalités effectivement utilisées restent prioritaires.

Seuils exploratoires : extrémité ≥15 %, non-réponse >10 %, |asymétrie| >1, concentration ≥80 % ou écart-type <0,50. Le seuil de 15 % est volontairement sensible et cohérent avec R/08 : un signal isolé n'implique pas un dysfonctionnement. Les codes de diagnostic et les mesures sont conservés.

`A_EXAMINER` combine plusieurs familles : liaison faible (item-total <0,30 ou corrélation polychorique moyenne <0,20), structure faible (charge <0,40, communalité <0,20 ou MSA <0,50), paire potentiellement redondante (>0,85), quasi-constance, non-réponse élevée, ou extrémité accompagnée d'asymétrie. Les critères structurels ne sont pas déduits de l'alpha. `CONSERVER` signifie conservation provisoire, non validation. Les libellés et raisons accompagnent chaque décision ; la redondance conceptuelle nécessite une lecture métier et n'est pas déduite d'une seule corrélation.

## Corrélations, fidélité et adéquation factorielle

Les corrélations polychorïques supposent des réponses continues sous-jacentes bivariées normales séparées par des seuils. `psych::polychoric` est appelé sans lissage automatique, avec correction de continuité de 0,5. Une matrice non définie positive provoque un arrêt. Les matrices RDS, leurs valeurs propres minimales et leurs corrélations extrêmes sont sauvegardées.

L'alpha brut porte sur les codes observés ; l'alpha standardisé sur leurs corrélations de Pearson. La corrélation item-total corrigée exclut l'item du total (`r.drop`). Dans `item_total_analysis.csv`, la variance reprend toutes les réponses disponibles à l'item ; la moyenne de dimension, les corrélations et l'alpha utilisent les cas complets du bloc. L'alpha après suppression reste une information, jamais une règle de suppression. Un alpha ≥0,95 déclenche un examen de la redondance. Aucun seuil de 0,70 ne décide de la qualité.

Un modèle minres à un facteur est ajusté à chaque matrice polychorique. L'oméga total est calculé par `(somme des charges)^2 / ((somme des charges)^2 + somme des unicités)` sous un modèle congénérique standardisé, à erreurs non corrélées. Il autorise des charges inégales, contrairement à l'hypothèse de tau-équivalence nécessaire à l'interprétation usuelle de l'alpha comme fidélité. Il dépend néanmoins de l'adéquation du modèle. Des unicités inadmissibles rendent l'oméga indisponible. L'oméga ordinal décrit les réponses latentes et ne mesure pas exactement la fidélité de la somme des codes observés ; sa différence avec l'alpha ne prouve pas une amélioration. Aucun oméga hiérarchique n'est calculé sans modèle hiérarchique justifié.

Le KMO et les MSA sont calculés sur les matrices polychorïques, par bloc puis globalement. Bartlett est calculé sur Pearson et cas complets afin d'utiliser un effectif commun cohérent. Sa p-valeur est **indicative** : l'hypothèse de normalité multivariée des données continues et l'indépendance simple ne décrivent pas exactement nos réponses ordinales issues d'un sondage. Une petite p-valeur rejette seulement une matrice identité ; elle ne démontre ni unidimensionnalité ni qualité pédagogique.

## Analyse parallèle et décision

`psych::fa.parallel(cor="poly", fa="fa", fm="minres", sim=FALSE, SMC=FALSE)` compare les valeurs propres factorielles au quantile 95 % de 100 réplications permutant indépendamment les colonnes et conservant leurs marges. Les graines par dimension dérivent de 20260920. Les objets complets et huit graphiques sont archivés. Le choix du nombre de facteurs est exploratoire, sensible aux effectifs, aux communalités et à l'incertitude Monte-Carlo.

`PLUTOT_OUI` exige un facteur suggéré, un modèle admissible, des charges/communalités/MSA satisfaisantes et des corrélations positives. Des signaux contradictoires donnent `INCERTAIN` ; plusieurs facteurs associés à une structure faible donnent `NON`. Le programme n'attribue pas `OUI` automatiquement. Alpha, oméga et nombre d'items sont affichés dans les arguments, sans seuil de fidélité imposé.

Le rattachement thématique vient du dictionnaire et reste une hypothèse : les six pratiques d'une dimension ne sont pas nécessairement interchangeables. La revue conceptuelle, les résidus, les charges croisées globales et la stabilité restent à examiner avant de valider des scores. La matrice globale et son KMO préparent R/10 ; une matrice globale factorisable ne valide pas huit facteurs distincts.

### Lecture préliminaire des 48 libellés

Cette lecture motive la conservation provisoire des six items de chaque bloc et limite la confiance à un niveau modéré même si les indicateurs convergent. Elle ne remplace pas une expertise de contenu ni des entretiens cognitifs.

| Bloc | Cohérence thématique et réserve à examiner |
|---|---|
| EXP | Objectifs, démonstration, explicitation, décomposition et guidage couvrent l'enseignement explicite. EXP06 (vérification de compréhension) peut aussi relever d'EVA. |
| DIF | Aides, difficulté, temps, groupes et supports décrivent l'adaptation. DIF06 vise l'approfondissement pour les élèves avancés, plutôt que la remédiation. |
| EVA | Recueil d'information, critères, feedback, ajustement et reprise forment un cycle formatif. EVA06 porte sur l'autoévaluation des élèves et pourrait avoir des conditions d'usage distinctes. |
| GCL | Règles, routines, transitions et interventions renvoient à l'organisation de la classe. Les trois derniers items ciblent davantage la régulation des comportements. |
| COL | Les six items décrivent du travail avec les collègues. Préparer ensemble, partager une ressource et élaborer des repères communs peuvent engager des intensités différentes de coopération. |
| NUM | Le numérique est le point commun ; illustration, entraînement, production et recueil de réponses ne sont pas identiques. NUM06 porte sur l'esprit critique informationnel, à examiner dans la structure globale. |
| DEV | Ressources, formation, expérimentation, analyse et objectifs relèvent du développement professionnel. DEV02 dépend d'occasions de formation, DEV05 de l'accès à une personne ressource. |
| REL | Écoute, reconnaissance, participation et inclusion renvoient aux relations éducatives. REL05 vise les familles, contrairement aux autres items centrés sur les élèves. |

Aucune paire de libellés n'est strictement identique. Une corrélation élevée reste un signal de proximité, pas une preuve de contenu superflu. Les recouvrements EXP/EVA et les facettes de NUM/REL justifient de différer toute conclusion définitive.

## Résultats de l'exécution initiale

La base contient 1 509 enseignants ; les modèles par bloc utilisent 1 419 à 1 445 cas complets, et la matrice globale 1 161. Les neuf matrices sont définies positives sans lissage. Aucune corrélation négative n'apparaît à l'intérieur des blocs ; la matrice globale en comporte deux, avec un minimum de −0,012.

Les alphas bruts vont de 0,743 à 0,825 et les omégas ordinaux de 0,774 à 0,849. Les KMO par bloc vont de 0,840 à 0,891, avec 0,898 globalement. Les p-valeurs de Bartlett sont trop petites pour la précision numérique utilisée et apparaissent comme zéro dans le CSV : cela ne signifie pas une probabilité mathématiquement nulle et ne résout pas les limites d'approximation indiquées plus haut.

Les huit analyses parallèles suggèrent un facteur. Les huit décisions sont `PLUTOT_OUI`, confiance modérée, sans validation définitive. Aucun item ne cumule les critères requis pour `A_EXAMINER`. Les 15 signaux plancher et 18 signaux plafond restent visibles ; aucun item n'est quasi constant, fortement asymétrique ou au-delà de 10 % de non-réponse. Ces proportions sont non pondérées et peuvent différer du diagnostic pondéré de R/08.

Tous les items sont conservés provisoirement ; les réserves conceptuelles du tableau précédent restent applicables. Ces nombres décrivent cette exécution du démonstrateur et devront être actualisés si les données ou paramètres changent.

## Sensibilité qualité et décision sur les items (prompts 70–71)

Quatre scénarios sont calculés à partir de la base nettoyée, sans la modifier : tous les inclus ; exclusion du straightlining signalé ; complétion globale d'au moins 80 % ; combinaison des deux restrictions. Le seuil de complétion reprend `nettoyage.completion_sensibilite`. Chaque scénario refait une sélection des cas complets sur les six items du bloc et indique ses effectifs.

Le straightlining dit « sévère » désigne ici le signal déjà construit : au moins 90 % des réponses identiques parmi au moins 24 items principaux renseignés. Il ne constitue pas une preuve d'invalidité. Aucun flag de vérité issu du simulateur n'est utilisé. Un flag non évaluable ne conduit pas à une exclusion implicite ; son nombre est fourni.

La comparaison porte sur alpha brut, oméga ordinal, corrélations polychorïques, charges, communalités, RMSR (racine de la moyenne des carrés des résidus hors diagonale), spectre et congruence des charges. Les différences avec le scénario initial sont exportées. La structure est comparée **à nombre de facteurs fixé à un** ; l'analyse parallèle n'est pas répétée pour chaque restriction. Une bonne stabilité des charges ne prouve donc pas la stabilité du nombre de facteurs. Il n'existe pas de seuil universel transformant un delta de fidélité en différence importante : les amplitudes et changements qualitatifs doivent être lus ensemble.

Le tableau `decision_items.csv` reprend les coefficients réellement calculés et les libellés du dictionnaire. Les réserves de contenu identifiées pour EXP06, NUM06 et REL05 entraînent `CONSERVER_AVEC_RESERVE`. Les autres items sont conservés en l'absence d'indices convergents d'exclusion ; les alertes statistiques préliminaires, si présentes, entraînent aussi une réserve. Aucune exclusion n'est appliquée sur le seul alpha. Ces décisions clôturent cette étape et restent révisables après l'analyse factorielle globale.

La liste `metadata/items_retenus_scores.yml` est distincte du questionnaire original et sera utilisée pour préparer les scores. Elle n'en définit ni la règle de gestion des manquants ni la validation définitive. Les matrices et résultats restent générés, non versionnés.

Lors de l'exécution initiale de cette sensibilité, les scénarios retiennent respectivement 1 509, 1 479, 1 456 et 1 427 personnes avant sélection des cas complets par dimension. Les écarts absolus maximaux à la référence sont de 0,01541 pour alpha, 0,01467 pour oméga, 0,03151 pour une corrélation et 0,02655 pour une charge. La congruence minimale des charges est de 0,99987. Le retrait des straightliners réduit légèrement les coefficients de fidélité ; le filtre de complétion seul les modifie très peu. Ces amplitudes appuient la stabilité descriptive du modèle à un facteur fixé, sans établir une invariance complète ni la stabilité du nombre de facteurs. Elles ne justifient pas de nouvelle exclusion d'item : 45 sont conservés et 3 conservés avec réserve de contenu.

## Références techniques

- [Documentation psych : corrélations polychorïques](https://www.personality-project.org/r/psych/help/tetrachor.html).
- [Documentation psych : analyse parallèle ordinale](https://personality-project.org/r/psych/help/fa.parallel.html).

Les avertissements d'exécution sont visibles et archivés dans `outputs/tables/avertissements_psychometrie.txt` ; les versions effectives figurent dans `session_psychometrie.txt`.
