# Génération des 48 items ordinaux

> Données simulées à des fins de démonstration méthodologique. Les résultats présentés ne constituent pas des résultats officiels de la DEPP et ne décrivent pas la population réelle des enseignants.

## Périmètre

Cette étape produit six items par dimension (EXP, DIF, EVA, GCL, COL, NUM, DEV,
REL) pour les répondants simulés. Elle ne génère pas encore FAIS, PRIO ou CTRL,
ni la non-réponse partielle aux items. Aucun score ni alpha cible n'est imposé.

## Effets contextuels

Le socle latent corrélé est conservé dans son fichier de référence. On lui
ajoute une composante contextuelle : L_id = L_id^(0) + X_i beta_d. Les trois
variables explicatives sont centrées et réduites sur l'échantillon initial de
2 000 unités, avant non-réponse : log(1 + jours de formation), équipement codé
0/1/2 (Faible/Moyen/Bon), log(1 + ancienneté). Le logarithme donne à la relation
avec l'ancienneté une forme croissante à rendements décroissants ; l'espacement
égal des catégories d'équipement est une convention de simulation.

| Variable transformée standardisée | Dimension | Coefficient |
|---|---|---:|
| Formation | DIF / EVA / DEV | 0,18 / 0,15 / 0,25 |
| Équipement | NUM | 0,35 |
| Ancienneté | EXP / GCL / REL | 0,12 / 0,18 / 0,08 |

Les autres coefficients sont nuls. La relation COL–DEV provient déjà du socle
corrélé : aucun effet causal supplémentaire de COL n'est ajouté. Tous ces
paramètres sont des hypothèses de démonstration. Les moyennes et variances
après ajout ne sont pas forcées à 0 et 1 ; la matrice de corrélation est
recalculée et vérifiée. La sélection des répondants et le partage de certaines
variables entre réponse et traits peuvent modifier les distributions.

## Modèle des items

Pour un enseignant i et un item j de dimension d :

\[
Y^*_{ij}=\lambda_j L_{id}-\varepsilon_{ij},
\qquad \varepsilon_{ij}\sim\mathcal N(0,\sigma_j^2).
\]

Les erreurs sont indépendantes entre items et enseignants, et indépendantes
des traits. Soustraire cette erreur centrée symétrique revient en loi à
l'ajouter. Les items ne sont donc pas simulés indépendamment marginalement :
ils partagent les traits de leur dimension et les corrélations entre dimensions.

Les paramètres, générés une seule fois avec la graine 20260913, sont :

- lambda_j uniforme entre 0,50 et 0,80 ;
- sigma_j = sqrt(1 − lambda_j²) × m_j, avec m_j uniforme entre 0,90 et 1,10 ;
- une difficulté commune aux quatre seuils de l'item, uniforme entre −0,35 et 0,35 ;
- quatre seuils de base (−1,20 ; −0,35 ; 0,40 ; 1,20), décalés selon la dimension
  puis perturbés séparément de ±0,10 au maximum.

Les décalages dimensionnels sont EXP −0,25 ; DIF +0,05 ; EVA −0,15 ; GCL −0,35 ;
COL +0,15 ; NUM +0,20 ; DEV +0,15 ; REL −0,25. Un décalage positif rend les
catégories élevées moins fréquentes, à trait donné. Ces différences ne sont
pas un classement réel des pratiques. Les quatre seuils doivent rester
strictement croissants ; leur validité est vérifiée, jamais réparée silencieusement.

Les saturations indiquées sont les coefficients du modèle générateur. Après
les effets contextuels et la variation de variance d'erreur, elles ne sont pas
exactement des saturations standardisées observées. Les paramètres précis des
48 items sont enregistrés dans `metadata/parametres_items.csv`.

Avec t_j0 = −∞ et t_j5 = +∞, la réponse vaut k si
t_j(k−1) < Y*_ij ≤ t_jk. Les codes sont 1 Jamais, 2 Rarement, 3 Parfois,
4 Souvent, 5 Très souvent. La graine des erreurs est 20260914. Ni les seuils
ni les paramètres ne sont ajustés après examen de l'alpha ou des fréquences.

## Sorties et diagnostics

- `data/simulated/traits_latents_contextuels.rds` : identifiants et huit traits
  après effets, séparés des réponses observables.
- `data/simulated/reponses_items_principaux.rds` : caractéristiques et poids
  des répondants, indicatrice de réponse, probabilité de réponse théorique et
  48 items. La probabilité théorique est une information du simulateur.
- `outputs/tables/frequences_items.csv` : cinq modalités par item, y compris
  les modalités éventuellement absentes.
- `outputs/tables/distributions_dimensions.csv` : fréquences regroupant les
  six items de chaque dimension, avec dénominateur 6 × nombre de répondants.
  Il ne s'agit pas de distributions de scores, ni d'observations indépendantes.
- `outputs/tables/correlation_latente_contextuelle.csv` : corrélations après effets.

Les diagnostics sont non pondérés et descriptifs. Ils portent sur les 48 items,
les bornes, l'absence de valeurs manquantes à ce stade, les extrêmes et la
reproductibilité. L'analyse psychométrique et l'examen de contenu ultérieurs
devront évaluer l'adéquation des échelles ; aucun item ne sera supprimé sur
le seul critère de l'alpha. Le modèle est volontairement plus simple qu'une
collecte réelle (pas encore de dépendances résiduelles ou de biais de déclaration).

```powershell
Rscript.exe tests/run_tests.R
Rscript.exe R/04_questionnaire_simulation.R
```
