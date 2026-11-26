"""Benchmark sur une copie synthétique ; aucune modification des marts."""
import json,sys,uuid,statistics
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
from run import connect,environment,ROOT
from psycopg2 import sql
schema='benchmark_'+uuid.uuid4().hex[:12]
out=ROOT/'docs/performance';out.mkdir(parents=True,exist_ok=True)
conn=connect();conn.autocommit=True
with conn.cursor() as cur:
 try:
  cur.execute(sql.SQL('create schema {}').format(sql.Identifier(schema)))
  cur.execute(sql.SQL('create table {}.wins as select f.season_key, f.rider_key, f.win_count from generate_series(1,3244) g cross join {}.fct_wins f limit 10000000').format(sql.Identifier(schema),sql.Identifier(environment().get('DBT_SCHEMA','analytics')+'_marts')))
  cur.execute(sql.SQL('select count(*) from {}.wins').format(sql.Identifier(schema)));assert cur.fetchone()[0]==10000000
  cur.execute(sql.SQL('select season_key,rider_key from {}.wins where season_key=2021 limit 1').format(sql.Identifier(schema)));params=cur.fetchone()
  q=sql.SQL('select sum(win_count) from {}.wins where season_key=%s and rider_key=%s').format(sql.Identifier(schema))
  cur.execute(q,params);expected=cur.fetchone()[0]
  def measure():
   plans=[]
   for _ in range(3):
    cur.execute(sql.SQL('explain (analyze,buffers,format json) ')+q,params);plans.append(cur.fetchone()[0][0])
   return plans
  cur.execute(sql.SQL('analyze {}.wins').format(sql.Identifier(schema)));before=measure()
  cur.execute(sql.SQL('create index on {}.wins (season_key,rider_key)').format(sql.Identifier(schema)))
  cur.execute(sql.SQL('analyze {}.wins').format(sql.Identifier(schema)));after=measure()
  cur.execute(q,params);assert cur.fetchone()[0]==expected
  b=statistics.median(x['Execution Time'] for x in before);a=statistics.median(x['Execution Time'] for x in after)
  report=dict(rows=10000000,repetitions=3,before_ms=b,after_ms=a,speedup=b/a,result=expected,before=before,after=after)
  (out/'benchmark.json').write_text(json.dumps(report,indent=2)+'\n')
  (out/'README.md').write_text(f'''# Performance\n\nMesure sur PostgreSQL, le 26 novembre 2026, sur 10 millions de lignes synthétiques obtenues par répétition de fct_wins. Les marts et sources ne sont pas modifiés.\n\nRequête : SUM(win_count) filtré par saison et pilote. Index B-tree composé (season_key, rider_key). Trois EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON) avant et après ; médianes retenues.\n\nSans index : {b:.2f} ms. Avec index : {a:.2f} ms. Accélération : {b/a:.1f} fois. Résultat identique : {expected}.\n\nLes plans sont dans benchmark.json. Les données sont synthétiques et les essais réchauffent le cache. Le gain dépend de la requête et de la machine ; il ne se généralise pas à toutes les analyses. Le schéma de test est supprimé en fin d'exécution.\n\nDepuis le dossier projet : .venv/bin/python scripts/benchmark.py (Windows : .venv\\Scripts\\python.exe scripts/benchmark.py).\n''')
  print(json.dumps({k:report[k] for k in ['rows','before_ms','after_ms','speedup']}))
 finally:cur.execute(sql.SQL('drop schema if exists {} cascade').format(sql.Identifier(schema)))
conn.close()
