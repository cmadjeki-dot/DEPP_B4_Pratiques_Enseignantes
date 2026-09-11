# Audit final du démonstrateur

Évaluation critique du 11 septembre 2026, sur les sources et livrables disponibles. Les notes sont des appréciations argumentées, non une évaluation officielle de la DEPP ni un score issu d'une grille institutionnelle. Le statut technique de publication est suivi séparément dans `checklist_publication.md`.

| Axe | Note / 10 | Point fort | Faiblesse | Action corrective prioritaire |
|---|---:|---|---|---|
| Rigueur scientifique | 8 | Simulation, incertitudes et absence de causalité explicites | Dépendances inscrites dans le générateur | Confronter le protocole à une enquête et une validation externes avant toute application réelle |
| Méthodologie d’enquête | 8 | Inclusion connue, stratification, correction et calibration | Plan et mécanisme de non-réponse simplifiés | Étudier une sensibilité à une non-réponse non ignorable |
| Qualité du code | 7 | Fonctions réutilisables, arrêts explicites et tests | Style parfois compact ; noms de tests hétérogènes | Harmoniser progressivement le style sans changer les résultats |
| Reproductibilité | 8 | renv, graines, maître et reproduction GitHub Actions réussie après contrôle de portabilité | Premier calcul coûteux ; dépendance aux versions numériques | Conserver les journaux et revérifier lors des évolutions de versions |
| Documentation | 8 | Dictionnaires, décisions, limites et deux README conservés | Volume élevé et traces historiques parfois vieillissantes | Distinguer systématiquement documents historiques et état courant |
| Psychométrie | 8 | Ordinalité prise en compte, contenu et diagnostics combinés | Absence de validation externe ; mesure issue du générateur | Examiner l’invariance et une validation confirmatoire sur de nouvelles données |
| Visualisation | 8 | Figures sobres, sources et incertitudes ; accueil et rapport contrôlés sur mobile | Certaines figures détaillées demandent un grand écran | Élargir progressivement la vérification à d'autres tailles et navigateurs |
| Restitution décisionnelle | 8 | Note courte et chiffres calculés automatiquement | Le lecteur pourrait surinterpréter les écarts déclarés | Maintenir les réserves au plus près des résultats |
| Valeur pour un entretien | 9 | Chaîne complète et présentation de neuf minutes | Risque de consacrer trop de temps aux détails techniques | Répéter et préparer deux exemples de décisions méthodologiques |
| Qualité du portfolio | 8 | Dépôt et site publiés, rapport, note et présentation accessibles | Bloc préparé mais non intégré au portfolio principal | Ajouter le bloc Markdown au portfolio et maintenir les liens |

## Lecture selon les quatre rôles

- **Statisticien senior** : la distinction mesure, sondage, qualité et estimation est convaincante ; la validation sur données réelles reste hors périmètre.
- **Recruteur** : les livrables permettent de discuter des décisions, des erreurs et des compromis concrets ; préparer une démonstration courte.
- **Chef de bureau** : la traçabilité et la note facilitent la revue ; une étude de production nécessiterait prétests, validation collective et organisation opérationnelle.
- **Reviewer GitHub** : les sources et dépendances sont structurées ; le build distant réussi apporte une preuve supplémentaire de portabilité, avec le premier échec et sa correction documentés.

## Avis

**PRÊT À ÊTRE PRÉSENTÉ** comme démonstrateur méthodologique publié : le pipeline distant, les 76 tests, les 831 vérifications et le déploiement ont réussi ; le site passe les 180 contrôles HTTP. Cet avis ne certifie pas une étude réelle. Les limites de simulation, l'absence de validation externe et la stabilité faible de la typologie doivent rester explicites pendant l'entretien.
