%% Code for Reading in and Converting FLIR duo Pro tiff images to temperatures
% Ari Koeppel - 2019
clear
close all;
%What this code does:
% 1) make a copy of the .tif file
% 2) open the copy using the tiff class and the 'r+' option:
% 4) Convert number to temperature in C
% 5) write() the new image, producing new file with _TempC suffix
% 6) close tiff;
%% Import Data
%First place all your images of interest in a single folder.
FLIRDir = uigetdir('~','Directory of raw FLIR .tiffs');%gets directory (that folder)
FLIRFiles = dir(fullfile(FLIRDir,'*.tif*')); %gets all files
token = 0;
fprintf(1, 'Now reading files from %s\n', FLIRDir);
tic
for k = 1:length(FLIRFiles)
  fullFileName = fullfile(FLIRDir, FLIRFiles(k).name);
  newfilename = [fullFileName(1:end-5),'_TempC',fullFileName(end-4:end)];
  status = copyfile(fullFileName,newfilename,'f');
  t = Tiff(newfilename,'r+');
  RAW = read(t);
  T_File = 0.04.*double(RAW)-273.15;  %deg C
  setTag(t,'BitsPerSample',32); %An internal note to program to treat data as 32 Bit float rather than uint16 -not actually written to file
  setTag(t,'SampleFormat',Tiff.SampleFormat.IEEEFP); %An internal note to program to treat data as ~float rather than uint16 -not actually written to file
  write(t,single(T_File));
  close(t);
%   info = imfinfo(fullFileName);
%   timestamp = datetime(info.FileModDate);
%   imagesc(imread(newfilename));
%   c = colorbar;
%   colormap('hot');
%   c.Label.String = 'Temp (^{\circ}C)'
%   TEST(k) = T_File(30,30);
end
toc

%% Obtain Flat Field
% It may necessary to calculate and correct for a dynamic flat field
% since the instument temperature changes and affects the flat field
% differently during day and night.
FLIRFiles = dir(fullfile(FLIRDir,'*TempC.tiff')); %gets all files
fullFLIRFileName = fullfile(FLIRDir, FLIRFiles(1).name);
first = imread(fullFLIRFileName);
Flat = zeros(size(first,1),size(first,2),length(FLIRFiles));
FLIR_Data = zeros(size(first,1),size(first,2),length(FLIRFiles));
FLIR_Data_Corr = zeros(size(first,1),size(first,2),length(FLIRFiles));
Center_Temp = zeros(size(FLIRFiles));
Corner = zeros(size(FLIRFiles));

for k = 1:length(FLIRFiles)
  fullFLIRFileName = fullfile(FLIRDir, FLIRFiles(k).name);
  FLIR_Data(:,:,k) = imread(fullFLIRFileName);
  Box_filt = imboxfilt(FLIR_Data(:,:,k),191);
  Center_Temp(k) = mean2(Box_filt(size(FLIR_Data,1)/2-5:size(FLIR_Data,1)/2+5,size(FLIR_Data,2)/2-5:size(FLIR_Data,2)/2+5));
  Corner(k) = mean2(Box_filt(434:492,555:620));
  Flat(:,:,k) = Box_filt-Center_Temp(k);
end

Im_corr_mn = mean(Flat,3);
Center_Im_corr_mn = mean2(Im_corr_mn(size(Im_corr_mn,1)/2-5:size(Im_corr_mn,1)/2+5,size(Im_corr_mn,2)/2-5:size(Im_corr_mn,2)/2+5));
Corner_Im_corr_mn = mean2(Im_corr_mn(434:492,555:620));
Im_corr_md = median(Flat,3);
Center_Im_corr_md = mean2(Im_corr_md(size(Im_corr_md,1)/2-5:size(Im_corr_md,1)/2+5,size(Im_corr_md,2)/2-5:size(Im_corr_md,2)/2+5));
Corner_Im_corr_md = mean2(Im_corr_md(434:492,555:620));
imshowpair(Im_corr_mn,Im_corr_md,'montage');
Ratio = (Corner-Center_Temp)/(Corner_Im_corr_md-Center_Im_corr_md); % Use Ratio for Dynamic

%% Soil spot temps
for k = 1:244
  %FLIR_Data(Y1:Y2,X1:X2,k));
  FLIR_Data_Corr(:,:,k) = FLIR_Data(:,:,k) - Im_corr_mn;%.*Ratio(k);
end