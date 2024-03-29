%% Code for Geo-aligning FLIR Duo/Vue Pro rjpg images with DJI VIS images ... 
% and converting raw thermal data to temperatures (C) using adjustable observation/atmospheric variables
% Ari Koeppel - 2021
% Requires exiftool.exe to be installed on system
% Best practice to make copies of all files before running as exiftools
% modifies files
clear
close all;

%% Import Data
FLIRDir = uigetdir('X:\common\FIELD_CAMPAIGNS\WoodhouseMesa_Sept2022\UAV\IR\','Directory of raw FLIR .RJPGs');%gets directory
FLIRFiles = dir(fullfile(FLIRDir,'*.jpg')); %gets all files
% DJIDir = uigetdir('X:\common\FIELD_CAMPAIGNS\WoodhouseMesa_Sept2022\UAV\VIS\','Directory of raw DJI .jpgs');
% DJIFiles = dir(fullfile(DJIDir,'*.jpg'));
% fprintf(1, 'Now reading files from %s and %s\n', FLIRDir, DJIDir);
[LoggerDataFile, Loggerfilepath] = uigetfile('X:\common\FIELD_CAMPAIGNS\WoodhouseMesa_Sept2022\GroundStation\Logger\','AllData Logger File');
LoggerDataFile = fullfile(Loggerfilepath,LoggerDataFile);
Data = struct2cell(load(LoggerDataFile));
Data = Data{:,:};
%% Geoalign FLIR images to DJI images
% gpx_out = [FLIRDir,'\DJI_GPSTrack.gpx'];
% tic
% exif = which('exiftool.exe');
% if isempty(exif)
%     error('exiftool.exe not found in path')
% end
% %Make sure gpx.fmt file exits
% temp1=['"' exif '" -fileOrder DateTimeOriginal -p gpx.fmt "',DJIDir,'" > "',gpx_out,'"'];
% [status1, log1] = system(temp1);
% %Change the geosync time to reflect the local GMT offset of the cameras -07:00:00
% %in Flagstaff, likely to be -7 or -14 off depending on if DJI is also off
% temp2=['"' exif '" -geosync=-07:00:00 -geotag "',gpx_out,'" "',FLIRDir,'"'];
% [status2, log2] = system(temp2);
% 
% %Use this linux code in ubuntu to remove the _original from original files
% %if needed
% %for filename in ./*; do mv "./$filename" "./$(echo "$filename" | sed -e 's/_original//g')";  done
tic
%% Convert R.JPGs to tiffs with temperature
%FLIRDir = uigetdir('~','Directory of geo_aligned FLIR .jpgs');%gets directory
FLIRFiles = dir(fullfile(FLIRDir,'*.jpg')); %gets all files
exif = which('exiftool.exe');
for k = 1:length(FLIRFiles)
    alignedFileName = fullfile(FLIRDir, FLIRFiles(k).name);
    raw_thermal = [alignedFileName(1:end-4),'_RawThermal.tiff'];
    %Extract raw thermal data and metadata calibration parameters
    temp3 = ['"' exif '" -rawthermalimage -b -w %0f"',raw_thermal,'" -q -execute -csv "-planck*" -emissivity -objectdistance -IRWindowTemperature -IRWindowTransmission "-*reflect*" "-*humidity" "-atmospheric*" -rawthermalimagetype "-date*" -common_args ',alignedFileName,' > ',FLIRDir,'\FLIR_meta.csv'];
    [~,~] = system(temp3);
    tbl = readtable([FLIRDir,'\FLIR_meta.csv']);
    FLIR_Time= datetime(FLIRFiles(k).name(1:15),'InputFormat','yyyyMMdd_HHmmss');
    WT = withtol(FLIR_Time,seconds(30));
    TEMPdata = Data(WT,:);
    tbl.RelativeHumidity = mean(TEMPdata.RH,'omitnan'); % point value from logger
    tbl.AtmosphericTemperature = mean(TEMPdata.AirTC,'omitnan'); % Point value from logger
    tbl.ObjectDistance = "17.50 m"; %(Black Point: 25-40 m, Hunt's 15-30 m, Baby Eskers: 95 m, Glacer Margin 25-35m, Woodhouse2022 10-25m)
    thermal_C = [raw_thermal(1:end-16),'_TempC',raw_thermal(end-4:end)];
    status = copyfile(raw_thermal,thermal_C,'f');
    t = Tiff(thermal_C,'r+');
    RAW = single(read(t));
    %Processing
    T_Calibrated = Thermal_Calibration(RAW,tbl);
    %
    setTag(t,'BitsPerSample',32); %An internal note to program to treat data as 32 Bit float rather than uint16 -not actually written to file
    setTag(t,'SampleFormat',Tiff.SampleFormat.IEEEFP); %An internal note to program to treat data as ~float rather than uint16 -not actually written to file
    write(t,single(T_Calibrated));
    close(t);
    temp4=['"' exif '" -TagsFromFile "',alignedFileName,'" -exif:all -XMP:all "',thermal_C,'"'];
    [~,~] = system(temp4);
    %imagesc(imread(thermal_C));
%   c = colorbar;
%   colormap('hot');
%   c.Label.String = 'Temp (^{\circ}C)'
%   TEST(k) = T_File(30,30);
end
delete(fullfile(FLIRDir,'*_original'))

% %% Destripe rows
% % FLIRDir = uigetdir('X:\common\','Directory of geo_aligned + Calibrated FLIR .tiffs');%gets directory
% FLIRFiles = dir(fullfile(FLIRDir,'*_TempC.tiff')); %gets all files
% for k = 1:length(FLIRFiles)
%     FileName = fullfile(FLIRDir, FLIRFiles(k).name);
%     destripe = [FileName(1:end-5),'_Destriped.tiff'];
%     status = copyfile(FileName,destripe,'f');
%     t = Tiff(destripe,'r+');
%     RAW = single(read(t));
%     DS = zeros(size(RAW));
%     xavg = mean(RAW,2);
%     windowSize = 31; 
%     conv = movmean(xavg,windowSize,'omitnan');
%     for i = 1:size(RAW,1)
%         DS(i,:) = RAW(i,:) - (xavg(i)-conv(i));
% %         %Add an over arching if that if range(RAW(i,:))< ? to prevent
% %         %adding stripes
% %         if i < 11
% %             DS(i,:) = RAW(i,:) - (xavg(i)-mean(xavg(1:20)));
% %         elseif i > size(RAW,1)-10
% %             DS(i,:) = RAW(i,:) - (xavg(i)-mean(xavg(end-20:end)));
% %         else
% %             DS(i,:) = RAW(i,:) - (xavg(i)-mean(xavg(i-10:i+10)));
% %         end
%     end
%     write(t,single(DS));
%     close(t);
% end

%% Obtain Flat Field
% Calculating and correcting for a static flat field is suffiecient for UAV
% flights where the instrument temperature changes little throughout
% flight
FLIRFiles = dir(fullfile(FLIRDir,'*TempC.tiff'));%gets all files dir(fullfile(FLIRDir,'*TempC_Destriped.tiff'))
Center_Temp = zeros(size(FLIRFiles));
% Corner = Center_Temp;
fullFLIRFileName = fullfile(FLIRDir, FLIRFiles(1).name);
first = imread(fullFLIRFileName);
Flat = zeros(size(first,1),size(first,2),length(FLIRFiles));
fprintf(1, 'Now reading files from %s\n', FLIRDir);
for k = 1:length(FLIRFiles)
  fullFileName = fullfile(FLIRDir, FLIRFiles(k).name);
  RAW = imread(fullFileName);
  Box_filt = imboxfilt(RAW,191);
  Center_Temp(k) = mean2(Box_filt(size(Box_filt,1)/2-5:size(Box_filt,1)/2+5,size(Box_filt,2)/2-5:size(Box_filt,2)/2+5));
%   Corner(k) = mean2(Box_filt(434:492,555:620));
  Flat(:,:,k) = Box_filt-Center_Temp(k);
end
Im_corr_mn = mean(Flat,3);
% Center_Im_corr_mn = mean2(Im_corr_mn(size(Im_corr_mn,1)/2-5:size(Im_corr_mn,1)/2+5,size(Im_corr_mn,2)/2-5:size(Im_corr_mn,2)/2+5));
% Corner_Im_corr_mn = mean2(Im_corr_mn(434:492,555:620));
Im_corr_md = median(Flat,3);
% Center_Im_corr_md = mean2(Im_corr_md(size(Im_corr_md,1)/2-5:size(Im_corr_md,1)/2+5,size(Im_corr_md,2)/2-5:size(Im_corr_md,2)/2+5));
% Corner_Im_corr_md = mean2(Im_corr_md(434:492,555:620));
imshowpair(Im_corr_mn,Im_corr_md,'montage');
% %Calculate how intensly the flat field applies to each image 
% Ratio = (Corner-Center_Temp)./(Corner_Im_corr_md-Center_Im_corr_md);

%% Correct Flat Field
for k = 1:length(FLIRFiles)
    fullFileName = fullfile(FLIRDir, FLIRFiles(k).name);
    newfilename = [fullFileName(1:end-5),'_FFC',fullFileName(end-4:end)];
    status = copyfile(fullFileName,newfilename,'f');
    t = Tiff(newfilename,'r+');
    RAW = read(t);
    T_File = RAW - Im_corr_mn;%*Ratio(k);
    setTag(t,'BitsPerSample',32); %An internal note to program to treat data as 32 Bit float rather than uint16 -not actually written to file
    setTag(t,'SampleFormat',Tiff.SampleFormat.IEEEFP); %An internal note to program to treat data as ~float rather than uint16 -not actually written to file
    write(t,single(T_File));
    close(t);
end
%% Functions
toc
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