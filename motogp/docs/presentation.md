# Trame de présentation du groupe

## 1. Sujet et données

Présenter les membres, la provenance et la licence vérifiées du dataset. Expliquer la différence entre championnats moto historiques et catégorie MotoGP moderne. Montrer la période réellement couverte et la saison 2022 partielle.

## 2. Architecture

Montrer le DAG dbt et les six sources, les vues de staging, l'enrichissement des circuits et les marts. Expliquer `source()` et `ref()`, et pourquoi une vue suffit aux couches de préparation sur ce volume.

## 3. Étoile et grain

Afficher `schema_etoile.md`. Expliquer une ligne de fait, les cinq dimensions, `win_count` et les clés techniques. Signaler les doublons apparents et les identités de pilotes non réconciliées.

## 4. Démonstration

Lancer `python run.py all`, montrer le résultat des tests puis `python run.py docs`. Dans le catalogue, ouvrir `fct_wins` et afficher sa lignée et ses colonnes. Ouvrir les trois CSV dans `target/results` pour répondre aux trois questions. Choisir une saison/catégorie et expliquer un chiffre réellement calculé, sans présenter le rang par victoires comme le classement officiel.

## 5. SCD2

Ouvrir `analytics_snapshots.snap_circuits`. Montrer `dbt_valid_from` et `dbt_valid_to`. Sur un deuxième lancement sans modification, le nombre de versions reste identique.

Pour montrer un changement réel, utiliser exclusivement une copie de démonstration des sources, dans une base/schéma isolé : modifier une valeur de circuit dans cette copie, relancer le pipeline, constater l'ancienne version clôturée et la nouvelle version courante, puis restaurer la valeur et relancer. Ne pas modifier les données partagées du groupe pour la démonstration. Le premier lancement ne peut montrer qu'une seule version initiale par circuit.

## 6. Analyse critique

Ouvrir `04_quality_audit.csv`. Expliquer les valeurs manquantes, les limites des jointures par nom et l'absence de points ou de temps au tour. Ne pas joindre de force les statistiques de carrière incohérentes. Proposer une source avec identifiants de pilotes, dates de course et historique complet comme amélioration.

## Avant vendredi 9h15

- Tous les tests `dbt build` passent sur la base du groupe.
- La documentation est générée et le DAG est accessible.
- Les trois questions utilisent bien les faits et dimensions.
- Chaque membre sait expliquer une partie du pipeline.
- Le lien de provenance et la licence sont renseignés.
- Le dépôt final est poussé et le camarade peut le cloner.
- Les CSV de résultats et captures de démonstration sont disponibles pour l'oral.
