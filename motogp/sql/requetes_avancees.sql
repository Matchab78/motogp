-- PostgreSQL. Sources : les six CSV data2 importés dans le schéma motogp.
SET search_path TO motogp, public;

-- Indicateurs fondés sur les lignes disponibles, toutes catégories sauf indication.
-- Pas de points, départs, abandons, temps au tour ni identifiant/date de course.
-- Ne pas supprimer automatiquement les lignes identiques : leur nature est inconnue.

-- ============================================================================
-- 1. CLASSEMENT : RANK / DENSE_RANK / ROW_NUMBER
-- Question métier : qui sont les trois premiers rangs de vainqueurs par saison
-- et catégorie depuis 2015, selon les victoires enregistrées ?
-- Les ex aequo peuvent faire apparaître plus de trois pilotes.
-- ============================================================================
WITH victoires_saison AS (
    SELECT season AS saison, class AS categorie, rider AS pilote,
           COUNT(*) AS victoires
    FROM grand_prix_race_winners
    GROUP BY season, class, rider
), classement AS (
    SELECT *,
           RANK() OVER (PARTITION BY saison, categorie ORDER BY victoires DESC) AS rang,
           DENSE_RANK() OVER (PARTITION BY saison, categorie ORDER BY victoires DESC) AS rang_dense,
           ROW_NUMBER() OVER (PARTITION BY saison, categorie ORDER BY victoires DESC, pilote) AS numero_ligne
    FROM victoires_saison
)
SELECT * FROM classement
WHERE rang <= 3 AND saison >= 2015
ORDER BY saison DESC, categorie, rang, pilote;

-- ============================================================================
-- 2. LAG / LEAD
-- Question métier : comment évoluent les victoires de Valentino Rossi d'une
-- année à l'autre dans chaque catégorie où le fichier lui attribue une victoire ?
-- Remplace la comparaison de temps au tour. La grille annuelle inclut les zéros.
-- Un zéro signifie aucune victoire enregistrée, pas nécessairement une participation.
-- ============================================================================
WITH bornes AS (
    SELECT MIN(season) AS debut, MAX(season) AS fin FROM grand_prix_race_winners
), categories AS (
    SELECT DISTINCT class FROM grand_prix_race_winners WHERE rider = 'Valentino Rossi'
), annuel AS (
    SELECT season, class, COUNT(*) AS victoires
    FROM grand_prix_race_winners WHERE rider = 'Valentino Rossi'
    GROUP BY season, class
), grille AS (
    SELECT s.saison, c.class AS categorie, COALESCE(a.victoires, 0) AS victoires
    FROM bornes b
    CROSS JOIN LATERAL generate_series(b.debut, b.fin) AS s(saison)
    CROSS JOIN categories c
    LEFT JOIN annuel a ON a.season = s.saison AND a.class = c.class
), comparaison AS (
    SELECT *,
           LAG(victoires) OVER (PARTITION BY categorie ORDER BY saison) AS victoires_annee_precedente,
           LEAD(victoires) OVER (PARTITION BY categorie ORDER BY saison) AS victoires_annee_suivante
    FROM grille
)
SELECT *, victoires - victoires_annee_precedente AS ecart_annuel
FROM comparaison
ORDER BY categorie, saison;

-- ============================================================================
-- 3. NTILE
-- Question métier : comment répartir les pilotes en quatre groupes selon leurs
-- victoires de carrière, parmi ceux ayant au moins 20 places dans le top 6 ?
-- Remplace la moyenne des points par départ, impossible à calculer avec data2.
-- Le top 6 n'est ni le nombre de départs ni un taux de réussite.
-- ============================================================================
WITH stats AS (
    SELECT rider AS pilote, country AS pays_pilote, victories AS victoires,
           victories + number_of_second + number_of_third + number_of_4th
             + number_of_5th + number_of_6th AS places_top_6
    FROM riders_finishing_positions
)
SELECT *, NTILE(4) OVER (ORDER BY victoires DESC, pilote) AS quartile_victoires
FROM stats
WHERE places_top_6 >= 20
ORDER BY quartile_victoires, victoires DESC, pilote;

-- ============================================================================
-- 4. FENÊTRE GLISSANTE : ROWS BETWEEN
-- Question métier : comment évoluent les victoires des constructeurs sur cinq
-- saisons et leur cumul dans la catégorie MotoGP telle que nommée par la source ?
-- Remplace les temps au tour : une ligne = une saison, y compris sans victoire.
-- ============================================================================
WITH bornes AS (
    SELECT MIN(season) AS debut, MAX(season) AS fin
    FROM grand_prix_race_winners WHERE class = 'MotoGP™'
), constructeurs AS (
    SELECT DISTINCT COALESCE(constructor, 'Constructeur inconnu') AS constructor
    FROM grand_prix_race_winners WHERE class = 'MotoGP™'
), annuel AS (
    SELECT season, COALESCE(constructor, 'Constructeur inconnu') AS constructor, COUNT(*) AS victoires
    FROM grand_prix_race_winners WHERE class = 'MotoGP™'
    GROUP BY season, constructor
), grille AS (
    SELECT s.saison, c.constructor AS constructeur, COALESCE(a.victoires, 0) AS victoires
    FROM bornes b
    CROSS JOIN LATERAL generate_series(b.debut, b.fin) AS s(saison)
    CROSS JOIN constructeurs c
    LEFT JOIN annuel a ON a.season = s.saison AND a.constructor = c.constructor
)
SELECT *,
       ROUND(AVG(victoires) OVER (
           PARTITION BY constructeur ORDER BY saison ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
       ), 2) AS moyenne_mobile_5_saisons,
       SUM(victoires) OVER (
           PARTITION BY constructeur ORDER BY saison ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS victoires_cumulees
FROM grille
ORDER BY constructeur, saison;
-- Les quatre premières fenêtres contiennent moins de cinq saisons.

-- ============================================================================
-- 5. CTE RÉCURSIVE
-- Question métier : comment évolue la couverture des victoires par décennie ?
-- Bornes des décennies calculées depuis les données.
-- C'est une génération de série temporelle, pas une hiérarchie métier.
-- ============================================================================
WITH RECURSIVE bornes AS (
    SELECT (MIN(season) / 10) * 10 AS debut, (MAX(season) / 10) * 10 AS fin
    FROM grand_prix_race_winners
), decennies (annee_debut) AS (
    SELECT debut FROM bornes WHERE debut IS NOT NULL
    UNION ALL
    SELECT d.annee_debut + 10 FROM decennies d CROSS JOIN bornes b
    WHERE d.annee_debut + 10 <= b.fin
)
SELECT d.annee_debut AS debut_decennie, COUNT(w.season) AS victoires_enregistrees,
       COUNT(DISTINCT w.circuit) AS circuits_distincts,
       COUNT(DISTINCT w.rider) AS pilotes_vainqueurs
FROM decennies d
LEFT JOIN grand_prix_race_winners w ON w.season BETWEEN d.annee_debut AND d.annee_debut + 9
GROUP BY d.annee_debut
ORDER BY d.annee_debut;

-- ============================================================================
-- 6. ENCHAÎNEMENT DE CTEs
-- Question métier : quels constructeurs dominent les victoires de leur catégorie
-- entre 2014 et 2024, selon les saisons disponibles ?
-- Remplace la fiabilité : aucun départ ni abandon disponible pour mesurer celle-ci.
-- ============================================================================
WITH periode AS (
    SELECT * FROM grand_prix_race_winners WHERE season BETWEEN 2014 AND 2024
), victoires_constructeurs AS (
    SELECT class AS categorie, constructor AS constructeur,
           COUNT(*) AS victoires, COUNT(DISTINCT rider) AS pilotes_vainqueurs,
           COUNT(DISTINCT season) AS saisons_avec_victoire
    FROM periode
    GROUP BY class, constructor
), totaux AS (
    SELECT class AS categorie, COUNT(*) AS victoires_categorie
    FROM periode GROUP BY class
), synthese AS (
    SELECT v.*, ROUND(100.0 * v.victoires / NULLIF(t.victoires_categorie, 0), 2)
               AS part_victoires_categorie_pct
    FROM victoires_constructeurs v JOIN totaux t USING (categorie)
)
SELECT * FROM synthese
ORDER BY categorie, part_victoires_categorie_pct DESC, constructeur;
