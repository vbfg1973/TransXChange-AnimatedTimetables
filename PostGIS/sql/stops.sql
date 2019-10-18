CREATE TABLE "stops" (
"id" serial,
"gid" serial,
"atcocode" varchar(15),
"commonname" varchar(65),
"street" varchar(150),
"stoptype" varchar(3),
"busstoptype" varchar(3),
"timingstatus" varchar(3),
"bearing" varchar(3),
"easting" integer,
"northing" integer
);

ALTER TABLE "stops" ADD PRIMARY KEY (gid);
SELECT AddGeometryColumn('','stops','geom','27700','POINT',2);
