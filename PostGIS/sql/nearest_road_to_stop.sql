CREATE EXTENSION postgis_topology;
SET search_path = topology,public;

ALTER TABLE candidatestops ADD COLUMN atcocode VARCHAR(20);
UPDATE candidatestops AS cs SET atcocode = s.atcocode
FROM stops AS s
WHERE s.id = cs.stop_id;

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
	a.startnode,
	a.endnode,
	a.formofway,
	a.__primary,
	a.trunkroad,
	(ST_Dump(ST_Split(ST_Snap(a.geom2d, b.geom, 0.00001), b.geom))).geom,
	b.atcocode,
	true AS split
FROM 
    roadlinks a
JOIN 
    candidatestops b 
ON 
    ST_DWithin(b.geom, a.geom2d, 30)
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
		a.startnode,
		a.endnode,
		a.formofway,
		a.__primary,
		a.trunkroad,
		a.geom2d AS geom,
		null,
		false AS split
	FROM roadlinks a
	LEFT JOIN tmproads tr
	ON a.gid = tr.gid
	WHERE tr.gid IS NULL
);

---- Generate nodes from new roads table
--DROP TABLE IF EXISTS newroadnodes;
--CREATE TABLE newroadnodes AS (
--   SELECT gid AS road_id, ST_StartPoint(geom) AS geom FROM newroadlinks
--	UNION
--	SELECT gid AS road_id, ST_EndPoint(geom) AS geom FROM newroadlinks
--);
--ALTER TABLE newroadnodes ADD COLUMN gid INTEGER;
--
---- tidy up, index and cluster
DROP TABLE tmproads;
CREATE INDEX ON newroadlinks USING GIST(geom);
--CREATE INDEX ON newroadnodes USING GIST(geom);
--CLUSTER newroadnodes USING newroadnodes_geom_idx;
CLUSTER newroadlinks USING newroadlinks_geom_idx;

DROP SEQUENCE IF EXISTS newroadlinks_sequence;
CREATE SEQUENCE IF NOT EXISTS newroadlinks_sequence;
UPDATE newroadlinks SET gid =  nextval('newroadlinks_sequence');
CREATE INDEX ON newroadlinks USING BTREE(gid);
--
--DROP SEQUENCE IF EXISTS newroadnodes_sequence;
--CREATE SEQUENCE IF NOT EXISTS newroadnodes_sequence;
--UPDATE newroadnodes SET gid =  nextval('newroadnodes_sequence');
--CREATE INDEX ON newroadnodes USING BTREE(id);

ALTER TABLE newroadlinks ADD COLUMN "source" integer;
ALTER TABLE newroadlinks ADD COLUMN "target" integer;
SELECT pgr_createTopology('newroadlinks', 0.00001, 'geom', 'gid');

---- Road startpoint and endpoint columns
--SELECT AddGeometryColumn('public', 'newroadlinks', 'startpoint', 27700, 'POINT', 2);
--SELECT AddGeometryColumn('public', 'newroadlinks', 'endpoint', 27700, 'POINT', 2);
--UPDATE newroadlinks SET startpoint = ST_Force2d(ST_StartPoint(geom));
--UPDATE newroadlinks SET endpoint = ST_Force2d(ST_EndPoint(geom));
--CREATE INDEX ON newroadlinks USING gist (startpoint);
--CREATE INDEX ON newroadlinks USING gist (endpoint);
--
--ALTER TABLE newroadlinks ADD COLUMN source INTEGER;
--ALTER TABLE newroadlinks ADD COLUMN target INTEGER;  
--ALTER TABLE newroadlinks ADD COLUMN cost DOUBLE PRECISION;
--ALTER TABLE newroadlinks ADD COLUMN reverse_cost DOUBLE PRECISION;
--
--UPDATE newroadlinks SET id = gid;
--UPDATE newroadlinks SET cost = 1;
--UPDATE newroadlinks SET reverse_cost = 1;
--
--
--UPDATE roadlinks SET geom2d = ST_Force2d(geom);
--SELECT pgr_nodeNetwork('newroadlinks', 0.001, 'id', 'geom2d');
--
--
--UPDATE newroadlinks AS nrl SET source = sq.node_id FROM (
--SELECT DISTINCT ON (r.gid) r.gid AS road_id, p.id AS node_id, ST_Distance(r.startpoint, p.geom) AS distance
--	  FROM newroadlinks r
-- LEFT JOIN newroadnodes p ON ST_DWithin(r.startpoint, p.geom, 30)
--  ORDER BY r.gid, distance ASC
--  ) AS sq
--  WHERE nrl.gid = sq.road_id;
--
--UPDATE newroadlinks AS nrl SET target = sq.node_id FROM (
--SELECT DISTINCT ON (r.gid) r.gid AS road_id, p.id AS node_id, ST_Distance(r.endpoint, p.geom) AS distance
--	  FROM newroadlinks r
-- LEFT JOIN newroadnodes p ON ST_DWithin(r.endpoint, p.geom, 30)
--  ORDER BY r.gid, distance ASC
--  ) AS sq
--  WHERE nrl.gid = sq.road_id;
--
--
---- Store atcocode against the node
--ALTER TABLE newroadnodes ADD COLUMN atcocode VARCHAR(20);
--UPDATE newroadnodes AS nrn SET atcocode = ac.atcocode 
--FROM (
--SELECT DISTINCT ON (s.atcocode) s.atcocode AS atcocode, p.id AS node_id, ST_Distance(s.geom, p.geom) AS distance
--	  FROM candidatestops s
-- LEFT JOIN newroadnodes p ON ST_DWithin(s.geom, p.geom, 30)
--  ORDER BY s.atcocode, distance ASC) AS ac
--  WHERE nrn.id = ac.node_id;
--CREATE INDEX ON newroadnodes USING BTREE(atcocode);
--
--
--SELECT X.* FROM pgr_dijkstra(
--                'SELECT id, source, target, cost FROM newroadlinks',
--                (SELECT id FROM newroadnodes WHERE atcocode = '450010887'),
--				(SELECT id FROM newroadnodes WHERE atcocode = '450023831'),
--				false
--		) AS X
--		ORDER BY seq;
--
