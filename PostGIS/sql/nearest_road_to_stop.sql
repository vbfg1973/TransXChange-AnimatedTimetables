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
DROP TABLE IF EXISTS roads;
CREATE TABLE roads AS (
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
--   SELECT gid AS road_id, ST_StartPoint(geom) AS geom FROM roads
--	UNION
--	SELECT gid AS road_id, ST_EndPoint(geom) AS geom FROM roads
--);
--ALTER TABLE newroadnodes ADD COLUMN gid INTEGER;
--
---- tidy up, index and cluster
DROP TABLE tmproads;
CREATE INDEX ON roads USING GIST(geom);
--CREATE INDEX ON newroadnodes USING GIST(geom);
--CLUSTER newroadnodes USING newroadnodes_geom_idx;
CLUSTER roads USING roads_geom_idx;

DROP SEQUENCE IF EXISTS roads_sequence;
CREATE SEQUENCE IF NOT EXISTS roads_sequence;
UPDATE roads SET gid =  nextval('roads_sequence');
CREATE INDEX ON roads USING BTREE(gid);
--
--DROP SEQUENCE IF EXISTS newroadnodes_sequence;
--CREATE SEQUENCE IF NOT EXISTS newroadnodes_sequence;
--UPDATE newroadnodes SET gid =  nextval('newroadnodes_sequence');
--CREATE INDEX ON newroadnodes USING BTREE(id);

ALTER TABLE roads ADD COLUMN "source" integer;
ALTER TABLE roads ADD COLUMN "target" integer;
