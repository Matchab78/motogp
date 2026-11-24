 -- commande pour Supprimer  au cas ou l'index existant pour revenir à l'état "sans index"
-- docker exec -it postgres-bench psql -U postgres -d motogp -c "DROP INDEX IF EXISTS f1.idx_lap_times_race_driver_cover;"

CREATE INDEX idx_lap_times_race_driver_cover 
ON f1.lap_times (race_id, driver_id, lap) 
INCLUDE (milliseconds);
ANALYZE f1.lap_times;