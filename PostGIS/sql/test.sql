
DROP TABLE IF EXISTS testline;
CREATE TABLE testline AS SELECT ST_MakeLine(ST_MakePoint(10,20), ST_MakePoint(30,40)) AS geom;

DROP TABLE IF EXISTS testpoint;
CREATE TABLE testpoint AS SELECT ST_MakePoint(15,25) AS geom;

DROP TABLE IF EXISTS testsplit;
CREATE TABLE testsplit AS(
SELECT
    (ST_Dump(ST_Split(ST_Snap(a.geom, b.geom, 0.00001),b.geom))).geom
FROM 
    testline a
JOIN 
    testpoint b 
ON 
    ST_DWithin(b.geom, a.geom, 30)
);

