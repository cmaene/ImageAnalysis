--need to upload "spatialite" module in SQLite3
.header on
.load /usr/local/lib/mod_spatialite.so sqlite3_modspatialite_init
--select InitSpatialMetaData(); --unecessary since we know it's spatial

-----------------------------------------------------------------------------------------------------
.print ""
.print "DATA CHECKING --------START"

.print ""
.print "select CheckSpatialMetaData();"
select CheckSpatialMetaData();

.print ""
.print "select * from spatial_ref_sys;"
select * from spatial_ref_sys;

--check tables
.print ""
.print "what tables are inside..?"
.tables

.print ""
.print "select * from geometry_columns;"
select * from geometry_columns;

.print ""
.print "select natural, count(natural), SUM(Area(GeomFromWKB(GEOMETRY))) from multipolygons group by natural;"
select natural, count(natural), SUM(Area(GeomFromWKB(GEOMETRY))) from multipolygons group by natural;

.print ""
.print "select landuse, count(landuse), SUM(Area(GeomFromWKB(GEOMETRY))) from multipolygons group by landuse;"
select landuse, count(landuse), SUM(Area(GeomFromWKB(GEOMETRY))) from multipolygons group by landuse;

.print ""
.print "DATA CHECKING --------DONE"

-----------------------------------------------------------------------------------------------------
.print ""
.print "start adding training label: water(1), forest(2), farm(3), railway(4), building(5)"

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
.print ""
.print "create table water (OGC_FID INTEGER PRIMARY KEY AUTOINCREMENT,  other_tags VARCHAR);"
create table water (OGC_FID INTEGER PRIMARY KEY AUTOINCREMENT, natural VARCHAR, other_tags VARCHAR);

--establish Geometry column
.print ""
.print "select AddFDOGeometryColumn('water', 'GEOMETRY', 4326, 6, 2, 'WKB');"
select AddFDOGeometryColumn('water', 'GEOMETRY', 4326, 6, 2, 'WKB');

--insert rows from existing table where natural="water" or other_tags like "%waterway%"
.print ""
.print "insert data from multipolygons"
insert into water(OGC_FID, natural, other_tags, geometry) select OGC_FID, natural, other_tags, geometry from multipolygons where natural="water" or other_tags like "%waterway%";

.print ""
.print "add a new column - training label"
.print "alter table water add column label integer;"
alter table water add column label integer;
update water set label=1;

.print ""
.print "check to see if labels are created correctly"
.print "select label, count(label), SUM(Area(GeomFromWKB(geometry))) from water group by label;"
select label, count(label), SUM(Area(GeomFromWKB(geometry))) from water group by label;

-----------------------------------------------------------------------------------------------------

--create a blank "forest" table
.print ""
.print "create table forest (OGC_FID INTEGER PRIMARY KEY AUTOINCREMENT,  landuse VARCHAR);"
create table forest (OGC_FID INTEGER PRIMARY KEY AUTOINCREMENT, landuse VARCHAR);

--establish Geometry column
.print ""
.print "select AddFDOGeometryColumn('forest', 'GEOMETRY', 4326, 6, 2, 'WKB');"
select AddFDOGeometryColumn('forest', 'GEOMETRY', 4326, 6, 2, 'WKB');

--insert rows from existing table where landuse="forest" or natural="wood";
.print ""
.print "insert data from multipolygons"
insert into forest(OGC_FID, landuse, geometry) select OGC_FID, landuse, geometry from multipolygons where landuse="forest" or natural="wood";

.print ""
.print "add a new column - training label"
.print "alter table forest add column label integer;"
alter table forest add column label integer;
update forest set label=2;

.print ""
.print "check to see if labels are created correctly"
.print "select label, count(label), SUM(Area(GeomFromWKB(geometry))) from forest group by label;"
select label, count(label), SUM(Area(GeomFromWKB(geometry))) from forest group by label;

-----------------------------------------------------------------------------------------------------

--create a blank "farm" table
.print ""
.print "create table farm (OGC_FID INTEGER PRIMARY KEY AUTOINCREMENT,  landuse VARCHAR);"
create table farm (OGC_FID INTEGER PRIMARY KEY AUTOINCREMENT, landuse VARCHAR);

--establish Geometry column
.print ""
.print "select AddFDOGeometryColumn('farm', 'GEOMETRY', 4326, 6, 2, 'WKB');"
select AddFDOGeometryColumn('farm', 'GEOMETRY', 4326, 6, 2, 'WKB');

--insert rows from existing table where landuse="farm" or landuse="farmland";
.print ""
.print "insert data from multipolygons"
insert into farm(OGC_FID, landuse, geometry) select OGC_FID, landuse, geometry from multipolygons where landuse="farm" or landuse="farmland";

.print ""
.print "add a new column - training label"
.print "alter table farm add column label integer;"
alter table farm add column label integer;
update farm set label=3;

.print ""
.print "check to see if labels are created correctly"
.print "select label, count(label), SUM(Area(GeomFromWKB(geometry))) from farm group by label;"
select label, count(label), SUM(Area(GeomFromWKB(geometry))) from farm group by label;

-----------------------------------------------------------------------------------------------------

--create a blank "railway" table
.print ""
.print "create table railway (OGC_FID INTEGER PRIMARY KEY AUTOINCREMENT,  landuse VARCHAR);"
create table railway (OGC_FID INTEGER PRIMARY KEY AUTOINCREMENT, landuse VARCHAR);

--establish Geometry column
.print ""
.print "select AddFDOGeometryColumn('railway', 'GEOMETRY', 4326, 6, 2, 'WKB');"
select AddFDOGeometryColumn('railway', 'GEOMETRY', 4326, 6, 2, 'WKB');

--insert rows from existing table where landuse="railways";
.print ""
.print "insert data from multipolygons"
insert into railway(OGC_FID, landuse, geometry) select OGC_FID, landuse, geometry from multipolygons where landuse="railway";

.print ""
.print "add a new column - training label"
.print "alter table railway add column label integer;"
alter table railway add column label integer;
update railway set label=4;

.print ""
.print "check to see if labels are created correctly"
.print "select label, count(label), SUM(Area(GeomFromWKB(geometry))) from railway group by label;"
select label, count(label), SUM(Area(GeomFromWKB(geometry))) from railway group by label;

-----------------------------------------------------------------------------------------------------

--create a blank "building" table
.print ""
.print "create table building (OGC_FID INTEGER PRIMARY KEY AUTOINCREMENT,  building VARCHAR);"
create table building (OGC_FID INTEGER PRIMARY KEY AUTOINCREMENT, building VARCHAR);

--establish Geometry column
.print ""
.print "select AddFDOGeometryColumn('building', 'GEOMETRY', 4326, 6, 2, 'WKB');"
select AddFDOGeometryColumn('building', 'GEOMETRY', 4326, 6, 2, 'WKB');

--insert rows from existing table where building="yes";
.print ""
.print "insert data from multipolygons"
insert into building(OGC_FID, building, geometry) select OGC_FID, building, geometry from multipolygons where building="yes";

.print ""
.print "add a new column - training label"
.print "alter table building add column label integer;"
alter table building add column label integer;
update building set label=5;

.print ""
.print "check to see if labels are created correctly"
.print "select label, count(label), SUM(Area(GeomFromWKB(geometry))) from building group by label;"
select label, count(label), SUM(Area(GeomFromWKB(geometry))) from building group by label;

-----------------------------------------------------------------------------------------------------

.print ""
.print "after creating training data, delete the original input, multipolygons"
drop table multipolygons;
vacuum;

