
-- Force a 2d road geometry and index
SELECT AddGeometryColumn('public', 'roadlinks', 'geom2d', 27700, 'LINESTRING', 2);
UPDATE roadlinks SET geom2d = ST_Force2d(geom);
CREATE INDEX roadlinks_geom2d_idx ON public.roadlinks USING gist (geom2d);
CLUSTER public.roadlinks using roadlinks_geom_idx;

-- Split roads by stops and store in temp table
DROP TABLE IF EXISTS tmproads;
CREATE TABLE tmproads AS(
SELECT
    a.gid,
    a.fictitious, 
	a.identifier, 
	a.class, 
	a.roadnumber, 
	a.name1, 
	a.name1_lang, 
	a.name2, 
	a.name2_lang,
	a.formofway,
	a.__primary,
	a.trunkroad,
	(ST_Dump(ST_Split(ST_Snap(a.geom, b.geom, 0.00001), b.geom))).geom
FROM 
    roadlinks a
JOIN 
    candidatestops b 
ON 
    ST_DWithin(b.geom, a.geom, 30)
);

-- Merge with roads not split into new roads table
DROP TABLE IF EXISTS newroadlinks;
CREATE TABLE newroadlinks AS (
	SELECT * FROM tmproads

	UNION ALL

	SELECT
		a.gid,
		a.fictitious, 
		a.identifier, 
		a.class, 
		a.roadnumber, 
		a.name1, 
		a.name1_lang, 
		a.name2, 
		a.name2_lang,
		a.formofway,
		a.__primary,
		a.trunkroad,
		a.geom
	FROM roadlinks a
	LEFT JOIN tmproads tr
	ON a.gid = tr.gid
	WHERE tr.gid IS NULL
);

-- Generate nodes from new roads table
DROP TABLE IF EXISTS newroadnodes;
CREATE TABLE newroadnodes AS (
    SELECT ST_StartPoint(geom) AS geom FROM newroadlinks
	UNION
	SELECT ST_EndPoint(geom) AS geom FROM newroadlinks
);

-- tidy up, index and cluster
DROP TABLE tmproads;
CREATE INDEX ON newroadlinks USING GIST(geom);
CREATE INDEX ON newroadnodes USING GIST(geom);
CLUSTER newroadnodes USING newroadnodes_geom_idx;
CLUSTER newroadlinks USING newroadlinks_geom_idx;

DROP SEQUENCE IF EXISTS newroadnodes_sequence;
CREATE SEQUENCE IF NOT EXISTS newroadnodes_sequence;
alter table newroadnodes ADD COLUMN id INTEGER;
UPDATE newroadnodes SET id =  nextval('newroadnodes_sequence');
CREATE INDEX ON newroadnodes USING BTREE(id);

DROP SEQUENCE IF EXISTS newroadlinks_sequence;
CREATE SEQUENCE IF NOT EXISTS newroadlinks_sequence;
alter table newroadlinks ADD COLUMN id INTEGER;
UPDATE newroadlinks SET id =  nextval('newroadlinks_sequence');
CREATE INDEX ON newroadlinks USING BTREE(id);

-- Road startpoint and endpoint columns
ALTER TABLE newroadlinks ADD COLUMN start_id INTEGER;
ALTER TABLE newroadlinks ADD COLUMN end_id INTEGER;
SELECT AddGeometryColumn('public', 'newroadlinks', 'startpoint', 27700, 'POINT', 2);
SELECT AddGeometryColumn('public', 'newroadlinks', 'endpoint', 27700, 'POINT', 2);
UPDATE newroadlinks SET startpoint = ST_Force2d(ST_StartPoint(geom));
UPDATE newroadlinks SET endpoint = ST_Force2d(ST_EndPoint(geom));
CREATE INDEX ON newroadlinks USING gist (startpoint);
CREATE INDEX ON newroadlinks USING gist (endpoint);

-- Store atcocode against the node
ALTER TABLE newroadnodes ADD COLUMN atcocode VARCHAR(20);
UPDATE newroadnodes AS nrn SET atcocode = ac.atcocode 
FROM (
SELECT DISTINCT ON (s.atcocode) s.atcocode AS atcocode, p.id AS node_id, ST_Distance(s.geom, p.geom) AS distance
	  FROM candidatestops s
 LEFT JOIN newroadnodes p ON ST_DWithin(s.geom, p.geom, 30)
  ORDER BY s.atcocode, distance ASC) AS ac
  WHERE nrn.id = ac.node_id;
CREATE INDEX ON newroadnodes USING BTREE(atcocode);

-- This is also shit but closer to what I want
--UPDATE newroadlinks AS nrl SET nrl.start_id = sq.node_id FROM (
SELECT DISTINCT ON (r.gid) p.id AS node_id, r.gid AS road_id, ST_Distance(r.startpoint, p.geom) AS distance
	  FROM newroadlinks r
 LEFT JOIN newroadnodes p ON ST_DWithin(r.startpoint, p.geom, 30)
  ORDER BY r.gid, distance ASC
  LIMIT 100;
  --) AS sq
  --WHERE nrl.id = sq.road_id
  
  