# Checklist avant publication

Audit du 11 septembre 2026. Les coches représentent des vérifications effectuées ; les étapes distantes restent à confirmer après déploiement.

## Sources et données

- [x] Arborescence essentielle présente ; scripts, fonctions, configurations et métadonnées séparés.
- [x] README précédent conservé intégralement dans `README_historique.md`.
- [x] README final : avertissement visible, méthode, limites, commandes et table des scripts.
- [x] Données individuelles et sorties volumineuses exclues ; seuls les `.gitkeep` sont suivis dans `data/` et `outputs/`.
- [x] Chemins de traitement relatifs dans R et Quarto ; paramètres Windows locaux dans `.vscode/settings.json` et dans les instructions historiques, sans répertoire personnel.
- [x] Aucun fichier temporaire ni identifiant secret détecté dans le périmètre versionné par les recherches ciblées. Ce contrôle ne constitue pas une certification exhaustive.
- [x] Questionnaire, dictionnaires, plan de sondage, règles qualité et limites documentés.

## Reproduction

- [x] `renv::restore(prompt = FALSE)` : bibliothèque déjà synchronisée avec le verrou.
- [x] Script maître créé avec processus isolés, statut, durée et arrêt sur erreur.
- [x] Pipeline complet terminé : 17 étapes, 729,8 secondes ; voir `outputs/pipeline_execution_log.txt`.
- [x] Tests complets exécutés après génération de la note : 75 blocs et 826 vérifications réussis, aucun échec ni test ignoré.
- [x] Rendu global et audit des liens terminés sans erreur.
- [ ] Reproduction sur un environnement GitHub Actions vierge validée.

Les sorties antérieures sont présentes pendant la vérification locale. L’analyse parallèle utilise un cache contrôlé si les entrées et versions concordent. La réussite locale ne suffit pas à certifier la reproduction sur une autre machine.

Avertissement non bloquant observé : `testthat` a été compilé sous R 4.6.1, contre R 4.6.0 pour l'exécution. Tous les tests ont réussi ; surveiller la compatibilité lors de la restauration distante, sans modifier automatiquement les versions verrouillées.

## Git et publication

- [x] Dépôt distant existant inspecté : un commit initial et un README seulement ; aucun workflow existant.
- [x] Historiques réunis sans force push ; branche `main` et remote vérifiés.
- [x] Commit final `8ee1450`, puis fusion `3258210` conservant le commit initial distant ; état propre contrôlé avant push.
- [x] Push confirmé vers `origin/main`.
- [ ] Pages configuré sur GitHub Actions, build et déploiement réussis.
- [ ] Accueil, rapport, figures, liens et navigation publiés contrôlés.
- [x] Mermaid rendu dans le README GitHub ; disposition verticale retenue pour améliorer la lisibilité.
- [x] Accueil et rapport locaux vérifiés à 390 pixels avec émulation mobile : aucun débordement horizontal. Contrôle des URL publiées encore à effectuer.

Le schéma utilise la syntaxe `flowchart TB` dans un bloc `mermaid`, prise en charge par [GitHub](https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/creating-diagrams). Le premier rendu horizontal fonctionnait mais réduisait excessivement les libellés ; la lecture verticale évite cet effet.

Le workflow sépare construction et déploiement, limite les droits Pages au second job et publie uniquement `_site`, conformément au [schéma GitHub Pages](https://docs.github.com/en/pages/getting-started-with-github-pages/using-custom-workflows-with-github-pages). R/Quarto et les dépendances sont restaurés avant le calcul ; aucun résultat individuel n’est envoyé comme artefact Pages.

## Conditions d'activation distante

L'authentification GitHub est désormais opérationnelle : push confirmé et API Pages consultée. La source Pages est déjà configurée sur `workflow`. Le premier build vierge a restauré renv et installé R/Quarto avec succès, puis a bloqué sur la vérification des charges factorielles (incident détaillé ci-dessous). Ne jamais écrire de jeton dans les sources ou la documentation.

Dans le dépôt GitHub, choisir **Settings → Pages → Build and deployment → Source : GitHub Actions**. Le workflow part sur un push vers `main` ou via **Actions → Reproduction et publication Quarto → Run workflow**. Les journaux sont conservés comme artefact même après un échec de calcul. Les étapes de rendu, tests et audit doivent réussir avant l'envoi de l'artefact Pages.

URL cible, à ne présenter comme publiée qu'après contrôle :
`https://cmadjeki-dot.github.io/DEPP_B4_Pratiques_Enseignantes/`.

Le runner Windows et les versions R/Quarto correspondent au contexte local afin de limiter les différences numériques et d'encodage. Aucune empreinte de validation scientifique ne doit être actualisée automatiquement pour contourner un échec.

## Incident du premier build et correction contrôlée

Le run `34575612681` a échoué en étape 10 : l'empreinte du CSV des charges différait. Le calcul avait retrouvé huit facteurs, mais ce seul constat ne suffit pas à autoriser les scores.

La référence locale déjà approuvée est conservée dans `metadata/loadings_efa_reference.csv`, avec son empreinte originale inchangée. En cas d'empreinte différente du fichier recalculé, le contrôle exige les mêmes colonnes, items, facteurs et libellés, toutes les valeurs finies, et un écart absolu maximal de `1e-10` sur les charges. Ce seuil ne tolère que des différences numériques négligeables ; il ne permet ni permutation, ni changement de signe, ni changement substantiel de charges. La référence est protégée des conversions de fins de ligne par `.gitattributes`.

Le nouveau contrôle est testé avec identité, perturbation de `1e-12`, écart de `0,001`, item modifié et valeur manquante. Le prochain build doit établir si l'écart distant est effectivement dans cette tolérance ; sinon, il restera bloqué et nécessitera une revue.
