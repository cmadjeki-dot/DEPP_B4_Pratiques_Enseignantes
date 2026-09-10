# Faisabilité, priorité et écarts exploratoires

> Données simulées à des fins de démonstration méthodologique. Les résultats présentés ne constituent pas des résultats officiels de la DEPP et ne décrivent pas la population réelle des enseignants.

Le script 04 enrichit les réponses principales avec huit FAIS, huit PRIO,
huit SCORE_PROV et huit GAP. Les paramètres sont dans `config/config.yml`,
dans l'ordre EXP, DIF, EVA, GCL, COL, NUM, DEV, REL. La graine est 20260915.
La sortie distincte `data/simulated/reponses_faisabilite_priorite.rds` conserve
les caractéristiques, les poids et les 48 items existants.

## Faisabilité

Le continu sous-jacent combine l'équipement (Faible/Moyen/Bon codé 0/1/2),
l'effectif de classe et log(1 + jours de formation). Ces prédicteurs sont
centrés et réduits sur les 2 000 enseignants avant non-réponse. Les coefficients
varient selon la dimension : équipement positif, effectif négatif et formation
positive. La convention d'équidistance des niveaux d'équipement est simulatoire.
Un bruit normal individuel commun (écart-type 0,30) et un bruit indépendant
par dimension (0,85) représentent les autres contraintes et perceptions.
Ces associations hypothétiques ne sont pas des effets causaux estimés.

## Priorité

Une préférence professionnelle latente spécifique à chaque dimension est
construite par O = 0,35 L + sqrt(1 − 0,35²) U, où L est le trait de pratiques
contextualisé et U une normale standard indépendante. La composante autonome
est majoritaire. Le continu de priorité est P = 0,80 O + 0,60 E, avec E normal
standard indépendant. La préférence domine donc l'erreur de mesure, tout en
restant seulement partiellement associée aux pratiques. Les coefficients ne
sont pas des corrélations empiriques imposées, notamment car Var(L) varie.

Les deux continus sont convertis en cinq catégories par quatre seuils
strictement croissants, décalés selon la dimension. Les libellés sont ceux
du dictionnaire : faisabilité actuelle et priorité sur les douze prochains mois.
Les fréquences et les corrélations de Spearman priorité/pratiques sont exportées
dans `outputs/tables/frequences_complements.csv` et `diagnostic_complements.csv`.
Ces diagnostics sont non pondérés ; aucun paramètre n'est ajusté aux résultats.

## Scores provisoires et limites des écarts

`SCORE_PROV_EXP` est la moyenne arithmétique des six items EXP ; même règle pour
les autres dimensions. Les six réponses sont exigées : une valeur manquante
interrompt le calcul à cette étape. Aucun score définitif `SCORE_EXP` n'est créé.
Les règles de complétude après non-réponse partielle seront définies ultérieurement.

`GAP_EXP = PRIO_EXP − SCORE_PROV_EXP`, et de même pour les huit dimensions.
Les moyennes sont comprises entre 1 et 5 et les écarts entre −4 et 4. Les GAP
peuvent être fractionnaires. Un signe positif indique seulement un code de
priorité supérieur à la moyenne des codes de fréquence dans cette convention.
Les deux échelles n'ont pas les mêmes ancrages sémantiques : cet écart n'est
ni une mesure validée de besoin, ni une distance métrique démontrée, ni une
preuve de déficit. Il ne doit pas servir à classer les enseignants ou décider
d'une intervention. Les scores définitifs attendront l'analyse psychométrique.

Les quatre contrôles sont ajoutés dans une sortie distincte, selon
[leur documentation](controles.md). La non-réponse partielle reste à simuler.
