# Mécanisme de non-réponse totale

> Données simulées à des fins de démonstration méthodologique. Les résultats présentés ne constituent pas des résultats officiels de la DEPP et ne décrivent pas la population réelle des enseignants.

## Modèle retenu

Pour chaque unité de l'échantillon initial, une indicatrice `repondant` est
tirée selon une loi de Bernoulli de probabilité p_i. La valeur 1 désigne un
répondant simulé et 0 un non-répondant. Il ne s'agit pas de réponses collectées.
La non-réponse partielle aux items sera traitée séparément.

\[
\operatorname{logit}(p_i)=\alpha + x_i^\top\beta,
\qquad R_i\mid x_i\sim\operatorname{Bernoulli}(p_i).
\]

Les coefficients sont des hypothèses de démonstration, sans interprétation
causale ni origine dans une enquête réelle :

| Caractéristique | Coefficient sur le logit |
|---|---:|
| Collège (référence : premier degré) | −0,20 |
| Privé sous contrat (référence : public) | −0,15 |
| REP (référence : hors EP) | −0,15 |
| REP+ (référence : hors EP) | −0,30 |
| Formation continue, par 5 jours | +0,25 |
| Bon équipement numérique (référence : faible ou moyen) | +0,15 |
| Ancienneté, par 10 ans | −0,08 |
| Effectif de classe, par 5 élèves | −0,15 |

L'intercept est résolu numériquement pour obtenir une **moyenne non pondérée
des probabilités de 0,75** sur les 2 000 unités initiales. Ce réglage fixe
l'espérance de 1 500 répondants, pas le nombre effectivement réalisé. Aucun
quota ni nouveau tirage n'est appliqué pour obtenir exactement 75 %.
Les tirages sont indépendants conditionnellement aux caractéristiques et
utilisent la graine dédiée 20260912.

Le mécanisme dépend uniquement de variables disponibles pour tous les individus
échantillonnés. Il correspond à une hypothèse MAR conditionnellement à ces
variables pour les futures réponses au questionnaire ; il ne dépend pas
directement de réponses ou traits latents inobservés. Dans le socle latent
sans effets contextuels, il ne crée pas nécessairement de biais sur les
traits. Les effets contextuels ajoutés au script 04 peuvent créer une association entre
probabilité de réponse et pratiques. Un scénario MNAR relèverait d'une analyse
de sensibilité distincte, non mise en œuvre ici.

## Fichiers et utilisation

- `echantillon_nonreponse.rds` conserve toutes les unités initiales et ajoute
  `prob_reponse_theorique` et `repondant`.
- `repondants.rds` contient uniquement les lignes où `repondant = 1`.
- Les deux fichiers sont enregistrés sous `data/simulated/` et ignorés par Git.
- `outputs/tables/controle_nonreponse.csv` présente les nombres et taux attendus
  et observés par strate, ainsi que la somme des poids initiaux des répondants.

`prob_reponse_theorique` est une information connue du simulateur, pas une
propension estimée accessible dans une enquête réelle. Elle pourra servir de
référence de validation ; l'ajustement opérationnel de non-réponse devra estimer
les probabilités à partir des informations disponibles, avec ses diagnostics.

Les `pi_h` et `poids_base` sont conservés à l'identique. La somme des poids des
seuls répondants n'est pas forcée à 100 000. Aucun poids corrigé n'est encore
calculé. Le modèle, l'intercept et les paramètres sont conservés dans les
attributs des fichiers.

## Continuité des traits latents

Le script 04 reconstitue les traits sur l'échantillon initial avec la graine
déjà utilisée, puis filtre les répondants par identifiant. Il ne redistribue
pas les traits en fonction du nombre de réponses. Le fichier provisoire de
réponse complète reste conservé ; la sortie courante est
`data/simulated/traits_latents_repondants.rds`. Le script 04 produit ensuite
les traits contextuels et les 48 items dans des fichiers distincts, selon
[la méthode documentée](simulation_items.md).

## Contrôles

Le scénario exécuté produit **1 521 répondants et 479 non-répondants**, soit
76,05 % de réponse observée pour 75 % attendus. Les probabilités individuelles
vont de 0,6090 à 0,8850. La somme des poids de base des répondants est d'environ
76 595,43 ; elle n'a pas été corrigée. Chaque strate conserve au moins 70 répondants.

Le script vérifie l'unicité des identifiants, les probabilités dans ]0 ; 1[,
les indicatrices dans {0,1}, la conservation des colonnes initiales et des poids,
les effectifs par strate, la reproductibilité et la relecture des RDS. Il
s'arrête si moins de deux répondants subsistent dans une strate, sans refaire
un tirage pour contourner cet échec. Une sortie différente déjà présente ne
peut pas être écrasée silencieusement.

```powershell
Rscript.exe tests/run_tests.R
Rscript.exe R/03_nonresponse.R
Rscript.exe R/04_questionnaire_simulation.R
```
