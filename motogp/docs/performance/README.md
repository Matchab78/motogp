# Performance

Mesure sur PostgreSQL, le 26 novembre 2026, sur 10 millions de lignes synthétiques obtenues par répétition de fct_wins. Les marts et sources ne sont pas modifiés.

Requête : SUM(win_count) filtré par saison et pilote. Index B-tree composé (season_key, rider_key). Trois EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON) avant et après ; médianes retenues.

Sans index : 458.23 ms. Avec index : 14.33 ms. Accélération : 32.0 fois. Résultat identique : 25952.

Les plans sont dans benchmark.json. Les données sont synthétiques et les essais réchauffent le cache. Le gain dépend de la requête et de la machine ; il ne se généralise pas à toutes les analyses. Le schéma de test est supprimé en fin d'exécution.

Depuis le dossier projet : .venv/bin/python scripts/benchmark.py (Windows : .venv\Scripts\python.exe scripts/benchmark.py).
