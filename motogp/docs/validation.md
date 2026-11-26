# Vérification du projet

Validation réalisée le 26 novembre 2026 sur une instance PostgreSQL 17.5 temporaire et isolée, avec les six CSV `data2` inclus. Aucune connexion à la base du groupe n'a été utilisée.

Environnement : Python 3.12.16, dbt-core 1.10.15, dbt-postgres 1.9.1.

## Résultat

- `dbt build` : 13 modèles (7 vues, 6 tables), 1 snapshot et **103 tests réussis**, aucun avertissement, aucune erreur.
- `dbt docs generate` : catalogue et manifeste générés.
- `dbt compile` : quatre analyses compilées puis exécutées sur PostgreSQL et exportées en CSV.
- Analyse 1 : 1 019 lignes, analyse 2 : 7 936 lignes, analyse 3 : 2 118 lignes. Ces volumes comprennent toutes les saisons et catégories disponibles.

| Mart | Lignes |
|---|---:|
| `dim_riders` | 388 |
| `dim_constructors` | 89 |
| `dim_circuits` | 71 |
| `dim_seasons` | 74 |
| `dim_classes` | 9 |
| `fct_wins` | 3083 |

## Vérifications de comportement

- Deuxième exécution du snapshot sans changement : toujours 72 versions de circuits.
- Modification d'un pays dans la source de test : ancienne version clôturée, nouvelle version courante créée. Valeur restaurée ensuite. Le snapshot conserve bien l'historique de cette démonstration et 72 versions courantes.
- Modification volontaire d'une mesure de fait de 1 à 2 : le test métier de conservation des victoires échoue avec une ligne d'écart. Après restauration, les 103 tests passent à nouveau.
- Import facultatif relancé sur les tables existantes : refus sans écrasement ; 3 083 lignes source conservées.

## Audit des CSV fournis

| Indicateur | Valeur |
|---|---:|
| Lignes de victoires | 3 083 |
| Occurrences supplémentaires de lignes identiques après nettoyage | 9 |
| Constructeurs manquants | 28 |
| Pays de pilotes manquants | 65 |
| Victoires sans correspondance dans le référentiel de circuits | 0 |

Cette validation porte sur les CSV inclus et une base isolée. Le camarade doit encore configurer l'accès à votre PostgreSQL, puis exécuter `python run.py all` dans votre environnement. Les chemins, droits, schémas et éventuelles différences de données de votre base ne peuvent pas être validés sans cette connexion.
