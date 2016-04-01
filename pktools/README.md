### pktools
pktools is a set of handy tools, system utilities written in C++, for manipulating and analyzing satellite/spectral images. Works like GDAL utilities - pktools rely on GDAL too!

####Steps: (as described in pktools.sh)
* pktools/pkextract:         extract multispectral imagery values at sample locations - note: input is seasonal..
* R:                 visualize spectral profiles by season (script: plotSpectral.R & output: spectral_by_season.png)
* Bash:              download and process training "base" data from OpenStreetMap.
* SQLite/Spatialite: create training labels (script: createTraining.sql)
* pktools/pkextract:         extract multispectral imagery values with the training data
* pktools/pksvm:             create a supervised model and applied to the input imagery (fall) image.. (example: supervised_xx.png)

####References:
[pktools home page](http://pktools.nongnu.org/html/index.html)

[Open Source Geospatial Tools: Applications in Earth Observation](http://www.springer.com/us/book/9783319018232) : Book by authors of pktools, Daniel Mclnerney & Pieter Kempeneers. See chapter 12, "Pktools".
