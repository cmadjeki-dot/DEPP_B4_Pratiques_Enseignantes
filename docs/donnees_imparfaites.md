# Injection contrôlée de données imparfaites

> Données simulées à des fins de démonstration méthodologique. Les résultats présentés ne constituent pas des résultats officiels de la DEPP et ne décrivent pas la population réelle des enseignants.

Exécuter `Rscript.exe R/04_donnees_imparfaites.R` après le script 04 de simulation.
La graine 20260917 et tous les paramètres figurent dans `config/config.yml`.
La référence complète reste intacte ; la nouvelle collecte brute est enregistrée
dans `data/simulated/reponses_imparfaites.rds`. Aucun nettoyage n'est réalisé.
Les scores provisoires, GAP et recodages sont absents de cette sortie pour ne
pas conserver des valeurs dérivées des réponses antérieures à l'injection.

## Ordre et mécanismes

1. Trente enseignants reçoivent une même modalité sur 46 des 48 items de
   pratiques. Les deux autres réponses restent intactes. Le registre distingue
   les cellules ciblées des valeurs effectivement changées.
2. Vingt-cinq abandons sont tirés : toutes les questions après une position
   aléatoire entre 20 et 48 sont mises à NA selon l'ordre réel de passation.
3. Quarante autres enseignants ont 18 réponses supprimées, réparties dans le
   questionnaire. Ce groupe est distinct des abandons.
4. Chaque cellule encore présente a une probabilité de 0,005 de devenir NA.
5. Chaque cellule encore présente des dix dernières questions a une probabilité
   supplémentaire de 0,06 de devenir NA. Ce mécanisme concerne PRIO et les
   deux derniers contrôles, conformément à l'ordre de passation.
6. Les durées ordinaires suivent une loi lognormale de médiane 900 secondes et
   d'écart-type logarithmique 0,30, multipliée par la complétion et bornée à
   300 secondes. Vingt-cinq durées sont remplacées par 20 à 90 secondes.

Les effectifs imposés sont des cas de test, pas des prévalences estimées. Les
groupes de réponses constantes et rapides sont tirés indépendamment des
groupes partiels/abandons : les chevauchements sont permis. Les masquages
peuvent effacer certaines réponses constantes. Les effectifs ne s'additionnent
donc pas pour obtenir un nombre de personnes distinctes affectées.

## Variables et registre

`statut_questionnaire` vaut Abandon pour les abandons injectés, sinon Complet
si les 68 réponses sont présentes, et Partiel dans les autres cas. Le nombre
final de Partiel dépasse donc généralement les 40 cas imposés.
`taux_completion` est la proportion de réponses présentes parmi les 68 questions
(entre 0 et 1, sans scores ni recodages). `date_reponse_simulee` est une date
de dernière activité, tirée du 1er au 10 septembre 2026, y compris pour les abandons.
`duree_secondes` est entière et positive.

`flag_straightlining_simule` et `flag_rapide_simule` indiquent les groupes
injectés. Ce sont des informations du simulateur, à réserver à l'évaluation
des futurs détecteurs, jamais à utiliser comme règles de détection.
Les contrôles CTRL déjà simulés ne sont pas forcés à correspondre aux nouveaux
groupes ; ils ne constituent pas une vérité de référence sur ces anomalies.

`outputs/tables/registre_imperfections.csv` documente chaque cellule ciblée :
identifiant, variable, cause, avant/après et modification effective. Une cellule
peut subir une réponse constante puis un masquage ; elle ne reçoit qu'une seule
cause de valeur manquante. `bilan_imperfections.csv` donne les nombres exacts
de personnes et cellules par cause. Ces fichiers individuels sont ignorés par Git.
Aucun doublon technique n'est injecté à cette étape. Les poids et identifiants
sont conservés. R/05_quality.R reste à développer indépendamment du registre.

## Bilan de l'exécution de référence

| Cause | Enseignants concernés | Cellules ciblées | Cellules modifiées |
|---|---:|---:|---:|
| Réponses quasi constantes | 30 | 1 380 | 1 087 |
| Abandons | 25 | 856 | 856 |
| Questionnaires partiels imposés | 40 | 720 | 720 |
| Manquants aléatoires | 407 | 475 | 475 |
| Manquants supplémentaires de fin | 671 | 857 | 857 |
| Durées très courtes | 25 | 25 | 25 |

La sortie comporte 1 521 lignes et 96 colonnes, sans doublon d'identifiant.
Elle contient 2 908 réponses manquantes sur 103 428 cellules de questionnaire.
Les statuts finaux sont 594 Complet, 902 Partiel et 25 Abandon. Les 293 cellules
ciblées de straightlining déjà égales à la modalité imposée ne sont pas comptées
comme modifications. Les nombres par cause précèdent les éventuels effets
des masquages suivants ; le registre conserve toute la séquence.
