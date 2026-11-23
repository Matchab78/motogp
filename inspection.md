# Inspection des 14 CSV F1

Source : https://github.com/Matchab78/f1datarace
Commit : e1233bf0d74589783d5092d48a4d2d869d90b54f

Inspection complète de toutes les lignes. Noms convertis en snake_case. Valeurs vides et `\N` converties en NULL. Durées conservées en TEXT ; utiliser milliseconds pour les calculs.

## seasons.csv
77 lignes — clé primaire : year

| Colonne CSV → SQL | Type PostgreSQL | NULL |
|---|---|---:|
| year → year | INTEGER | 0 |
| url → url | TEXT | 0 |

## circuits.csv
78 lignes — clé primaire : circuit_id

| Colonne CSV → SQL | Type PostgreSQL | NULL |
|---|---|---:|
| circuitId → circuit_id | INTEGER | 0 |
| circuitRef → circuit_ref | TEXT | 0 |
| name → name | TEXT | 0 |
| location → location | TEXT | 0 |
| country → country | TEXT | 0 |
| lat → lat | NUMERIC | 0 |
| lng → lng | NUMERIC | 0 |
| alt → alt | INTEGER | 0 |
| url → url | TEXT | 0 |

## constructors.csv
214 lignes — clé primaire : constructor_id

| Colonne CSV → SQL | Type PostgreSQL | NULL |
|---|---|---:|
| constructorId → constructor_id | INTEGER | 0 |
| constructorRef → constructor_ref | TEXT | 0 |
| name → name | TEXT | 0 |
| nationality → nationality | TEXT | 0 |
| url → url | TEXT | 0 |

## drivers.csv
867 lignes — clé primaire : driver_id

| Colonne CSV → SQL | Type PostgreSQL | NULL |
|---|---|---:|
| driverId → driver_id | INTEGER | 0 |
| driverRef → driver_ref | TEXT | 0 |
| number → number | INTEGER | 802 |
| code → code | TEXT | 757 |
| forename → forename | TEXT | 0 |
| surname → surname | TEXT | 0 |
| dob → dob | DATE | 0 |
| nationality → nationality | TEXT | 0 |
| url → url | TEXT | 0 |

## status.csv
141 lignes — clé primaire : status_id

| Colonne CSV → SQL | Type PostgreSQL | NULL |
|---|---|---:|
| statusId → status_id | INTEGER | 0 |
| status → status | TEXT | 0 |

## races.csv
1,172 lignes — clé primaire : race_id

| Colonne CSV → SQL | Type PostgreSQL | NULL |
|---|---|---:|
| raceId → race_id | INTEGER | 0 |
| year → year | INTEGER | 0 |
| round → round | INTEGER | 0 |
| circuitId → circuit_id | INTEGER | 0 |
| name → name | TEXT | 0 |
| date → date | DATE | 0 |
| time → time | TIME | 731 |
| url → url | TEXT | 0 |
| fp1_date → fp1_date | DATE | 1035 |
| fp1_time → fp1_time | TIME | 1057 |
| fp2_date → fp2_date | DATE | 1053 |
| fp2_time → fp2_time | TIME | 1075 |
| fp3_date → fp3_date | DATE | 1065 |
| fp3_time → fp3_time | TIME | 1084 |
| quali_date → quali_date | DATE | 1035 |
| quali_time → quali_time | TIME | 1057 |
| sprint_date → sprint_date | DATE | 1142 |
| sprint_time → sprint_time | TIME | 1145 |

## constructor_results.csv
13,096 lignes — clé primaire : constructor_results_id

| Colonne CSV → SQL | Type PostgreSQL | NULL |
|---|---|---:|
| constructorResultsId → constructor_results_id | INTEGER | 0 |
| raceId → race_id | INTEGER | 0 |
| constructorId → constructor_id | INTEGER | 0 |
| points → points | NUMERIC | 0 |
| status → status | TEXT | 13079 |

## constructor_standings.csv
13,862 lignes — clé primaire : constructor_standings_id

| Colonne CSV → SQL | Type PostgreSQL | NULL |
|---|---|---:|
| constructorStandingsId → constructor_standings_id | INTEGER | 0 |
| raceId → race_id | INTEGER | 0 |
| constructorId → constructor_id | INTEGER | 0 |
| points → points | NUMERIC | 0 |
| position → position | INTEGER | 0 |
| positionText → position_text | TEXT | 0 |
| wins → wins | INTEGER | 0 |

## driver_standings.csv
35,838 lignes — clé primaire : driver_standings_id

| Colonne CSV → SQL | Type PostgreSQL | NULL |
|---|---|---:|
| driverStandingsId → driver_standings_id | INTEGER | 0 |
| raceId → race_id | INTEGER | 0 |
| driverId → driver_id | INTEGER | 0 |
| points → points | NUMERIC | 0 |
| position → position | INTEGER | 8 |
| positionText → position_text | TEXT | 0 |
| wins → wins | INTEGER | 0 |

## qualifying.csv
11,430 lignes — clé primaire : qualify_id

| Colonne CSV → SQL | Type PostgreSQL | NULL |
|---|---|---:|
| qualifyId → qualify_id | INTEGER | 0 |
| raceId → race_id | INTEGER | 0 |
| driverId → driver_id | INTEGER | 0 |
| constructorId → constructor_id | INTEGER | 0 |
| number → number | INTEGER | 0 |
| position → position | INTEGER | 0 |
| q1 → q1 | TEXT | 166 |
| q2 → q2 | TEXT | 4899 |
| q3 → q3 | TEXT | 7361 |

## results.csv
27,700 lignes — clé primaire : result_id

| Colonne CSV → SQL | Type PostgreSQL | NULL |
|---|---|---:|
| resultId → result_id | INTEGER | 0 |
| raceId → race_id | INTEGER | 0 |
| driverId → driver_id | INTEGER | 0 |
| constructorId → constructor_id | INTEGER | 0 |
| number → number | INTEGER | 6 |
| grid → grid | INTEGER | 20 |
| position → position | INTEGER | 10953 |
| positionText → position_text | TEXT | 0 |
| positionOrder → position_order | INTEGER | 0 |
| points → points | NUMERIC | 0 |
| laps → laps | INTEGER | 0 |
| time → time | TEXT | 19438 |
| milliseconds → milliseconds | INTEGER | 19438 |
| fastestLap → fastest_lap | INTEGER | 18544 |
| rank → rank | INTEGER | 18286 |
| fastestLapTime → fastest_lap_time | TEXT | 18544 |
| fastestLapSpeed → fastest_lap_speed | NUMERIC | 19448 |
| statusId → status_id | INTEGER | 0 |

## sprint_results.csv
612 lignes — clé primaire : result_id

| Colonne CSV → SQL | Type PostgreSQL | NULL |
|---|---|---:|
| resultId → result_id | INTEGER | 0 |
| raceId → race_id | INTEGER | 0 |
| driverId → driver_id | INTEGER | 0 |
| constructorId → constructor_id | INTEGER | 0 |
| number → number | INTEGER | 0 |
| grid → grid | INTEGER | 0 |
| position → position | INTEGER | 15 |
| positionText → position_text | TEXT | 0 |
| positionOrder → position_order | INTEGER | 0 |
| points → points | NUMERIC | 0 |
| laps → laps | INTEGER | 0 |
| time → time | TEXT | 48 |
| milliseconds → milliseconds | INTEGER | 47 |
| fastestLap → fastest_lap | INTEGER | 23 |
| fastestLapTime → fastest_lap_time | TEXT | 23 |
| statusId → status_id | INTEGER | 2 |
| rank → rank | INTEGER | 374 |

## lap_times.csv
890,328 lignes — clé primaire : lap_time_id

| Colonne CSV → SQL | Type PostgreSQL | NULL |
|---|---|---:|
| raceId → race_id | INTEGER | 0 |
| driverId → driver_id | INTEGER | 0 |
| lap → lap | INTEGER | 0 |
| position → position | INTEGER | 0 |
| time → time | TEXT | 0 |
| milliseconds → milliseconds | INTEGER | 0 |

## pit_stops.csv
22,973 lignes — clé primaire : race_id, driver_id, stop

| Colonne CSV → SQL | Type PostgreSQL | NULL |
|---|---|---:|
| raceId → race_id | INTEGER | 0 |
| driverId → driver_id | INTEGER | 0 |
| stop → stop | INTEGER | 0 |
| lap → lap | INTEGER | 0 |
| time → time | TIME | 0 |
| duration → duration | TEXT | 3 |
| milliseconds → milliseconds | INTEGER | 3 |
