# Audit de référence de la base brute

> Données simulées à des fins de démonstration méthodologique. Les résultats présentés ne constituent pas des résultats officiels de la DEPP et ne décrivent pas la population réelle des enseignants.

Audit exécuté le 10 septembre 2026, sans modification des données ni de
`R/05_quality.R`. Les fréquences et taux ci-dessous sont non pondérés. Les
indicateurs d'injection n'ont pas été utilisés pour établir les diagnostics.
L'empreinte MD5 de la base avant et après audit est identique :
`8bbd5cc241ea10b1a625251ea3d8ceed`.

## Structure et validité

La base contient 1 521 lignes et 93 colonnes, dont 68 réponses questionnaire.
Aucun identifiant dupliqué ni ligne entièrement dupliquée. Les identifiants
correspondent aux participants du suivi des 2 000 enseignants tirés.
Les 68 réponses sont stockées en entiers ; aucune valeur observée ne sort
des modalités du dictionnaire (1 à 5, sauf CTRL03 binaire 0/1).
Aucune valeur manquante dans les caractéristiques, les variables de sondage
ou les variables de terrain. Toutes les dates sont du 1er au 10 septembre 2026.

Les âges vont de 23 à 65 ans (médiane 43), l'ancienneté de 0 à 42 ans
(médiane 15) et les effectifs de classe de 13 à 35 (médiane 24).
Aucune incohérence âge/ancienneté, ancienneté dans la classe/ancienneté totale,
privé/éducation prioritaire ou premier degré/discipline. Les probabilités
d'inclusion sont dans ]0,1] et les poids sont positifs, entre 20,36 et 64,64.

## Valeurs manquantes et complétion

| Bloc | Cellules manquantes | Cellules attendues | Pourcentage |
|---|---:|---:|---:|
| Pratiques | 1 230 | 73 008 | 1,68 % |
| Faisabilité | 341 | 12 168 | 2,80 % |
| Priorité | 1 011 | 12 168 | 8,31 % |
| Contrôles | 326 | 6 084 | 5,36 % |
| Total | 2 908 | 103 428 | 2,81 % |

Les dix dernières questions ont 8,48 % de réponses manquantes, contre 1,83 %
pour les 58 premières. Cette différence associe position et contenu : elle
ne suffit pas à établir empiriquement un effet causal de fatigue. CTRL04 est
la variable la plus manquante (145, soit 9,53 %), puis PRIO_REL (144, 9,47 %).
Les pratiques vont de 0,59 % manquants pour DIF01 à 3,16 % pour REL06.

La complétion recalculée sur les 68 questions concorde exactement avec
`taux_completion`. Elle va de 32,35 % à 100 %, avec médiane 98,53 % et
quartiles 97,06 % et 100 %. Les statuts sont cohérents avec cette complétion :
594 Complet, 902 Partiel et 25 Abandon. Donc 927 questionnaires sont incomplets,
dont 65 sous 80 % et 12 sous 50 %. Le statut Abandon est une information de
terrain distincte de la seule proportion de réponses présentes.

## Durées et réponses constantes

La durée médiane est de 873 secondes (14 min 33 s), les quartiles de 712 et
1 074 secondes, et les extrêmes de 25 et 2 228 secondes. Aucune durée n'est
manquante, non finie ou non positive.

| Seuil descriptif de durée | Questionnaires |
|---|---:|
| Moins de 60 secondes | 16 |
| Moins de 120 secondes | 25 |
| Moins de 180 secondes | 25 |
| Moins de 300 secondes | 25 |

Le seuil de 120 secondes signale 25 cas (1,64 % des reçus). Il n'est pas validé
par un prétest et ne constitue pas une règle d'exclusion. La complétion et le
statut devront accompagner l'interprétation des durées, notamment des abandons.

Le straightlining est examiné sur les seuls 48 items de pratiques, sans les
FAIS, PRIO ou CTRL qui ont d'autres significations. Le critère principal est
une modalité représentant au moins 90 % des réponses observées, avec au moins
24 items présents. Il signale 30 questionnaires (1,97 %). Les seuils de 80 %
et 95 % signalent également 30 cas. Trois questionnaires ont moins de 24 items
présents et ne sont pas évaluables avec ce critère.

Un second indicateur recherche une série d'au moins 20 réponses identiques
dans l'ordre des items de pratiques ; toute valeur manquante rompt la série.
Il signale 27 cas. Il ne mesure pas exactement la même propriété que la part
modale. Aucun des 30 profils à forte part modale n'appartient aux 25 cas rapides.
Il n'est pas possible d'inférer une mauvaise qualité avec certitude à partir
d'un seul de ces signaux : certaines pratiques peuvent réellement être homogènes.

## Contrôles auxiliaires

CTRL01 contient 1 455 réponses attendues (3), 55 réponses différentes et
11 manquantes ; les réponses différentes représentent 3,64 % des 1 510 réponses
observées. CTRL03 contient 68 Non, 1 319 Oui et 134 manquantes.
Les réponses brutes 4 ou 5 concernent 218 cas pour CTRL02 et 160 pour CTRL04.
Ces deux derniers items sont inversés et déclaratifs : aucune réponse unique
n'est attendue. Les manquants ne sont pas assimilés à un échec. Aucun recodage
n'est enregistré dans la base et aucun score de contrôle n'est calculé.

## Participation selon le plan de sondage

Le taux de participation est le nombre de questionnaires reçus, y compris
partiels et abandons, divisé par le nombre initialement tiré. Il vaut
1 521 / 2 000 = 76,05 %. Les 479 non-répondants totaux ne figurent pas dans
la base de questionnaires, mais leur existence est prise en compte au dénominateur.

| Strate | Tirés | Reçus | Taux |
|---|---:|---:|---:|
| P1_PUBLIC_HEP | 620 | 498 | 80,32 % |
| P1_PUBLIC_REP | 130 | 95 | 73,08 % |
| P1_PUBLIC_REPPLUS | 100 | 78 | 78,00 % |
| P1_PRIVE | 150 | 117 | 78,00 % |
| COL_PUBLIC_HEP | 600 | 440 | 73,33 % |
| COL_PUBLIC_REP | 150 | 115 | 76,67 % |
| COL_PUBLIC_REPPLUS | 100 | 70 | 70,00 % |
| COL_PRIVE | 150 | 108 | 72,00 % |

| Ventilation | Tirés | Reçus | Taux |
|---|---:|---:|---:|
| Premier degré | 1 000 | 788 | 78,80 % |
| Collège | 1 000 | 733 | 73,30 % |
| Public | 1 700 | 1 296 | 76,24 % |
| Privé sous contrat | 300 | 225 | 75,00 % |

À titre de sensibilité descriptive, 1 456 questionnaires sont remplis à au
moins 80 %, soit 72,80 % des tirés ; 594 sont complets, soit 29,70 % des tirés.
Ces définitions alternatives ne sont pas des critères d'acceptation retenus.
Les taux correspondants pour chaque groupe figurent dans le tableau CSV.

## Distributions et références pour le contrôle qualité

La base reçue comprend 1 163 enseignants hors EP, 210 en REP et 148 en REP+ ;
758 en urbain, 462 en périurbain et 301 en rural ; 1 085 femmes et 436 hommes.
Ces effectifs décrivent les répondants simulés et ne sont pas des estimations
de la population réelle. Toutes les distributions des 68 questions sont
exportées avec leur dénominateur observé, sans mélanger absence et modalité.

Les fichiers suivants sont des sorties locales de diagnostic, ignorées par Git :

- `outputs/tables/audit_brut_schema.csv` : les 93 noms, types et taux de manquants ;
- `audit_brut_bornes_items.csv` : bornes observées et anomalies des 68 questions ;
- `audit_brut_frequences_items.csv` : fréquences de chaque modalité par question ;
- `audit_brut_indicateurs.csv` : complétion, durées signalées et constance par individu ;
- `audit_brut_taux_reponse.csv` : taux par strate, degré et secteur ;
- `audit_brut_execution.txt` : résultats détaillés, dont distributions et résumés ;
- `audit_brut_execution.R` : script ponctuel permettant de reproduire cet audit.

Les contrôles structurels sont satisfaisants. R/05_quality.R devra produire
des indicateurs distincts de complétion, durée, constance et contrôles auxiliaires,
avec leurs seuils documentés et une catégorie non évaluable si nécessaire.
Les éventuelles décisions de nettoyage relèveront d'une étape ultérieure.
