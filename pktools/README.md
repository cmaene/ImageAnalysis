## pktools
pktools is a set of handy tools, system utilities written in C++, for manipulating and analyzing satellite/spectral images. Works like GDAL utilities - pktools rely on GDAL too!

###Steps: (as seen in pktools.sh)
* extract multispectral imagery values at sample locations - note: input is seasonal (4 images)
* visualize spectral profiles by season - with R
* download and process training "base" data (openstreet map)
* create training labels - with SQLite/spatialite
* extract multispectral imagery values with the training data
* create a supervised model and applied to the input imagery (fall image) - output: supervised.png

###References:
[pktools home page](http://pktools.nongnu.org/html/index.html)

[Open Source Geospatial Tools: Applications in Earth Observation](http://www.springer.com/us/book/9783319018232) : Book by authors of pktools, Daniel Mclnerney & Pieter Kempeneers. See chapter 12, "Pktools".
