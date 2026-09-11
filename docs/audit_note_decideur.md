# Contrôle de la note décideur

La note comporte les neuf sections demandées. Sa longueur imprimée est de **trois pages A4**, sans annexe : messages principaux en première page, profils et figure en deuxième page, écarts et précautions en troisième page.

Huit indicateurs prioritaires sont explicitement sélectionnés dans `indicateurs_cles_decideur.csv` : participation, scores GCL et NUM, écarts DIF/COL/NUM, part du profil 2 et association équipement–NUM. Les autres dimensions de la figure servent à situer ces messages dans l’ensemble des mesures ; elles ne donnent pas lieu à une sélection supplémentaire de résultats clés.

Les cinq messages commencent par « Dans les données simulées » et distinguent constat, chiffre, interprétation et limite. Les valeurs et les intervalles proviennent des sorties calculées. Les écarts positifs sont calculés sur les paires disponibles, y compris le numérique dont l’intervalle inclut zéro. La sélection n’est donc pas fondée uniquement sur la significativité.

La figure représente les huit scores pondérés avec leurs intervalles à 95 %, sur une échelle commune 1–5. Les noms des profils sont neutres et leurs caractéristiques relatives sont extraites des moyennes observées. La faible stabilité de la partition est explicitement signalée.

Le rendu Quarto HTML a réussi. La mise en page HTML et la figure ont été inspectées visuellement. Le PDF est obtenu avec l’impression HTML d’Edge, déjà installé ; son nombre de pages a été vérifié dans le fichier produit. Aucun moteur LaTeX ni package supplémentaire n’a été installé. Il s’agit d’un PDF issu du navigateur, pas d’un rendu LaTeX.

La suite complète de tests vérifie notamment la correspondance des huit indicateurs avec les tableaux sources, les cinq messages et la présence de la figure. `tests/audit_rapport.ps1` couvre désormais les quatre pages du site, leurs ressources locales, leurs liens et la mention de simulation. Les sorties et le PDF restent ignorés par Git et sont reproductibles depuis les sources.
