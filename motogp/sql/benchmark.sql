-- PostgreSQL / psql. À lancer dans une même session.
-- Les tables TEMP disparaissent à la fermeture ; les marts restent inchangés.
\set ON_ERROR_STOP on
\pset pager off
\timing on

CREATE TEMP TABLE benchmark_wins AS
SELECT f.season_key, f.rider_key, f.win_count
FROM generate_series(1, 3244) AS repetition
CROSS JOIN analytics_marts.fct_wins AS f
LIMIT 10000000;

SELECT COUNT(*) AS lignes_de_test FROM benchmark_wins;

-- Même pilote et même saison dans tous les essais.
SELECT rider_key AS pilote_key
FROM analytics_marts.dim_riders
WHERE rider_name = 'Fabio Quartararo'
ORDER BY rider_country NULLS LAST
LIMIT 1
\gset

ANALYZE benchmark_wins;

\echo 'TEST 1 : SANS INDEX — trois executions de la meme requete'
EXPLAIN (ANALYZE, BUFFERS)
SELECT SUM(win_count) FROM benchmark_wins
WHERE season_key = 2021 AND rider_key = :'pilote_key';
EXPLAIN (ANALYZE, BUFFERS)
SELECT SUM(win_count) FROM benchmark_wins
WHERE season_key = 2021 AND rider_key = :'pilote_key';
EXPLAIN (ANALYZE, BUFFERS)
SELECT SUM(win_count) FROM benchmark_wins
WHERE season_key = 2021 AND rider_key = :'pilote_key';

CREATE TEMP TABLE resultat_avant AS
SELECT SUM(win_count) AS victoires FROM benchmark_wins
WHERE season_key = 2021 AND rider_key = :'pilote_key';

CREATE INDEX benchmark_saison_pilote_idx
ON benchmark_wins (season_key, rider_key);

ANALYZE benchmark_wins;

\echo 'TEST 2 : AVEC INDEX — trois executions de la meme requete'
EXPLAIN (ANALYZE, BUFFERS)
SELECT SUM(win_count) FROM benchmark_wins
WHERE season_key = 2021 AND rider_key = :'pilote_key';
EXPLAIN (ANALYZE, BUFFERS)
SELECT SUM(win_count) FROM benchmark_wins
WHERE season_key = 2021 AND rider_key = :'pilote_key';
EXPLAIN (ANALYZE, BUFFERS)
SELECT SUM(win_count) FROM benchmark_wins
WHERE season_key = 2021 AND rider_key = :'pilote_key';

CREATE TEMP TABLE resultat_apres AS
SELECT SUM(win_count) AS victoires FROM benchmark_wins
WHERE season_key = 2021 AND rider_key = :'pilote_key';

\echo 'CONTROLE : resultat identique avant / apres index'
SELECT a.victoires AS avant_index, b.victoires AS apres_index,
       a.victoires = b.victoires AS resultats_identiques
FROM resultat_avant AS a CROSS JOIN resultat_apres AS b;

-- Comparer les six lignes "Execution Time" : médiane des trois essais par test.
-- Le plan, les buffers lus et le temps sont affichés pour chaque essai.
-- Les données sont synthétiques et les essais réchauffent le cache.
