SELECT DISTINCT ON (p.gid)
p.gid AS stop_id, r.gid as road_id, ST_Distance(p.geom, r.geom)
FROM stops p
    LEFT JOIN roadlinks r ON ST_DWithin(p.geom, r.geom, 100)
--WHERE p.atcocode LIKE '4500%'
ORDER BY stop_id, ST_Distance(p.geom, r.geom), road_id