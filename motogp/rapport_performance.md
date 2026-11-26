# Rapport de performance — MotoGP

Mesures du 26 novembre 2026, avec PostgreSQL 17 dans Docker. Les trois benchmarks sont exécutés en SQL avec psql, dans `sql/benchmark.sql`.

## Jeu de test et méthode

La table temporaire `benchmark_wins` contient exactement **10 000 000 de lignes**, obtenues par répétition des 3 083 lignes de `analytics_marts.fct_wins`. Elle conserve la saison, le pilote, la catégorie, le constructeur et la mesure de victoire. Les sources et les marts ne sont pas modifiés. Le jeu de test disparaît à la fermeture de la session ; la base métier garde son volume réel.

Pour chaque benchmark : ANALYZE, trois EXPLAIN (ANALYZE, BUFFERS) sans index, création de l'index, ANALYZE, puis trois exécutions de la même requête. L'index est supprimé avant de passer au benchmark suivant. Les temps comparés sont les médianes de `Execution Time`, hors création de table et d'index. Les trois répétitions mesurent la variabilité ; elles ne remplacent pas les trois cas distincts.

## Résumé

| Benchmark | Sans index | Avec index | Différence | Temps en moins | Accélération |
|---|---:|---:|---:|---:|---:|
| Pilote + saison | 682.042 ms | 23.196 ms | 658.846 ms | 96.6 % | ×29.4 |
| Catégorie + saison | 1078.556 ms | 29.930 ms | 1048.626 ms | 97.2 % | ×36.0 |
| Constructeur depuis 2018 | 576.955 ms | 53.186 ms | 523.769 ms | 90.8 % | ×10.8 |

## Benchmark 1 — Pilote + saison

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT SUM(win_count) FROM benchmark_wins
WHERE season_key = 2021 AND rider_key = :'pilote_key';

CREATE INDEX benchmark_idx ON benchmark_wins (season_key, rider_key);

-- Réexécuter exactement le même EXPLAIN après CREATE INDEX.
```

Sans index, PostgreSQL parcourt les 10 millions de lignes (`Seq Scan`). Après indexation, il repère les lignes du filtre avec `Bitmap Index Scan`, puis lit les blocs concernés avec `Bitmap Heap Scan`.

Essais sans index : 682.042, 698.875, 575.977 ms. Avec index : 44.330, 21.538, 23.196 ms. Résultat identique avant et après : **16 220**, sur les données synthétiques.

## Benchmark 2 — Catégorie + saison

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT COUNT(*) FROM benchmark_wins
WHERE class_key = :'categorie_key' AND season_key = 2021;

CREATE INDEX benchmark_idx ON benchmark_wins (class_key, season_key);

-- Réexécuter exactement le même EXPLAIN après CREATE INDEX.
```

Sans index, PostgreSQL parcourt les 10 millions de lignes (`Seq Scan`). Après indexation, il repère les lignes du filtre avec `Bitmap Index Scan`, puis lit les blocs concernés avec `Bitmap Heap Scan`.

Essais sans index : 1238.645, 1032.564, 1078.556 ms. Avec index : 50.683, 29.930, 26.610 ms. Résultat identique avant et après : **58 392**, sur les données synthétiques.

## Benchmark 3 — Constructeur depuis 2018

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT SUM(win_count) FROM benchmark_wins
WHERE constructor_key = :'constructeur_key' AND season_key >= 2018;

CREATE INDEX benchmark_idx ON benchmark_wins (constructor_key) WHERE season_key >= 2018;

-- Réexécuter exactement le même EXPLAIN après CREATE INDEX.
```

Sans index, PostgreSQL parcourt les 10 millions de lignes (`Seq Scan`). Après indexation, il repère les lignes du filtre avec `Bitmap Index Scan`, puis lit les blocs concernés avec `Bitmap Heap Scan`.

Essais sans index : 810.745, 576.955, 535.771 ms. Avec index : 53.903, 53.067, 53.186 ms. Résultat identique avant et après : **68 124**, sur les données synthétiques.

L'index partiel exclut les saisons antérieures à 2018. Il est adapté à ce filtre récent, mais ne couvre pas les requêtes sur toutes les saisons.

## Plans et limites

Les 18 plans complets, les buffers et les contrôles d'égalité sont conservés dans `docs/performance/benchmark_sql.txt`. Les paramètres psql sélectionnent Quartararo, la catégorie MotoGP et Ducati depuis les dimensions, dans la même session.

Le volume est synthétique : il reproduit la distribution du petit fichier source, sans simuler de nouvelles courses. Les essais réchauffent le cache. Les résultats dépendent des filtres, de la largeur des lignes et de la machine. La construction et le stockage des index ont aussi un coût, non inclus dans les temps de lecture affichés. Ces gains ne se généralisent pas à toutes les requêtes.

Les mesures remplacent le benchmark précédent, qui ne contenait qu'un seul cas et une table moins large. Il ne faut pas mélanger leurs temps.

## Exécution

Depuis le dossier `motogp`, Docker démarré :

```bash
docker compose cp sql/benchmark.sql postgres:/tmp/benchmark.sql
docker compose exec postgres psql -X -U motogp -d motogp -f /tmp/benchmark.sql
```

Le fichier se lance entièrement avec psql : les variables et les tables temporaires doivent rester dans la même session.

## Autres éléments du jalon

Les six requêtes de `sql/requetes_avancees.sql` ont été exécutées sans erreur sur PostgreSQL : classement, LAG/LEAD, NTILE, fenêtre glissante, CTE récursive et enchaînement de CTE. Elles renvoient respectivement 97, 222, 289, 1 850, 9 et 18 lignes. La récursivité génère des décennies ; elle ne parcourt pas une hiérarchie métier.

`dbt debug` affiche `All checks passed!`. Le push Git reste à faire pour les fichiers modifiés.
