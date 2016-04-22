-- ref: http://www.gaia-gis.it/gaia-sins/spatialite-sql-4.2.0.html

--need to upload "spatialite" module in SQLite3
--https://www.sqlite.org/cli.html
.header on
.explain on
.mode column
.echo on
.load /usr/local/lib/mod_spatialite.so sqlite3_modspatialite_init
--select InitSpatialMetaData(); --unecessary since we know it's spatial

drop view traininglabel; -- just in case

-- examples:
--OGC_  GEOMETRY       land  labe  b0    b1             b2  b3             b4                 b5                 b6                  b7                 b8                    b9                b10             
------  -------------  ----  ----  ----  -------------  --  -------------  -----------------  -----------------  ------------------  -----------------  --------------------  ----------------  ----------------
--1                    farm  3     0.12  0.10462536662  0.  0.07202699780  0.226306647062302  0.124616049230099  0.0844899192452431  0.069579154253006  0.000855422287713736  300.070159912109  299.016586303711
--2                    farm  3     0.13  0.11810164153  0.  0.08726676553  0.21780501306057   0.149410292506218  0.10120365396142    0.091188576072454  0.000885883899172768  299.993072509766  298.969604492187


--append all label and band info (average val) to one table/view
create view traininglabel as
    select label,b0,b1,b2,b3,b4,b5,b6,b7,b8,b9,b10 from water
    union all 
    select label,b0,b1,b2,b3,b4,b5,b6,b7,b8,b9,b10 from forest
    union all 
    select label,b0,b1,b2,b3,b4,b5,b6,b7,b8,b9,b10 from farm
    union all 
    select label,b0,b1,b2,b3,b4,b5,b6,b7,b8,b9,b10 from building
    union all 
    select label,b0,b1,b2,b3,b4,b5,b6,b7,b8,b9,b10 from railway
    union all 
    select label,b0,b1,b2,b3,b4,b5,b6,b7,b8,b9,b10 from highway;

.mode csv
--we don't want the "select ..." statement in the output
.echo off
.header off
.output traininglabel.csv
select * from traininglabel;
--.output stdout --to print the output content, warning could be long

--no need to keep the traininglabel view after exporting to csv file.
drop view traininglabel;
