-- PostgreSQL / psql : trois benchmarks distincts, trois essais avant et après.
-- Tables temporaires : les sources et les marts restent inchangés.
\set ON_ERROR_STOP on
\pset pager off
\timing on
CREATE TEMP TABLE benchmark_wins AS
SELECT f.season_key, f.rider_key, f.class_key, f.constructor_key, f.win_count
FROM generate_series(1, 3244) AS repetition
CROSS JOIN analytics_marts.fct_wins AS f
LIMIT 10000000;
SELECT COUNT(*) AS lignes_de_test FROM benchmark_wins;
SELECT rider_key AS pilote_key FROM analytics_marts.dim_riders
WHERE rider_name = 'Fabio Quartararo' ORDER BY rider_country NULLS LAST LIMIT 1
\gset
SELECT class_key AS categorie_key FROM analytics_marts.dim_classes
WHERE class_name = 'MotoGP™'
\gset
SELECT constructor_key AS constructeur_key FROM analytics_marts.dim_constructors
WHERE constructor_name = 'Ducati'
\gset
CREATE TEMP TABLE comparaison (benchmark integer, avant bigint, apres bigint);

-- BENCHMARK 1 : Victoires de Quartararo en 2021.
-- Un seul index testé à la fois pour isoler son effet.
ANALYZE benchmark_wins;
\echo 'B1_BEFORE : SANS INDEX'
EXPLAIN (ANALYZE, BUFFERS)
SELECT SUM(win_count) FROM benchmark_wins
WHERE season_key = 2021 AND rider_key = :'pilote_key';
EXPLAIN (ANALYZE, BUFFERS)
SELECT SUM(win_count) FROM benchmark_wins
WHERE season_key = 2021 AND rider_key = :'pilote_key';
EXPLAIN (ANALYZE, BUFFERS)
SELECT SUM(win_count) FROM benchmark_wins
WHERE season_key = 2021 AND rider_key = :'pilote_key';
INSERT INTO comparaison (benchmark, avant) SELECT 1, resultat FROM (SELECT SUM(win_count) FROM benchmark_wins
WHERE season_key = 2021 AND rider_key = :'pilote_key') AS t(resultat);
CREATE INDEX benchmark_idx ON benchmark_wins (season_key, rider_key);
ANALYZE benchmark_wins;
\echo 'B1_AFTER : AVEC INDEX'
EXPLAIN (ANALYZE, BUFFERS)
SELECT SUM(win_count) FROM benchmark_wins
WHERE season_key = 2021 AND rider_key = :'pilote_key';
EXPLAIN (ANALYZE, BUFFERS)
SELECT SUM(win_count) FROM benchmark_wins
WHERE season_key = 2021 AND rider_key = :'pilote_key';
EXPLAIN (ANALYZE, BUFFERS)
SELECT SUM(win_count) FROM benchmark_wins
WHERE season_key = 2021 AND rider_key = :'pilote_key';
UPDATE comparaison SET apres = (SELECT SUM(win_count) FROM benchmark_wins
WHERE season_key = 2021 AND rider_key = :'pilote_key') WHERE benchmark = 1;
DROP INDEX benchmark_idx;

-- BENCHMARK 2 : Victoires de la categorie MotoGP en 2021.
-- Un seul index testé à la fois pour isoler son effet.
ANALYZE benchmark_wins;
\echo 'B2_BEFORE : SANS INDEX'
EXPLAIN (ANALYZE, BUFFERS)
SELECT COUNT(*) FROM benchmark_wins
WHERE class_key = :'categorie_key' AND season_key = 2021;
EXPLAIN (ANALYZE, BUFFERS)
SELECT COUNT(*) FROM benchmark_wins
WHERE class_key = :'categorie_key' AND season_key = 2021;
EXPLAIN (ANALYZE, BUFFERS)
SELECT COUNT(*) FROM benchmark_wins
WHERE class_key = :'categorie_key' AND season_key = 2021;
INSERT INTO comparaison (benchmark, avant) SELECT 2, resultat FROM (SELECT COUNT(*) FROM benchmark_wins
WHERE class_key = :'categorie_key' AND season_key = 2021) AS t(resultat);
CREATE INDEX benchmark_idx ON benchmark_wins (class_key, season_key);
ANALYZE benchmark_wins;
\echo 'B2_AFTER : AVEC INDEX'
EXPLAIN (ANALYZE, BUFFERS)
SELECT COUNT(*) FROM benchmark_wins
WHERE class_key = :'categorie_key' AND season_key = 2021;
EXPLAIN (ANALYZE, BUFFERS)
SELECT COUNT(*) FROM benchmark_wins
WHERE class_key = :'categorie_key' AND season_key = 2021;
EXPLAIN (ANALYZE, BUFFERS)
SELECT COUNT(*) FROM benchmark_wins
WHERE class_key = :'categorie_key' AND season_key = 2021;
UPDATE comparaison SET apres = (SELECT COUNT(*) FROM benchmark_wins
WHERE class_key = :'categorie_key' AND season_key = 2021) WHERE benchmark = 2;
DROP INDEX benchmark_idx;

-- BENCHMARK 3 : Victoires de Ducati depuis 2018.
-- Un seul index testé à la fois pour isoler son effet.
ANALYZE benchmark_wins;
\echo 'B3_BEFORE : SANS INDEX'
EXPLAIN (ANALYZE, BUFFERS)
SELECT SUM(win_count) FROM benchmark_wins
WHERE constructor_key = :'constructeur_key' AND season_key >= 2018;
EXPLAIN (ANALYZE, BUFFERS)
SELECT SUM(win_count) FROM benchmark_wins
WHERE constructor_key = :'constructeur_key' AND season_key >= 2018;
EXPLAIN (ANALYZE, BUFFERS)
SELECT SUM(win_count) FROM benchmark_wins
WHERE constructor_key = :'constructeur_key' AND season_key >= 2018;
INSERT INTO comparaison (benchmark, avant) SELECT 3, resultat FROM (SELECT SUM(win_count) FROM benchmark_wins
WHERE constructor_key = :'constructeur_key' AND season_key >= 2018) AS t(resultat);
CREATE INDEX benchmark_idx ON benchmark_wins (constructor_key) WHERE season_key >= 2018;
ANALYZE benchmark_wins;
\echo 'B3_AFTER : AVEC INDEX'
EXPLAIN (ANALYZE, BUFFERS)
SELECT SUM(win_count) FROM benchmark_wins
WHERE constructor_key = :'constructeur_key' AND season_key >= 2018;
EXPLAIN (ANALYZE, BUFFERS)
SELECT SUM(win_count) FROM benchmark_wins
WHERE constructor_key = :'constructeur_key' AND season_key >= 2018;
EXPLAIN (ANALYZE, BUFFERS)
SELECT SUM(win_count) FROM benchmark_wins
WHERE constructor_key = :'constructeur_key' AND season_key >= 2018;
UPDATE comparaison SET apres = (SELECT SUM(win_count) FROM benchmark_wins
WHERE constructor_key = :'constructeur_key' AND season_key >= 2018) WHERE benchmark = 3;
DROP INDEX benchmark_idx;

\echo 'RESULTATS : les trois controles doivent afficher true'
SELECT benchmark, avant, apres, avant = apres AS resultats_identiques
FROM comparaison ORDER BY benchmark;
-- Comparer les médianes des Execution Time, les opérateurs et les buffers.
-- Données synthétiques, cache réchauffé : résultats propres à ces trois requêtes.
