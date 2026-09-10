# Structure globale et scores du démonstrateur

Données simulées à des fins de démonstration méthodologique. Les résultats présentés ne constituent pas des résultats officiels de la DEPP et ne décrivent pas la population réelle des enseignants.

Les dépendances statistiques intégrées aux données sont des hypothèses de simulation et ne constituent pas des résultats empiriques sur les enseignants.

## Méthode

`R/10_factor_analysis.R` utilise exclusivement les items retenus dans `metadata/items_retenus_scores.yml` et la base nettoyée. Les corrélations polychorïques sont recalculées sur les cas complets de ces items : la matrice n'est pas supposée inchangée si la liste évolue. Les analyses sont exploratoires, non pondérées ; elles ne constituent pas une inférence tenant compte du plan de sondage. La sélection des cas complets et le mécanisme simulé limitent la généralisation.

L'analyse parallèle ordinale utilise 100 permutations indépendantes des colonnes, le quantile 95 %, et la méthode factorielle minres avec communalités initiales issues d'un facteur (SMC=FALSE). Ce dernier choix peut influencer le nombre proposé dans une structure multifactorielle. Le nombre de facteurs n'est pas fixé à huit. La solution suggérée est comparée à une solution théorique à huit facteurs lorsque les nombres diffèrent. Le RMSR est descriptif ; il ne suffit pas à choisir le modèle le plus complexe.

L'extraction minres est appliquée à la matrice polychorïque, avec rotation oblimin : les facteurs peuvent être corrélés. Les charges exportées sont les coefficients de la matrice de configuration, distincts des corrélations item-facteur (matrice de structure). L'orientation du signe de chaque facteur est arbitraire ; on rend positive sa plus forte charge et on transforme également la matrice des corrélations factorielles.

Les communalités prennent en compte les corrélations entre facteurs. Les contributions de variance sous rotation oblique ne constituent pas des parts indépendantes d'un partage causal : ne pas les interpréter comme des effets pédagogiques séparés. `variance_expliquee_efa.csv` conserve les indicateurs fournis par psych et leurs libellés.

Une alerte de charge croisée est produite si la deuxième charge absolue atteint 0,30, ou si la charge principale atteint 0,40 mais dépasse la seconde de moins de 0,20. Le fichier `diagnostic_charges_efa.csv` conserve les mesures pour tous les items ; `cross_loadings.csv` ne contient que les alertes (et peut donc être vide avec en-têtes). `REVOIR` invite à relire le contenu, sans exclusion automatique. Les libellés et recouvrements conceptuels restent indispensables à l'interprétation.

Le cache de l'analyse parallèle est invalidé si les données nettoyées, la liste retenue, les paramètres, R ou psych changent. Il évite de répéter les permutations lors d'une simple mise en forme ; les modèles factoriels et sorties sont recalculés. Les fichiers sources ne sont jamais modifiés.

## Règle de score envisagée

Seules les dimensions dont la cohérence statistique et conceptuelle est suffisamment étayée peuvent recevoir un score définitif **pour le pipeline de démonstration**, sans revendication d'une échelle empiriquement validée chez les enseignants réels. Les réserves de contenu sont maintenues même si les charges correspondent aux blocs théoriques.

Le score sera la moyenne non pondérée des items retenus et effectivement renseignés, avec au moins deux tiers des items du bloc (arrondi supérieur : quatre sur six). Les répondants insuffisamment renseignés restent à NA. Cette proratisation suppose les réponses disponibles suffisamment représentatives du bloc ; comparer les scores calculés sur tous les items renseignés et les cas complets reste utile. Une même moyenne obtenue sur quatre ou six items n'a pas exactement la même précision.

Les Z utiliseront la moyenne et l'écart-type usuels non pondérés des scores disponibles dans la base analytique, avec conservation des paramètres. Ils décrivent une position relative dans cette base et servent aux analyses multivariées. Les scores originaux sur 1–5 seront conservés. Les statistiques de rapport principal devront ensuite utiliser le plan survey ; les descriptifs de contrôle des scores sont non pondérés.

Les corrélations des scores utiliseront les paires disponibles, avec une matrice des effectifs associés : les dénominateurs peuvent différer. Il ne s'agit pas d'une nouvelle matrice polychorïque des items. Aucun poids ni identifiant ne sera modifié ; la base enrichie sera écrite séparément dans `data/processed/questionnaire_scores.rds`.

Références : [AFE minres et rotation oblique dans psych](https://personality-project.org/r/psych/help/fa.html) ; [analyse parallèle ordinale](https://personality-project.org/r/psych/help/fa.parallel.html).

## Revue de la solution obtenue

L'analyse globale sur 1 161 cas complets suggère huit facteurs, sans que ce nombre ait été imposé. Chaque groupe de six items a son maximum de charge sur un même facteur : F1=REL, F2=NUM, F3=DIF, F4=DEV, F5=GCL, F6=COL, F7=EVA et F8=EXP. La lecture des libellés conduit aux interprétations détaillées dans `metadata/revue_facteurs.csv`, reprises avec les items principaux dans `interpretation_facteurs.csv`.

Les charges principales vont approximativement de 0,474 à 0,808. Le RMSR est de 0,0113 ; aucune alerte de charge croisée n'est déclenchée aux seuils annoncés. La solution empirique et le modèle théorique ayant le même nombre de facteurs, ils correspondent ici à un seul ajustement exploratoire, et non à une comparaison de deux modèles indépendants. Ces résultats sont attendus dans un générateur organisé autour de huit traits : ils ne valident pas empiriquement le questionnaire dans la population réelle.

La cohérence observée, la psychométrie par bloc et l'examen du contenu permettent de retenir les huit scores pour ce pipeline. Les 48 items restent utilisés, avec les réserves de contenu déjà documentées pour EXP06, NUM06 et REL05. Aucun item n'est exclu sur un seuil isolé. Une validation externe, l'invariance entre contextes et une éventuelle analyse confirmatoire restent hors de cette conclusion.

La revue comporte l'empreinte du tableau de charges effectivement examiné. Une réexécution initiale après fixation explicite de la graine de rotation a légèrement modifié les charges (environ un millionième), sans modifier les regroupements ni les alertes. Le contrôle a arrêté le calcul des scores ; après examen de cette nouvelle sortie, la revue a été actualisée. Toute évolution ultérieure des charges exige de même une nouvelle revue.

Les scores finalement calculés reposent sur quatre à six réponses : les effectifs disponibles sont EXP=1 503, DIF=1 500, EVA=1 503, GCL=1 500, COL=1 504, NUM=1 498, DEV=1 496 et REL=1 488 sur 1 509 inclus. Les autres valeurs restent à NA. Tous les scores sont dans [1;5]. Les paramètres de standardisation et les effectifs par paire sont exportés ; les cas incomplets en scores devront être traités explicitement avant une classification multivariée.
