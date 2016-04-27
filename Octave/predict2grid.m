cd tools

% fread wouldn't load all values.. use dlmread instead
%fid=fopen('libsvm_satellite.predict','r')
%vec=fread(fid);

arg_list = argv ();
fname = arg_list{1};
nrow = str2num(arg_list{2});
ncol = str2num(arg_list{3});

vec=dlmread(fname);
length(vec)
length(unique(vec))
unv=unique(vec);
% unique value occurrences:
a=[unv histc(vec,unv)]

max(vec)
grid=reshape(vec,ncol,nrow);
size(grid)
% flip and rotate the grid
grid=rot90(grid(:,end:-1:1));
size(grid)
grid=uint8(grid);
class(grid)
%grid(10:20,30:40)
cd ../

% save as tif
% imwrite(grid,[fname,'_predicted.tif'],'tif');
imwrite(grid,[fname,'_predicted.tif'],'tif');

% save as CSV file
csvwrite([fname,'_predicted.csv'],grid);

