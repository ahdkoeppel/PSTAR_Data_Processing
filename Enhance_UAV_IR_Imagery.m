%% Code for Geo-aligning FLIR Duo/Vue Pro rjpg images with DJI VIS images ... 
% and converting raw thermal data to temperatures (C) using adjustable observation/atmospheric variables
% Ari Koeppel - 2021-2023
% Requires exiftool.exe to be installed on system
clear
close all;

%% Import Data
FLIRDir = uigetdir('X:\common\FIELD_CAMPAIGNS\WoodhouseMesa_Sept2022\UAV\IR\','Directory of raw FLIR .tiffs');%gets directory
FLIRFiles = dir(fullfile(FLIRDir,'*TempC_FFC.tiff'));%gets all files dir(fullfile(FLIRDir,'*TempC_Destriped.tiff'))

%% Destripe rows
for k = 1:length(FLIRFiles)
    fullFileName = fullfile(FLIRDir, FLIRFiles(k).name);
    newfilename = [fullFileName(1:end-5),'_WNR',fullFileName(end-4:end)];
    status = copyfile(fullFileName,newfilename,'f');
    t = Tiff(newfilename,'r+');
    RAW = read(t);
    T_File = wiener2(RAW, [5 5]); %Wiener filter
    setTag(t,'BitsPerSample',32); %An internal note to program to treat data as 32 Bit float rather than uint16 -not actually written to file
    setTag(t,'SampleFormat',Tiff.SampleFormat.IEEEFP); %An internal note to program to treat data as ~float rather than uint16 -not actually written to file
    write(t,single(T_File));
    close(t);
end

% PSF = fspecial('gaussian',5,5);
% bld = deconvblind(RAW, PSF);
% wnr2 = wiener2(bld, [5 5]);
