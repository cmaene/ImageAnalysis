#/usr/bin/ocatave

%% initialization
clear; close all;

%% add path to additional packages/scripts
% addpath("~/Downloads/octave/mapping-1.2.1/inst")
% help gdalread
% help rasterread
% help rad2deg
% [stat,info,bands]=gdalread('landsat8toafall_cf5.tif')
% bands.min

%% read landsat8 (r:353xc:484)
% tif=imread('landsat8toafall_cf5.tif');
% size(tif)

% fid=fopen([landsat8toafall_cf5_temp.tif],'r')
% b$i=fread(fid,[$nrow,$ncol],pxtype);

%% ============ Prepare data from multi-band images ============
%  Run gdal_translate to create individual band images

arg_list = argv ();
ntotal = str2num(arg_list{1});
ntrain=int16(floor(ntotal/3*2)); %split into 2/3 and 1/3
ntest=ntrain+1;

fprintf('upload data ...\n')
%%data = load('traininglabel.csv') %%need to skip header

cd temp
fid=fopen(['landsat8toa_b1.bil'],'r');
landsat8=fread(fid,'float32');
landsat8(landsat8==0)=NaN; % define NaN/nodata
size(landsat8)
for i=2:9
    fname=["landsat8toa_b" num2str(i) ".bil"];
    fid=fopen(fname,'r');
	newband=fread(fid,'float32');
	newband(newband==0)=NaN; % define NaN/nodata
	landsat8=[landsat8,newband];
end
# row, col
size(landsat8)

cd ../
save "landsat8.mat" landsat8 -binary;

% show what's in the workspace
whos

%% Setup the parameters you will use for this part of the exercise


%% training data (926 x 11 bands, plus 1 label) - minus b10/11
traindata=dlmread('traininglabel.csv',",");
[obs,input_layer_size]=size(traindata);
% input_layer_size = 11 bands - minus b10/11
num_labels = length(unique(traindata(:,1))); % 6 labels, from 1 to 6  
X=traindata(:,2:10);
y=traindata(:,1);

%% preparation for LIBSVM
%% http://www.csie.ntu.edu.tw/~cjlin/libsvm/faq.html#/Q03:_Data_preparation
addpath("~/Downloads/libsvm/libsvm-3.21/matlab")
% randomize data before spliting
[N,M]=size(traindata); 
traindata_rsort=traindata(randperm(N),:);

% convert to sparse data set
labels = traindata_rsort(:, 1); % labels from the 1st column
%features = traindata_rsort(:, 2:end); 
features = traindata_rsort(:, 2:end-2); 
features_sparse = sparse(features); % features must be in a sparse matrix
% train = 2/3 of all training data - give more for training
train_label=labels(1:ntrain,:);
train_data=features_sparse(1:ntrain,:);
libsvmwrite('libsvm_train', train_label, train_data);
% test = rest of 1/3 for validation
test_label=labels(ntest:ntotal,:);
test_data=features_sparse(ntest:ntotal,:);
libsvmwrite('libsvm_test', test_label, test_data);

%% test data, which includes "testdata"
load('landsat8.mat');
[N2,M2]=size(landsat8);
landsat8_label=zeros(N2,1);
landsat8_sparse = sparse(landsat8); % features must be in a sparse matrix
% NaN are recorded as "nan" in the output
libsvmwrite('libsvm_satellite', landsat8_label, landsat8_sparse);

