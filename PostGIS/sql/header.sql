DROP DATABASE gis;
CREATE DATABASE gis;
\c gis;

--CREATE SCHEMA openroads;
--SET search_path TO openroads;

CREATE EXTENSION postgis;
CREATE EXTENSION pgrouting;


CREATE TABLE "roadlinks" (
"id" serial,
"gid" serial,
"fictitious" varchar(5),
"identifier" varchar(38),
"class" varchar(22),
"roadnumber" varchar(10),
"name1" varchar(150),
"name1_lang" varchar(3),
"name2" varchar(150),
"name2_lang" varchar(3),
"formofway" varchar(50),
"length" int4,
"__primary" varchar(5),
"trunkroad" varchar(5),
"loop" varchar(5),
"startnode" varchar(38),
"endnode" varchar(38),
"structure" varchar(14),
"nametoid" varchar(20),
"numbertoid" varchar(20),
"function" varchar(40));
ALTER TABLE "roadlinks" ADD PRIMARY KEY (gid);
SELECT AddGeometryColumn('','roadlinks','geom','27700','LINESTRING',4);

CREATE TABLE "roadnodes" (
"id" serial,
"gid" serial,
"identifier" varchar(38),
"formofnode" varchar(20));

ALTER TABLE "roadnodes" ADD PRIMARY KEY (gid);
SELECT AddGeometryColumn('','roadnodes','geom','27700','POINT',4);

