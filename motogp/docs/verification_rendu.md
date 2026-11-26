# Vérification du rendu

Vérification du 26 novembre 2026, sur le code, les fichiers dbt générés et les résultats d'exécution. Références : support du jour « dbt.pptx », diapositives 17 à 19, 28 à 31 ; barème initial « Fondation SQL ».

## Rendu dbt de vendredi

| Demande | État et preuve |
|---|---|
| Sources → staging → intermediate → marts | Réalisé : six sources, six modèles staging, un intermediate et six marts. |
| Tests sur chaque couche | Réalisé : tests sources, staging, intermediate et marts ; 128 tests réussis au dernier lancement complet. |
| Test métier personnalisé | Réalisé : `tests/assert_wins_match_staging.sql` vérifie les totaux par saison et catégorie. |
| `dbt docs generate` | Réalisé : `target/catalog.json` et `target/manifest.json` générés ; documentation consultable. |
| Étoile dans les marts | Réalisé : `fct_wins` et cinq dimensions ; grain et mesure décrits dans `schema_etoile.md`. |
| Trois questions fondées sur l'étoile | Réalisé : `analyses/01_top_riders.sql`, `02_constructor_evolution.sql`, `03_rider_circuits.sql`. |
| Dépôt Git final | Dépôt poussé jusqu'au commit `87bde44`. Le nettoyage documentaire et la présentation ajoutés aujourd'hui restent à committer et pousser. |
| Présentation | Support de sept diapositives, avec noms, trois graphiques sur deux pages et notes pour cinq minutes, selon la consigne orale confirmée. Le support écrit prévoit 10 minutes + 5 minutes de questions. |
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
| Performance — 3 points | Réalisé : table de test de 10 M de lignes synthétiques issues des faits, EXPLAIN ANALYZE avant/après index B-tree, trois mesures par situation. Médianes : 458,225 ms puis 14,332 ms ; gain ×31,97 sur ce test. Plans et protocole dans `performance/`. |
| Pipeline dbt — 4 points | Réalisé : couches, tests et documentation. |
| Étoile — 2 points | Réalisée et cohérente avec les trois questions. |
| Oral — 3 points | Support corrigé disponible ; démonstration, maîtrise et réponses à préparer ensemble. |
| Qualité du livrable — 1 point | README simplifié, code organisé et documentation regroupée. Push final à faire. |
| Bonus streaming/asyncio — 1 point | Non réalisé, facultatif. |

## Informations à compléter

- Provenance vérifiée : [Moto GP World Championship (1949–2022)](https://www.kaggle.com/datasets/alrizacelk/moto-gp-world-championship19492022/data), ALİ RIZA CELİK (`alrizacelk`), Kaggle, licence CC0 — domaine public.
- Membres : Quentin Ott, Mathis Chabault, Herman Tongo, Saoban Radji. Dépôt : https://github.com/Matchab78/motogp.
- Fiche projet et dépôt Moodle : non vérifiables dans le dossier local.

La partie dbt du dernier énoncé est couverte. Le barème global ne peut pas être considéré comme entièrement couvert tant que les écarts ci-dessus restent ouverts. Les statuts ne constituent pas une prévision de note.

## Vérifications du support du jour

- Diapo 6 : staging limité au nettoyage et au typage ; calcul du numéro de doublon déplacé en intermediate.
- Diapo 18 : noms des modèles staging conformes à `stg_<source>__<table>`.
- Diapo 19 : unicité et non-nullité des clés techniques source et staging ; relation intermediate vers le référentiel circuits ; unicité et relations des marts. 128 tests passent.
- Diapo 28 : `docs/schema_etoile.png` fourni, avec les modèles dans `models/marts/`. Metabase est optionnel et n'est pas installé.
- Diapo 30 : noms des membres, sujet, modèle analytique, exemple SQL avancé, performance mesurée, pipeline et analyse critique présents dans le support corrigé. Le schéma relationnel normalisé initial reste incomplet ; l'étoile ne le remplace pas.
- Diapo 17 : revue croisée entre groupes et trois retours non attestés ; à confirmer avec le groupe.
- Le support ne formule pas une obligation de « trois publics ». La diapositive de livraison distingue l'équipe data, les utilisateurs SQL et les personnes sans SQL pour expliquer les usages.
