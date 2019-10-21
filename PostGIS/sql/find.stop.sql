-- This works for a single line

--CREATE TABLE mystop AS
--SELECT s.ATCOCode AS ATCOCode,
--       ST_Distance(r.geom, s.geom) AS distance_m,
--       ST_ClosestPoint(r.geom, s.geom) AS geom
--  FROM roadlinks AS r, stops AS s
-- WHERE s.ATCOCode = '450010895'
-- ORDER BY distance_m ASC
-- LIMIT 1;


-- Candidate for processing all! - doesn't work!!
CREATE TABLE newstops AS
SELECT
  * 
FROM (
  SELECT
     s.ATCOCode AS ATCOCode,
     ST_Distance(r.geom, s.geom) AS distance_m,
     ST_ClosestPoint(r.geom, s.geom) AS geom,
     ROW_NUMBER() OVER (PARTITION BY ATCOCode) AS r
  	 FROM roadlinks AS r, wtstops AS s
	 WHERE ST_DWithin(r.geom, s.geom, 50) -- limit query to 500m
     ORDER BY distance_m ASC) x
  WHERE x.r = 1;


--  This is very slow!! - perhaps needs something to whittle down the candidate geoms first!
-- eg:

--SELECT stops.*, ST_Distance(roadlinks.geom, stops.geom)/1000.0 AS distance_km
--FROM roadlinks, stops
--WHERE roadlinks.id = 123 AND ST_DWithin(roadlinks.geom, stops.geom, 5000.0)
--ORDER BY ST_LineLocateStopsnt(roadlinks.geom, stops.geom),
--         ST_Distance(roadlinks.geom, stops.geom);
--
