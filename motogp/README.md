# Fil rouge MotoGP — dbt et PostgreSQL

Projet prêt à exécuter sur la base PostgreSQL du groupe. Données : les six CSV `data2` inclus. Le nom historique du dossier parent `f1-local` et le schéma source par défaut `f1` ne désignent pas le sujet analysé.

## Démarrage pour la personne qui a accès à PostgreSQL

Prérequis : Python 3.10 à 3.13 (3.12 recommandé), PostgreSQL 15+ accessible, la base existante et un utilisateur pouvant lire les sources et créer des schémas/tables dans cette base. Le projet ne crée pas la base et ne modifie pas ses droits.

Ouvrir un terminal dans le dossier contenant ce README et `dbt_project.yml`, puis :

```bash
python run.py setup
python run.py configure
python run.py all
python run.py docs
```

Sur Mac/Linux, utiliser `python3` si `python` n'existe pas. Sur Windows, on peut utiliser `py -3.12` à la place de `python`. Le lanceur utilise ensuite automatiquement son environnement `.venv`, sans activation manuelle.

Pendant `configure`, renseigner l'hôte, le port, **le vrai nom de votre base**, l'utilisateur, le mot de passe et **le schéma où sont vos six tables**. `localhost` convient uniquement sur l'ordinateur qui héberge PostgreSQL. Si vos sources sont dans `motogp` plutôt que `f1`, saisir `motogp`. Ne pas reprendre aveuglément les valeurs par défaut. La connexion est stockée dans `.connection.json`, ignoré par Git.

`all` enchaîne `dbt debug`, vérification des six sources, `dbt build` (modèles, snapshot, tests), `dbt docs generate`, `dbt compile`, puis l'exécution en lecture seule des analyses. Toute erreur interrompt la suite.

Résultats :
- tables analytiques dans `analytics_marts` par défaut ;
- vues dans `analytics_staging` et `analytics_intermediate` ;
- historique dans `analytics_snapshots` ;
- quatre CSV de réponses/audit dans `target/results/` ;
- catalogue et manifeste dans `target/` ;
- documentation locale via `http://127.0.0.1:8080` après `docs` (Ctrl+C pour arrêter).

Les schémas de sortie sont reconstruits par dbt, les sources restent en lecture seule durant `all`. Changer le préfixe `analytics` à la configuration si ces noms sont déjà utilisés par un autre projet.

### Si les sources ne sont pas encore importées

Sur un schéma source ne contenant aucune des six tables :

```bash
python run.py import-data
python run.py all
```

L'import facultatif crée les tables en snake_case depuis les CSV inclus, dans une transaction. Il refuse toute table déjà présente, sans suppression ni écrasement. Sur les tables existantes, ne pas lancer cet import. Les colonnes attendues sont listées dans `scripts/datasets.json`. Si vos tables ont encore les en-têtes CSV (`Rider`, `Class`, etc.), elles doivent d'abord être normalisées ou importées dans un autre schéma vide avec ce lanceur.

### Utiliser directement les commandes dbt

`config/profiles.yml` contient seulement des références aux variables d'environnement. Si vous préférez votre profil `motogp` existant, conservez-le dans `~/.dbt/profiles.yml` et lancez vos commandes dbt habituelles. Définir `DBT_RAW_SCHEMA` si le schéma source n'est pas `f1`. Le lanceur, lui, utilise exclusivement son profil `config/profiles.yml` et la connexion configurée.

## Architecture et matérialisations

```text
sources (six tables PostgreSQL)
  └─ staging (six vues : nettoyage, types, conservation des valeurs manquantes)
       ├─ stg_circuits → snap_circuits (SCD2)
       └─ stg_race_winners + stg_circuits
            └─ int_race_winners_enriched (vue, LEFT JOIN contrôlée)
                 ├─ cinq dimensions (tables)
                 └─ fct_wins (table)
                      └─ trois analyses métier et un audit qualité
```

Les six sources sont déclarées, nettoyées et testées. L'étoile utilise les victoires et le référentiel des circuits. Les autres jeux restent disponibles en staging pour des analyses complémentaires ; leur simple présence ne justifie pas une jointure risquée.

## Méthode de Kimball et grain

1. Processus : analyser les victoires enregistrées dans les championnats moto.
2. Grain : **une ligne de victoire présente dans la source**, sans prétendre identifier une course de manière unique.
3. Dimensions : pilote, constructeur, circuit, saison, catégorie.
4. Mesure : `win_count = 1`, additive dans toutes les dimensions.

Schéma avec cardinalités : [docs/schema_etoile.md](docs/schema_etoile.md).

`win_id` est une empreinte des attributs nettoyés et du numéro d'occurrence parmi les lignes identiques. Ce numéro distingue les occurrences sans identifier la course réelle. Les doublons sont conservés. Les dimensions utilisent des empreintes déterministes des attributs métier, avec encodage de longueur pour distinguer NULL, texte vide et séparateurs. Les relations sont contrôlées par des tests dbt, pas par des contraintes FK physiques.

La dimension pilote distingue le nom et le pays source. Un pays absent peut donc créer un second membre pour un même nom. Les analyses regroupent explicitement par nom pour retrouver l'indicateur source, avec le risque d'homonymie indiqué. Une future table de correspondance validée permettrait de résoudre ces identités.

## Les trois questions métier sur l'étoile

1. Quels pilotes ont le plus de victoires enregistrées par saison et catégorie ? `analyses/01_top_riders.sql` : top 3 par RANK, ex aequo conservés.
2. Comment évolue la part des victoires de chaque constructeur par catégorie ? `analyses/02_constructor_evolution.sql` : années sans victoire à zéro, LAG et variation en points de pourcentage.
3. Sur quels circuits chaque pilote gagne-t-il le plus par catégorie ? `analyses/03_rider_circuits.sql` : top 3 des rangs, ex aequo conservés.

Exécution/export après construction : `python run.py questions`. Les SQL compilés sont dans `target/compiled/motogp/analyses/`, prêts à ouvrir dans un client SQL connecté à la même base. Les exercices SQL avancés précédents, indépendants de l'étoile, sont conservés dans `sql/`.

## Tests

- Sources : présence de valeurs sur un attribut obligatoire de chaque table ; le lanceur vérifie aussi toutes les colonnes requises.
- Chaque modèle staging : champs obligatoires, valeurs non négatives, unicité lorsque le grain le permet.
- Intermediate : unicité de `win_id`, valeurs obligatoires et conservation des lignes après enrichissement.
- Marts : clés uniques/non nulles, relations de la table de faits vers les dimensions, mesure égale à 1.
- Test métier personnalisé : `tests/assert_wins_match_staging.sql` compare les totaux staging et étoile par saison et catégorie. Aucune victoire ne doit disparaître ou être multipliée.
- Snapshot : identifiant de version unique et au plus une version courante par circuit.

Un test SQL singulier échoue s'il renvoie au moins une ligne. Les anomalies connues ne sont pas maquillées pour faire réussir les tests : le rapport qualité permet de les montrer séparément.

## Snapshot et versioning

`snap_circuits` suit les modifications du pays et du total historique déclaré, avec la stratégie `check` car les CSV n'ont pas de `updated_at`. Les colonnes `dbt_valid_from` et `dbt_valid_to` conservent les versions observées depuis le premier lancement. Relancer sans changement ne crée pas de nouvelle version. Le snapshot ne reconstitue pas le passé antérieur au premier lancement et ne sert pas à attribuer un pays historique à une victoire.

La procédure de démonstration SCD2 est dans `docs/presentation.md`. Git conserve les versions du code. Les CSV constituent un extrait figé et ne sont pas automatiquement rafraîchis depuis Internet.

## Limites des données et provenance

- 3 083 lignes de victoires dans les CSV fournis, de 1949 à 2022, réparties sur neuf catégories ; 2022 est partielle.
- Neuf occurrences supplémentaires de lignes brutes identiques : absence de date/identifiant de course pour décider s'il s'agit de doublons ou d'épreuves distinctes.
- 28 constructeurs et 65 pays de pilotes manquants dans le fichier des victoires.
- `country` dans les victoires désigne le pays du pilote, pas celui du circuit.
- Les libellés historiques de catégorie sont conservés ; `MotoGP™` n'implique pas que toutes les années relèvent du règlement moderne MotoGP.
- Aucun point, temps au tour, départ ou abandon : aucun classement officiel ou taux de fiabilité reconstitué.
- Des statistiques de carrière divergent entre fichiers. Les noms de `riders_info` sont inversés et certains noms de `riders_finishing_positions` sont répétés. Aucun rapprochement automatique avec les victoires.
- Le nombre d'événements déclaré dans le référentiel des circuits ne doit pas être ajouté aux victoires.
- **Lien exact du dataset, auteur et licence : à compléter par le groupe avant le rendu.** Ces informations ne figurent pas dans les CSV fournis. Ne pas déclarer une licence ouverte sans l'avoir vérifiée. Conserver le dépôt privé tant que les droits de redistribution de `data2` ne sont pas établis.

Les références techniques officielles utilisées sont [les profils dbt](https://docs.getdbt.com/docs/local/profiles.yml), [les variables d'environnement](https://docs.getdbt.com/reference/dbt-jinja-functions/env_var) et [les snapshots](https://docs.getdbt.com/docs/build/snapshots).

## Livraison Git

Voir [docs/livraison.md](docs/livraison.md). Ne jamais versionner `.connection.json`, `.venv`, `target`, `logs`, `.env` ou un profil contenant des mots de passe. Les résultats et captures nécessaires au rendu sont à exporter séparément après l'exécution du groupe.

## Validation réalisée

Le projet a été exécuté sur PostgreSQL avec les CSV fournis : 103 tests passent. Voir [le rapport de validation](docs/validation.md) pour les résultats mesurés et les limites de cette vérification.
