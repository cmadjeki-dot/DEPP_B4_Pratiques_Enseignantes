# Nettoyage et inclusion analytique — règles version 1.0

> Données simulées à des fins de démonstration méthodologique. Les résultats présentés ne constituent pas des résultats officiels de la DEPP et ne décrivent pas la population réelle des enseignants.

Le script `R/06_cleaning.R` charge la base brute et les résultats du script 05.
Il recalcule les contrôles et compare les flags enregistrés : une discordance
impose de relancer le contrôle qualité. La base brute est conservée et son
empreinte contrôlée. Aucune imputation ou aucun score définitif n'est produit.

## Corrections de domaine

Chaque correction est consignée avant son application à une copie de travail :
ligne source, identifiant, variable, ancienne valeur, nouvelle valeur, motif et
type. Les domaines des 68 questions proviennent du dictionnaire (CTRL03 est
binaire). Une valeur observée impossible devient NA ; une absence préexistante
n'est pas une nouvelle correction.

Les bornes sont 23–65 ans pour l'âge, 0–43 pour les anciennetés, 12–35 élèves
et 0–20 jours de formation, avec valeurs entières. L'ancienneté supérieure à
l'âge moins 22 devient NA en conservant l'âge valide ; l'ancienneté de classe
supérieure à l'ancienneté totale devient NA. Cette priorité est une convention
explicite de nettoyage, pas une preuve que l'âge est exact.
Les modalités catégorielles non présentes dans la population synthétique
deviennent NA. Les contradictions entre catégories valides (privé en EP ou
degré/discipline) sont signalées et rendent le cas inexploitable dans l'analyse
principale ; aucune catégorie de remplacement n'est inventée.
Les poids ne sont jamais corrigés ou recalibrés ici.

## Doublons techniques

Les groupes sont définis par identifiant non vide identique. Toutes les copies
portent `flag_doublon` et un `id_doublon_groupe`. Si leur contexte de sondage
est contradictoire, le script s'arrête pour examen, sans les assimiler à des
copies techniques. Des identifiants différents ne sont pas fusionnés sur la
seule ressemblance des réponses.

La priorité est : complétion valide de 100 %, puis taux valide décroissant,
puis durée valide non signalée rapide, puis date la plus récente, puis numéro
de ligne source le plus petit. Une date manquante est la moins prioritaire.
Le classement ne favorise pas arbitrairement la durée la plus longue.
`decision_doublon` vaut UNIQUE, CONSERVER_REFERENCE ou EXCLURE_COPIE.
Toutes les occurrences du groupe sont exportées dans `traitement_doublons.csv`.

## Inclusion principale

L'ordre de priorité du statut est :

1. EXCLU_DOUBLON : copie non prioritaire.
2. EXCLU_INEXPLOITABLE : identifiant absent/inconnu, informations de sondage
   incohérentes, contradiction privé/EP ou degré/discipline, ou zéro réponse valide.
3. EXCLU_COMPLETION : moins de 50 % des 68 réponses valides ou moins de 24
   pratiques valides sur 48.
4. EXCLU_QUALITE : cumul très rapide ET straightlining ET échec observé à CTRL01.
5. INCLUS : aucun des critères précédents.

`raison_exclusion` conserve les motifs cumulés, même si un seul statut prioritaire
est attribué. Un signal non évaluable n'est pas assimilé à un échec. Une rapidité
ou une constance isolée ne suffit pas. Un abandon est exclu selon son contenu,
pas automatiquement selon son statut terrain. Le seuil de 50 % exige au moins
la moitié du questionnaire ; le minimum de 24 pratiques protège aussi le bloc
principal. Ces choix sont prudents mais conventionnels, à soumettre à sensibilité.
Ils ne garantissent pas la calculabilité de chacune des huit échelles.

## Analyse de sensibilité

`flag_analyse_principale` indique INCLUS. `flag_analyse_sensibilite` impose en
plus au moins 80 % de réponses valides, aucune très grande rapidité, aucun cumul
rapidité avec constance ou échec CTRL01, et des flags rapidité/constance évaluables.
Cette sélection volontairement plus stricte est un sous-ensemble de la principale.
`raison_hors_sensibilite` distingue les cas écartés de ce scénario.

Les flags de qualité décrivent la collecte brute et restent inchangés : ils
ne sont pas réinterprétés comme diagnostics post-nettoyage. Les nombres valides
et `taux_completion_clean` sont calculés après corrections, sans écraser le taux
original. Les flags homonymes de variables source portent le suffixe
`_diagnostic_brut`. La version des règles et le numéro de ligne accompagnent
chaque observation. Une sélection analytique peut changer la composition de
l'échantillon ; les poids de base conservés nécessiteront un traitement ultérieur
de la non-réponse et de la sélection, sans les faire sommer artificiellement.

## Livrables

- `data/interim/questionnaire_statuts.rds` : toutes les lignes avec décisions.
- `data/processed/questionnaire_clean.rds` : lignes incluses dans la principale.
- `data/processed/questionnaire_exclus.rds` : lignes exclues et motifs.
- `outputs/tables/journal_corrections.csv` : événements de correction, même vide.
- `outputs/tables/traitement_doublons.csv` : groupes de copies, même vide.

Les deux sous-bases forment une partition de la table de décisions. Chaque
RDS est relu. Une sortie existante différente déclenche un arrêt et exige un
nouveau chemin/version ; aucune suppression silencieuse n'est effectuée.

```powershell
Rscript.exe R/05_quality.R
Rscript.exe R/06_cleaning.R
Rscript.exe tests/run_tests.R
```

## Réalisation de référence

L'exécution conserve 1 509 des 1 521 questionnaires (99,21 %) ; 12 sont
EXCLU_COMPLETION. La sélection de sensibilité comprend 1 441 questionnaires.
Aucune valeur hors domaine ni aucun doublon n'est présent : les journaux
correspondants comportent leurs en-têtes sans événement. Les tests exercent
néanmoins les corrections et les arbitrages sur des copies en mémoire.
