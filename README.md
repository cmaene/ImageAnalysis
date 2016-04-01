## ImageAnalysis
All files related to image analysis using geospatial imagery, or remotely sensed images such as satellite images and aerial photographs. Since images take a simple structure (matrices/matrix tables), they are generally easier to analyze and we have so many options for applications to analyze them!

#### pktools
There are many software applications to conduct remote sensing image analysis but I was intrigued by this open source software.. They are written in C (I think) and thus work fast! Once tricky installation part is done, it's good to go.. I summarized the basic analysis steps in bash script (in Linux/Ubuntu but the same can be done in Mac and Windows with their terminal/command windows) which use not only pktools but also other helpful tools to obtain and process input data (bash, GDAL/OGR, R, SQLite/Spatialite.) For more comprehensive analyses, please consult the book in the references area..

#### Octave
Open source version of MATLAB is how I understand the software (without extensive tool sets) - since images are simply matrices, it makes sense to use matrix-based statisistical analysis software like MATLAB/Octave.. The problem is, though, Octave doesn't come with input conversion components, so processing geospatial images (images/matrix data with spatial reference system information, projection, location/XY) to work in Octave isn't easy.. Perhaps, time for MATLAB? Still, for classification analysis, I think Octave does a great job. I will add more on this later.

#### WMS
Not exactly about analysis per se, but I am adding this section to help users understand how WMS (web map services) and it's siblings (WMTS, WFS) work. To make geospatial images obtained through web services work in spatial analsysis applications, we need to master certain tricks. I can't cover them all but here is what I would do to obtain and process WMS images.
