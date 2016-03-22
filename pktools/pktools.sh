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

# we have four landsat8 for each season 
SEASONS=(spring summer fall winter)
for season in "${SEASONS[@]}"
do
	rm wksp/$season'_mean.geojson' # delete previously created .geojson, otherwise error in ogr2ogr/CSV
	rm wksp/$season'_mean.csv' # delete previously created .geojson, otherwise error in ogr2ogr/CSV
	pkextract -i 'landsat8toa'$season'_cf5.tif' -s KyotoSamples.shp -o wksp/$season'_mean.geojson' -f "GeoJSON" -r mean -point
	ogr2ogr -skipfailures -overwrite -f "CSV" wksp/$season'_mean.csv' wksp/$season'_mean.geojson'
done

# -------------------------------------------------------
# Post-wildfire analysis
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
