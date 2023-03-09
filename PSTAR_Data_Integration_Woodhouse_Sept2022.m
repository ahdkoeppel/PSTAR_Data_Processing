%% Code for Reading in and plotting ground station CR1000X  and FLIR duo Pro data
% Ari Koeppel - 2020-2022
% Temperature positions change by +-nearest(#of pixels/# of images(indices)*(k-first index where change starts))
clear
close all;

%% Import Data
% Dir = input('Enter full FLIR Image Directory (i.e. "C:\\Users\\akoeppel\\Desktop\\"):  ','s');
LogDir = uigetdir('X:\common\','Directory of 1 Min Logger Data');%gets directory
FLIRDir = uigetdir('X:\common\','Directory of temp-corrected FLIR .tiffs');%gets directory
fprintf(1, 'Now reading files from %s and %s\n', LogDir, FLIRDir);
tic

%Get 3 sec data from CR1000X
LogFile = dir(fullfile(LogDir,'*.mat')); %gets all files
LoggerData = struct2cell(load(fullfile(LogDir, LogFile.name)));
LoggerData = LoggerData{:,:};
%Correct GMT time (-6)
LoggerData.TIMESTAMP = LoggerData.TIMESTAMP - hours(7);
LoggerData = table2timetable(LoggerData);

% LoggerData = synchronize(LoggerData1Min,LoggerData3Sec,'Minutely','linear');


%Get data from FLIR images
FLIRFiles = dir(fullfile(FLIRDir,'*TempC.tiff')); %gets all files
fullFLIRFileName = fullfile(FLIRDir, FLIRFiles(1).name);
first = imread(fullFLIRFileName);
FLIR_Data = zeros(size(first,1),size(first,2),length(FLIRFiles));
FLIR_Data_Corr = zeros(size(first,1),size(first,2),length(FLIRFiles));
Center_Temp = zeros(size(FLIRFiles));
Corner = zeros(size(FLIRFiles));
Flat = zeros(size(first,1),size(first,2),length(FLIRFiles));
Control_Sand_Temp = zeros(size(FLIRFiles));
Center_Sand_Temp = zeros(size(FLIRFiles));
Corner_Sand_Temp = zeros(size(FLIRFiles));
Wet_Soil1_Temp = zeros(size(FLIRFiles));
Wet_Soil2_Temp = zeros(size(FLIRFiles));
CS240_Black = zeros(size(FLIRFiles));
CS240_White = zeros(size(FLIRFiles));

FLIRVISFiles = dir(fullfile(FLIRDir,'*.jpg')); %gets all files
dry_RGB_refl = zeros(size(FLIRVISFiles));
wet_RGB_refl= zeros(size(FLIRVISFiles));
for k = 1:length(FLIRVISFiles)
    FLIR_VIS_Dat = imread(fullfile(FLIRDir, FLIRVISFiles(k).name));
    dry_RGB_refl(k) = mean2(FLIR_VIS_Dat(1277:1681,1201:1708,:)); 
    wet_RGB_refl(k) = mean2(FLIR_VIS_Dat(749:786,1493:1590,:)); 
    FLIR_Time(k)= datetime(FLIRVISFiles(k).name(1:15),'InputFormat','yyyyMMdd_HHmmss');
end
Albedo = median(Data.SWLower_Avg(Data.SolarElevationCorrectedForAtmRefractiondeg>0)./Data.SWUpper_Avg(Data.SolarElevationCorrectedForAtmRefractiondeg>0));
FLIR_VIS_albedo_dry = timetable(FLIR_Time',ones(size(FLIR_Time')).*Albedo);
FLIR_VIS_albedo_Wet = timetable(FLIR_Time',wet_RGB_refl(:,1)./dry_RGB_refl(:,1).*Albedo);


%% Obtain Flat Field
% It may necessary to calculate and correct for a dynamic flat field
% since the instument temperature changes and affects the flat field
% differently during day and night.
for k = 1:length(FLIRFiles)
  fullFLIRFileName = fullfile(FLIRDir, FLIRFiles(k).name);
  FLIR_Data(:,:,k) = imread(fullFLIRFileName);
  %imagesc(FLIR_Data(:,:,k))
%   sigma = 20;
%   Im_corr = imflatfield(FLIR_Data(:,:,k),sigma);
  Box_filt = imboxfilt(FLIR_Data(:,:,k),191);
  Center_Temp(k) = mean2(Box_filt(size(FLIR_Data,1)/2-5:size(FLIR_Data,1)/2+5,size(FLIR_Data,2)/2-5:size(FLIR_Data,2)/2+5));
  Corner(k) = mean2(Box_filt(487:507,5:25));
  Flat(:,:,k) = Box_filt-Center_Temp(k);
%   imshowpair(FLIR_Data(:,:,k),Im_corr,'montage');
end

Im_corr_mn = mean(Flat,3);
Center_Im_corr_mn = mean2(Im_corr_mn(size(Im_corr_mn,1)/2-5:size(Im_corr_mn,1)/2+5,size(Im_corr_mn,2)/2-5:size(Im_corr_mn,2)/2+5));
Corner_Im_corr_mn = mean2(Im_corr_mn(487:507,5:25));
Im_corr_md = median(Flat,3);
Center_Im_corr_md = mean2(Im_corr_md(size(Im_corr_md,1)/2-5:size(Im_corr_md,1)/2+5,size(Im_corr_md,2)/2-5:size(Im_corr_md,2)/2+5));
Corner_Im_corr_md = mean2(Im_corr_md(487:507,5:25));
imshowpair(Im_corr_mn,Im_corr_md,'montage');
% Ratio = (Corner-Center_Temp)/(Corner_Im_corr_md-Center_Im_corr_md); % Use Ratio for Dynamic

%% Soil spot temps
for k = 1:length(FLIRFiles)
  %FLIR_Data(Y1:Y2,X1:X2,k));
  FLIR_Data_Corr(:,:,k) = FLIR_Data(:,:,k) - Im_corr_mn;%.*Ratio(k);
  Control_Sand_Temp(k) = mean2(FLIR_Data_Corr(104:116,43:57,k));
  Center_Sand_Temp(k) = mean2(FLIR_Data_Corr(237:285,268:320,k));
  Corner_Sand_Temp(k) = mean2(FLIR_Data_Corr(487:507,5:25,k));
  Wet_Soil1_Temp(k) = mean2(FLIR_Data_Corr(86:100,150:160,k)); %No sensor, Starts @ 9/16 11:30 AM
  Wet_Soil2_Temp(k) = mean2(FLIR_Data_Corr(113:124,222:241,k)); %With Sensor, Starts @ 9/16 11:36 AM
  CS240_Black(k) = mean2(FLIR_Data_Corr(263:279,348:366,k));
  CS240_White(k) = mean2(FLIR_Data_Corr(229:248,348:366,k));
%   FLIR_Time(k)= datetime(FLIRFiles(k).name(1:15),'InputFormat','yyyyMMdd_HHmmss');
end

%% Plot Data

tstart=datetime(2022,09,15,15,09,0); 
tend=datetime(2022,09,19,13,09,0); 

%FLIR surface temp
% figure(1)
% %X =1:1:length(FLIRFiles);
% %plot(FLIR_Time,Dry_Point_Temp(:,1)-Full_Scene_Temp(:,1));
% plot(FLIR_Time,Dry_Point_Temp(:,1));
% legend('Dry');
% xlim([tstart tend]);

%FLIR and sensor cal target temp
SBlackMean = mean([LoggerData.CS240T_C_Avg1 LoggerData.CS240T_C_Avg2],2);
SWhiteMean = mean([LoggerData.CS240T_C_Avg3 LoggerData.CS240T_C_Avg4],2);
figure(1)
plot(FLIR_Time,CS240_Black(:,1),FLIR_Time,CS240_White(:,1),LoggerData.TIMESTAMP,SBlackMean,LoggerData.TIMESTAMP,SWhiteMean);
legend('FLIRBlack','FLIRWhite','SBlack','SWhite');
xlim([tstart tend]);
xlabel('Temp (C)');

%Corrected FLIR Surface Temp
Control_Sand_Temp = timetable(FLIR_Time',Control_Sand_Temp(:,1));
Center_Sand_Temp = timetable(FLIR_Time',Center_Sand_Temp(:,1));
Corner_Sand_Temp = timetable(FLIR_Time',Corner_Sand_Temp(:,1));
Wet_Soil1_Temp = timetable(FLIR_Time',Wet_Soil1_Temp(:,1));
Wet_Soil2_Temp = timetable(FLIR_Time',Wet_Soil2_Temp(:,1));
FLIR_CS240Black = timetable(FLIR_Time',CS240_Black(:,1));
FLIR_CS240White = timetable(FLIR_Time',CS240_White(:,1));
AllData = synchronize(LoggerData,FLIR_CS240Black,FLIR_CS240White,Control_Sand_Temp,Center_Sand_Temp,Corner_Sand_Temp,Wet_Soil1_Temp,Wet_Soil2_Temp,'Minutely','linear');
SBlackMean = mean([AllData.CS240T_C_Avg1 AllData.CS240T_C_Avg2],2);
SWhiteMean = mean([AllData.CS240T_C_Avg3 AllData.CS240T_C_Avg4],2);
Noise = mean([AllData.FLIR_CS240Black-SBlackMean,AllData.FLIR_CS240Black-SWhiteMean],2);
figure(2)
plot(AllData.TIMESTAMP,Noise);
legend('FLIR Noise')
xlim([tstart tend]);
ylabel('Temp (C)');


AllData.Control_Sand_Temp_Corr = AllData.Control_Sand_Temp - Noise;
AllData.Center_Sand_Temp_Corr = AllData.Center_Sand_Temp - Noise;
AllData.Corner_Sand_Temp_Corr = AllData.Corner_Sand_Temp - Noise;
AllData.Wet_Soil1_Temp_Corr = AllData.Wet_Soil1_Temp - Noise;
AllData.Wet_Soil2_Temp_Corr = AllData.Wet_Soil2_Temp - Noise;

figure(3)
plot(AllData.TIMESTAMP,AllData.Control_Sand_Temp_Corr);
hold on
plot(AllData.TIMESTAMP,AllData.Wet_Soil2_Temp_Corr);
plot(AllData.TIMESTAMP,AllData.SoilTemp1);
plot(AllData.TIMESTAMP,AllData.AirTC);
ylabel('Temp (C)');
legend('Corrected FLIR Dry', 'Corrected FLIR Wet','Ground Probe 1', 'Air Temp');
xlim([tstart tend]);

SolarData.Date = SolarData.Date + hours(24.*SolarData.TimepastLocalMidnight);