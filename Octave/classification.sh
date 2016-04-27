#!/bin/bash

cd /home/chieko/Documents/ImageAnalysis/Octave

# input is projected to UTM - prep before reprojecting to WGS84
gdalsrsinfo -o wkt landsat8toaUTM.tif > orignalsrs.txt
# add "no data" using the cloud mask
gdal_calc.py -A landsat8toaUTM.tif --A_band=11 --allBands A -B landsat8toa_bqa.tif --outfile=landsat8toaUTM_nocloud.tif --overwrite --calc="A*(B<23552)" --NoDataValue=0 
# reproject to WGS84 (same as training/OSM data)
gdalwarp -s_srs orignalsrs.txt -t_srs '+proj=longlat +ellps=WGS84 +datum=WGS84' landsat8toaUTM_nocloud.tif landsat8toa_nocloud.tif
# tell it again 0=NaN
gdal_translate -a_nodata 0 landsat8toa_nocloud.tif landsat8toa.tif

# -------------------------------------------------------
# SQLite - check data & create training labels 
# -------------------------------------------------------
# let's work on a copy of the openstreet DB & also get one more input shp
cp ../pktools/openstreet.sqlite training.sqlite
cp ../pktools/lines_osm.* ./

# run the SQL script
sqlite3 training.sqlite < createTraining.sql

# extract multispectral image values using the training labels
rm training_features.sqlite
pkextract -i landsat8toa.tif -s training.sqlite -r median -polygon -srcnodata 0 -bndnodata 0 -t 100 -f SQLite -o training_features.sqlite

# extract and format the training label data from sqlite DB, output: traininglabel.csv
sqlite3 training_features.sqlite < db2Labeldata.sql 

# how many lines/cases in the training feature (no header included)
num_trainingcases=`wc -l traininglabel.csv`

# reading raster data is tricky, as Octave doesn't read most raster formats
# one way is to use "gdal_translate" to turn it into ESRI BIL format that comes with header file

mkdir temp
# run to extract the first band
gdal_translate -of EHdr -quiet landsat8toa.tif temp/landsat8toa_b1.bil

# get the info from the header
nbands=`cat temp/landsat8toa_b1.hdr | grep 'NBANDS' | awk '{print $2}'`
nrow=`cat temp/landsat8toa_b1.hdr | grep 'NROWS' | awk '{print $2}'`
ncol=`cat temp/landsat8toa_b1.hdr | grep 'NCOLS' | awk '{print $2}'`
pxtype=`cat temp/landsat8toa_b1.hdr | grep 'PIXELTYPE' | awk '{print $2}'`

# repeat for all bands, one band only for each
for i in `seq 1 $nbands`; do
    gdal_translate -b $i -of EHdr -quiet landsat8toa.tif temp/landsat8toa_b$i.bil
done

# use octave to prepare data for LIBSVM/Support Vector Machine classification analysis
octave preparedata.m $num_trainingcases

mv libsvm_train tools/libsvm_train
mv libsvm_test tools/libsvm_test
mv libsvm_satellite tools/libsvm_satellite
cd tools

# easy.py creates scaled data and select best model
# python easy.py libsvm_train libsvm_test
# or do the following
../svm-scale -l -1 -u 1 -s range libsvm_train > libsvm_train.scale
../svm-scale -r range libsvm_test > libsvm_test.scale
../svm-scale -r range libsvm_satellite > libsvm_satellite.scale
python grid.py libsvm_train.scale > grid_train.txt
bestc=`awk 'END{print $1}' grid_train.txt`
bestg=`awk 'END{print $2}' grid_train.txt`
echo "best C/cost is: " $bestc
echo "best Gausian Kernel is: " $bestg
../svm-train -c $bestc -g $bestg libsvm_train.scale
../svm-predict libsvm_test.scale libsvm_train.scale.model libsvm_test.predict
../svm-predict libsvm_satellite.scale libsvm_train.scale.model libsvm_satellite.predict
# run again without scalling data
# python grid.py libsvm_train  > grid_train.txt
# bestc=`awk 'END{print $1}' grid_train.txt`
# bestg=`awk 'END{print $2}' grid_train.txt`
# echo "best C/cost is: " $bestc
# echo "best Gausian Kernel is: " $bestg
# read -p "Press [Enter] key to resume..."
# ../svm-train -c $bestc -g $bestg libsvm_train
# ../svm-predict libsvm_test libsvm_train.model libsvm_test.predict
# ../svm-predict libsvm_satellite libsvm_train.model libsvm_satellite.predict2

cd ../
# run another octave script - output 1 band tif: //input//_predicted.tif
octave predict2grid.m libsvm_satellite.predict $nrow $ncol

# -------------------------------------------------------
# what a pain to add the cloud mask back again, but it needs to be done..
# -------------------------------------------------------
# reproject to WGS84 (same as training/OSM data)
gdalwarp -s_srs orignalsrs.txt -t_srs '+proj=longlat +ellps=WGS84 +datum=WGS84' landsat8toa_bqa.tif landsat8toa_bqaWGS84.tif
# replace values with 0(="no data") using the cloud mask
gdal_calc.py -A libsvm_satellite.predict_predicted.tif --A_band=1 --allBands A -B landsat8toa_bqaWGS84.tif --outfile=temp.tif --overwrite --calc="A*(B<23552)" --NoDataValue=0 

# -------------------------------------------------------
# add color-relief to the 1-band tif using gdaldem
# ref: http://www.gdal.org/gdaldem.html#gdaldem_color_relief
# -------------------------------------------------------
rm colormap.txt
touch colormap.txt # create a text file with value-color list
colors=(black blue green yellow gray orange red brown)
cnt=0
for c in ${colors[@]}; do
    colmap=`echo $cnt $c`
    echo $colmap >> colormap.txt
    let cnt=cnt+1
done
# apply gdaldem color-relief
gdaldem color-relief temp.tif colormap.txt libsvm_satellite_predicted.tif

# -------------------------------------------------------
# assign georeference info 
# -------------------------------------------------------
# copy the projection info first
gdalsrsinfo -o wkt landsat8toa.tif > srsinfo.txt
gdal_translate -a_srs srsinfo.txt libsvm_satellite_predicted.tif libsvm_satellite_predicted_georef.tif 
# copy input's corner coordinates and apply with gdal_edit.py
gdalinfo landsat8toa.tif>gdalinfo.txt
ulx=`cat gdalinfo.txt | grep "Upper Left" | awk '{print $4}' | sed 's/,//g'`
uly=`cat gdalinfo.txt | grep "Upper Left" | awk '{print $5}' | sed 's/)//g'`
lrx=`cat gdalinfo.txt | grep "Lower Right" | awk '{print $4}' | sed 's/,//g'`
lry=`cat gdalinfo.txt | grep "Lower Right" | awk '{print $5}' | sed 's/)//g'`
gdal_edit.py -a_ullr $ulx $uly $lrx $lry libsvm_satellite_predicted_georef.tif

# saving as github friendly PNG format for displaying only
gdal_translate -of "PNG" libsvm_satellite_predicted.tif output_example.png
