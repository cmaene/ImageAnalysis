% change the input tar file name here
input = 'F101993.v4.tar'

% untar file
% v4 composite tar file structure is
% untarfile = 
% {
%   [1,1] = F101993.v4b_web.avg_vis.tfw
%   [2,1] = F101993.v4b_web.avg_vis.tif.gz
%   [3,1] = F101993.v4b_web.cf_cvg.tfw
%   [4,1] = F101993.v4b_web.cf_cvg.tif.gz
%   [5,1] = F101993.v4b_web.stable_lights.avg_vis.tfw
%   [6,1] = F101993.v4b_web.stable_lights.avg_vis.tif.gz
%   [7,1] = README_V4.txt
% }
untarfile= untar(input){[6,1]}

% ungz file
% gz file structure
% ungzfile = 
% {
%   [1,1] = /mnt/ide0/home/cmaene/ThomasCovert/F101993.v4b_web.stable_lights.avg_vis.tif
% }
ungzfile = gunzip(untarfile){[1,1]}

% read the file
tiff=imread(ungzfile);

% clip the file based on a country extent
% India: latitude range 8N-36N (4680-8040) and longitude range 68E-98E (29760-33360) 
% clipped=tiff(4680:8040,29760:33360);
% Mexico: latitude range 33N-14N (5040-7320) and longitude range 118W-86W (7440-11280)
% clipped=tiff(5040:7320,7440:11280);

%%%%%% Change the following based on the country extent (see above).
clipped=tiff(5040:7320,7440:11280);

image(clipped);

% save as TIFF file
imwrite(clipped,[input,'_clip.tif']);

% save as CSV file
csvwrite([input,'_clip.csv'],clipped);
