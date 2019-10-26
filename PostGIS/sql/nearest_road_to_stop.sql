SELECT AddGeometryColumn('public', 'roadlinks', 'geom2d', 27700, 'LINESTRING', 2);
UPDATE roadlinks SET geom2d = ST_Force2d(geom);
CREATE INDEX roadlinks_geom2d_idx ON public.roadlinks USING gist (geom2d);
CLUSTER public.roadlinks using roadlinks_geom_idx;

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

DROP TABLE IF EXISTS newroadnodes;
CREATE TABLE newroadnodes AS (
    SELECT ST_StartPoint(geom) AS geom FROM newroadlinks
	UNION
	SELECT ST_EndPoint(geom) AS geom FROM newroadlinks
);

DROP TABLE tmproads;

CREATE INDEX ON newroadlinks USING GIST(geom);
CREATE INDEX ON newroadnodes USING GIST(geom);
CLUSTER newroadnodes USING newroadnodes_geom_idx;
CLUSTER newroadlinks USING newroadlinks_geom_idx;

CREATE SEQUENCE IF NOT EXISTS number_sequence;
alter table newroadnodes ADD COLUMN id INTEGER;
UPDATE newroadnodes SET id =  nextval('number_sequence');
CREATE INDEX ON newroadnodes USING BTREE(id);

ALTER TABLE newroadlinks ADD COLUMN start_id INTEGER;
ALTER TABLE newroadlinks ADD COLUMN end_id INTEGER;

-- These are ridculously slow!
UPDATE newroadlinks AS a SET start_id = b.id FROM newroadnodes AS b WHERE ST_StartPoint(a.geom) = b.geom;
UPDATE newroadlinks AS a SET end_id = b.id FROM newroadnodes AS b WHERE ST_EndPoint(a.geom) = b.geom;

