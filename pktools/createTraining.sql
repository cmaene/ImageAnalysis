--need to upload "spatialite" module in SQLite3
.header on
.explain on
.mode column
.echo on
.load /usr/local/lib/mod_spatialite.so sqlite3_modspatialite_init
--select InitSpatialMetaData(); --unecessary since we know it's spatial

-----------------------------------------------------------------------------------------------------

--DATA CHECKING --------START

select CheckSpatialMetaData();

select * from spatial_ref_sys;

--check tables -- what tables are inside..?
.tables

select * from geometry_columns;

select natural, count(natural), SUM(Area(GeomFromWKB(GEOMETRY))) from multipolygons group by natural;

select landuse, count(landuse), SUM(Area(GeomFromWKB(GEOMETRY))) from multipolygons group by landuse;

--DATA CHECKING --------DONE

-----------------------------------------------------------------------------------------------------

--start adding training label: water(1), forest(2), farm(3), railway(4), building(5)

-- drop in case, training table already exists
drop table water;    --1
drop table forest;   --2
drop table farm;     --3
drop table railway;  --4
drop table building; --5
vacuum;
-----------------------------------------------------------------------------------------------------

-- TRIED TO "CREATE TABLE X AS SELECT" BUT IT JUST DOESN'T WORK WITH SPATIAL DATA
--create table water as select type, natural, other_tags, geometry from multipolygons where natural="water" or other_tags like "%waterway%";
--select RecoverFDOGeometryColumn('water', 'GEOMETRY', 4326, 6, 2, 'WKB');

--create a blank "water" table
create table water (OGC_FID INTEGER PRIMARY KEY AUTOINCREMENT, natural VARCHAR, other_tags VARCHAR);

--establish Geometry column
select AddFDOGeometryColumn('water', 'GEOMETRY', 4326, 6, 2, 'WKB');

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
select AddFDOGeometryColumn('forest', 'GEOMETRY', 4326, 6, 2, 'WKB');

--insert rows from existing table where landuse="forest" or natural="wood";
insert into forest(OGC_FID, landuse, geometry) select OGC_FID, landuse, geometry from multipolygons where landuse="forest" or natural="wood";

--add a new column - training label
alter table forest add column label integer;
update forest set label=2;

--check to see if labels are created correctly
select label, count(label), SUM(Area(GeomFromWKB(geometry))) from forest group by label;

-----------------------------------------------------------------------------------------------------

--create a blank "farm" table
create table farm (OGC_FID INTEGER PRIMARY KEY AUTOINCREMENT, landuse VARCHAR);

--establish Geometry column
select AddFDOGeometryColumn('farm', 'GEOMETRY', 4326, 6, 2, 'WKB');

--insert rows from existing table where landuse="farm" or landuse="farmland";
insert into farm(OGC_FID, landuse, geometry) select OGC_FID, landuse, geometry from multipolygons where landuse="farm" or landuse="farmland";

--add a new column - training label
alter table farm add column label integer;
update farm set label=3;

--check to see if labels are created correctly
select label, count(label), SUM(Area(GeomFromWKB(geometry))) from farm group by label;

-----------------------------------------------------------------------------------------------------

--create a blank "railway" table
create table railway (OGC_FID INTEGER PRIMARY KEY AUTOINCREMENT, landuse VARCHAR);

--establish Geometry column
select AddFDOGeometryColumn('railway', 'GEOMETRY', 4326, 6, 2, 'WKB');

--insert rows from existing table where landuse="railways";
insert into railway(OGC_FID, landuse, geometry) select OGC_FID, landuse, geometry from multipolygons where landuse="railway";

--add a new column - training label
alter table railway add column label integer;
update railway set label=4;

--check to see if labels are created correctly
select label, count(label), SUM(Area(GeomFromWKB(geometry))) from railway group by label;

-----------------------------------------------------------------------------------------------------

--create a blank "building" table
create table building (OGC_FID INTEGER PRIMARY KEY AUTOINCREMENT, building VARCHAR);

--establish Geometry column
select AddFDOGeometryColumn('building', 'GEOMETRY', 4326, 6, 2, 'WKB');

--insert rows from existing table where building="yes";
insert into building(OGC_FID, building, geometry) select OGC_FID, building, geometry from multipolygons where building="yes";

--add a new column - training label
alter table building add column label integer;
update building set label=5;

--check to see if labels are created correctly
select label, count(label), SUM(Area(GeomFromWKB(geometry))) from building group by label;

-----------------------------------------------------------------------------------------------------

drop table multipolygons;
vacuum;

