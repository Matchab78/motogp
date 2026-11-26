# Benchmark SQL : avant et après index

Le fichier `sql/benchmark.sql` est exécuté par psql dans PostgreSQL. Il crée une table temporaire de 10 millions de lignes en répétant les faits. Les tables du projet ne sont pas modifiées.

## Protocole

1. Construire la table sans index et lancer ANALYZE.
2. Exécuter trois fois EXPLAIN (ANALYZE, BUFFERS) sur la somme des victoires de Fabio Quartararo en 2021.
3. Créer l'index B-tree (season_key, rider_key), puis relancer ANALYZE.
4. Exécuter trois fois exactement la même requête.
5. Comparer les plans, les temps médians et les résultats.

## Résultats du 26 novembre 2026

| Mesure | Sans index | Avec index |
|---|---:|---:|
| Essai 1 | 439.704 ms | 38.926 ms |
| Essai 2 | 446.953 ms | 19.133 ms |
| Essai 3 | 432.151 ms | 13.994 ms |
| Médiane | 439.704 ms | 19.133 ms |
| Résultat SQL | 16 220 | 16 220 |
| Accès aux données | Seq Scan | Bitmap Index Scan puis Bitmap Heap Scan |

Différence : 420.571 ms de moins, soit 95.6 % de temps en moins et une accélération de 23.0 fois sur ce test.

Le parcours séquentiel examine les 10 millions de lignes. Après création de l'index, PostgreSQL repère les lignes correspondant au filtre puis lit les blocs concernés. Les sorties complètes et les buffers sont dans `benchmark_sql.txt`.

Les données sont synthétiques et les essais réchauffent le cache. Le gain dépend du filtre, du cache et de la machine ; il ne se généralise pas à toutes les requêtes. Les tables temporaires disparaissent à la fermeture de la session.

## Exécuter

Depuis le dossier `motogp`, avec Docker démarré :

```bash
docker compose cp sql/benchmark.sql postgres:/tmp/benchmark.sql
docker compose exec postgres psql -X -U motogp -d motogp -f /tmp/benchmark.sql
```

Le script utilise les commandes psql `\gset` et `\echo` : lancer le fichier entier avec psql pour conserver les variables et les tables temporaires dans la même session.
