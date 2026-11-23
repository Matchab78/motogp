# Base F1 locale et PopSQL

Les 14 CSV du dépôt Matchab78/f1datarace ont été inspectés intégralement au commit e1233bf0d74589783d5092d48a4d2d869d90b54f. 1 018 388 lignes sont conservées. Voir inspection.md pour toutes les colonnes, types, clés et nombres de NULL. La plage des années du fichier races est 1950–2026 : c'est le contenu du dépôt, sans validation externe de l'authenticité ou de l'exhaustivité des résultats.

PopSQL est une interface SQL : PostgreSQL stocke la base sur ton ordinateur. Utiliser PopSQL Desktop en connexion Direct pour accéder à localhost.

## Démarrer PostgreSQL

1. Installer Docker Desktop si nécessaire et le démarrer.
2. Ouvrir un terminal dans ce dossier décompressé.
3. Créer le fichier .env avec un mot de passe local :

```sh
python3 -c 'import secrets; from pathlib import Path; Path(".env").write_text("F1_PASSWORD=" + secrets.token_hex(24) + "\n")'
docker compose up -d --wait
docker compose exec -T db psql -U f1 -d f1 -v ON_ERROR_STOP=1 -f /scripts/import.sql
```

L'import crée le schéma f1 dans une transaction, charge les CSV, ajoute les clés étrangères et index, puis lance ANALYZE. Il refuse de remplacer un schéma f1 existant. Lancer l'import une seule fois ; en cas d'échec, corriger la cause puis relancer. Le volume Docker conserve les données après arrêt du conteneur. `docker compose stop` arrête le serveur sans supprimer les données.

## Connexion PopSQL Desktop

Preferences → Connections → Add new Connection → PostgreSQL.

| Paramètre | Valeur |
|---|---|
| Connection name | F1 local |
| Hostname | 127.0.0.1 |
| Port | 5433 |
| Database | f1 |
| Username | f1 |
| Password | Valeur F1_PASSWORD du fichier .env |
| Connection type | Direct |
| SSL | Désactivé pour ce serveur local |
| SSH | Désactivé |

Le port 5433 évite de prendre le port PostgreSQL habituel 5432 ; il doit être libre. Le serveur écoute uniquement sur 127.0.0.1. Ne pas partager le fichier .env. Ces identifiants sont créés au premier démarrage du volume ; changer ensuite .env ne change pas automatiquement le mot de passe déjà enregistré dans PostgreSQL.

Dans PopSQL, exécuter :

```sql
SELECT COUNT(*) FROM f1.results;
-- Attendu : 27700
```

Ouvrir ensuite requetes.sql. La première instruction définit le schéma pour la session ; on peut aussi préfixer chaque table par f1.

Attention : import.sql utilise la commande psql `\copy` et doit être lancé avec la commande terminal ci-dessus. Il ne peut pas être collé tel quel dans PopSQL.

## Fichiers et relations

| CSV / table | Lignes | Contenu |
|---|---:|---|
| seasons | 77 | Saisons |
| circuits | 78 | Circuits et coordonnées |
| constructors | 214 | Écuries |
| drivers | 867 | Pilotes |
| status | 141 | Statuts d'arrivée et d'abandon |
| races | 1 172 | Calendrier et horaires |
| constructor_results | 13 096 | Points des écuries par course |
| constructor_standings | 13 862 | Classement cumulé des écuries après chaque course |
| driver_standings | 35 838 | Classement cumulé des pilotes après chaque course |
| qualifying | 11 430 | Qualifications Q1/Q2/Q3 |
| results | 27 700 | Résultats des courses principales |
| sprint_results | 612 | Résultats des sprints |
| lap_times | 890 328 | Temps au tour |
| pit_stops | 22 973 | Arrêts aux stands |

races relie seasons et circuits. Les tables de résultats relient races, drivers, constructors et status selon leurs colonnes. lap_times et pit_stops relient races et drivers. Les classements cumulatifs ne doivent pas être additionnés entre courses.

## Nettoyage et limites

- Noms SQL en snake_case : driverId devient driver_id.
- Les marqueurs CSV `\N` deviennent NULL ; les points sont en NUMERIC pour préserver les fractions.
- Les durées et écarts restent en TEXT ; utiliser milliseconds pour les calculs. Les heures de calendrier et de passage aux stands sont TIME, sans fuseau ajouté arbitrairement.
- lap_times contient 1 979 occurrences excédentaires de la clé (race_id, driver_id, lap). Toutes les lignes sont conservées, avec lap_time_id comme clé technique. Dédupliquer explicitement avant une moyenne si nécessaire, par exemple avec SELECT DISTINCT race_id, driver_id, lap, position, time, milliseconds FROM f1.lap_times. Ne pas inclure lap_time_id dans ce DISTINCT.
- Les 1 172 entrées du calendrier ne correspondent qu'à 1 170 courses ayant des lignes dans results.
- Toutes les clés primaires retenues et les références étrangères ont été vérifiées sur l'intégralité des fichiers.

## Alternative immédiatement disponible : SQLite

f1.sqlite contient déjà les 14 tables, les données et les index, avec vérification d'intégrité réussie. Ouvrir ce fichier avec DB Browser for SQLite ou un client compatible SQLite. Cette alternative est distincte de la connexion PostgreSQL proposée pour PopSQL.

Les requêtes de requetes.sql fonctionnent dans SQLite en supprimant l'instruction SET search_path. SQLite utilise REAL pour les décimaux, contrairement à NUMERIC exact dans PostgreSQL.

## Validation effectuée

Base SQLite importée : 1 018 388 lignes ; PRAGMA integrity_check = ok ; aucune violation de clé étrangère. Les trois exemples de requêtes ont été exécutés dans SQLite. L'import PostgreSQL n'a pas pu être exécuté dans cet environnement car le moteur Docker n'était pas démarré ; le kit doit donc encore être validé par son premier lancement PostgreSQL.

Documentation :
- https://docs.popsql.com/docs/connecting-to-postgresql
- https://docs.popsql.com/docs/cloud-direct-connections
