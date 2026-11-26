# Vérification du rendu

Vérification du 26 novembre 2026, sur le code, les fichiers dbt générés et les résultats d'exécution. Références : liste du rendu de vendredi transmise dans le chat et diapositives 38 à 41 du support « Fondation SQL ».

## Rendu dbt de vendredi

| Demande | État et preuve |
|---|---|
| Sources → staging → intermediate → marts | Réalisé : six sources, six modèles staging, un intermediate et six marts. |
| Tests sur chaque couche | Réalisé : tests sources, staging, intermediate et marts ; 103 tests réussis au dernier lancement complet. |
| Test métier personnalisé | Réalisé : `tests/assert_wins_match_staging.sql` vérifie les totaux par saison et catégorie. |
| `dbt docs generate` | Réalisé : `target/catalog.json` et `target/manifest.json` générés ; documentation consultable. |
| Étoile dans les marts | Réalisé : `fct_wins` et cinq dimensions ; grain et mesure décrits dans `schema_etoile.md`. |
| Trois questions fondées sur l'étoile | Réalisé : `analyses/01_top_riders.sql`, `02_constructor_evolution.sql`, `03_rider_circuits.sql`. |
| Dépôt Git final | Dépôt poussé jusqu'au commit `87bde44`. Le nettoyage documentaire et la présentation ajoutés aujourd'hui restent à committer et pousser. |
| Présentation | Support de huit diapositives avec notes, prévu pour cinq minutes ; répétition en groupe à faire. |
| Datavis demandée en complément | Réalisée : trois graphiques modifiables dans `Presentation_MotoGP.pptx`, calculés depuis les résultats des analyses sur l'étoile. |

## Notions du cours

| Notion | Mise en œuvre |
|---|---|
| Matérialisations | Vues pour staging/intermediate, tables pour marts. |
| Documentation | Descriptions des modèles et colonnes en YAML, catalogue généré. |
| Snapshot SCD2 | `snap_circuits` avec stratégie `check` ; historique des attributs observés depuis le premier lancement. |
| Versioning | Git pour le code, CSV figés pour les données ; pas d'historique automatique des fichiers source. |
| Kimball | Processus : victoires ; grain : ligne source ; cinq dimensions ; mesure additive `win_count`. |

## Barème global du fil rouge — points encore incomplets

| Critère du support | Constat |
|---|---|
| Modélisation relationnelle — 3 points | Types et étoile documentés, clés sources techniques créées à l'import. Les marts ont des clés logiques et des tests, mais pas de PK/FK physiques. La normalisation relationnelle initiale reste à justifier et les contraintes à compléter si exigées. |
| SQL avancé — 4 points | RANK, DENSE_RANK, ROW_NUMBER, LAG/LEAD, NTILE, fenêtres et CTE présents dans `sql/requetes_avancees.sql`. La CTE récursive génère des décennies : elle ne parcourt pas une hiérarchie métier, demandée parmi les critères de la base. Pertinence à renforcer. |
| Performance — 3 points | Aucun benchmark MotoGP, plan EXPLAIN ANALYZE interprété ni gain avant/après index retrouvé dans le dépôt actuel. Partie à réaliser ; les anciens travaux F1 ne prouvent pas les performances MotoGP. |
| Pipeline dbt — 4 points | Réalisé : couches, tests et documentation. |
| Étoile — 2 points | Réalisée et cohérente avec les trois questions. |
| Oral — 3 points | Support disponible ; démonstration, maîtrise et réponses à préparer ensemble. |
| Qualité du livrable — 1 point | README simplifié, code organisé et documentation regroupée. Push final à faire. |
| Bonus streaming/asyncio — 1 point | Non réalisé, facultatif. |

## Informations à compléter

- Lien exact du dataset, auteur et licence : absents des fichiers fournis.
- Noms des membres et lien du dépôt dans le rendu.
- Fiche projet et dépôt Moodle : non vérifiables dans le dossier local.

La partie dbt du dernier énoncé est couverte. Le barème global ne peut pas être considéré comme entièrement couvert tant que les écarts ci-dessus restent ouverts. Les statuts ne constituent pas une prévision de note.
