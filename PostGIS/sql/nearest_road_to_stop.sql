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
