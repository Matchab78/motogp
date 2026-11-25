SET search_path TO f1, public;
 
-- ============================================================================
-- 1. CLASSEMENT (RANK / DENSE_RANK / ROW_NUMBER)
-- ============================================================================
WITH points_saison AS (
    SELECT 
        ra.year,
        d.driver_id,
        d.forename || ' ' || d.surname AS pilote,
        SUM(r.points) AS total_points,
        COUNT(*) FILTER (WHERE r.position = 1) AS victoires
    FROM results r
    JOIN races ra ON r.race_id = ra.race_id
    JOIN drivers d ON r.driver_id = d.driver_id
    GROUP BY ra.year, d.driver_id, pilote
),
classement_saison AS (
    SELECT 
        year,
        pilote,
        total_points,
        victoires,
        RANK() OVER (PARTITION BY year ORDER BY total_points DESC, victoires DESC) AS rang_strict,
        DENSE_RANK() OVER (PARTITION BY year ORDER BY total_points DESC) AS rang_dense
    FROM points_saison
)
SELECT *
FROM classement_saison
WHERE rang_strict <= 3 AND year >= 2015
ORDER BY year DESC, rang_strict ASC;
 
 
-- ============================================================================
-- 2. LAG / LEAD
-- ============================================================================
SELECT 
    ra.year,
    ra.name AS grand_prix,
    d.surname AS pilote,
    lt.lap,
    lt.milliseconds AS temps_tour_ms,
    LAG(lt.milliseconds) OVER (PARTITION BY lt.race_id, lt.driver_id ORDER BY lt.lap) AS tour_prec_ms,
    LEAD(lt.milliseconds) OVER (PARTITION BY lt.race_id, lt.driver_id ORDER BY lt.lap) AS tour_suiv_ms,
    lt.milliseconds - LAG(lt.milliseconds) OVER (PARTITION BY lt.race_id, lt.driver_id ORDER BY lt.lap) AS ecart_prec_ms
FROM lap_times lt
JOIN races ra ON lt.race_id = ra.race_id
JOIN drivers d ON lt.driver_id = d.driver_id
WHERE ra.year = 2023 AND ra.round = 1 AND d.code = 'VER'
ORDER BY lt.lap
LIMIT 25;
 
 
-- ============================================================================
-- 3. NTILE
-- ============================================================================
WITH stats_pilotes AS (
    SELECT 
        d.driver_id,
        d.forename || ' ' || d.surname AS pilote,
        d.nationality,
        COUNT(*) AS nb_courses,
        ROUND(AVG(r.points), 2) AS moy_points_course
    FROM results r
    JOIN drivers d ON r.driver_id = d.driver_id
    GROUP BY d.driver_id, pilote, d.nationality
    HAVING COUNT(*) >= 20
)
SELECT 
    pilote,
    nationality,
    nb_courses,
    moy_points_course,
    NTILE(4) OVER (ORDER BY moy_points_course DESC) AS quartile_performance
FROM stats_pilotes
ORDER BY quartile_performance ASC, moy_points_course DESC;
 
 
-- ============================================================================
-- 4. FENÊTRE GLISSANTE (ROWS BETWEEN)
-- ============================================================================
SELECT 
    lt.race_id,
    d.code AS pilote,
    lt.lap,
    lt.milliseconds,
    ROUND(
        AVG(lt.milliseconds) OVER (
            PARTITION BY lt.race_id, lt.driver_id 
            ORDER BY lt.lap 
            ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
        ), 2
    ) AS moyenne_mobile_5_tours_ms,
    MIN(lt.milliseconds) OVER (
        PARTITION BY lt.race_id, lt.driver_id 
        ORDER BY lt.lap 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS meilleur_tour_cumule_ms
FROM lap_times lt
JOIN drivers d ON lt.driver_id = d.driver_id
WHERE lt.race_id = 1100 AND d.code IN ('VER', 'HAM', 'LEC')
ORDER BY d.code, lt.lap;
 
 
-- ============================================================================
-- 5. CTE RÉCURSIVE (WITH RECURSIVE)
-- ============================================================================
WITH RECURSIVE decennies (annee_debut) AS (
    -- Ancrage : première décennie de la F1
    SELECT 1950
    UNION ALL
    -- Étape récursive : incrément de 10 ans jusqu'en 2020
    SELECT annee_debut + 10
    FROM decennies
    WHERE annee_debut + 10 <= 2020
)
SELECT 
    d.annee_debut || 's' AS decennie,
    COUNT(ra.race_id) AS nb_grands_prix,
    COUNT(DISTINCT ra.circuit_id) AS nb_circuits_distincts
FROM decennies d
LEFT JOIN races ra 
    ON ra.year BETWEEN d.annee_debut AND d.annee_debut + 9
GROUP BY d.annee_debut
ORDER BY d.annee_debut;
 
 
-- ============================================================================
-- 6. ENCHAÎNEMENT DE CTEs
-- ============================================================================
WITH courses_hybrides AS (
    SELECT race_id, year
    FROM races
    WHERE year BETWEEN 2014 AND 2024
),
resultats_ecuries AS (
    SELECT 
        c.name AS ecurie,
        COUNT(*) AS total_departs,
        COUNT(*) FILTER (
            WHERE s.status = 'Finished' OR s.status LIKE '+% Lap%'
        ) AS arrivees_classees,
        SUM(r.points) AS total_points
    FROM results r
    JOIN courses_hybrides ch ON r.race_id = ch.race_id
    JOIN constructors c ON r.constructor_id = c.constructor_id
    JOIN status s ON r.status_id = s.status_id
    GROUP BY c.name
    HAVING COUNT(*) >= 50
),
synthese_fiabilite AS (
    SELECT 
        ecurie,
        total_departs,
        arrivees_classees,
        total_points,
        ROUND(100.0 * arrivees_classees / total_departs, 2) AS taux_fiabilite_pct,
        ROUND(total_points / total_departs, 2) AS points_par_depart
    FROM resultats_ecuries
)
SELECT *
FROM synthese_fiabilite
ORDER BY taux_fiabilite_pct DESC, points_par_depart DESC;
