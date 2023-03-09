%% Code for Reading in and plotting ground station CR1000X  and FLIR duo Pro data
% Ari Koeppel - 2020
% Temperature positions change by +-nearest(#of pixels/# of images(indices)*(k-first index where change starts))
clear
close all;

%% Import Data
% Dir = input('Enter full FLIR Image Directory (i.e. "C:\\Users\\akoeppel\\Desktop\\"):  ','s');
LogDir = uigetdir('X:\common\','Directory of 1 Min Logger Data');%gets directory
FLIRDir = uigetdir('X:\common\FIELD_CAMPAIGNS\Mojave_Oct2021\Pahrump_Playa\Ground_Station\FLIR\20211015_182959','Directory of temp-corrected FLIR .tiffs');%gets directory
fprintf(1, 'Now reading files from %s and %s\n', LogDir, FLIRDir);
tic

%Get 3 sec data from CR1000X
LogFile = dir(fullfile(LogDir,'*.mat')); %gets all files
LoggerData = struct2cell(load(fullfile(LogDir, LogFile.name)));
LoggerData = LoggerData{:,:};
%Correct GMT time (-7)
LoggerData.TIMESTAMP = LoggerData.TIMESTAMP - hours(7);
LoggerData = table2timetable(LoggerData);

%Get data from FLIR images
FLIRFiles = dir(fullfile(FLIRDir,'*TempC.tiff')); %gets all files
fullFLIRFileName = fullfile(FLIRDir, FLIRFiles(1).name);
first = imread(fullFLIRFileName);
FLIR_Data = zeros(size(first,1),size(first,2),length(FLIRFiles));
FLIR_Data_Corr = zeros(size(first,1),size(first,2),length(FLIRFiles));
Box_filt = zeros(size(first,1),size(first,2),length(FLIRFiles));
Full_Scene_Temp = zeros(size(FLIRFiles));
Soilleft_Temp = zeros(size(FLIRFiles));
Soilright_Temp = zeros(size(FLIRFiles));
Wet_Soil1st_Temp = zeros(size(FLIRFiles));
Wet_Soil2nd_Temp = zeros(size(FLIRFiles));
CS240_Black = zeros(size(FLIRFiles));
CS240_White = zeros(size(FLIRFiles));
Center_Temp = zeros(size(FLIRFiles));
Corner = zeros(size(FLIRFiles));
Flat = zeros(size(first,1),size(first,2),length(FLIRFiles));

%% Obtain Flat Field
% It is necessary to calculate and correct for a dynamic flat field
% since the instument temperature changes and affects the flat field
% differently during day and night.
for k = 1:length(FLIRFiles)
  fullFLIRFileName = fullfile(FLIRDir, FLIRFiles(k).name);
  FLIR_Data(:,:,k) = imread(fullFLIRFileName);
  %imagesc(FLIR_Data(:,:,k))
%   Center_Temp(k) = mean2(FLIR_Data(size(FLIR_Data,1)/2-5:size(FLIR_Data,1)/2+5,size(FLIR_Data,2)/2-5:size(FLIR_Data,2)/2+5,k));
  Box_filt(:,:,k) = imboxfilt(FLIR_Data(:,:,k),191);
  Center_Temp(k) = mean2(Box_filt(200:225,290:340,k));
  Corner(k) = mean2(Box_filt(434:492,555:620,k));
  Flat(:,:,k) = Box_filt(:,:,k)-Center_Temp(k);
  %FLIR_Data(Y1:Y2,X1:X2,k));
end
%Calculate average and median flat field pattern
Im_corr_mn = mean(Flat,3);
Center_Im_corr_mn = mean2(Im_corr_mn(200:225,290:340));
Corner_Im_corr_mn = mean2(Im_corr_mn(434:492,555:620));
Im_corr_md = median(Flat,3);
Center_Im_corr_md = mean2(Im_corr_md(200:225,290:340));
Corner_Im_corr_md = mean2(Im_corr_md(434:492,555:620));
imshowpair(Im_corr_mn,Im_corr_md,'montage');
%Calculate how intensly the flat field applies to each image 
Ratio = (Corner-Center_Temp)/(Corner_Im_corr_md-Center_Im_corr_md);

%Correct flat field and calculate FLIR temperature for ROIs
for k = 1:length(FLIRFiles)
  FLIR_Data_Corr(:,:,k) = FLIR_Data(:,:,k) - Im_corr_md.*Ratio(k);
  CS240_Black(k) = mean2(FLIR_Data_Corr(341:352,436:447,k)); % correct with CS240X_Avg(3 and 4)
  CS240_White(k) = mean2(FLIR_Data_Corr(342:356,471:483,k)); % correct with CS240X_Avg(1 and 2)
  Soilleft_Temp(k) = mean2(FLIR_Data_Corr(373:394,375:403,k));
  Soilright_Temp(k) = mean2(FLIR_Data_Corr(373:394,375:403,k));
  Wet_Soil1st_Temp(k) = mean2(FLIR_Data_Corr(409:426,286:304,k));
  Wet_Soil2nd_Temp(k) = mean2(FLIR_Data_Corr(339:367,511:542,k));
  FLIR_Time(k)= datetime(FLIRFiles(k).name(1:15),'InputFormat','yyyyMMdd_HHmmss');
end
%% Plot Data

tstart=datetime(2021,10,15,18,29,0); 
tend=datetime(2021,10,18,08,53,0);

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
DrySoil_left = timetable(FLIR_Time',Soilleft_Temp(:,1));
DrySoil_right = timetable(FLIR_Time',Soilright_Temp(:,1));
WetSoil1st = timetable(FLIR_Time',Wet_Soil1st_Temp(:,1));
WetSoil2nd = timetable(FLIR_Time',Wet_Soil2nd_Temp(:,1));
FLIR_CS240Black = timetable(FLIR_Time',CS240_Black(:,1));
FLIR_CS240White = timetable(FLIR_Time',CS240_White(:,1));
% SensorBlack = timetable(LoggerData.TIMESTAMP,SBlackMean);
% SensorWhite = timetable(LoggerData.TIMESTAMP,SWhiteMean);
%SyncedVars = synchronize(FLIRBlack,SensorBlack,FLIRWhite,SensorWhite,DrySurf,WetSurf,'union','linear');
%SyncedVars = synchronize(FLIRBlack,SensorBlack,FLIRWhite,SensorWhite,DrySurf,'union','linear');
AllData = synchronize(LoggerData,FLIR_CS240Black,FLIR_CS240White,DrySoil_left,DrySoil_right,WetSoil1st,WetSoil2nd,'Minutely','linear');
Noise = mean([AllData.Var1_FLIR_CS240Black-SBlackMean,AllData.Var1_FLIR_CS240Black-SWhiteMean],2);
figure(2)
plot(AllData.TIMESTAMP,Noise);
legend('FLIR Noise')
xlim([tstart tend]);
ylabel('Temp (C)');


AllData.FLIR_DrySoil_left_Corr = AllData.FLIR_DrySoil_left-Noise;
AllData.FLIR_DrySoil_right_Corr = AllData.FLIR_DrySoil_right-Noise;
AllData.FLIR_WetSoil1st_Corr = AllData.FLIR_WetSoil1st-Noise;
AllData.FLIR_WetSoil2nd_Corr = AllData.FLIR_WetSoil2nd-Noise;

figure(3)
plot(AllData.TIMESTAMP,AllData.FLIR_DrySoil_left_Corr);
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
