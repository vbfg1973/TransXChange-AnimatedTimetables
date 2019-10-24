SELECT DISTINCT ON (p.gid)
p.gid AS stop_id, r.gid as road_id, ST_Distance(p.geom, r.geom)
FROM stops p
    LEFT JOIN roadlinks r ON ST_DWithin(p.geom, r.geom, 100)
--WHERE p.atcocode LIKE '4500%'
ORDER BY stop_id, ST_Distance(p.geom, r.geom), road_id

CREATE TABLE stopcandidates AS 
 SELECT t.stop_id, t.road_id, ST_ClosestPoint(t.stop_geom, t.road_geom) AS geom
 FROM (
		SELECT DISTINCT ON (p.gid)
		p.gid AS stop_id, r.gid as road_id, ST_Distance(p.geom, r.geom) AS distance, p.geom AS stop_geom, r.geom AS road_geom
		FROM stops p
			LEFT JOIN roadlinks r ON ST_DWithin(p.geom, r.geom, 30)
		WHERE p.atcocode LIKE '4500%'
		ORDER BY stop_id, distance, road_id
	) AS t,
	roadlinks AS rl, stops AS s;
