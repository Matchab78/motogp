# Validation

Projet exécuté le 26 novembre 2026 avec dbt-core 1.10.15 et dbt-postgres 1.9.1, sous Python 3.12, sur PostgreSQL, puis sur la base Docker locale.

- `dbt build` : 13 modèles, un snapshot et 103 tests réussis, aucune erreur.
- `dbt docs generate` : catalogue et manifeste générés.
- Trois analyses métier et un audit qualité compilés, exécutés et exportés dans `target/results/`.
- `fct_wins` : 3 083 lignes et 3 083 victoires enregistrées.

| Dimension | Lignes |
|---|---:|
| Pilotes | 388 |
| Constructeurs | 89 |
| Circuits | 71 |
| Saisons | 74 |
| Catégories | 9 |

Sur une base de test isolée, le snapshot sans changement conserve ses 72 versions initiales. Une modification d'attribut crée une nouvelle version et clôture l'ancienne. Un total de victoires volontairement faussé fait échouer le test métier ; après restauration, les tests repassent.

L'audit relève neuf occurrences supplémentaires de lignes identiques, 28 constructeurs manquants et 65 pays de pilotes manquants. Toutes les lignes de victoires trouvent un circuit dans le référentiel. Ces contrôles ne prouvent pas l'exhaustivité ou l'exactitude historique du dataset.
