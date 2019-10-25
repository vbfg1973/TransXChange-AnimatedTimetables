-- Fin the road closest to the stop
CREATE TABLE nearestroads AS
		SELECT DISTINCT ON (p.gid)
		p.gid AS stop_id, r.gid as road_id, ST_Distance(p.geom, r.geom) AS distance, p.geom AS stop_geom, r.geom AS road_geom
		FROM stops p
			LEFT JOIN roadlinks r ON ST_DWithin(p.geom, r.geom, 30)
		ORDER BY stop_id, distance, road_id;

-- Create a point on the road nearest to the stop at the point where it is closest
CREATE TABLE candidatestops AS SELECT stop_id, road_id, ST_ClosestPoint(road_geom, stop_geom) AS geom FROM nearestroads;

-- Get rid of the table representing nearestroads
DROP TABLE nearestroads;

SELECT n.id, ST_Split(n.geom, ST_ClosestPoint(n.geom,ST_Buffer(p.geom, 100))) AS geom
    FROM roadlinks n, candidatestops p WHERE geom is not null

CREATE TABLE splitroads AS
SELECT stop_id, road_id, ST_Split(road_geom, ST_ClosestPoint(road_geom, stop_geom)) AS geom
  FROM (SELECT DISTINCT ON (p.gid)
		p.gid AS stop_id,
		p.atcocode AS atcocode,
		r.gid AS road_id,
		ST_Distance(p.geom, r.geom) AS distance,
		p.geom AS stop_geom,
		r.geom AS road_geom
		FROM stops p
			LEFT JOIN roadlinks r ON ST_DWithin(p.geom, r.geom, 30)
		ORDER BY stop_id, distance, road_id) AS foo
WHERE road_id IS NOT NULL;
