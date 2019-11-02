import argparse
from os import getenv
import psycopg2

parser = argparse.ArgumentParser()
parser.add_argument("-H", "--host", help="host location of postgres database", type=str)
parser.add_argument("-U", "--user", help="username to connect to the database", type=str)
parser.add_argument("-d", "--dbname", help="database name", type=str)
parser.add_argument("-p", "--port", help="port to connect to postgres", type=str)
args = parser.parse_args()
password = "postgres"

conn = psycopg2.connect(
    f"dbname={args.dbname} user={args.user} host={args.host} port={args.port} password={password}"
)
cur = conn.cursor()
print("connected to database")

cur.execute("SELECT MIN(gid), MAX(gid) FROM newroadlinks;")
min_id, max_id = cur.fetchone()
print(f"there are {max_id - min_id + 1} edges to be processed")
cur.close()

interval = 20000
for x in range(min_id, max_id+1, interval):
    cur = conn.cursor()
    cur.execute("select pgr_createTopology('newroadlinks', 0.0001, 'geom', 'gid', rows_where:='gid>={x} and gid<{x+interval}');"
)
    conn.commit()
    x_max = x + interval - 1
    if x_max > max_id:
        x_max = max_id
    print(f"edges {x} - {x_max} have been processed")

cur = conn.cursor()
