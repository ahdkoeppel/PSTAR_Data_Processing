%% Code for Reading in and plotting ground station CR1000X  and FLIR duo Pro data
% Ari Koeppel - 2020
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
%Correct GMT time (-7)
LoggerData.TIMESTAMP = LoggerData.TIMESTAMP - hours(7);
LoggerData = table2timetable(LoggerData);

LoggerData = synchronize(LoggerData1Min,LoggerData3Sec,'Minutely','linear');


%Get data from FLIR images
FLIRFiles = dir(fullfile(FLIRDir,'*TempC.tiff')); %gets all files
fullFLIRFileName = fullfile(FLIRDir, FLIRFiles(1).name);
first = imread(fullFLIRFileName);
FLIR_Data = zeros(size(first,1),size(first,2),length(FLIRFiles));
FLIR_Data_Corr = zeros(size(first,1),size(first,2),length(FLIRFiles));
Center_Temp = zeros(size(FLIRFiles));
Corner = zeros(size(FLIRFiles));
Flat = zeros(size(first,1),size(first,2),length(FLIRFiles));
Soil_Temp_Large_Area = zeros(size(FLIRFiles));
Cobble_Temp = zeros(size(FLIRFiles));
Sand_Temp = zeros(size(FLIRFiles));
Dry_Mud_Temp = zeros(size(FLIRFiles));
Wet_Soil1st_Temp = zeros(size(FLIRFiles));
Wet_Soil2nd_Temp = zeros(size(FLIRFiles));
Wet_Soil3rd_Temp = zeros(size(FLIRFiles));
CS240_Black = zeros(size(FLIRFiles));
CS240_White = zeros(size(FLIRFiles));

%% Find temps from each image
for k = 1:length(FLIRFiles)
  fullFLIRFileName = fullfile(FLIRDir, FLIRFiles(k).name);
  FLIR_Data(:,:,k) = imread(fullFLIRFileName);
  %imagesc(FLIR_Data(:,:,k))
%   sigma = 20;
%   Im_corr = imflatfield(FLIR_Data(:,:,k),sigma);
  Box_filt = imboxfilt(FLIR_Data(:,:,k),151);
  Center_Temp(k) = mean2(Box_filt(size(FLIR_Data,1)/2-5:size(FLIR_Data,1)/2+5,size(FLIR_Data,2)/2-5:size(FLIR_Data,2)/2+5));
  Corner(k) = mean2(Box_filt(434:492,555:620));
  Flat(:,:,k) = Box_filt-Center_Temp(k);
%   imshowpair(FLIR_Data(:,:,k),Im_corr,'montage');
end

Im_corr_mn = mean(Flat,3);
Center_Im_corr_mn = mean2(Im_corr_mn(size(Im_corr_mn,1)/2-5:size(Im_corr_mn,1)/2+5,size(Im_corr_mn,2)/2-5:size(Im_corr_mn,2)/2+5));
Corner_Im_corr_mn = mean2(Im_corr_mn(434:492,555:620));
Im_corr_md = median(Flat,3);
Center_Im_corr_md = mean2(Im_corr_md(size(Im_corr_md,1)/2-5:size(Im_corr_md,1)/2+5,size(Im_corr_md,2)/2-5:size(Im_corr_md,2)/2+5));
Corner_Im_corr_md = mean2(Im_corr_md(434:492,555:620));
imshowpair(Im_corr_mn,Im_corr_md,'montage');
Ratio = (Corner-Center_Temp)/(Corner_Im_corr_md-Center_Im_corr_md);

for k = 1:length(FLIRFiles)
      %FLIR_Data(Y1:Y2,X1:X2,k));
  FLIR_Data_Corr(:,:,k) = FLIR_Data(:,:,k) - Im_corr_md.*Ratio(k);
  CS240_Black(k) = mean2(FLIR_Data_Corr(90:104,407:424,k)); % Accurate for Sperry Wash
  CS240_White(k) = mean2(FLIR_Data_Corr(119:132,387:402,k)); % Accurate for Sperry Wash
  Soil_Temp_Large_Area(k) = mean2(FLIR_Data_Corr(157:222,327:540,k)); % Accurate for Sperry Wash
  Cobble_Temp(k) = mean2(FLIR_Data_Corr(218:223,369:380,k)); % Accurate for Sperry Wash
  Sand_Temp(k) = mean2(FLIR_Data_Corr(61:84,559:596,k)); % Accurate for Sperry Wash
  Dry_Mud_Temp(k) = mean2(FLIR_Data_Corr(29:59,594:626,k)); % Accurate for Sperry Wash
  Wet_Soil1st_Temp(k) = mean2(FLIR_Data_Corr(371:398,507:536,k)); %Starts @ 2417% Accurate for Sperry Wash
  Wet_Soil2nd_Temp(k) = mean2(FLIR_Data_Corr(421:457,578:606,k));% Accurate for Sperry Wash
  Wet_Soil3rd_Temp(k) = mean2(FLIR_Data_Corr(380:405,454:473,k));% Accurate for Sperry Wash
  FLIR_Time(k)= datetime(FLIRFiles(k).name(1:15),'InputFormat','yyyyMMdd_HHmmss');
end
%% Plot Data

tstart=datetime(2021,10,18,17,04,0); 
tend=datetime(2021,10,21,10,0,0);

%FLIR surface temp
% figure(1)
% %X =1:1:length(FLIRFiles);
% %plot(FLIR_Time,Dry_Point_Temp(:,1)-Full_Scene_Temp(:,1));
% plot(FLIR_Time,Dry_Point_Temp(:,1));
% legend('Dry');
% xlim([tstart tend]);

%FLIR and sensor cal target temp
SBlackMean = mean([LoggerData.CS240T_C3 LoggerData.CS240T_C4],2);
SWhiteMean = mean([LoggerData.CS240T_C1 LoggerData.CS240T_C2],2);
figure(1)
plot(FLIR_Time,CS240_Black(:,1),FLIR_Time,CS240_White(:,1),LoggerData.TIMESTAMP,SBlackMean,LoggerData.TIMESTAMP,SWhiteMean);
legend('FLIRBlack','FLIRWhite','SBlack','SWhite');
xlim([tstart tend]);
xlabel('Temp (C)');

%Corrected FLIR Surface Temp
Soil_Large_Area = timetable(FLIR_Time',Soil_Temp_Large_Area(:,1));
Cobble = timetable(FLIR_Time',Cobble_Temp(:,1));
Sand = timetable(FLIR_Time',Sand_Temp(:,1));
Mud = timetable(FLIR_Time',Dry_Mud_Temp(:,1));
WetSoil1st = timetable(FLIR_Time',Wet_Soil1st_Temp(:,1));
WetSoil2nd = timetable(FLIR_Time',Wet_Soil2nd_Temp(:,1));
WetSoil3rd = timetable(FLIR_Time',Wet_Soil3rd_Temp(:,1));
FLIR_CS240Black = timetable(FLIR_Time',CS240_Black(:,1));
FLIR_CS240White = timetable(FLIR_Time',CS240_White(:,1));
% SensorBlack = timetable(LoggerData.TIMESTAMP,SBlackMean);
% SensorWhite = timetable(LoggerData.TIMESTAMP,SWhiteMean);
%SyncedVars = synchronize(FLIRBlack,SensorBlack,FLIRWhite,SensorWhite,DrySurf,WetSurf,'union','linear');
%SyncedVars = synchronize(FLIRBlack,SensorBlack,FLIRWhite,SensorWhite,DrySurf,'union','linear');
AllData = synchronize(LoggerData,FLIR_CS240Black,FLIR_CS240White,Soil_Large_Area,Cobble,Sand,Mud,WetSoil1st,WetSoil2nd,WetSoil3rd,'Minutely','linear');
Noise = mean([AllData.FLIR_CS240Black-SBlackMean,AllData.FLIR_CS240Black-SWhiteMean],2);
figure(2)
plot(AllData.TIMESTAMP,Noise);
legend('FLIR Noise')
xlim([tstart tend]);
ylabel('Temp (C)');


AllData.FLIR_Soil_Large_Area_Corr = AllData.FLIR_Soil_Large_Area-Noise;
AllData.FLIR_Cobble_Corr = AllData.FLIR_Cobble-Noise;
AllData.FLIR_Mud_Corr = AllData.FLIR_Mud-Noise;
AllData.FLIR_Sand_Corr = AllData.FLIR_Sand-Noise;
AllData.FLIR_WetSoil1st_Corr = AllData.FLIR_WetSoil1st-Noise;
AllData.FLIR_WetSoil2nd_Corr = AllData.FLIR_WetSoil2nd-Noise;
AllData.FLIR_WetSoil3rd_Corr = AllData.FLIR_WetSoil3rd-Noise;

figure(3)
plot(AllData.TIMESTAMP,AllData.FLIR_Soil_Large_Area_Corr);
hold on
plot(AllData.TIMESTAMP,AllData.FLIR_WetSoil1st_Corr);
plot(AllData.TIMESTAMP,AllData.T109_C_Avg1);
plot(AllData.TIMESTAMP,AllData.AirTC_Avg);
ylabel('Temp (C)');
yyaxis right
plot(AllData.TIMESTAMP,AllData.WS_ms_10_U_WVT);
%plot(AllData.TIMESTAMP,AllData.WS_ms_10);
legend('Corrected FLIR Dry', 'Corrected FLIR Wet','Ground Probe 1', 'Air Temp', 'Wind Speed 30');
xlim([tstart tend]);
ylabel('Net Downward Irradiance (W/m^2)')
%ylabel('Wind Speed (m/s)');
