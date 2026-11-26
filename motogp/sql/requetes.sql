-- PostgreSQL. Sources : les six CSV de outputs/f1-local/data2.
-- f1 est le nom technique du schéma déclaré dans votre sources.yml dbt.
-- Si vous utilisez import_motogp.sql, remplacez f1 par motogp ci-dessous.
SET search_path TO f1, public;

-- Les fichiers couvrent plusieurs catégories du championnat moto.
-- Pour la seule catégorie nommée MotoGP dans la source : WHERE class = 'MotoGP™'.
-- Les volumes ci-dessous comptent les lignes du fichier, sans dédoublonnage :
-- sans date ni identifiant de course, deux lignes identiques restent ambiguës.

-- 1. Question métier : quels pilotes totalisent le plus de victoires enregistrées ?
-- Adaptation du top des pilotes F1, toutes catégories présentes confondues.
SELECT rider AS pilote, COUNT(*) AS victoires_enregistrees
FROM grand_prix_race_winners
GROUP BY rider
ORDER BY victoires_enregistrees DESC, pilote
LIMIT 10;

-- 2. Question métier : quels pilotes gagnent le plus par saison et catégorie ?
-- Remplace les points F1 (absents de data2) par les victoires enregistrées.
-- Ne constitue pas le classement officiel du championnat.
SELECT season AS saison, class AS categorie, rider AS pilote,
       COUNT(*) AS victoires_enregistrees
FROM grand_prix_race_winners
GROUP BY season, class, rider
ORDER BY saison DESC, categorie, victoires_enregistrees DESC, pilote;

-- 3. Question métier : quelle période et quels circuits couvre le fichier ?
-- Pas de COUNT de courses : aucun identifiant de course dans data2.
SELECT MIN(season) AS premiere_saison, MAX(season) AS derniere_saison,
       COUNT(*) AS lignes_de_victoires,
       COUNT(DISTINCT circuit) AS circuits_distincts,
       COUNT(DISTINCT class) AS categories_distinctes
FROM grand_prix_race_winners;

-- 4. Question métier : où se situent les circuits des victoires enregistrées ?
-- Agrégation du référentiel avant jointure pour éviter de multiplier les lignes.
-- Country dans les vainqueurs désigne le pilote ; ici on utilise le pays du circuit.
WITH circuits AS (
    SELECT track, MIN(country) AS pays_circuit
    FROM grand_prix_events_held
    GROUP BY track
    HAVING COUNT(DISTINCT country) = 1
)
SELECT w.circuit, c.pays_circuit, COUNT(*) AS victoires_enregistrees
FROM grand_prix_race_winners w
LEFT JOIN circuits c ON c.track = w.circuit
GROUP BY w.circuit, c.pays_circuit
ORDER BY victoires_enregistrees DESC, w.circuit;

-- 5. Question métier : quels constructeurs remportent le plus de titres par catégorie ?
SELECT constructor AS constructeur, class AS categorie, COUNT(*) AS titres_enregistres
FROM constructor_world_championship
GROUP BY constructor, class
HAVING COUNT(*) >= 3
ORDER BY titres_enregistres DESC, constructeur, categorie;
