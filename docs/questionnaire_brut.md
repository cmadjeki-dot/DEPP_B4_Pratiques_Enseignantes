# Livraison de la base brute de questionnaire

> Données simulées à des fins de démonstration méthodologique. Les résultats présentés ne constituent pas des résultats officiels de la DEPP et ne décrivent pas la population réelle des enseignants.

`R/04_questionnaire_brut.R` crée `data/simulated/questionnaire_brut.rds` depuis
la version imparfaite de la collecte, en vérifiant les caractéristiques et
informations de sondage avec l'échantillon initial. Aucun tirage aléatoire
n'est nécessaire : l'assemblage est déterministe.

La livraison contient les 20 colonnes de l'échantillon (identifiant,
caractéristiques, strates et poids), les 68 réponses du questionnaire et cinq
variables de terrain : repondant, statut_questionnaire, duree_secondes,
date_reponse_simulee, taux_completion. Les codes, classes R et valeurs manquantes
sont conservés tels quels, ainsi que tous les questionnaires commencés, y
compris les abandons. Aucune ligne n'est supprimée et aucune anomalie corrigée.

Le périmètre est de 1 521 questionnaires commencés : 594 complets, 902 partiels
et 25 abandons. Les 479 non-répondants totaux restent dans le suivi séparé
`echantillon_nonreponse.rds`. L'indicatrice repondant décrit la participation
initiale, pas la complétude ni l'acceptation du questionnaire après contrôle.
La livraison comprend 93 colonnes et conserve 2 908 réponses manquantes.

La probabilité théorique de réponse, les indicateurs d'anomalies injectées
et les attributs contenant les paramètres de simulation ne sont pas livrés :
ils ne seraient pas connus du statisticien dans une collecte réelle. Ils
restent disponibles dans les références et le registre de simulation pour
évaluer les futurs détecteurs. Les scores, GAP et recodages ne sont pas ajoutés.
Les poids de base sont ceux du plan de sondage, sans correction de non-réponse.

Le fichier est relu après sauvegarde et comparé intégralement à l'objet en
mémoire. Chaque colonne livrée doit être identique à la source. Une sortie
existante différente provoque un arrêt ; une sortie identique est conservée.
La mention de simulation et une provenance minimale accompagnent le RDS.

```powershell
Rscript.exe R/04_questionnaire_brut.R
Rscript.exe tests/run_tests.R
```

Le contrôle qualité utilisera cette livraison ; les vérités de simulation
seront consultées séparément pour évaluer les résultats de détection.
