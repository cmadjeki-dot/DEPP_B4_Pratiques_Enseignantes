# Items de contrôle et recodages

> Données simulées à des fins de démonstration méthodologique. Les résultats présentés ne constituent pas des résultats officiels de la DEPP et ne décrivent pas la population réelle des enseignants.

| Variable | Interprétation | Codage |
|---|---|---|
| CTRL01 | Consigne de lecture explicite | 1 à 5 ; réponse attendue 3 |
| CTRL02 | Fréquence de réponse sans lecture complète | 1 Jamais à 5 Très souvent ; inversé |
| CTRL03 | Respect déclaré du niveau de classe de référence | 0 Non, 1 Oui |
| CTRL04 | Difficultés à répondre avec précision | 1 Pas du tout à 5 Tout à fait ; inversé |

La consigne initiale de CTRL02 (sélectionner Souvent) est remplacée par une
autoévaluation négative. CTRL04 porte désormais sur les difficultés et non
sur la précision directement. Le dictionnaire et le questionnaire généré
reflètent cette révision ; CTRL01 et CTRL03 sont conservés.

## Recodages

```r
CTRL02_reverse = 6 - CTRL02
CTRL04_reverse = 6 - CTRL04
```

La correspondance est 1→5, 2→4, 3→3, 4→2, 5→1. Les variables brutes sont
conservées ; les deux variables dérivées ne sont pas des questions supplémentaires.
Un code recodé élevé traduit moins de difficultés déclarées. Ce recodage
n'établit pas à lui seul la validité d'une réponse. Les quatre contrôles et
leurs recodages sont exclus de toutes les échelles principales, des moyennes
provisoires et des GAP. Aucune moyenne globale de contrôle n'est calculée.

## Simulation reproductible

La graine 20260916 et les paramètres figurent dans `config/config.yml`.
CTRL01 respecte la consigne avec une probabilité de 0,96 ; sinon une des quatre
autres réponses est tirée. CTRL03 vaut 1 avec probabilité 0,95.
CTRL02 et CTRL04 reposent chacun sur 0,55 D + sqrt(1 − 0,55²) E,
où D est une difficulté normale commune et E un bruit normal indépendant.
Quatre seuils croissants convertissent ces continus en réponses ordinales ;
CTRL04 a un décalage de seuils de 0,15. Les réponses basses sont plus fréquentes.
Il s'agit d'hypothèses de démonstration, pas de taux de qualité observés.

Cette étape ne dégrade pas les réponses principales déjà simulées. Les
contrôles ne constituent donc pas une vérité de référence sur leur qualité.
Le futur plan de contrôle devra confronter plusieurs signaux, examiner leurs
ambiguïtés et éviter une exclusion automatique sur un seul item. Aucune paire
de ces contrôles n'impose une égalité arithmétique entre réponses attendues.

La sortie est `data/simulated/reponses_questionnaire.rds` ; les fréquences sont
dans `outputs/tables/frequences_controles.csv`. Les données antérieures sont
conservées, les bornes, identifiants, recodages et la reproductibilité contrôlés.
