-- Function to break lines into smaller segments at points where stops occur
CREATE OR REPLACE FUNCTION upgis_CutLineAtPoints(param_ml_geom geometry, param_mp_geom geometry, param_tol double precision)
	   RETURNS geometry AS
$$
	DECLARE
		var_resultgeom geometry;
		-- dump out multis into single points
		-- and lines so we can use line ref functions
		var_pset geometry[] := ARRAY(SELECT geom FROM ST_Dump(param_mp_geom));
		var_lset geometry[] := ARRAY(SELECT geom FROM ST_Dump(param_ml_geom));

		var_sline geometry;
		var_eline geometry;

		var_perc_line double precision;
		var_refgeom geometry;

		BEGIN
		FOR i in 1 .. array_upper(var_pset, 1)
			LOOP
			-- Loop through the line strings
			FOR j in 1 .. array_upper(var_lset, 1)
				LOOP
				-- Check the distance and update if within tolerance
				IF ST_DWithin(var_lset[j], var_pset[i], param_tol)
				   AND NOT ST_Intersects(ST_Boundary(var_lset[j]), var_pset[i]) THEN
				   IF ST_NumGeometries(ST_Multi(var_lset[j])) = 1 THEN
				   	  -- get percent along line for point
					  var_perc_line := ST_LineLocatePoint(var_lset[j], var_pset[i]);
					  IF var_perc_line BETWEEN 0.0001 AND 0.9999 THEN
					  	 -- First cut
					  	 var_sline := ST_LineSubstring(var_lset[j], 0, var_perc_line);
						 -- Second cut
						 var_eline := ST_LineSubstring(var_lset[j], var_perc_line, 1);
						 -- fix rounding so start line abutts second cut
						 var_eline := ST_SetPoint(var_eline, 0, ST_EndPoint(var_sline));
						 -- Collect the two lines together
						 var_lset[j] := ST_Collect(var_sline, var_eline);
					  END IF;
				   ELSE
				     var_lset[j] := upgis_CutLineAtPoints(var_lset[j], var_pset[i]);
			  END IF;
			END IF;
		  END LOOP;
	    END LOOP;
	  RETURN ST_Union(var_lset);
    END;
  $$
LANGUAGE 'plpgsql' IMMUTABLE STRICT;

-- Generate the new road segments
CREATE TABLE newroads AS
SELECT rl.id AS id,
       rl.gid AS gid,
	   rl.fictitious AS fictitious,
	   rl.identifier AS identifier,
	   rl.class AS class,
	   rl.roadnumber AS roadnumber,
	   rl.name1 AS name1,
	   rl.name1_lang AS name1_lang,
	   rl.formofway AS formofway,
	   rl.__primary AS __primary,
	   rl.trunkroad AS trunkroad,
	   rl.loop AS loop,
	   rl.structure AS structure,
	   rl.nametoid AS nametoid,
	   rl.numbertoid AS numbertoid,
	   rl.function AS function,
	   rl.speed_mph,
	   upgis_CutLineAtPoints(rl.geom, cs.geom, 1) AS geom
FROM candidatestops AS cs,
     roadlinks AS rl
WHERE cs.road_id = rl.gid;

-- But it don't fucking work cos it ain't breaking the lines at the stops near me, cos the below nodes aren't being created at those points:

CREATE TABLE newnodes AS SELECT road_id, id, (geom).geom FROM (SELECT id AS road_id, ROW_NUMBER() OVER (order by id) AS id, ST_DUMPPOINTS(geom) AS geom FROM roadlinks) AS foo;
