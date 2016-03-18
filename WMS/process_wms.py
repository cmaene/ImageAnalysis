#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
incomplete routines:
- download image from WMS
- add world file to the downloaded image
- classify to extract particular info
- vectorize the binary classified image
"""
import os,sys,math
from owslib.wms import WebMapService

def write_worldfile(iname,psize,xulcoord,yulcoord,yrotation=0.0,xrotation=0.0):
    '''
    https://en.wikipedia.org/wiki/World_file
    psize:   pixel X size
    yrotation: rotation about the Y axis (usually 0.0)
    xrotation: rotation about the X axis (usually 0.0)
    0-psize: inverted/negative pixel Y size
    xulcoord:  X coordinate of upper left pixel center
    yulcoord:  Y coordinate of upper left pixel center
    '''
    # the template. where data from the csv will be formatted to geojson
    info = str(psize)+"\n"+str(yrotation)+"\n"+str(xrotation)+"\n"+str(0-psize)+"\n"+str(xulcoord)+"\n"+str(yulcoord)
    # opens an text file to write the output to
    if iname.strip().split('.')[1]=="png":
        oname=iname.strip().split('.')[0]+".pgw"
    elif iname.strip().split('.')[1]=="jpg":
        oname=iname.strip().split('.')[0]+".jgw"    
    elif iname.strip().split('.')[1]=="tif":
        oname=iname.strip().split('.')[0]+".tfw"    
    outFileHandle = open(oname, "w")
    outFileHandle.write(info)
    outFileHandle.close()
        
def write_vrt4point(iname,lon="x",lat="y"):
    # the template. where input will be formatted to vrt
    template = \
        '''\
<OGRVRTDataSource>
    <OGRVRTLayer name="%s">
        <SrcDataSource>./%s</SrcDataSource>
        <GeometryType>wkbPoint</GeometryType>
        <LayerSRS>WGS84</LayerSRS>
        <GeometryField encoding="PointFromColumns" x="%s" y="%s"/>
    </OGRVRTLayer>
</OGRVRTDataSource>
        '''
    fname = iname.strip().split('.')[0]
    oname = fname+".vrt"
    output = template % (fname,iname,lon,lat)
    # opens an text file to write the output to
    outFileHandle = open(oname, "w")
    outFileHandle.write(output)
    outFileHandle.close()

if __name__ == '__main__':

    wms = WebMapService('http://bhuvan5.nrsc.gov.in/bhuvan/wms')
    '''
    # learn on WMS services  
    print(wms.identification.type)
    print(wms.identification.version)
    print(wms.identification.title)
    print(wms.identification.abstract)
    print(list(wms.contents))
    print(wms['vector:AS_LULC50K_1112'].title)
    print(wms['vector:AS_LULC50K_1112'].boundingBoxWGS84)
    print(wms['vector:AS_LULC50K_1112'].crsOptions)
    print(wms['vector:AS_LULC50K_1112'].styles)
    '''
    # download WMS image for the study area
    # consider spliting large area - high resolution/large data may end with download failure
    pixsize = 0.0002  # put the desired resolution (in the SRS unit), 0.0002 deg = approx. 20m
    xmax = 93.02335   # put the desired extent - x maximum
    xmin = 92.1496    # put the desired extent - x minimum
    ymax = 26.6149    # put the desired extent - y maximum
    ymin = 25.7929    # put the desired extent - y minimum
    xwidth = math.ceil((xmax-xmin)/pixsize)
    ywidth = math.ceil((ymax-ymin)/pixsize)
    img = wms.getmap(layers=['vector:AS_LULC50K_1112'],
            srs = 'EPSG:4326',
            bbox = (xmin,ymin,xmax,ymax),
            size = (xwidth,ywidth),
            format = 'image/png',
            transparent = False  # true means more bytes
        ) 
    out = open('studyarea.png', 'wb')
    out.write(img.read())
    out.close()

    # write an appropriate world file:
    write_worldfile("studyarea.png",pixsize,xmax,ymax)
    
    # VRT is my typical approach to turn XY data to geospatial 
    write_vrt4point("villages.csv","x","y") 
    # optional: with GDAL/OGR, convert the VRT output from above to geojson & KML
    os.system('ogr2ogr -skipfailures -overwrite -f "GeoJSON" villages.geojson villages.vrt')
    os.system('ogr2ogr -skipfailures -overwrite -f "LIBKML" villages.kml villages.vrt')
	
