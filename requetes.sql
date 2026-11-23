-- PostgreSQL / PopSQL : exécuter cette ligne avant les requêtes.
SET search_path TO f1, public;

-- Victoires par pilote (courses principales).
SELECT d.forename, d.surname, COUNT(*) AS victoires
FROM results r JOIN drivers d ON d.driver_id = r.driver_id
WHERE r.position_order = 1
GROUP BY d.driver_id, d.forename, d.surname
ORDER BY victoires DESC LIMIT 10;

-- Points par pilote et saison : inclut les sprints.
-- Somme des points attribués dans ces fichiers, pas une reconstitution
-- des anciens règlements à résultats décomptés ou sanctions au championnat.
WITH points AS (
  SELECT race_id, driver_id, points FROM results
  UNION ALL
  SELECT race_id, driver_id, points FROM sprint_results
)
SELECT ra.year, d.forename, d.surname, SUM(p.points) AS points
FROM points p JOIN races ra ON ra.race_id=p.race_id
JOIN drivers d ON d.driver_id=p.driver_id
GROUP BY ra.year, d.driver_id, d.forename, d.surname
ORDER BY ra.year DESC, points DESC;

-- Couverture réelle des résultats, distincte du calendrier.
SELECT MIN(ra.year) AS premiere_saison, MAX(ra.year) AS derniere_saison,
       COUNT(DISTINCT ra.race_id) AS courses_avec_resultats
FROM races ra JOIN results r ON r.race_id=ra.race_id;
