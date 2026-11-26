"""Lanceur PostgreSQL multiplateforme. Les secrets restent dans .connection.json (ignoré par Git)."""
import argparse
import csv
import getpass
import importlib.util
import io
import json
import os
from pathlib import Path
import subprocess
import sys
import venv

ROOT = Path(__file__).resolve().parent
LOCAL_CONFIG = ROOT / '.connection.json'
VENV = ROOT / '.venv'
PYTHON = VENV / ('Scripts/python.exe' if os.name == 'nt' else 'bin/python')
DBT = VENV / ('Scripts/dbt.exe' if os.name == 'nt' else 'bin/dbt')

def setup():
    if not ((3, 10) <= sys.version_info[:2] <= (3, 13)):
        raise SystemExit('Utiliser Python 3.10 à 3.13 (3.12 recommandé). Sur Windows : py -3.12 run.py setup')
    if not PYTHON.exists():
        venv.EnvBuilder(with_pip=True).create(VENV)
    subprocess.run([str(PYTHON), '-m', 'pip', 'install', '-r', str(ROOT / 'requirements.txt')], check=True)
    print('Installation terminée. Puis : python run.py configure')

def configure():
    previous = json.loads(LOCAL_CONFIG.read_text()) if LOCAL_CONFIG.exists() else {}
    def ask(label, key, default):
        return input(f'{label} [{previous.get(key, default)}] : ').strip() or previous.get(key, default)
    config = {
        'DBT_HOST': ask('Hôte PostgreSQL', 'DBT_HOST', 'localhost'),
        'DBT_PORT': ask('Port', 'DBT_PORT', '5432'),
        'DBT_DATABASE': ask('Base contenant vos tables MotoGP', 'DBT_DATABASE', 'motogp'),
        'DBT_USER': ask('Utilisateur', 'DBT_USER', 'postgres'),
        'DBT_RAW_SCHEMA': ask('Schéma contenant les six sources', 'DBT_RAW_SCHEMA', 'f1'),
        'DBT_SCHEMA': ask('Préfixe des schémas de sortie dbt', 'DBT_SCHEMA', 'analytics'),
        'DBT_SSLMODE': ask('Mode SSL', 'DBT_SSLMODE', 'prefer'),
        'DBT_ENV_SECRET_PASSWORD': getpass.getpass('Mot de passe PostgreSQL (masqué) : '),
    }
    int(config['DBT_PORT'])
    if not config['DBT_SCHEMA'] or not config['DBT_RAW_SCHEMA']:
        raise SystemExit('Les schémas doivent avoir un nom.')
    if config['DBT_RAW_SCHEMA'] in {config['DBT_SCHEMA'] + '_' + x for x in ('staging','intermediate','marts','snapshots')}:
        raise SystemExit('Le schéma source doit être différent des schémas produits par dbt.')
    LOCAL_CONFIG.write_text(json.dumps(config, indent=2) + '\n')
    if os.name != 'nt':
        LOCAL_CONFIG.chmod(0o600)
    print('Connexion enregistrée localement, exclue de Git. Puis : python run.py all')

def environment():
    config = json.loads(LOCAL_CONFIG.read_text()) if LOCAL_CONFIG.exists() else {}
    env = {**config, **os.environ}
    env['DBT_SEND_ANONYMOUS_USAGE_STATS'] = 'false'
    if not LOCAL_CONFIG.exists() and not env.get('DBT_USER'):
        raise SystemExit('Configurer la connexion : python run.py configure')
    return env

def dbt(*args):
    if not DBT.exists():
        raise SystemExit('Installer dbt : python run.py setup')
    subprocess.run([str(DBT), *args, '--profiles-dir', str(ROOT / 'config'), '--project-dir', str(ROOT)],
                   cwd=ROOT, env=environment(), check=True)

def connect(raw=False):
    import psycopg2
    e = environment()
    return psycopg2.connect(host=e.get('DBT_HOST','localhost'), port=int(e.get('DBT_PORT','5432')),
        dbname=e.get('DBT_RAW_DATABASE',e.get('DBT_DATABASE','motogp')) if raw else e.get('DBT_DATABASE','motogp'),
        user=e.get('DBT_USER','postgres'), password=e.get('DBT_ENV_SECRET_PASSWORD',''),
        sslmode=e.get('DBT_SSLMODE','prefer'), connect_timeout=10)

def datasets():
    return json.loads((ROOT / 'scripts/datasets.json').read_text())

def preflight():
    e = environment()
    schema = e.get('DBT_RAW_SCHEMA','f1')
    produced = {e.get('DBT_SCHEMA','analytics') + '_' + x for x in ('staging','intermediate','marts','snapshots')}
    if schema in produced:
        raise SystemExit('Le schéma source ne doit pas être un schéma de sortie dbt.')
    if e.get('DBT_RAW_DATABASE', e.get('DBT_DATABASE','motogp')) != e.get('DBT_DATABASE','motogp'):
        raise SystemExit('PostgreSQL : sources et modèles doivent être dans la même base.')
    with connect(raw=True) as conn, conn.cursor() as cur:
        for table, spec in datasets().items():
            cur.execute('select column_name from information_schema.columns where table_schema=%s and table_name=%s', (schema, table))
            existing = {r[0] for r in cur.fetchall()}
            missing = {name for name, _ in spec['columns']} - existing
            if missing:
                raise SystemExit(f'Source {schema}.{table} : colonnes absentes {sorted(missing)}. '
                    'Vérifier la connexion et les noms snake_case. Sur un schéma vide : python run.py import-data')
    print('Les six tables sources et leurs colonnes sont présentes.')

def import_data():
    # Optional bootstrap on an EMPTY schema. Never drops, truncates or overwrites a table.
    import psycopg2.sql as sql
    schema = environment().get('DBT_RAW_SCHEMA','f1')
    with connect(raw=True) as conn, conn.cursor() as cur:
        for table in datasets():
            cur.execute('select 1 from information_schema.tables where table_schema=%s and table_name=%s', (schema,table))
            if cur.fetchone():
                raise SystemExit(f'{schema}.{table} existe déjà. Import annulé sans modification. Utiliser all avec les sources existantes.')
        cur.execute(sql.SQL('create schema if not exists {}').format(sql.Identifier(schema)))
        for table, spec in datasets().items():
            fields = [sql.SQL('source_row_id bigint generated always as identity primary key')]
            fields += [sql.SQL('{} {}').format(sql.Identifier(n),sql.SQL(t)) for n,t in spec['columns']]
            cur.execute(sql.SQL('create table {}.{} ({})').format(sql.Identifier(schema),sql.Identifier(table),sql.SQL(', ').join(fields)))
            buf=io.StringIO()
            writer=csv.writer(buf,lineterminator='\n')
            with (ROOT/'data2'/spec['file']).open(encoding='utf-8-sig',newline='') as f:
                reader=csv.reader(f);next(reader)
                for row in reader:
                    if len(row)!=len(spec['columns']):
                        raise ValueError(f'Nombre de colonnes incorrect : {spec["file"]}')
                    writer.writerow([r'\N' if x in ('',r'\N') else x for x in row])
            buf.seek(0)
            copy=sql.SQL("copy {}.{} ({}) from stdin with (format csv, null '\\N')").format(
                sql.Identifier(schema),sql.Identifier(table),sql.SQL(', ').join(sql.Identifier(n) for n,_ in spec['columns']))
            cur.copy_expert(copy.as_string(conn),buf)
            print(f'Import : {schema}.{table}')
    print('Import validé en une transaction. Puis : python run.py all')

def export_questions():
    # Compile the analyses against the actual connection/schema; do not hard-code analytics_marts.
    dbt('compile')
    out=ROOT/'target/results';out.mkdir(parents=True,exist_ok=True)
    with connect() as conn, conn.cursor() as cur:
        cur.execute('set transaction read only')
        for source in sorted((ROOT/'analyses').glob('*.sql')):
            compiled=ROOT/'target/compiled/motogp/analyses'/source.name
            cur.execute(compiled.read_text())
            rows=cur.fetchall()
            with (out/(source.stem+'.csv')).open('w',encoding='utf-8-sig',newline='') as f:
                writer=csv.writer(f);writer.writerow([c.name for c in cur.description]);writer.writerows(rows)
            print(f'{source.stem} : {len(rows)} lignes -> target/results/{source.stem}.csv')

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('command',choices=['setup','configure','check','import-data','all','questions','docs'])
    args=parser.parse_args()
    if args.command=='setup':
        setup();return
    if args.command=='configure':
        configure();return
    # Import/export uses psycopg2 from the project virtual environment, on all platforms.
    if PYTHON.exists() and Path(sys.prefix).resolve()!=VENV.resolve():
        result=subprocess.run([str(PYTHON),str(Path(__file__).resolve()),args.command])
        raise SystemExit(result.returncode)
    if not importlib.util.find_spec('psycopg2'):
        raise SystemExit('Dépendances absentes : python run.py setup')
    if args.command=='import-data':
        import_data()
    elif args.command=='check':
        dbt('debug');preflight()
    elif args.command=='all':
        dbt('debug');preflight();dbt('build');dbt('docs','generate');export_questions()
        print('Pipeline validé. Documentation : python run.py docs')
    elif args.command=='questions':
        preflight();export_questions()
    elif args.command=='docs':
        dbt('docs','serve','--host','127.0.0.1','--port','8080')

if __name__=='__main__':
    try:
        main()
    except subprocess.CalledProcessError as error:
        raise SystemExit(f'Commande arrêtée (code {error.returncode}). Corriger le message ci-dessus avant de relancer.')
    except Exception as error:
        # Do not print connection DSNs containing secrets.
        raise SystemExit(f'{type(error).__name__}: {error}')
