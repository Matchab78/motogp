# MotoGP — Projet fil rouge

Analyse des victoires en championnats moto avec PostgreSQL, Docker et dbt.

## Installation

Prérequis : Docker Desktop et Python 3.12 (versions 3.10 à 3.13 compatibles).
Depuis ce dossier, copier `.env.example` en `.env`, puis lancer :

```bash
docker compose up -d --wait
python3.12 run.py setup
python3.12 run.py configure
python3.12 run.py import-data
python3.12 run.py all
```

`import-data` se lance une seule fois sur une base vide. Sur Windows, remplacer `python3.12` par `py -3.12`.

Connexion locale : hôte `127.0.0.1`, port `5433`, base et utilisateur `motogp`, schéma source `motogp`, préfixe de sortie `analytics`, SSL `prefer`. Le mot de passe est celui de `.env`. Les fichiers `.env` et `.connection.json` ne sont pas versionnés.

## Utilisation

Une fois l'installation terminée :

```bash
docker compose up -d --wait
python3 run.py all
python3 run.py docs
```

Le lanceur utilise automatiquement son environnement Python 3.12 pour dbt. `all` exécute `dbt debug`, `dbt build`, `dbt docs generate`, `dbt compile`, puis exporte les analyses. La documentation est accessible sur http://127.0.0.1:8080.

Pour interroger la base :

```bash
docker compose exec postgres psql -U motogp -d motogp
```

```sql
SELECT COUNT(*) FROM analytics_marts.fct_wins;
```

## Organisation

- `data2/` : six CSV sources.
- `models/staging/` : nettoyage et typage, sous forme de vues.
- `models/intermediate/` : enrichissement des victoires avec les circuits, sous forme de vue.
- `models/marts/` : cinq dimensions et la table `fct_wins`.
- `tests/` et fichiers YAML : contrôles de qualité et de cohérence.
- `snapshots/` : historique SCD2 des attributs des circuits.
- `analyses/` : trois questions métier et un audit qualité.
- `sql/` : exercices SQL simples et avancés sur les sources MotoGP.
- `target/results/` : résultats CSV générés par le lanceur, non versionnés.

## Données et analyse

Le grain est une ligne de victoire enregistrée dans le fichier source. La mesure `win_count` vaut 1. Les dimensions sont le pilote, le constructeur, le circuit, la saison et la catégorie.

Nos questions : quels pilotes gagnent le plus par saison et catégorie, comment évolue la part des victoires des constructeurs, et sur quels circuits les pilotes gagnent le plus ?

Les CSV contiennent 3 083 lignes de victoires, entre 1949 et 2022, sur neuf catégories. La couverture est partielle. Les neuf occurrences supplémentaires de lignes identiques sont conservées, faute d'identifiant de course. Les classements calculés ne sont pas les classements officiels du championnat.

Source : [Moto GP World Championship (1949–2022)](https://www.kaggle.com/datasets/alrizacelk/moto-gp-world-championship19492022/data), publié par ALİ RIZA CELİK (`alrizacelk`) sur Kaggle. Licence indiquée : **CC0 — domaine public**.

## Documents

- [Vérification des consignes](docs/verification_rendu.md)
- [Schéma en étoile](docs/schema_etoile.md)
- [Résultats de validation](docs/validation.md)
- [Présentation avec graphiques](docs/Presentation_MotoGP.pptx)

## Groupe

Quentin Ott, Mathis Chabault, Herman Tongo, Saoban Radji.

Le schéma demandé est dans `docs/schema_etoile.png`. Les plans et mesures avant/après index sont dans `docs/performance/`. Pour refaire le benchmark sur 10 M de lignes synthétiques : `.venv/bin/python scripts/benchmark.py` (Windows : `.venv\Scripts\python.exe scripts/benchmark.py`).
