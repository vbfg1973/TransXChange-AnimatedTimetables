PGPASSWORD="postgres"
PGUSER="postgres"
PGHOST="localhost"
PGPORT="5432"
SRCDIR="/media/data/DataSets/NAPTAN/data/GIS/data"
TMPDIR="/tmp"
SQLDIR="../sql"

ls $SRCDIR/*Link.shp | parallel shp2pgsql -S -a -s 27700 {} public.roadlinks > $TMPDIR/roadlinks.sql
ls $SRCDIR/*Node.shp | parallel shp2pgsql -S -a -s 27700 {} public.roadnodes > $TMPDIR/roadnodes.sql

psql -U $PGUSER -h $PGHOST -p $PGPORT < $SQLDIR/header.sql
psql -U $PGUSER -h $PGHOST -p $PGPORT gis < $TMPDIR/roadlinks.sql
psql -U $PGUSER -h $PGHOST -p $PGPORT gis < $TMPDIR/roadnodes.sql
psql -U $PGUSER -h $PGHOST -p $PGPORT gis < $SQLDIR/pgrouting-openroads.sql

