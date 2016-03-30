#!/bin/bash

today=`date +"%m%d%y"`
cd /home/chieko/Documents/ImageAnalysis/pktools

# -------------------------------------------------------
# Extract spectral profil for training classes
# -------------------------------------------------------
# see training.shp description
#ogrinfo -al -so training.shp
# see input landsat7 description
#gdalinfo landsat7.tif

# I have four landsat8 images, one for each season 
SEASONS=(spring summer fall winter)
for season in "${SEASONS[@]}"
do
	rm wksp/$season'_mean.geojson' # delete previously created .geojson, otherwise error in ogr2ogr/CSV
	rm wksp/$season'_mean.csv' # delete previously created .geojson, otherwise error in ogr2ogr/CSV
	pkextract -i 'landsat8toa'$season'_cf5.tif' -s KyotoSamples.shp -o wksp/$season'_mean.geojson' -f "GeoJSON" -r mean -point
	ogr2ogr -skipfailures -overwrite -f "CSV" wksp/$season'_mean.csv' wksp/$season'_mean.geojson'
done

# -------------------------------------------------------
# Seasonal differences in spectral profiles
# http://www.spatial-ecology.net/dokuwiki/doku.php?id=wiki:gnuplot2a - good idea but gnuplot is too picky for me
# I am using R for plotting and saving..
# -------------------------------------------------------
echoseasons="`echo ${SEASONS[@]}`"
Rscript plotSpectral.R "$echoseasons"

# combine the images
images=()
for season in "${SEASONS[@]}"
do
	#Rscript plotSpectral.R $season
	images+='wksp/spectral_'$season'.png ' 
done
#convert $images -append spectralall.png # this vertically appends...
montage -mode concatenate -tile 2x2 $images spectral_by_season.png

# -------------------------------------------------------
# use OpenStreetMap as training data
# and then try SVM classification -
# -------------------------------------------------------
# download openstreetmap data for the imagery extent
# openstreetmap APIs are all tricky, don't know why.. see: http://wiki.openstreetmap.org/wiki/Xapi
# downloaded below is OSM XML format: http://wiki.openstreetmap.org/wiki/OSM_XML
curl "http://overpass-api.de/api/map?bbox=135.6697726,34.9499443,135.8002080,35.0450759" -o openstreet.osm

#ogr2ogr -f "ESRI Shapefile" wksp openstreet.osm -skipfailures -overwrite -lco ENCODING=UTF-8
# I believe sqlite handles OSM data better - this normally takes a long time...
ogr2ogr -f "SQLite" openstreet.sqlite openstreet.osm -skipfailures -overwrite -lco ENCODING=UTF-8

# the output wasn't clip out by extent, so I will clip it myself..
# also, "multipolygons" after openstreet.osm specifies to translate multipolygons layer only!
# note: this is relatively a large area and takes about 2-3 hours..
ogr2ogr -f SQLite -dsco SPATIALLITE=YES -clipsrc "POLYGON((135.6697726 34.9499443, 135.6697726 35.0450759, 135.8002080 35.0450759, 135.8002080 34.9499443, 135.6697726 34.9499443))" openstreet.sqlite openstreet.osm multipolygons -skipfailures -overwrite -lco ENCODING=UTF-8
# check what's there..
ogrinfo -so -al openstreet.sqlite

# SQLite - check data & create training labels ----------
# ogrinfo -dialect SQLite -sql "SELECT natural, other_tags FROM multipolygons WHERE natural='water' OR other_tags LIKE '%waterway%'" openstreet.sqlite
# ogr2ogr -f SQLite -dsco SPATIALITE=YES -dialect SQLite -sql "SELECT natural, other_tags FROM multipolygons WHERE natural='water' OR other_tags LIKE '%waterway%'" temp.sqlite openstreet.sqlite -nln water2 
# although ogrinfo and ogr2ogr can access spatialite db (see above examples), 
# doing things directly in sqlite works better when it comes to manipulating. 
# Besides, SQL scripts are easy to run
# also note that I couldn't "-update" tables with ogr2ogr with SQLite dialect, something is wrong with ogr2ogr with -update option...
# -------------------------------------------------------
# let's work on a copy of the openstreet DB
cp openstreet.sqlite training.sqlite

# run the SQL script
sqlite3 training.sqlite < createTable.sql

# -------------------------------------------------------
# continue on training data creation
# extract multispectral image values using the training labels
# and then try SVM classification -
# -------------------------------------------------------
pkextract -i landsat8toafall_cf5.tif -s training.sqlite -r median -polygon -srcnodata 0 -bndnodata 0 -t 50 -f SQLite -o training_features.sqlite

# supervised classification with SVM (Support Vector Machine)
pksvm -i landsat8toafall_cf5.tif -t traing_features.sqalite -nodata 0 -o landsat8toafall_cf5_supervised.tif
