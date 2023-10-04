%% Code for Geo-aligning FLIR Duo/Vue Pro rjpg images with DJI VIS images ... 
% and converting raw thermal data to temperatures (C) using adjustable observation/atmospheric variables
% Ari Koeppel - 2021
% Requires exiftool.exe to be installed on system
% Best practice to make copies of all files before running as exiftools
% modifies files
clear
close all;

%% Import Data
%FLIR Data
FLIRDir = uigetdir('X:\common\FIELD_CAMPAIGNS\','Directory of raw FLIR .RJPGs');%gets directory
FLIRFiles = dir(fullfile(FLIRDir,'*.jpg')); %gets all files
%DJI Vis Data
DJIDir = uigetdir('X:\common\FIELD_CAMPAIGNS\WoodhouseMesa_Sept2022\UAV\VIS\','Directory of raw DJI .jpgs');
DJIFiles = dir(fullfile(DJIDir,'*.jpg'));
fprintf(1, 'Now reading files from %s and %s\n', FLIRDir, DJIDir);
%Logger Data
[LoggerDataFile, Loggerfilepath] = uigetfile('X:\common\FIELD_CAMPAIGNS\WoodhouseMesa_Sept2022\GroundStation\Logger\','AllData Logger File');
LoggerDataFile = fullfile(Loggerfilepath,LoggerDataFile);
Data = struct2cell(load(LoggerDataFile));
Data = Data{:,:};
%% Geoalign FLIR images to DJI images
gpx_out = [FLIRDir,'\DJI_GPSTrack.gpx'];
exif = which('exiftool.exe');
if isempty(exif)
    error('exiftool.exe not found in path')
end
%Make sure gpx.fmt file exits
temp1=['"' exif '" -fileOrder DateTimeOriginal -p gpx.fmt "',DJIDir,'" > "',gpx_out,'"'];
[status1, log1] = system(temp1);
%Change the geosync time to reflect the local GMT offset of the cameras -07:00:00
%in Flagstaff, but camera internal times can get messed up, so if this step isn't working change the value in the line of code below
temp2=['"' exif '" -geosync=-07:00:00 -geotag "',gpx_out,'" "',FLIRDir,'"'];
[status2, log2] = system(temp2);

%At this point the updated geotagged IR images retain the filename, while the uneditted files are given a _original suffix
%If needed you can use this linux code to remove the _original from the original files
%for filename in ./*; do mv "./$filename" "./$(echo "$filename" | sed -e 's/_original//g')";  done

%% Convert R.JPGs to tiffs with temperature
FLIRFiles = dir(fullfile(FLIRDir,'*.jpg')); %gets all files
exif = which('exiftool.exe');
for k = 1:length(FLIRFiles)
    alignedFileName = fullfile(FLIRDir, FLIRFiles(k).name);
    raw_thermal = [alignedFileName(1:end-4),'_RawThermal.tiff'];
    %Extract raw thermal data to file with _RawThermal.tiff suffix and metadata calibration parameters to FLIR_meta.csv
    temp3 = ['"' exif '" -rawthermalimage -b -w %0f"',raw_thermal,'" -q -execute -csv "-planck*" -emissivity -objectdistance -IRWindowTemperature -IRWindowTransmission "-*reflect*" "-*humidity" "-atmospheric*" -rawthermalimagetype "-date*" -common_args ',alignedFileName,' > ',FLIRDir,'\FLIR_meta.csv'];
    [~,~] = system(temp3);
    tbl = readtable([FLIRDir,'\FLIR_meta.csv']);
    %Get FLIR timestamp
    FLIR_Time= datetime(FLIRFiles(k).name(1:15),'InputFormat','yyyyMMdd_HHmmss');
    %Find closest Logger Data timestamp
    WT = withtol(FLIR_Time,seconds(30));
    TEMPdata = Data(WT,:);
    % Use RH value from logger for calibration
    tbl.RelativeHumidity = mean(TEMPdata.RH,'omitnan'); 
    % Use Air Temp value from logger for calibration
    tbl.AtmosphericTemperature = mean(TEMPdata.AirTC,'omitnan'); 
    %Input UAV flight height below:
    tbl.ObjectDistance = "17.50 m"; %(Black Point: 25-40 m, Hunt's 15-30 m, Baby Eskers: 95 m, Glacer Margin 25-35m, Woodhouse2022 10-25m)
    thermal_C = [raw_thermal(1:end-16),'_TempC',raw_thermal(end-4:end)];
    status = copyfile(raw_thermal,thermal_C,'f');
    t = Tiff(thermal_C,'r+');
    RAW = single(read(t));
    %Run Calibration function and save calibrated output to file with _TempC.tiff suffix
    T_Calibrated = Thermal_Calibration(RAW,tbl);
    setTag(t,'BitsPerSample',32); %An internal note to program to treat data as 32 Bit float rather than uint16 -not actually written to file
    setTag(t,'SampleFormat',Tiff.SampleFormat.IEEEFP); %An internal note to program to treat data as ~float rather than uint16 -not actually written to file
    write(t,single(T_Calibrated));
    close(t);
    %Add metadata from original image file and geotags to calibrated file
    temp4=['"' exif '" -TagsFromFile "',alignedFileName,'" -exif:all -XMP:all "',thermal_C,'"'];
    [~,~] = system(temp4);
    %The following code can be used to visualize the images (do not include in loop)
%   imagesc(imread(thermal_C));
%   c = colorbar;
%   colormap('hot');
%   c.Label.String = 'Temp (^{\circ}C)'
end
%The following line can be used to delete the _original suffixed files
%delete(fullfile(FLIRDir,'*_original'))

%% Destripe rows
% Some data has row striping instrument artifacts. I haven't perfected a 
% technique for dealing with all cases, but here is a starting place that 
% calculates the row by row mean and moving mean and subtracts the difference from the original row
% Section generates corrected images changing suffix to _Destriped.tiff
FLIRFiles = dir(fullfile(FLIRDir,'*_TempC.tiff')); %gets all files
for k = 1:length(FLIRFiles)
    FileName = fullfile(FLIRDir, FLIRFiles(k).name);
    destripe = [FileName(1:end-5),'_Destriped.tiff'];
    status = copyfile(FileName,destripe,'f');
    t = Tiff(destripe,'r+');
    RAW = single(read(t));
    DS = zeros(size(RAW));
    xavg = mean(RAW,2);
    %The window size (in pixels) is important and should be at least a few times as large as the typical striping artifact.
    windowSize = 31; 
    conv = movmean(xavg,windowSize,'omitnan');
    for i = 1:size(RAW,1)
        DS(i,:) = RAW(i,:) - (xavg(i)-conv(i));
%         %There has been an issue with this code adding stripes as a result of large temperature deviations that are real.
%         %One solution might be to ignore values above or below a certain threthold when calculating the row mean and moving mean
    end
    write(t,single(DS));
    close(t);
end

%% Obtain Flat Field
% The IR data hosts a vignetting pattern. This section calculates and corrects for a static flat field
% which is suffiecient for UAV flights where the instrument temperature changes little throughout
% flight. If the instrument temperature is changing, a dynamic flatfield that considers the ratio between center and edge could be used
FLIRFiles = dir(fullfile(FLIRDir,'*TempC.tiff'));%gets all files dir(fullfile(FLIRDir,'*TempC_Destriped.tiff'))
Center_Temp = zeros(size(FLIRFiles));
fullFLIRFileName = fullfile(FLIRDir, FLIRFiles(1).name);
first = imread(fullFLIRFileName);
Flat = zeros(size(first,1),size(first,2),length(FLIRFiles));
fprintf(1, 'Now reading files from %s\n', FLIRDir);
%When dealing with a lot of data, this could take a while
for k = 1:length(FLIRFiles)
  fullFileName = fullfile(FLIRDir, FLIRFiles(k).name);
  RAW = imread(fullFileName);
  %Use a large box filter
  Box_filt = imboxfilt(RAW,191);
  %Calculate the mean of a 10x10 pixel region at image center
  Center_Temp(k) = mean2(Box_filt(size(Box_filt,1)/2-5:size(Box_filt,1)/2+5,size(Box_filt,2)/2-5:size(Box_filt,2)/2+5));
  Flat(:,:,k) = Box_filt-Center_Temp(k);
end
%Calculate the mean of all box filtered flat fields
Im_corr_mn = mean(Flat,3);

%% Correct Flat Field
%Section uses the generated flat field to correct images changing suffix to _FFC.tiff
for k = 1:length(FLIRFiles)
    fullFileName = fullfile(FLIRDir, FLIRFiles(k).name);
    newfilename = [fullFileName(1:end-5),'_FFC',fullFileName(end-4:end)];
    status = copyfile(fullFileName,newfilename,'f');
    t = Tiff(newfilename,'r+');
    RAW = read(t);
    T_File = RAW - Im_corr_mn;
    setTag(t,'BitsPerSample',32); %An internal note to program to treat data as 32 Bit float rather than uint16 -not actually written to file
    setTag(t,'SampleFormat',Tiff.SampleFormat.IEEEFP); %An internal note to program to treat data as ~float rather than uint16 -not actually written to file
    write(t,single(T_File));
    close(t);
end
%% Functions
function [temp_celcius] = Thermal_Calibration(DATA,tbl)
        %Temperature calibration based on https://github.com/gtatters/Thermimage/blob/master/R/raw2temp.R
        E=tbl.Emissivity;
        OD=sscanf(tbl.ObjectDistance{:}, '%d'); %meters
        RTemp=sscanf(tbl.ReflectedApparentTemperature{:}, '%d');
        ATemp=tbl.AtmosphericTemperature; %sscanf(tbl.AtmosphericTemperature{:}, '%d'); %use logger value
        RH=tbl.RelativeHumidity;%sscanf(tbl.RelativeHumidity{:}, '%d'); %use logger value
        PR1=tbl.PlanckR1;
        PB=tbl.PlanckB;
        PF=tbl.PlanckF;
        PO=tbl.PlanckO;
        PR2=tbl.PlanckR2;

        IRWTemp=sscanf(tbl.IRWindowTemperature{:}, '%d');%FlirImageExtractor.extract_float(meta["IRWindowTemperature"]),
        IRT=tbl.IRWindowTransmission; %should be 1 for no lens/window

        ATA1 = tbl.AtmosphericTransAlpha1;%0.006569;
        ATA2 = tbl.AtmosphericTransAlpha2;%0.01262;
        ATB1 = tbl.AtmosphericTransBeta1;%-0.002276;
        ATB2 = tbl.AtmosphericTransBeta2;%-0.00667;
        ATX = tbl.AtmosphericTransX;%1.9;

% transmission through window (calibrated)
        emiss_wind = 1 - IRT;
        refl_wind = 0;
% transmission through the air
        h2o = (RH/100)*exp(1.5587+0.06939*ATemp-0.00027816*ATemp^2+0.00000068455*ATemp^3);
        tau1 = ATX*exp(-sqrt(OD/2)*(ATA1+ATB1*sqrt(h2o)))+(1-ATX)*exp(...
            -sqrt(OD/2)*(ATA2+ATB2*sqrt(h2o)));
        tau2 = ATX*exp(-sqrt(OD/2)*(ATA1+ATB1*sqrt(h2o)))+(1-ATX)*exp(...
            -sqrt(OD/2)*(ATA2+ATB2*sqrt(h2o)));
% 
% %         # radiance from the environment
        raw_refl1 = PR1 / (PR2 * (exp(PB / (RTemp + 273.15)) - PF)) - PO;
        raw_refl1_attn = (1 - E) / E * raw_refl1;
        raw_atm1 = PR1 / (PR2 * (exp(PB / (ATemp + 273.15)) - PF)) - PO;
        raw_atm1_attn = (1 - tau1) / E / tau1 * raw_atm1;
        raw_wind = PR1 / (PR2 * (exp(PB / (IRWTemp + 273.15)) - PF)) -PO;
        raw_wind_attn = emiss_wind / E / tau1 / IRT * raw_wind;
        raw_refl2 = PR1 / (PR2 * (exp(PB / (RTemp + 273.15)) - PF)) -PO;
        raw_refl2_attn = refl_wind / E / tau1 / IRT * raw_refl2;
        raw_atm2 = PR1 / (PR2 * (exp(PB / (ATemp + 273.15)) - PF)) - PO;
        raw_atm2_attn = (1 - tau2) / E / tau1 / IRT / tau2 * raw_atm2;


        raw_obj = (DATA./E./tau1./IRT./tau2-raw_atm1_attn-raw_atm2_attn-raw_refl1_attn-raw_wind_attn-raw_refl2_attn);

%  temperature from radiance
        temp_celcius = PB./log(PR1./(PR2.*(raw_obj+PO))+PF)-273.15;
end