-- PostgreSQL / PopSQL : exécuter cette ligne avant les requêtes.
SET search_path TO f1, public;

-- 1. CLASSEMENT (DENSE_RANK) : Classement annuel des pilotes par total de points
-- Objectif : Nous voulons classer les pilotes selon leur total de points pour chaque saison.
-- nnous utilisons DENSE_RANK() OVER (PARTITION BY ... ORDER BY ...) :
-- nous découpons le classement par saison (le rang repart à 1 chaque année).
-- triage des pilotes du plus grand total de points au plus petit à l'aide de order by.
SELECT
    ra.year AS saison,
    d.forename || ' ' || d.surname AS pilote,
    SUM(re.points) AS total_points,
    DENSE_RANK() OVER (
        PARTITION BY ra.year
        ORDER BY SUM(re.points) DESC
    ) AS rang_saison
FROM results re
JOIN races ra ON re.race_id = ra.race_id
JOIN drivers d ON re.driver_id = d.driver_id
GROUP BY ra.year, d.driver_id, d.forename, d.surname
ORDER BY saison DESC, rang_saison ASC
LIMIT 15;


-- Requête 2 : Évolution des points d'un pilote par rapport à sa course précédente
-- Utilise la fonction de décalage LAG() :
-- - PARTITION BY ra.year, d.driver_id isole l'historique de chaque pilote par saison.
-- - ORDER BY ra.round ASC classe les courses dans l'ordre chronologique du calendrier.
-- - LAG(re.points, 1, 0) récupère les points de la course précédente (0 pour la 1re manche).
SELECT
    ra.year AS saison,
    ra.round AS manche,
    ra.name AS grand_prix,
    d.forename || ' ' || d.surname AS pilote,
    re.points AS points_actuels,
    LAG(re.points, 1, 0) OVER (
        PARTITION BY ra.year, d.driver_id
        ORDER BY ra.round ASC
    ) AS points_course_prec,
    re.points - LAG(re.points, 1, 0) OVER (
        PARTITION BY ra.year, d.driver_id
        ORDER BY ra.round ASC
    ) AS evolution_points
FROM results re
JOIN races ra ON re.race_id = ra.race_id
JOIN drivers d ON re.driver_id = d.driver_id
WHERE ra.year >= 2020
ORDER BY saison DESC, pilote ASC, manche ASC
LIMIT 20;


-- Requête 3 : Répartition en 4 quartiles de rapidité sur la saison 2023 uniquement
-- Utilise WHERE ra.year = 2023 pour cibler les pilotes de cette saison sans scanner toute l'historique,
-- puis NTILE(4) OVER (ORDER BY AVG(lt.milliseconds) ASC) pour les classer en 4 groupes égaux
-- du plus rapide au plus lent.
SELECT
    d.forename || ' ' || d.surname AS pilote,
    COUNT(*) AS nb_tours,
    ROUND(AVG(lt.milliseconds) / 1000.0, 3) AS temps_moyen_sec,
    NTILE(4) OVER (
        ORDER BY AVG(lt.milliseconds) ASC
    ) AS quartile_rapidite
FROM lap_times lt
JOIN drivers d ON lt.driver_id = d.driver_id
JOIN races ra ON lt.race_id = ra.race_id
WHERE ra.year = 2023
GROUP BY d.driver_id, d.forename, d.surname
ORDER BY quartile_rapidite ASC, temps_moyen_sec ASC;