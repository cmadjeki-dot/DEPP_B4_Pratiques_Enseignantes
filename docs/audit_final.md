# Audit final du démonstrateur

Évaluation critique du 11 septembre 2026, sur les sources et livrables disponibles. Les notes sont des appréciations argumentées, non une évaluation officielle de la DEPP ni un score issu d'une grille institutionnelle. Le statut technique de publication est suivi séparément dans `checklist_publication.md`.

| Axe | Note / 10 | Point fort | Faiblesse | Action corrective prioritaire |
|---|---:|---|---|---|
| Rigueur scientifique | 8 | Simulation, incertitudes et absence de causalité explicites | Dépendances inscrites dans le générateur | Confronter le protocole à une enquête et une validation externes avant toute application réelle |
| Méthodologie d’enquête | 8 | Inclusion connue, stratification, correction et calibration | Plan et mécanisme de non-réponse simplifiés | Étudier une sensibilité à une non-réponse non ignorable |
| Qualité du code | 7 | Fonctions réutilisables, arrêts explicites et tests | Style parfois compact ; noms de tests hétérogènes | Harmoniser progressivement le style sans changer les résultats |
| Reproductibilité | 7 | renv, graines, empreintes, maître et journaux | Premier calcul coûteux ; validation distante encore à confirmer | Valider un build GitHub Actions vierge et conserver son journal |
| Documentation | 8 | Dictionnaires, décisions, limites et deux README conservés | Volume élevé et traces historiques parfois vieillissantes | Distinguer systématiquement documents historiques et état courant |
| Psychométrie | 8 | Ordinalité prise en compte, contenu et diagnostics combinés | Absence de validation externe ; mesure issue du générateur | Examiner l’invariance et une validation confirmatoire sur de nouvelles données |
| Visualisation | 8 | Figures sobres, sources et incertitudes | Certaines figures détaillées demandent un grand écran | Contrôler les tableaux et figures sur mobile après déploiement |
| Restitution décisionnelle | 8 | Note courte et chiffres calculés automatiquement | Le lecteur pourrait surinterpréter les écarts déclarés | Maintenir les réserves au plus près des résultats |
| Valeur pour un entretien | 9 | Chaîne complète et présentation de neuf minutes | Risque de consacrer trop de temps aux détails techniques | Répéter et préparer deux exemples de décisions méthodologiques |
| Qualité du portfolio | 7 | Projet documenté avec rapport, note et présentation | Publication et liens publics non encore validés | Achever le déploiement, vérifier les URL et intégrer le bloc portfolio |

## Lecture selon les quatre rôles

- **Statisticien senior** : la distinction mesure, sondage, qualité et estimation est convaincante ; la validation sur données réelles reste hors périmètre.
- **Recruteur** : les livrables permettent de discuter des décisions, des erreurs et des compromis concrets ; préparer une démonstration courte.
- **Chef de bureau** : la traçabilité et la note facilitent la revue ; une étude de production nécessiterait prétests, validation collective et organisation opérationnelle.
- **Reviewer GitHub** : les sources et dépendances sont structurées ; le build distant doit apporter la preuve supplémentaire de portabilité.

## Avis

**PRÊT À ÊTRE PRÉSENTÉ** comme démonstrateur méthodologique local, en explicitant les limites et la stabilité faible de la typologie. Cet avis ne certifie ni une étude réelle ni une publication en ligne : les cases de déploiement non validées dans la checklist restent à traiter avant de présenter le site comme publié.
