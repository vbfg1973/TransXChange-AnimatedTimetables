SELECT AddGeometryColumn('public', 'roadlinks', 'geom2d', 27700, 'LINESTRING', 2);
UPDATE roadlinks SET geom2d = ST_Force2d(geom);
CREATE INDEX roadlinks_geom2d_idx ON public.roadlinks USING gist (geom2d);
CLUSTER public.roadlinks using roadlinks_geom_idx;

CREATE TABLE splitroads AS
SELECT stop_id, road_id, ST_CollectionExtract(ST_Split(road_geom, ST_ClosestPoint(road_geom, stop_geom)), 2) AS geom
  FROM (
    -- 
    SELECT DISTINCT ON (p.gid)
	  	   p.gid AS stop_id,
		   p.atcocode AS atcocode,
		   r.gid AS road_id,
		   ST_Distance(p.geom, r.geom2d) AS distance,
		   p.geom AS stop_geom,
		   r.geom2d AS road_geom
	  FROM stops p
 LEFT JOIN roadlinks r ON ST_DWithin(p.geom, r.geom2d, 30)
  ORDER BY stop_id, distance, road_id
  ) AS foo
WHERE road_id IS NOT NULL;

CREATE TABLE newnodes AS SELECT (geom).geom FROM (SELECT ST_DUMPPOINTS(geom) AS geom FROM splitroads) AS foo;

SELECT COUNT(*) FROM (
    SELECT DISTINCT ON (p.gid)
	  	   p.gid AS stop_id,
		   p.atcocode AS atcocode,
		   r.gid AS road_id,
		   ST_Distance(p.geom, r.geom) AS distance,
		   p.geom AS stop_geom,
		   r.geom AS road_geom
	  FROM stops p
 LEFT JOIN roadlinks r ON ST_DWithin(p.geom, r.geom, 30)
  ORDER BY stop_id, distance, road_id) AS foo;
