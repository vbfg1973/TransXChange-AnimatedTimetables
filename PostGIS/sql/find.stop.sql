-- This works for a single line

CREATE TABLE mystop AS
SELECT s.ATCOCode AS ATCOCode,
       ST_Distance(r.geom, s.geom) AS distance_m,
       ST_ClosestPoint(r.geom, s.geom) AS geom
  FROM roadlinks AS r, stops AS s
 WHERE s.ATCOCode = '450010895'
 ORDER BY distance_m ASC
 LIMIT 1;

