-- ref: http://www.gaia-gis.it/gaia-sins/spatialite-sql-4.2.0.html

--need to upload "spatialite" module in SQLite3
.header on
.explain on
.mode column
.echo on
.load /usr/local/lib/mod_spatialite.so sqlite3_modspatialite_init
--select InitSpatialMetaData(); --unecessary since we know it's spatial

-----------------------------------------------------------------------------------------------------
--DATA CHECKING --------

--make sure of spatiality, plus type: FDO/OGR
select CheckSpatialMetaData();

--check SRS
select * from spatial_ref_sys;

--check tables -- what tables are inside..?
.tables

--check geometry column, notice geometry type is FDO/OGR
select * from geometry_columns;

--run basic queries, just to see it works
select natural, count(natural), SUM(Area(GeomFromWKB(GEOMETRY))) from multipolygons group by natural limit 5;
select landuse, count(landuse), SUM(Area(GeomFromWKB(GEOMETRY))) from multipolygons group by landuse limit 5;

-----------------------------------------------------------------------------------------------------

--start adding training label: water(1), forest(2), farm(3), railway(4), building(5)

-- drop in case, training table already exists
drop table water;    --1
drop table forest;   --2
drop table farm;     --3
drop table building; --4
drop table railway;  --5
drop table highway;  --6
drop table bamboo;   --7
vacuum;
-----------------------------------------------------------------------------------------------------

-- TRIED TO "CREATE TABLE X AS SELECT" BUT IT JUST DOESN'T WORK WITH SPATIAL DATA
--create table water as select type, natural, other_tags, geometry from multipolygons where natural="water" or other_tags like "%waterway%";
--select RecoverFDOGeometryColumn('water', 'GEOMETRY', 4326, 6, 2, 'WKB');

--create a blank "water" table
create table water (OGC_FID INTEGER PRIMARY KEY AUTOINCREMENT, natural VARCHAR, other_tags VARCHAR);

--establish Geometry column
select AddFDOGeometryColumn('water', 'geometry', 4326, 6, 2, 'WKB');

--insert rows from existing table where natural="water" or other_tags like "%waterway%"
insert into water(OGC_FID, natural, other_tags, geometry) select OGC_FID, natural, other_tags, geometry from multipolygons where natural="water" or other_tags like "%waterway%";

--add a new column - training label
alter table water add column label integer;
update water set label=1;

--check to see if labels are created correctly
select label, count(label), SUM(Area(GeomFromWKB(geometry))) from water group by label;

-----------------------------------------------------------------------------------------------------

--create a blank "forest" table
create table forest (OGC_FID INTEGER PRIMARY KEY AUTOINCREMENT, landuse VARCHAR);

--establish Geometry column
select AddFDOGeometryColumn('forest', 'geometry', 4326, 6, 2, 'WKB');

--insert rows from existing table where landuse="forest" or natural="wood";
insert into forest(OGC_FID, landuse, geometry) select OGC_FID, landuse, geometry from multipolygons where landuse="forest" or natural="wood" limit 300;

--add a new column - training label
alter table forest add column label integer;
update forest set label=2;

--check to see if labels are created correctly
select label, count(label), SUM(Area(GeomFromWKB(geometry))) from forest group by label;

-----------------------------------------------------------------------------------------------------

--create a blank "farm" table
create table farm (OGC_FID INTEGER PRIMARY KEY AUTOINCREMENT, landuse VARCHAR);

--establish Geometry column
select AddFDOGeometryColumn('farm', 'geometry', 4326, 6, 2, 'WKB');

--insert rows from existing table where landuse="farm" or landuse="farmland";
insert into farm(OGC_FID, landuse, geometry) select OGC_FID, landuse, geometry from multipolygons where landuse="farm" or landuse="farmland";

--add a new column - training label
alter table farm add column label integer;
update farm set label=3;

--check to see if labels are created correctly
select label, count(label), SUM(Area(GeomFromWKB(geometry))) from farm group by label;

-----------------------------------------------------------------------------------------------------

--create a blank "building" table
create table building (OGC_FID INTEGER PRIMARY KEY AUTOINCREMENT, building VARCHAR);

--establish Geometry column
select AddFDOGeometryColumn('building', 'geometry', 4326, 6, 2, 'WKB');

--insert rows from existing table where building="yes", limit to 200 features (too many buildings in source);
insert into building(OGC_FID, building, geometry) select OGC_FID, building, geometry from multipolygons where building="yes" limit 300;

--add a new column - training label
alter table building add column label integer;
update building set label=4;

--check to see if labels are created correctly
select label, count(label), SUM(Area(GeomFromWKB(geometry))) from building group by label;

-----------------------------------------------------------------------------------------------------

--create a blank "railway" table
create table railway (OGC_FID INTEGER PRIMARY KEY AUTOINCREMENT, landuse VARCHAR);

--establish Geometry column
select AddFDOGeometryColumn('railway', 'geometry', 4326, 6, 2, 'WKB');

--insert rows from existing table where landuse="railways";
insert into railway(OGC_FID, landuse, geometry) select OGC_FID, landuse, geometry from multipolygons where landuse="railway";

--add a new column - training label
alter table railway add column label integer;
update railway set label=5;

--check to see if labels are created correctly
select label, count(label), SUM(Area(GeomFromWKB(geometry))) from railway group by label;

-----------------------------------------------------------------------------------------------------

--creating highway training label is tricky as source for highways are lines, not polygons

--create table - instead of ".loadshp lines_osm shpline UTF8 4326" (works directly in spatialite)
--though "TEXT" is now replaced by VARCHAR
CREATE TABLE "lines" (
"OGC_FID" INTEGER PRIMARY KEY AUTOINCREMENT,
"osm_id" VARCHAR,
"name" VARCHAR,
"highway" VARCHAR,
"waterway" VARCHAR,
"aerialway" VARCHAR,
"barrier" VARCHAR,
"man_made" VARCHAR,
"other_tags" VARCHAR);

--establish Geometry column - note: linestring=2
select AddFDOGeometryColumn('lines', 'geometry', 4326, 2, 2, 'WKB');

--import lines shapefile. Note: I had to drop "other_tags" in shp prior to importing
--otherwise, kept getting "invalid character sequence", something bad in "other_tags"
create virtual table shpline using VirtualShape("lines_osm", "utf-8", 4326);

--insert from the VirtualShape table
insert into lines (osm_id, name, highway, waterway, aerialway, barrier, man_made, geometry) select osm_id, name, highway, waterway, aerialway, barrier, man_made, geometry from shpline WHERE highway="primary";
--select * from lines where highway="primary" limit 5; --just checking

--create a blank "highway" table
create table highway (OGC_FID INTEGER PRIMARY KEY AUTOINCREMENT, highway VARCHAR);

--establish Geometry column - note: multipolygons=6
select AddFDOGeometryColumn('highway', 'geometry', 4326, 6, 2, 'WKB');

--insert rows from lines (highways only) but buffered highways, 0.000025=approx.5m (2.5m*2) road width;
--insert into highway(OGC_FID, geometry) select OGC_FID, ST_UNION(ST_Buffer(geometry, 0.000025)) from lines; --better not to dissolve for collecting training data..
insert into highway(OGC_FID, geometry) select OGC_FID, ST_Buffer(geometry, 0.000025) from lines;

--add a new column - training label
alter table highway add column label integer;
update highway set label=6;

--check to see if labels are created correctly
select label, count(label), SUM(Area(GeomFromWKB(geometry))) from highway group by label;

-----------------------------------------------------------------------------------------------------

--creating bamboo label

--create table - instead of ".loadshp lines_osm shpline UTF8 4326" (works directly in spatialite)
CREATE TABLE "bamboo" (
"OGC_FID" INTEGER PRIMARY KEY AUTOINCREMENT,
"id" VARCHAR);

--establish Geometry column - note: multipolygons=6
select AddFDOGeometryColumn('bamboo', 'geometry', 4326, 6, 2, 'WKB');

--import lines shapefile. Note: I had to drop "other_tags" in shp prior to importing
--otherwise, kept getting "invalid character sequence", something bad in "other_tags"
create virtual table vbamboo using VirtualShape("KyotoBamboo", "utf-8", 4326);

--insert from the VirtualShape table
insert into bamboo(id, geometry) select id, geometry from vbamboo;

--add a new column - training label
alter table bamboo add column label integer;
update bamboo set label=7;

--check to see if labels are created correctly
select label, count(label), SUM(Area(GeomFromWKB(geometry))) from bamboo group by label;

-----------------------------------------------------------------------------------------------------

drop table multipolygons;
drop table lines;
vacuum;


