//code from "Open SOurce Geospatial Tools", Chapter 14.3
//compile e.g.:  g++ -o bqa2cloud bqa2cloud.cc -I/usr/include/gdal -lgdal
//optional: sudo cp ./bqa2cloud /usr/bin/ 
//usage e.g.:    ./bqa2cloud LC81100362015271LGN00_BQA.TIF LC81100362015271LGN00_CLD.TIF
//output values: 0=cloud free, 1=cloudy
#include <stdlib.h>
#include <string>
#include <vector>
#include <sstream>
#include <iostream>
#include <fstream>
#include "gdal_priv.h"
#include "cpl_conv.h"
using namespace std;
int main(int argc , char **argv){
	string stlsBQAimageFilename; // input QA band filename
	string stlsCLDimageFilename; // output cloud/cirrus mask
	unsigned short nNoCloud=0;
	unsigned short nCloud=1;
	unsigned short nCirrus=1;
	try {
		ostringstream stlosError;
		stlosError <<"usage: "<<argv[0]<<"[-nocloud <value>][-cloud <value>][-cirrus <value>] <bqa_input> <cloud_output>";
		for(int i=1; i<argc; i++){
			string stlsOption=argv[i];//convert to std::string
			if(stlsOption=="-nocloud"||stlsOption=="--nocloud"){
				nNoCloud=atoi(argv[++i]);
			}
			else if(stlsOption=="-cloud"||stlsOption=="--cloud"){
				nCloud=atoi(argv[++i]);
			}
			else if(stlsOption=="-cirrus"||stlsOption=="--cirrus"){
				nCirrus=atoi(argv[++i]);
			}
			else if(stlsOption=="-h"||stlsOption=="--help")
				throw(stlosError.str());
			else if(stlsOption.find('-')==0){
				cerr<<"Error: unknown option" << stlsOption<<endl;
				throw(stlosError.str());
			}
			else if(stlsBQAimageFilename.empty()){
				stlsBQAimageFilename=argv[i];
			}
			else if(stlsCLDimageFilename.empty()){
				stlsCLDimageFilename=argv[i];
			}
			else
				throw(stlosError.str());
			}
			if(stlsBQAimageFilename.empty()){
				cerr<<"Error: no BQA raster file provided"<<endl;
				throw(stlosError.str());
			}
			if(stlsCLDimageFilename.empty()){
				cerr<<"Error: no CLD raster file provided"<<endl;
				throw(stlosError.str());
			}
		}
		catch(string stlsError){
			cerr << stlsError << endl;
			exit(1);
		}	
		//create the input and output datasets here...
		
		//register all drivers
		GDALAllRegister();

		//open BQA dataset in read only mode
		GDALDataset *poBQAdataset;
		poBQAdataset=(GDALDataset *)GDALOpen(stlsBQAimageFilename.c_str(), GA_ReadOnly);

		//create a new dataset for the cloud mask in Create Copy mode
		GDALDriver *poDriver;
		poDriver=GetGDALDriverManager() -> GetDriverByName("GTiff");
		GDALDataset *poCLDdataset;

		//define some extra create options
		char **papszOptions=NULL;
		papszOptions=CSLSetNameValue(papszOptions, "TILED", "YES");
		papszOptions=CSLSetNameValue(papszOptions, "COMPRESS", "LZW");
		GDALProgressFunc pfnProgress=GDALTermProgress;
		float fprogress=0;
		const char * pszMessage;
		void* pProgressArg=NULL;
		pfnProgress(fprogress, pszMessage, pProgressArg);

		//create a copy of the source dataset
		poCLDdataset=poDriver->CreateCopy(stlsCLDimageFilename.c_str(), poBQAdataset, FALSE, papszOptions, NULL, NULL);

		//process datasets here...
		
		//buffer from type STL vector for reading and writing an entire line of our dataset
		vector<unsigned short>
		stlvLineBuffer(poBQAdataset->GetRasterXSize());
		GDALRasterBand *poBQAband;                //input band to read
		poBQAband=poBQAdataset->GetRasterBand(1); //GDAL uses 1 based index
		GDALRasterBand *poCLDband;                //output band to write
		poCLDband=poCLDdataset->GetRasterBand(1); //GDAL uses 1 based index
		//process line per line
		for(int irow=0; irow<poBQAdataset->GetRasterYSize(); ++irow){
			//read entire line instlvLineBuffer buffer
			poBQAband->RasterIO(GF_Read, 0, irow, stlvLineBuffer.size(), 1, &(stlvLineBuffer[0]), stlvLineBuffer.size(), 1, GDT_UInt16, 0, 0);
			//process per pixel
			bool bCloud=false;
			bool bCirrus=false;
			short nconfidenceBits=0;
			for(int icol=0;icol<poBQAdataset->GetRasterXSize();++icol){
				//interpret cloud mask here
				
				//check for cloud: retrieve bits 14--15 from QA band
				nconfidenceBits=(stlvLineBuffer[icol]>>14)&3;
				//check for cloud
				switch(nconfidenceBits){
					case(0): //00 undetermined
					case(1): //01 cloud low confidence
						bCloud=false;
						break;
					case(2): //10 cloud medium confidence
					case(3): //11 cloud high confidence
						bCloud=true;
						break;
				}
				if(bCloud){
					stlvLineBuffer[icol]=nCloud;
					continue; //next pixel
				}
				else{ //check for cirrus: retrieve bits 12--13 from QA band
					nconfidenceBits=(stlvLineBuffer[icol]>>12)&3;
					switch(nconfidenceBits){
						case(0): //00 undetermined
						case(1): //01 cirrus low confidence
							bCirrus=false;
							break;
						case(2): //10 cirrus medium confidence
						case(3): //11 cirrus high confidence
							bCirrus=true;
							break;
					}
					if(bCirrus){
						stlvLineBuffer[icol]=nCirrus;
						continue; //nextpixel
					}
					else
						stlvLineBuffer[icol]=nNoCloud;
				}
			}
			//write buffer stlvLineBuffer to output file
			poCLDband->RasterIO(GF_Write, 0, irow, stlvLineBuffer.size(), 1, &(stlvLineBuffer[0]), stlvLineBuffer.size(), 1, GDT_UInt16, 0, 0);
			//advance progress bar
			fprogress=static_cast<float>(irow+1)/poBQAdataset->GetRasterYSize();
			pfnProgress(fprogress, pszMessage, pProgressArg);
		}
		
		//clean up
		CSLDestroy(papszOptions);

		//close the datasets
		GDALClose((GDALDataset*)poBQAdataset);
		GDALClose((GDALDataset*)poCLDdataset);
		
		return 0;
}
