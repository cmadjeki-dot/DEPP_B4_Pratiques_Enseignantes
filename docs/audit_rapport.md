# Audit du rapport scientifique avant publication

## Périmètre

Accueil, rapport scientifique et annexes HTML produits par Quarto lors de l'audit initial. La note décideur est désormais rédigée, rendue et incluse dans la navigation ; voir `audit_note_decideur.md`. Le statut courant de publication et de reproduction figure dans `checklist_publication.md`.

## Corrections apportées

1. **Configuration** : site HTML simple, navigation à trois entrées, langue française et répertoire `_site/`. Le dossier `docs/` n’est pas utilisé comme destination de rendu afin de préserver les sources méthodologiques.
2. **Environnement Windows** : utilisation du chemin court de Quarto pour éviter le défaut du lanceur installé avec les espaces de `Program Files`. Le chemin de R est fourni au processus, sans installation ni modification de l’environnement permanent.
3. **Chiffres** : remplacement des saisies manuelles de résultats par des expressions R et tableaux chargés. Les fichiers utilisés sont contrôlés par empreintes avant rendu ; les résultats obsolètes provoquent un arrêt.
4. **Dénominateurs** : distinction sélectionnés, répondants, inclus analytiques, cas complets factoriels et enseignants classés. Les GAP utilisent des paires disponibles ; les parts de profils portent sur les seuls classés.
5. **Méthodologie** : précision des contraintes et de la distance logit de calibration ; `anciennete_classe` est décrite comme durée numérique, non comme tranche. Les méthodes non pondérées sont distinguées des estimations survey.
6. **Légendes** : numérotation automatique des cinq tableaux et cinq figures du corps du rapport ; libellé français « Tableau », titres, sources et notes d’incertitude. Les alternatives textuelles des figures sont renseignées.
7. **Lisibilité** : coefficients sélectionnés dans le corps, matrices, diagnostics et détails en annexe. Les domaines observés des identifiants individuels ne sont pas reproduits dans le dictionnaire publié.
8. **Interprétation** : absence de conclusion causale, distinction importance pratique / significativité, mention de l’instabilité des classes et de l’absence de validation externe. Les écarts déclarés ne sont pas présentés comme besoins prouvés.
9. **Audit Windows** : encodage UTF-8 avec BOM du script PowerShell pour préserver les accents. L’autorisation d’exécution est limitée au processus d’audit.

## Vérifications reproductibles

`tests/audit_rapport.ps1` vérifie les trois pages, la langue, la mention de simulation, l’absence de références non résolues, les liens locaux, les ancres et les ressources HTML. Le détail des contrôles et leur résultat sont exportés dans `outputs/tables/audit_rapport.csv`. Les liens externes ne font pas l’objet d’un contrôle réseau exhaustif ; les références techniques utilisées ont été consultées.

Les chiffres clés sont chargés par `R/functions/rapport.R` ; les figures externes proviennent des résultats calculés. L’histogramme de scores est rendu à partir de la base analytique et des poids finaux, sans réestimer les modèles. La relecture porte également sur les titres, les formulations françaises, les répétitions et les sources des légendes.

## Limites conservées dans la version destinée à publication

La publication doit conserver intégralement les mentions de simulation, la portée exploratoire de la psychométrie et des profils, les incertitudes conditionnelles et l’absence de causalité. La génération HTML n’est pas une validation externe du questionnaire. Le PDF reste une possibilité ultérieure, sans moteur installé automatiquement.
