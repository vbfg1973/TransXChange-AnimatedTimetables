FILE=$1
PGPASSWORD="postgres"
shp2pgsql -S -a -s 27700 $FILE openroads.roadlinks

