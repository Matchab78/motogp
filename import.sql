-- Import atomique des données MotoGP (data2) dans le schéma f1
BEGIN;
DROP SCHEMA IF EXISTS f1 CASCADE;
CREATE SCHEMA f1;
SET search_path TO f1, public;

CREATE TABLE constructor_world_championship (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  season INTEGER,
  constructor TEXT,
  class TEXT
);
\copy constructor_world_championship (season, constructor, class) FROM '/data2/constructure-world-championship.csv' WITH (FORMAT csv, HEADER true, NULL '');

CREATE TABLE grand_prix_events_held (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  times INTEGER,
  track TEXT,
  country TEXT
);
\copy grand_prix_events_held (times, track, country) FROM '/data2/grand-prix-events-held.csv' WITH (FORMAT csv, HEADER true, NULL '');

CREATE TABLE grand_prix_race_winners (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  circuit TEXT,
  class TEXT,
  constructor TEXT,
  country TEXT,
  rider TEXT,
  season INTEGER
);
\copy grand_prix_race_winners (circuit, class, constructor, country, rider, season) FROM '/data2/grand-prix-race-winners.csv' WITH (FORMAT csv, HEADER true, NULL '');

CREATE TABLE riders_finishing_positions (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  rider TEXT,
  victories INTEGER,
  number_of_second INTEGER,
  number_of_third INTEGER,
  number_of_fourth INTEGER,
  number_of_fifth INTEGER,
  number_of_sixth INTEGER,
  country TEXT
);
\copy riders_finishing_positions (rider, victories, number_of_second, number_of_third, number_of_fourth, number_of_fifth, number_of_sixth, country) FROM '/data2/riders-finishing-positions.csv' WITH (FORMAT csv, HEADER true, NULL '');

CREATE TABLE riders_info (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  rider_name TEXT,
  victories NUMERIC,
  second_places NUMERIC,
  third_places NUMERIC,
  pole_positions NUMERIC,
  race_fastest_lap NUMERIC,
  world_championships NUMERIC
);
\copy riders_info (rider_name, victories, second_places, third_places, pole_positions, race_fastest_lap, world_championships) FROM '/data2/riders-info.csv' WITH (FORMAT csv, HEADER true, NULL '');

CREATE TABLE same_nation_podium_lockouts (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  season INTEGER,
  track TEXT,
  riders_nation TEXT,
  class TEXT
);
\copy same_nation_podium_lockouts (season, track, riders_nation, class) FROM '/data2/same-nation-podium-lockouts.csv' WITH (FORMAT csv, HEADER true, NULL '');

CREATE INDEX ON grand_prix_race_winners (season);
CREATE INDEX ON grand_prix_race_winners (rider);
CREATE INDEX ON grand_prix_race_winners (constructor);
CREATE INDEX ON constructor_world_championship (season);
CREATE INDEX ON same_nation_podium_lockouts (season);

COMMIT;
ANALYZE;
