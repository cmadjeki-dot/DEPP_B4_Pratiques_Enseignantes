# Dimensions latentes continues — socle de simulation

> Données simulées à des fins de démonstration méthodologique. Les résultats présentés ne constituent pas des résultats officiels de la DEPP et ne décrivent pas la population réelle des enseignants.

## Périmètre et continuité

La première validation a utilisé les 2 000 unités sous une hypothèse provisoire
de réponse complète. Ce fichier est conservé comme référence. Désormais, le
[mécanisme de non-réponse](non_reponse.md) identifie les répondants simulés.
Le script 04 reconstitue les traits des 2 000 unités avec la même graine puis
sélectionne ces répondants par identifiant. La sortie courante est
`data/simulated/traits_latents_repondants.rds` ; aucune valeur latente n'est
réattribuée en fonction du statut de réponse. Les corrélations observées sont
recalculées sur les répondants et peuvent différer du diagnostic initial.

## Modèle

Chaque enseignant i reçoit un vecteur continu de huit traits suivant
une loi normale multivariée centrée, de covariance R :

\[
L_i \sim \mathcal{N}_8(0,R).
\]

La diagonale de R vaut 1. Les corrélations communes valent 0,20 ; six paires
ont des paramètres spécifiques : EXP–EVA 0,45 ; DIF–EVA 0,40 ; DIF–DEV 0,40 ;
COL–DEV 0,45 ; NUM–DEV 0,25 ; REL–GCL 0,30. Ces choix sont des hypothèses
de démonstration, pas des coefficients estimés sur des données enseignantes.

La matrice est symétrique et définie positive (valeur propre minimale environ
0,42436). Aucune corrélation n'excède 0,70. Aucune réparation automatique de
matrice n'est utilisée.

La simulation utilise la décomposition de Cholesky R = UᵀU. Une matrice Z de
normales standard indépendantes est multipliée à droite par U ; ses lignes
ont alors la covariance R. La graine est 20260911, avec les algorithmes
Mersenne-Twister, Inversion et Rejection fixés explicitement.

Les huit colonnes `latent_EXP` à `latent_REL` sont accompagnées de
`id_enseignant`, sans réponse ordinale ni score de questionnaire. Les traits
ne sont pas bornés entre 1 et 5. Ce fichier conserve le socle sans effets
contextuels. Le script produit ensuite une version contextuelle distincte et
les items ordinaux, avec un nouvel audit des corrélations : voir
[la simulation des items](simulation_items.md).

## Diagnostics

Le script affiche R, ses valeurs propres, la matrice observée, les écarts pour
les 28 paires, ainsi que les moyennes et écarts-types observés. Les corrélations
de Pearson sont **non pondérées** : elles évaluent le tirage multivarié dans
le groupe simulé, pas une estimation des pratiques dans la population.

La covariance et les moyennes empiriques ne sont ni forcées ni corrigées pour
reproduire exactement les paramètres théoriques. Leurs écarts sont attendus
pour un échantillon fini. Un écart absolu de corrélation supérieur à 0,10 est
signalé pour examen ; ce seuil descriptif n'est pas un test d'hypothèse.

Trois tableaux sont produits dans `outputs/tables/` :
`correlation_latente_theorique.csv`, `correlation_latente_observee.csv` et
`comparaison_correlations_latentes.csv`. Les tests contrôlent notamment la
définie-positivité, le rejet d'une matrice invalide, la covariance simulée sur
un effectif de contrôle et la reproductibilité. Le RDS est relu après sauvegarde.

```powershell
Rscript.exe tests/run_tests.R
Rscript.exe R/04_questionnaire_simulation.R
```
