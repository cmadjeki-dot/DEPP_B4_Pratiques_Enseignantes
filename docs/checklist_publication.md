# Checklist avant publication

Audit du 11 septembre 2026. Les coches représentent des vérifications effectuées. Le second build et le déploiement Pages ont réussi ; le site public a été contrôlé.

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
- [x] Reproduction sur un environnement GitHub Actions vierge validée : run `34579079810`, 76 tests et 831 vérifications réussis.

Les sorties antérieures sont présentes pendant la vérification locale. L’analyse parallèle utilise un cache contrôlé si les entrées et versions concordent. La réussite locale ne suffit pas à certifier la reproduction sur une autre machine.

Avertissement non bloquant observé : `testthat` a été compilé sous R 4.6.1, contre R 4.6.0 pour l'exécution. Tous les tests ont réussi ; surveiller la compatibilité lors de la restauration distante, sans modifier automatiquement les versions verrouillées.

## Git et publication

- [x] Dépôt distant existant inspecté : un commit initial et un README seulement ; aucun workflow existant.
- [x] Historiques réunis sans force push ; branche `main` et remote vérifiés.
- [x] Commit final `8ee1450`, puis fusion `3258210` conservant le commit initial distant ; état propre contrôlé avant push.
- [x] Push confirmé vers `origin/main`.
- [x] Pages configuré sur GitHub Actions, build et déploiement réussis (run `34579079810`).
- [x] Accueil, rapport, annexes, note, présentation, figures, liens et ancres publiés contrôlés : 180 vérifications HTTP, 49 URL uniques, aucun échec.
- [x] Mermaid rendu dans le README GitHub ; disposition verticale retenue pour améliorer la lisibilité.
- [x] Accueil et rapport locaux puis publiés vérifiés à 390 pixels avec émulation mobile : aucun débordement horizontal.

Le schéma utilise la syntaxe `flowchart TB` dans un bloc `mermaid`, prise en charge par [GitHub](https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/creating-diagrams). Le premier rendu horizontal fonctionnait mais réduisait excessivement les libellés ; la lecture verticale évite cet effet.

Le workflow sépare construction et déploiement, limite les droits Pages au second job et publie uniquement `_site`, conformément au [schéma GitHub Pages](https://docs.github.com/en/pages/getting-started-with-github-pages/using-custom-workflows-with-github-pages). R/Quarto et les dépendances sont restaurés avant le calcul ; aucun résultat individuel n’est envoyé comme artefact Pages.

## Conditions d'activation distante

L'authentification GitHub est opérationnelle : push confirmé et API Pages consultée. La source Pages est configurée sur `workflow`. Le premier build a bloqué sur la vérification des charges factorielles (incident détaillé ci-dessous), puis le second a réussi après correction contrôlée. Aucun jeton n'est écrit dans les sources ou la documentation.

Dans le dépôt GitHub, choisir **Settings → Pages → Build and deployment → Source : GitHub Actions**. Le workflow part sur un push vers `main` ou via **Actions → Reproduction et publication Quarto → Run workflow**. Les journaux sont conservés comme artefact même après un échec de calcul. Les étapes de rendu, tests et audit doivent réussir avant l'envoi de l'artefact Pages.

URL publiée et contrôlée :
`https://cmadjeki-dot.github.io/DEPP_B4_Pratiques_Enseignantes/`.

Le runner Windows et les versions R/Quarto correspondent au contexte local afin de limiter les différences numériques et d'encodage. Aucune empreinte de validation scientifique ne doit être actualisée automatiquement pour contourner un échec.

## Incident du premier build et correction contrôlée

Le run `34575612681` a échoué en étape 10 : l'empreinte du CSV des charges différait. Le calcul avait retrouvé huit facteurs, mais ce seul constat ne suffit pas à autoriser les scores.

La référence locale déjà approuvée est conservée dans `metadata/loadings_efa_reference.csv`, avec son empreinte originale inchangée. En cas d'empreinte différente du fichier recalculé, le contrôle exige les mêmes colonnes, items, facteurs et libellés, toutes les valeurs finies, et un écart absolu maximal de `1e-10` sur les charges. Ce seuil ne tolère que des différences numériques négligeables ; il ne permet ni permutation, ni changement de signe, ni changement substantiel de charges. La référence est protégée des conversions de fins de ligne par `.gitattributes`.

Le nouveau contrôle est testé avec identité, perturbation de `1e-12`, écart de `0,001`, item modifié et valeur manquante. Le second build a franchi ce contrôle, les analyses, le rendu et les tests ; une différence dépassant la tolérance restera bloquante lors des futures exécutions.

Après correction : 76 blocs testthat et 831 vérifications réussis localement puis sur GitHub. Le second run distant est `34579079810`. Le contrôleur HTTP `tests/audit_site_publication.py` a été exécuté sur le site local puis sur Pages : 180 contrôles, 49 URL uniques et aucun échec dans les deux cas. Le bilan public est dans `outputs/tables/audit_site_publie.csv`.

Le journal distant mesure un écart maximal de **2,376987 × 10⁻¹²** entre les charges recalculées et la référence, inférieur à `1e-10`. Il s'agit donc d'une différence numérique négligeable, sans remplacement de la référence ni assouplissement après observation. Les 17 étapes distantes ont pris 1 517,1 secondes, dont 1 249 secondes pour l'étape factorielle sans cache. Le run conserve les journaux et les charges recalculées comme artefact `journaux-pipeline`.

## Problèmes et limites restant à signaler

- Aucun lien cassé ni ressource absente détecté dans les cinq pages et leurs ressources internes contrôlées.
- L'audit HTTP ne couvre pas les liens vers des domaines externes, ni tous les navigateurs ou toutes les tailles d'écran.
- L'avertissement de compilation de testthat et les limites scientifiques demeurent documentés ; aucune conclusion empirique sur les enseignants réels n'est autorisée.
