%% Code for Reading in and plotting ground station CR1000X  and FLIR duo Pro data
% Ari Koeppel - 2020-2022
% Temperature positions change by +-nearest(#of pixels/# of images(indices)*(k-first index where change starts))
clear
close all;

%% Import Data
% Dir = input('Enter full FLIR Image Directory (i.e. "C:\\Users\\akoeppel\\Desktop\\"):  ','s');
LogDir = uigetdir('X:\common\','Directory of 1 Min Logger Data');%gets directory
FLIRDir = uigetdir('X:\common\FIELD_CAMPAIGNS\HuntsHole_Apr2022\Ground_Station\FLIR\Temp_Corr','Directory of temp-corrected FLIR .tiffs');%gets directory
fprintf(1, 'Now reading files from %s and %s\n', LogDir, FLIRDir);
tic

%Get 3 sec data from CR1000X
LogFile = dir(fullfile(LogDir,'*.mat')); %gets all files
LoggerData = struct2cell(load(fullfile(LogDir, LogFile.name)));
LoggerData = LoggerData{:,:};
%Correct GMT time (-6)
LoggerData.TIMESTAMP = LoggerData.TIMESTAMP - hours(6);
% LoggerData = table2timetable(LoggerData);

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
Bedrock1_Temp = zeros(size(FLIRFiles));
Bedrock2_Temp = zeros(size(FLIRFiles));
Bedrock3_Temp = zeros(size(FLIRFiles));
Caliche_Temp = zeros(size(FLIRFiles));
Sand_Temp = zeros(size(FLIRFiles));
Mixed_Surface1_Temp = zeros(size(FLIRFiles));
Mixed_Surface2_Temp = zeros(size(FLIRFiles));
Wet_Soil1_Temp = zeros(size(FLIRFiles));
Wet_Soil2_Temp = zeros(size(FLIRFiles));
CS240_Black = zeros(size(FLIRFiles));
CS240_White = zeros(size(FLIRFiles));

%% Obtain Flat Field
% It may necessary to calculate and correct for a dynamic flat field
% since the instument temperature changes and affects the flat field
% differently during day and night.
for k = 1:length(FLIRFiles)
%   fullFLIRFileName = fullfile(FLIRDir, FLIRFiles(k).name);
%   FLIR_Data(:,:,k) = imread(fullFLIRFileName);
  %imagesc(FLIR_Data(:,:,k))
%   sigma = 20;
%   Im_corr = imflatfield(FLIR_Data(:,:,k),sigma);
  Box_filt = imboxfilt(FLIR_Data(:,:,k),191);
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
Ratio = (Corner-Center_Temp)/(Corner_Im_corr_md-Center_Im_corr_md); % Use Ratio for Dynamic

%% Soil spot temps
for k = 1:244
  %FLIR_Data(Y1:Y2,X1:X2,k));
  FLIR_Data_Corr(:,:,k) = FLIR_Data(:,:,k) - Im_corr_md;%.*Ratio(k);
  CS240_Black(k) = mean2(FLIR_Data_Corr(292:302,294:309,k)); % Accurate for Hunts
  CS240_White(k) = mean2(FLIR_Data_Corr(260:268,288:303,k)); % Accurate for Hunts
  Bedrock1_Temp(k) = mean2(FLIR_Data_Corr(207:226,337:351,k)); % Accurate for Hunts - Darkest Toned
  Bedrock2_Temp(k) = mean2(FLIR_Data_Corr(204:212,396:420,k)); % Accurate for Hunts - Lightest Toned
  Bedrock3_Temp(k) = mean2(FLIR_Data_Corr(226:242,472:486,k)); % Accurate for Hunts - Mid-toned
  Caliche_Temp(k) = mean2(FLIR_Data_Corr(76:81,618:625,k)); % Accurate for Hunts
  Sand_Temp(k) = mean2(FLIR_Data_Corr(97:126,529:557,k)); % Accurate for Hunts
  Mixed_Surface1_Temp(k) = mean2(FLIR_Data_Corr(357:421,334:387,k)); % Accurate for Hunts - Blocks and Sand
  Mixed_Surface2_Temp(k) = mean2(FLIR_Data_Corr(133:176,562:632,k)); % Accurate for Hunts - Sand and Caliche
  Wet_Soil1_Temp(k) = mean2(FLIR_Data_Corr(43:54,343:355,k)); %Starts @ 1594 Accurate for Hunts - at undisturbed
  Wet_Soil2_Temp(k) = mean2(FLIR_Data_Corr(113:132,352:365,k)); %Starts @ 1594 Accurate for Hunts - at soil probe
  FLIR_Time(k)= datetime(FLIRFiles(k).name(1:15),'InputFormat','yyyyMMdd_HHmmss');
end
for k = 245
  %FLIR_Data(Y1:Y2,X1:X2,k));
  FLIR_Data_Corr(:,:,k) = FLIR_Data(:,:,k) - Im_corr_md;%.*Ratio(k);
  CS240_Black(k) = NaN;
  CS240_White(k) = NaN;
  Bedrock1_Temp(k) = mean2(FLIR_Data_Corr(207:226,337:351,k)); % Accurate for Hunts
  Bedrock2_Temp(k) = mean2(FLIR_Data_Corr(204:212,396:420,k)); % Accurate for Hunts - Lightest Toned
  Bedrock3_Temp(k) = mean2(FLIR_Data_Corr(226:242,472:486,k)); % Accurate for Hunts - Mid-toned
  Caliche_Temp(k) = mean2(FLIR_Data_Corr(76:81,618:625,k)); % Accurate for Hunts
  Sand_Temp(k) = mean2(FLIR_Data_Corr(97:126,529:557,k)); % Accurate for Hunts
  Mixed_Surface1_Temp(k) = mean2(FLIR_Data_Corr(357:421,334:387,k)); % Accurate for Hunts - Blocks and Sand
  Mixed_Surface2_Temp(k) = mean2(FLIR_Data_Corr(133:176,562:632,k)); % Accurate for Hunts - Sand and Caliche
  Wet_Soil1_Temp(k) = mean2(FLIR_Data_Corr(43:54,343:355,k)); %Starts @ 1594 Accurate for Hunts - at undisturbed
  Wet_Soil2_Temp(k) = mean2(FLIR_Data_Corr(113:132,352:365,k)); %Starts @ 1594 Accurate for Hunts - at soil probe
  FLIR_Time(k)= datetime(FLIRFiles(k).name(1:15),'InputFormat','yyyyMMdd_HHmmss');
end
for k = 246:length(FLIRFiles)
  %FLIR_Data(Y1:Y2,X1:X2,k));
  FLIR_Data_Corr(:,:,k) = FLIR_Data(:,:,k) - Im_corr_md;%.*Ratio(k);
  CS240_Black(k) = mean2(FLIR_Data_Corr(286:302,496:511,k)); % Accurate for Hunts
  CS240_White(k) = mean2(FLIR_Data_Corr(253:269,492:507,k)); % Accurate for Hunts
  Bedrock1_Temp(k) = mean2(FLIR_Data_Corr(207:226,337:351,k)); % Accurate for Hunts
  Bedrock2_Temp(k) = mean2(FLIR_Data_Corr(204:212,396:420,k)); % Accurate for Hunts - Lightest Toned
  Bedrock3_Temp(k) = mean2(FLIR_Data_Corr(226:242,472:486,k)); % Accurate for Hunts - Mid-toned
  Sand_Temp(k) = mean2(FLIR_Data_Corr(97:126,529:557,k)); % Accurate for Hunts
  Mixed_Surface1_Temp(k) = mean2(FLIR_Data_Corr(357:421,334:387,k)); % Accurate for Hunts - Blocks and Sand
  Mixed_Surface2_Temp(k) = mean2(FLIR_Data_Corr(133:176,562:632,k)); % Accurate for Hunts - Sand and Caliche
  Wet_Soil1_Temp(k) = mean2(FLIR_Data_Corr(43:54,343:355,k)); %Starts @ 1594 Accurate for Hunts - at undisturbed
  Wet_Soil2_Temp(k) = mean2(FLIR_Data_Corr(113:132,352:365,k)); %Starts @ 1594 Accurate for Hunts - at soil probe
  FLIR_Time(k)= datetime(FLIRFiles(k).name(1:15),'InputFormat','yyyyMMdd_HHmmss');
end

%% Plot Data

tstart=datetime(2022,04,24,09,44,0); 
tend=datetime(2022,04,26,09,26,0); 

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
Bedrock1_Temp = timetable(FLIR_Time',Bedrock1_Temp(:,1));
Bedrock2_Temp = timetable(FLIR_Time',Bedrock2_Temp(:,1));
Bedrock3_Temp = timetable(FLIR_Time',Bedrock3_Temp(:,1));
Sand_Temp = timetable(FLIR_Time',Sand_Temp(:,1));
Mixed_Surface1_Temp = timetable(FLIR_Time',Mixed_Surface1_Temp(:,1));
Mixed_Surface2_Temp = timetable(FLIR_Time',Mixed_Surface2_Temp(:,1));
Wet_Soil1_Temp = timetable(FLIR_Time',Wet_Soil1_Temp(:,1));
Wet_Soil2_Temp = timetable(FLIR_Time',Wet_Soil2_Temp(:,1));
FLIR_CS240Black = timetable(FLIR_Time',CS240_Black(:,1));
FLIR_CS240White = timetable(FLIR_Time',CS240_White(:,1));
% SensorBlack = timetable(LoggerData.TIMESTAMP,SBlackMean);
% SensorWhite = timetable(LoggerData.TIMESTAMP,SWhiteMean);
%SyncedVars = synchronize(FLIRBlack,SensorBlack,FLIRWhite,SensorWhite,DrySurf,WetSurf,'union','linear');
%SyncedVars = synchronize(FLIRBlack,SensorBlack,FLIRWhite,SensorWhite,DrySurf,'union','linear');
AllData = synchronize(LoggerData,FLIR_CS240Black,FLIR_CS240White,Bedrock1_Temp,Bedrock2_Temp,Bedrock3_Temp,Sand_Temp,Mixed_Surface1_Temp,Mixed_Surface2_Temp,Wet_Soil1_Temp,Wet_Soil2_Temp,'Minutely','linear');
SBlackMean = mean([AllData.CS240T_C3 AllData.CS240T_C4],2);
SWhiteMean = mean([AllData.CS240T_C1 AllData.CS240T_C2],2);
Noise = mean([AllData.FLIR_CS240Black-SBlackMean,AllData.FLIR_CS240Black-SWhiteMean],2);
figure(2)
plot(AllData.TIMESTAMP,Noise);
legend('FLIR Noise')
xlim([tstart tend]);
ylabel('Temp (C)');


AllData.Bedrock1_Temp_Corr = AllData.Bedrock1_Temp - Noise;
AllData.Bedrock2_Temp_Corr = AllData.Bedrock2_Temp - Noise;
AllData.Bedrock3_Temp_Corr = AllData.Bedrock3_Temp - Noise;
AllData.Sand_Temp_Corr = AllData.Sand_Temp - Noise;
AllData.Mixed_Surface1_Temp_Corr = AllData.Mixed_Surface1_Temp - Noise;
AllData.Mixed_Surface2_Temp_Corr = AllData.Mixed_Surface2_Temp - Noise;
AllData.Wet_Soil1_Temp_Corr = AllData.Wet_Soil1_Temp - Noise;
AllData.Wet_Soil2_Temp_Corr = AllData.Wet_Soil2_Temp - Noise;

figure(3)
plot(AllData.TIMESTAMP,AllData.Bedrock1_Temp_Corr);
hold on
plot(AllData.TIMESTAMP,AllData.Wet_Soil2_Temp_Corr);
plot(AllData.TIMESTAMP,AllData.SoilTemp1);
plot(AllData.TIMESTAMP,AllData.AirTC_Avg);
ylabel('Temp (C)');
legend('Corrected FLIR Dry', 'Corrected FLIR Wet','Ground Probe 1', 'Air Temp');
xlim([tstart tend]);

