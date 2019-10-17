CREATE VIEW network AS
	SELECT r.*, 
	       a.identifier AS start_id,
		   b.identifier AS end_id
	  FROM roads AS r
      JOIN nodes AS a ON r.startnode = a.identifier
	  JOIN nodes AS b on r.endnode = b.identifier;