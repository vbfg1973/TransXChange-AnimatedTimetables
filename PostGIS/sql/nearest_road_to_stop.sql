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

select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=1 and gid<20001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=20001 and gid<40001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=40001 and gid<60001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=60001 and gid<80001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=80001 and gid<100001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=100001 and gid<120001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=120001 and gid<140001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=140001 and gid<160001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=160001 and gid<180001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=180001 and gid<200001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=200001 and gid<220001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=220001 and gid<240001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=240001 and gid<260001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=260001 and gid<280001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=280001 and gid<300001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=300001 and gid<320001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=320001 and gid<340001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=340001 and gid<360001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=360001 and gid<380001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=380001 and gid<400001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=400001 and gid<420001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=420001 and gid<440001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=440001 and gid<460001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=460001 and gid<480001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=480001 and gid<500001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=500001 and gid<520001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=520001 and gid<540001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=540001 and gid<560001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=560001 and gid<580001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=580001 and gid<600001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=600001 and gid<620001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=620001 and gid<640001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=640001 and gid<660001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=660001 and gid<680001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=680001 and gid<700001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=700001 and gid<720001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=720001 and gid<740001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=740001 and gid<760001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=760001 and gid<780001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=780001 and gid<800001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=800001 and gid<820001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=820001 and gid<840001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=840001 and gid<860001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=860001 and gid<880001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=880001 and gid<900001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=900001 and gid<920001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=920001 and gid<940001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=940001 and gid<960001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=960001 and gid<980001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=980001 and gid<1000001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=1000001 and gid<1020001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=1020001 and gid<1040001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=1040001 and gid<1060001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=1060001 and gid<1080001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=1080001 and gid<1100001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=1100001 and gid<1120001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=1120001 and gid<1140001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=1140001 and gid<1160001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=1160001 and gid<1180001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=1180001 and gid<1200001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=1200001 and gid<1220001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=1220001 and gid<1240001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=1240001 and gid<1260001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=1260001 and gid<1280001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=1280001 and gid<1300001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=1300001 and gid<1320001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=1320001 and gid<1340001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=1340001 and gid<1360001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=1360001 and gid<1380001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=1380001 and gid<1400001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=1400001 and gid<1420001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=1420001 and gid<1440001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=1440001 and gid<1460001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=1460001 and gid<1480001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=1480001 and gid<1500001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=1500001 and gid<1520001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=1520001 and gid<1540001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=1540001 and gid<1560001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=1560001 and gid<1580001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=1580001 and gid<1600001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=1600001 and gid<1620001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=1620001 and gid<1640001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=1640001 and gid<1660001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=1660001 and gid<1680001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=1680001 and gid<1700001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=1700001 and gid<1720001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=1720001 and gid<1740001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=1740001 and gid<1760001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=1760001 and gid<1780001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=1780001 and gid<1800001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=1800001 and gid<1820001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=1820001 and gid<1840001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=1840001 and gid<1860001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=1860001 and gid<1880001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=1880001 and gid<1900001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=1900001 and gid<1920001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=1920001 and gid<1940001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=1940001 and gid<1960001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=1960001 and gid<1980001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=1980001 and gid<2000001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=2000001 and gid<2020001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=2020001 and gid<2040001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=2040001 and gid<2060001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=2060001 and gid<2080001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=2080001 and gid<2100001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=2100001 and gid<2120001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=2120001 and gid<2140001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=2140001 and gid<2160001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=2160001 and gid<2180001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=2180001 and gid<2200001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=2200001 and gid<2220001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=2220001 and gid<2240001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=2240001 and gid<2260001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=2260001 and gid<2280001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=2280001 and gid<2300001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=2300001 and gid<2320001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=2320001 and gid<2340001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=2340001 and gid<2360001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=2360001 and gid<2380001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=2380001 and gid<2400001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=2400001 and gid<2420001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=2420001 and gid<2440001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=2440001 and gid<2460001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=2460001 and gid<2480001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=2480001 and gid<2500001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=2500001 and gid<2520001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=2520001 and gid<2540001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=2540001 and gid<2560001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=2560001 and gid<2580001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=2580001 and gid<2600001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=2600001 and gid<2620001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=2620001 and gid<2640001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=2640001 and gid<2660001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=2660001 and gid<2680001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=2680001 and gid<2700001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=2700001 and gid<2720001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=2720001 and gid<2740001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=2740001 and gid<2760001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=2760001 and gid<2780001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=2780001 and gid<2800001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=2800001 and gid<2820001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=2820001 and gid<2840001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=2840001 and gid<2860001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=2860001 and gid<2880001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=2880001 and gid<2900001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=2900001 and gid<2920001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=2920001 and gid<2940001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=2940001 and gid<2960001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=2960001 and gid<2980001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=2980001 and gid<3000001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=3000001 and gid<3020001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=3020001 and gid<3040001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=3040001 and gid<3060001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=3060001 and gid<3080001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=3080001 and gid<3100001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=3100001 and gid<3120001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=3120001 and gid<3140001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=3140001 and gid<3160001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=3160001 and gid<3180001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=3180001 and gid<3200001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=3200001 and gid<3220001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=3220001 and gid<3240001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=3240001 and gid<3260001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=3260001 and gid<3280001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=3280001 and gid<3300001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=3300001 and gid<3320001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=3320001 and gid<3340001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=3340001 and gid<3360001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=3360001 and gid<3380001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=3380001 and gid<3400001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=3400001 and gid<3420001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=3420001 and gid<3440001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=3440001 and gid<3460001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=3460001 and gid<3480001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=3480001 and gid<3500001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=3500001 and gid<3520001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=3520001 and gid<3540001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=3540001 and gid<3560001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=3560001 and gid<3580001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=3580001 and gid<3600001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=3600001 and gid<3620001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=3620001 and gid<3640001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=3640001 and gid<3660001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=3660001 and gid<3680001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=3680001 and gid<3700001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=3700001 and gid<3720001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=3720001 and gid<3740001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=3740001 and gid<3760001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=3760001 and gid<3780001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=3780001 and gid<3800001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=3800001 and gid<3820001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=3820001 and gid<3840001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=3840001 and gid<3860001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=3860001 and gid<3880001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=3880001 and gid<3900001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=3900001 and gid<3920001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=3920001 and gid<3940001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=3940001 and gid<3960001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=3960001 and gid<3980001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=3980001 and gid<4000001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=4000001 and gid<4020001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=4020001 and gid<4040001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=4040001 and gid<4060001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=4060001 and gid<4080001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=4080001 and gid<4100001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=4100001 and gid<4120001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=4120001 and gid<4140001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=4140001 and gid<4160001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=4160001 and gid<4180001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=4180001 and gid<4200001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=4200001 and gid<4220001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=4220001 and gid<4240001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=4240001 and gid<4260001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=4260001 and gid<4280001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=4280001 and gid<4300001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=4300001 and gid<4320001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=4320001 and gid<4340001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=4340001 and gid<4360001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=4360001 and gid<4380001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=4380001 and gid<4400001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=4400001 and gid<4420001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=4420001 and gid<4440001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=4440001 and gid<4460001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=4460001 and gid<4480001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=4480001 and gid<4500001');
select pgr_createTopology('topology.roads', 0.0001, 'geom', 'gid', rows_where:='gid>=4500001 and gid<4520001');

ALTER TABLE topology.roads_vertices_pgr ADD COLUMN atcocode VARCHAR(15);
UPDATE topology.roads_vertices_pgr as v
SET atcocode = res.atcocode
FROM 
	(SELECT DISTINCT ON (b.atcocode)
		a.id, b.atcocode, ST_Distance(a.the_geom, b.geom)
	FROM 
		topology.roads_vertices_pgr a
	JOIN 
		candidatestops b 
	ON 
		ST_DWithin(b.geom, a.the_geom, 30)
	ORDER BY b.atcocode, ST_Distance(a.the_geom, b.geom) ASC) AS res
WHERE res.id = v.id;

CREATE INDEX roads_geom_idx ON topology.roads USING gist (geom);
CLUSTER topology.roads using roads_geom_idx;
CREATE INDEX vertices_geom_idx ON topology.roads_vertices_pgr USING gist (the_geom);
CLUSTER topology.roads_vertices_pgr using vertices_geom_idx;

DROP VIEW IF EXISTS fromto;
CREATE VIEW fromto AS
SELECT DISTINCT ON (ro.id) ro.id, fromstop.id AS from_id, fromstop.atcocode AS fromcode, tostop.id AS to_id, tostop.atcocode AS tocode
  FROM topology.roads_vertices_pgr AS fromstop, 
       topology.roads_vertices_pgr AS tostop, 
       routes AS ro 
 WHERE fromstop.atcocode = ro.fromcode 
   AND tostop.atcocode = ro.tocode;
 
DROP TABLE IF EXISTS routes;
CREATE TABLE routes AS SELECT rou.* 
  FROM pgr_dijkstra(
			'SELECT gid AS id, source, target, 1 AS cost FROM topology.roads',
			ARRAY(SELECT from_id FROM fromto WHERE fromcode LIKE '4500%' ORDER BY from_id),
			ARRAY(SELECT to_id FROM fromto WHERE tocode LIKE '4500%' ORDER BY from_id),
			false) AS rou;

