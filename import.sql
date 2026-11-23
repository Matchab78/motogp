-- Import atomique dans un schéma dédié. Refuse un schéma f1 déjà existant.
BEGIN;
CREATE SCHEMA f1;
SET search_path TO f1, public;
CREATE TABLE seasons (
  year INTEGER NOT NULL,
  url TEXT,
  PRIMARY KEY (year)
);
\copy seasons (year, url) FROM '/data/seasons.csv' WITH (FORMAT csv, HEADER true, NULL '\N');
CREATE TABLE circuits (
  circuit_id INTEGER NOT NULL,
  circuit_ref TEXT,
  name TEXT,
  location TEXT,
  country TEXT,
  lat NUMERIC,
  lng NUMERIC,
  alt INTEGER,
  url TEXT,
  PRIMARY KEY (circuit_id)
);
\copy circuits (circuit_id, circuit_ref, name, location, country, lat, lng, alt, url) FROM '/data/circuits.csv' WITH (FORMAT csv, HEADER true, NULL '\N');
CREATE TABLE constructors (
  constructor_id INTEGER NOT NULL,
  constructor_ref TEXT,
  name TEXT,
  nationality TEXT,
  url TEXT,
  PRIMARY KEY (constructor_id)
);
\copy constructors (constructor_id, constructor_ref, name, nationality, url) FROM '/data/constructors.csv' WITH (FORMAT csv, HEADER true, NULL '\N');
CREATE TABLE drivers (
  driver_id INTEGER NOT NULL,
  driver_ref TEXT,
  number INTEGER,
  code TEXT,
  forename TEXT,
  surname TEXT,
  dob DATE,
  nationality TEXT,
  url TEXT,
  PRIMARY KEY (driver_id)
);
\copy drivers (driver_id, driver_ref, number, code, forename, surname, dob, nationality, url) FROM '/data/drivers.csv' WITH (FORMAT csv, HEADER true, NULL '\N');
CREATE TABLE status (
  status_id INTEGER NOT NULL,
  status TEXT,
  PRIMARY KEY (status_id)
);
\copy status (status_id, status) FROM '/data/status.csv' WITH (FORMAT csv, HEADER true, NULL '\N');
CREATE TABLE races (
  race_id INTEGER NOT NULL,
  year INTEGER,
  round INTEGER,
  circuit_id INTEGER,
  name TEXT,
  date DATE,
  time TIME,
  url TEXT,
  fp1_date DATE,
  fp1_time TIME,
  fp2_date DATE,
  fp2_time TIME,
  fp3_date DATE,
  fp3_time TIME,
  quali_date DATE,
  quali_time TIME,
  sprint_date DATE,
  sprint_time TIME,
  PRIMARY KEY (race_id),
  FOREIGN KEY (year) REFERENCES seasons (year),
  FOREIGN KEY (circuit_id) REFERENCES circuits (circuit_id)
);
\copy races (race_id, year, round, circuit_id, name, date, time, url, fp1_date, fp1_time, fp2_date, fp2_time, fp3_date, fp3_time, quali_date, quali_time, sprint_date, sprint_time) FROM '/data/races.csv' WITH (FORMAT csv, HEADER true, NULL '\N');
CREATE TABLE constructor_results (
  constructor_results_id INTEGER NOT NULL,
  race_id INTEGER,
  constructor_id INTEGER,
  points NUMERIC,
  status TEXT,
  PRIMARY KEY (constructor_results_id),
  FOREIGN KEY (race_id) REFERENCES races (race_id),
  FOREIGN KEY (constructor_id) REFERENCES constructors (constructor_id)
);
\copy constructor_results (constructor_results_id, race_id, constructor_id, points, status) FROM '/data/constructor_results.csv' WITH (FORMAT csv, HEADER true, NULL '\N');
CREATE TABLE constructor_standings (
  constructor_standings_id INTEGER NOT NULL,
  race_id INTEGER,
  constructor_id INTEGER,
  points NUMERIC,
  position INTEGER,
  position_text TEXT,
  wins INTEGER,
  PRIMARY KEY (constructor_standings_id),
  FOREIGN KEY (race_id) REFERENCES races (race_id),
  FOREIGN KEY (constructor_id) REFERENCES constructors (constructor_id)
);
\copy constructor_standings (constructor_standings_id, race_id, constructor_id, points, position, position_text, wins) FROM '/data/constructor_standings.csv' WITH (FORMAT csv, HEADER true, NULL '\N');
CREATE TABLE driver_standings (
  driver_standings_id INTEGER NOT NULL,
  race_id INTEGER,
  driver_id INTEGER,
  points NUMERIC,
  position INTEGER,
  position_text TEXT,
  wins INTEGER,
  PRIMARY KEY (driver_standings_id),
  FOREIGN KEY (race_id) REFERENCES races (race_id),
  FOREIGN KEY (driver_id) REFERENCES drivers (driver_id)
);
\copy driver_standings (driver_standings_id, race_id, driver_id, points, position, position_text, wins) FROM '/data/driver_standings.csv' WITH (FORMAT csv, HEADER true, NULL '\N');
CREATE TABLE qualifying (
  qualify_id INTEGER NOT NULL,
  race_id INTEGER,
  driver_id INTEGER,
  constructor_id INTEGER,
  number INTEGER,
  position INTEGER,
  q1 TEXT,
  q2 TEXT,
  q3 TEXT,
  PRIMARY KEY (qualify_id),
  FOREIGN KEY (race_id) REFERENCES races (race_id),
  FOREIGN KEY (driver_id) REFERENCES drivers (driver_id),
  FOREIGN KEY (constructor_id) REFERENCES constructors (constructor_id)
);
\copy qualifying (qualify_id, race_id, driver_id, constructor_id, number, position, q1, q2, q3) FROM '/data/qualifying.csv' WITH (FORMAT csv, HEADER true, NULL '\N');
CREATE TABLE results (
  result_id INTEGER NOT NULL,
  race_id INTEGER,
  driver_id INTEGER,
  constructor_id INTEGER,
  number INTEGER,
  grid INTEGER,
  position INTEGER,
  position_text TEXT,
  position_order INTEGER,
  points NUMERIC,
  laps INTEGER,
  time TEXT,
  milliseconds INTEGER,
  fastest_lap INTEGER,
  rank INTEGER,
  fastest_lap_time TEXT,
  fastest_lap_speed NUMERIC,
  status_id INTEGER,
  PRIMARY KEY (result_id),
  FOREIGN KEY (race_id) REFERENCES races (race_id),
  FOREIGN KEY (driver_id) REFERENCES drivers (driver_id),
  FOREIGN KEY (constructor_id) REFERENCES constructors (constructor_id),
  FOREIGN KEY (status_id) REFERENCES status (status_id)
);
\copy results (result_id, race_id, driver_id, constructor_id, number, grid, position, position_text, position_order, points, laps, time, milliseconds, fastest_lap, rank, fastest_lap_time, fastest_lap_speed, status_id) FROM '/data/results.csv' WITH (FORMAT csv, HEADER true, NULL '\N');
CREATE TABLE sprint_results (
  result_id INTEGER NOT NULL,
  race_id INTEGER,
  driver_id INTEGER,
  constructor_id INTEGER,
  number INTEGER,
  grid INTEGER,
  position INTEGER,
  position_text TEXT,
  position_order INTEGER,
  points NUMERIC,
  laps INTEGER,
  time TEXT,
  milliseconds INTEGER,
  fastest_lap INTEGER,
  fastest_lap_time TEXT,
  status_id INTEGER,
  rank INTEGER,
  PRIMARY KEY (result_id),
  FOREIGN KEY (race_id) REFERENCES races (race_id),
  FOREIGN KEY (driver_id) REFERENCES drivers (driver_id),
  FOREIGN KEY (constructor_id) REFERENCES constructors (constructor_id),
  FOREIGN KEY (status_id) REFERENCES status (status_id)
);
\copy sprint_results (result_id, race_id, driver_id, constructor_id, number, grid, position, position_text, position_order, points, laps, time, milliseconds, fastest_lap, fastest_lap_time, status_id, rank) FROM '/data/sprint_results.csv' WITH (FORMAT csv, HEADER true, NULL '\N');
CREATE TABLE lap_times (
  lap_time_id BIGINT GENERATED ALWAYS AS IDENTITY,
  race_id INTEGER,
  driver_id INTEGER,
  lap INTEGER,
  position INTEGER,
  time TEXT,
  milliseconds INTEGER,
  PRIMARY KEY (lap_time_id),
  FOREIGN KEY (race_id) REFERENCES races (race_id),
  FOREIGN KEY (driver_id) REFERENCES drivers (driver_id)
);
\copy lap_times (race_id, driver_id, lap, position, time, milliseconds) FROM '/data/lap_times.csv' WITH (FORMAT csv, HEADER true, NULL '\N');
CREATE TABLE pit_stops (
  race_id INTEGER NOT NULL,
  driver_id INTEGER NOT NULL,
  stop INTEGER NOT NULL,
  lap INTEGER,
  time TIME,
  duration TEXT,
  milliseconds INTEGER,
  PRIMARY KEY (race_id, driver_id, stop),
  FOREIGN KEY (race_id) REFERENCES races (race_id),
  FOREIGN KEY (driver_id) REFERENCES drivers (driver_id)
);
\copy pit_stops (race_id, driver_id, stop, lap, time, duration, milliseconds) FROM '/data/pit_stops.csv' WITH (FORMAT csv, HEADER true, NULL '\N');
CREATE INDEX ON races (year);
CREATE INDEX ON races (circuit_id);
CREATE INDEX ON constructor_results (race_id);
CREATE INDEX ON constructor_results (constructor_id);
CREATE INDEX ON constructor_standings (race_id);
CREATE INDEX ON constructor_standings (constructor_id);
CREATE INDEX ON driver_standings (race_id);
CREATE INDEX ON driver_standings (driver_id);
CREATE INDEX ON qualifying (race_id);
CREATE INDEX ON qualifying (driver_id);
CREATE INDEX ON qualifying (constructor_id);
CREATE INDEX ON results (race_id);
CREATE INDEX ON results (driver_id);
CREATE INDEX ON results (constructor_id);
CREATE INDEX ON results (status_id);
CREATE INDEX ON sprint_results (race_id);
CREATE INDEX ON sprint_results (driver_id);
CREATE INDEX ON sprint_results (constructor_id);
CREATE INDEX ON sprint_results (status_id);
CREATE INDEX ON lap_times (race_id);
CREATE INDEX ON lap_times (driver_id);
CREATE INDEX ON pit_stops (driver_id);
COMMIT;
ANALYZE;
