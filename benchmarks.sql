
EXPLAIN (ANALYZE, BUFFERS)
SELECT driver_id, lap, AVG(milliseconds) AS avg_ms, MIN(milliseconds) AS min_ms
FROM f1.lap_times
WHERE race_id = 1098 AND driver_id = 830
GROUP BY driver_id, lap
ORDER BY lap;