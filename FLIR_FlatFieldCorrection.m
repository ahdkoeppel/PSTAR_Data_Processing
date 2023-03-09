%% Code for Reading in and Correcting Vignetting in FLIR Images
% Ari Koeppel - 2021
clear
close all;

%% Import Data
FLIRDir = uigetdir('X:\common\FIELD_CAMPAIGNS\Mojave_Oct2021\Pahrump_Playa\UAVs\Mosaicking\Phantom\FLIR','Directory of Temperature_Corrected FLIR .tiffs');%gets directory
FLIRFiles = dir(fullfile(FLIRDir,'*TempC.tiff')); %gets all files
fullFLIRFileName = fullfile(FLIRDir, FLIRFiles(1).name);
first = imread(fullFLIRFileName);
Corner = zeros(size(FLIRFiles));
Center_Temp = zeros(size(FLIRFiles));
Flat = zeros(size(first,1),size(first,2),length(FLIRFiles));
fprintf(1, 'Now reading files from %s\n', FLIRDir);


%% Obtain Flat Field
% Calculating and correcting for a static flat field is suffiecient for UAV
% flights where the instrument temperature changes little throughout
% flight
for k = 1:length(FLIRFiles)
  fullFLIRFileName = fullfile(FLIRDir, FLIRFiles(k).name);
  FLIR_Data = imread(fullFLIRFileName);
  %imagesc(FLIR_Data)
  Box_filt = imboxfilt(FLIR_Data,191);
  Center_Temp(k) = mean2(Box_filt(size(Box_filt,1)/2-5:size(Box_filt,1)/2+5,size(Box_filt,2)/2-5:size(Box_filt,2)/2+5));
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
%Calculate how intensly the flat field applies to each image 
Ratio = (Corner-Center_Temp)./(Corner_Im_corr_md-Center_Im_corr_md);

%% Correct Flat Field
for k = 1:length(FLIRFiles)
    fullFileName = fullfile(FLIRDir, FLIRFiles(k).name);
    newfilename = [fullFileName(1:end-5),'_FFC',fullFileName(end-4:end)];
    status = copyfile(fullFileName,newfilename,'f');
    t = Tiff(newfilename,'r+');
    FLIR_Data = read(t);
    T_File = FLIR_Data - Im_corr_md*Ratio(k);
    setTag(t,'BitsPerSample',32); %An internal note to program to treat data as 32 Bit float rather than uint16 -not actually written to file
    setTag(t,'SampleFormat',Tiff.SampleFormat.IEEEFP); %An internal note to program to treat data as ~float rather than uint16 -not actually written to file
    write(t,single(T_File));
    close(t);
end