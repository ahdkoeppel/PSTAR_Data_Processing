%% Code for Reading in and plotting ground station CR1000X  and FLIR duo Pro data
% Ari Koeppel - 2020
% Temperature positions change by +-nearest(#of pixels/# of images(indices)*(k-first index where change starts))
clear
close all;

%% Import Data
% Dir = input('Enter full FLIR Image Directory (i.e. "C:\\Users\\akoeppel\\Desktop\\"):  ','s');
LogDir3Sec = uigetdir('X:\common\','Directory of 3 sec Logger Data');%gets directory
LogDir1Min = uigetdir('X:\common\','Directory of 1 min Logger Data');%gets directory
FLIRDir = uigetdir('X:\common\','Directory of temp-corrected FLIR .tiffs');%gets directory
fprintf(1, 'Now reading files from %s and %s\n', LogDir3Sec, FLIRDir);
tic

%Get 3 sec data from CR1000X
LogFile3Sec = dir(fullfile(LogDir3Sec,'*.mat')); %gets all files
fullLogFileName3Sec = fullfile(LogDir3Sec, LogFile3Sec.name);
LoggerData3Sec = struct2cell(load(fullfile(LogDir3Sec, LogFile3Sec.name)));
LoggerData3Sec = LoggerData3Sec{:,:};
%Correct GMT time (-7)
LoggerData3Sec.TIMESTAMP = LoggerData3Sec.TIMESTAMP - hours(7);
LoggerData3Sec = table2timetable(LoggerData3Sec);

%Get data from CR1000X
LogFile1Min = dir(fullfile(LogDir1Min,'*.mat')); %gets all files
fullLogFileName1Min = fullfile(LogDir1Min, LogFile1Min.name);
LoggerData1Min = struct2cell(load(fullfile(LogDir1Min, LogFile1Min.name)));
LoggerData1Min = LoggerData1Min{:,:};
%Correct GMT time (-7)
LoggerData1Min.TIMESTAMP = LoggerData1Min.TIMESTAMP - hours(7);
LoggerData1Min = table2timetable(LoggerData1Min);

LoggerData = synchronize(LoggerData1Min,LoggerData3Sec,'Minutely','linear');

%Get data from FLIR images
FLIRFiles = dir(fullfile(FLIRDir,'*.tiff')); %gets all files
fullFLIRFileName = fullfile(FLIRDir, FLIRFiles(1).name);
first = imread(fullFLIRFileName);
FLIR_Data = zeros(size(first,1),size(first,2),length(FLIRFiles));
Soil_Temp = zeros(size(FLIRFiles));
Wet_Soil_Temp = zeros(size(FLIRFiles));
Full_Scene_Temp = zeros(size(FLIRFiles));
CS240_Black = zeros(size(FLIRFiles));
CS240_White = zeros(size(FLIRFiles));
FLIRVISFiles = dir(fullfile(FLIRDir,'*.jpg')); %gets all files
dry_RGB_refl = zeros(size(FLIRVISFiles));
wet_RGB_refl= zeros(size(FLIRVISFiles));
for k = 1:length(FLIRVISFiles)
    FLIR_VIS_Dat = imread(fullfile(FLIRDir, FLIRVISFiles(k).name));
    dry_RGB_refl(k) = mean2(FLIR_VIS_Dat(1238:1338,2150:2270,:)); %Note that this is ok b/c camera did not move during noticeable albedo change
    wet_RGB_refl(k) = mean2(FLIR_VIS_Dat(1510:1574,2090:2158,:)); %Note that this is ok b/c camera did not move during noticeable albedo change
    FLIR_Time(k)= datetime(FLIRVISFiles(k).name(1:15),'InputFormat','yyyyMMdd_HHmmss');
end
for k = 1:39
  fullFLIRFileName = fullfile(FLIRDir, FLIRFiles(k).name);
  FLIR_Data(:,:,k) = imread(fullFLIRFileName);
  Full_Scene_Temp(k) = mean2(FLIR_Data(:,:,k));
  %FLIR_Data(Y1:Y2,X1:X2,k));
  Soil_Temp(k) = NaN;
  CS240_Black(k) = NaN; % correct with CS240X_Avg(3 and 4)
  CS240_White(k) = NaN; % correct with CS240X_Avg(1 and 2)
  Wet_Soil_Temp(k) = NaN;
  FLIR_Time(k)= datetime(FLIRFiles(k).name(1:15),'InputFormat','yyyyMMdd_HHmmss');
end
for k = 40:80
  fullFLIRFileName = fullfile(FLIRDir, FLIRFiles(k).name);
  FLIR_Data(:,:,k) = imread(fullFLIRFileName);
  %imagesc(FLIR_Data(:,:,k))
  Full_Scene_Temp(k) = mean2(FLIR_Data(:,:,k));
  %FLIR_Data(Y1:Y2,X1:X2,k));
  CS240_Black(k) = mean2(FLIR_Data(262:276,277:289,k)); % correct with CS240X_Avg(3 and 4)
  CS240_White(k) = mean2(FLIR_Data(319:329,281:289,k)); % correct with CS240X_Avg(1 and 2)
  Soil_Temp(k) = mean2(FLIR_Data(310:329,372:393,k));
  Wet_Soil_Temp(k) = mean2(FLIR_Data(442:455,341:359,k));
  FLIR_Time(k)= datetime(FLIRFiles(k).name(1:15),'InputFormat','yyyyMMdd_HHmmss');
end
for k = 81:150
  fullFLIRFileName = fullfile(FLIRDir, FLIRFiles(k).name);
  FLIR_Data(:,:,k) = imread(fullFLIRFileName);
  %imagesc(FLIR_Data(:,:,k))
  Full_Scene_Temp(k) = mean2(FLIR_Data(:,:,k));
  %FLIR_Data(Y1:Y2,X1:X2,k));
  CS240_Black(k) = mean2(FLIR_Data(262-nearest(20/70*(k-80)):276-nearest(20/70*(k-80)),277:289,k)); % correct with CS240X_Avg(3 and 4)
  CS240_White(k) = mean2(FLIR_Data(319-nearest(20/70*(k-80)):329-nearest(20/70*(k-80)),281:289,k)); % correct with CS240X_Avg(1 and 2)
  Soil_Temp(k) = mean2(FLIR_Data(310-nearest(20/70*(k-80)):329-nearest(20/70*(k-80)),372:393,k));
  Wet_Soil_Temp(k) = mean2(FLIR_Data(442-nearest(20/70*(k-80)):455-nearest(20/70*(k-80)),341:359,k));
  FLIR_Time(k)= datetime(FLIRFiles(k).name(1:15),'InputFormat','yyyyMMdd_HHmmss');
end
for k = 151:300
  fullFLIRFileName = fullfile(FLIRDir, FLIRFiles(k).name);
  FLIR_Data(:,:,k) = imread(fullFLIRFileName);
  %imagesc(FLIR_Data(:,:,k))
  Full_Scene_Temp(k) = mean2(FLIR_Data(:,:,k));
  %FLIR_Data(Y1:Y2,X1:X2,k));
  CS240_Black(k) = mean2(FLIR_Data(242:256,277:289,k)); % correct with CS240X_Avg(3 and 4)
  CS240_White(k) = mean2(FLIR_Data(299:309,281:289,k)); % correct with CS240X_Avg(1 and 2)
  Soil_Temp(k) = mean2(FLIR_Data(290:309,372:393,k));
  Wet_Soil_Temp(k) = mean2(FLIR_Data(422:435,341:359,k));
  FLIR_Time(k)= datetime(FLIRFiles(k).name(1:15),'InputFormat','yyyyMMdd_HHmmss');
end
for k = 301:320
  fullFLIRFileName = fullfile(FLIRDir, FLIRFiles(k).name);
  FLIR_Data(:,:,k) = imread(fullFLIRFileName);
  %imagesc(FLIR_Data(:,:,k))
  Full_Scene_Temp(k) = mean2(FLIR_Data(:,:,k));
  %FLIR_Data(Y1:Y2,X1:X2,k));
  CS240_Black(k) = mean2(FLIR_Data(241-nearest(10/20*(k-300)):249-nearest(10/20*(k-300)),281:289,k)); % correct with CS240X_Avg(3 and 4)
  CS240_White(k) = mean2(FLIR_Data(293-nearest(10/20*(k-300)):302-nearest(10/20*(k-300)),283:291,k)); % correct with CS240X_Avg(1 and 2)
  Soil_Temp(k) = mean2(FLIR_Data(290-nearest(10/20*(k-300)):309-nearest(10/20*(k-300)),374:395,k));
  Wet_Soil_Temp(k) = mean2(FLIR_Data(422-nearest(10/20*(k-300)):435-nearest(10/20*(k-300)),343:361,k));
  FLIR_Time(k)= datetime(FLIRFiles(k).name(1:15),'InputFormat','yyyyMMdd_HHmmss');
end
for k = 321:1180
  fullFLIRFileName = fullfile(FLIRDir, FLIRFiles(k).name);
  FLIR_Data(:,:,k) = imread(fullFLIRFileName);
  %imagesc(FLIR_Data(:,:,k))
  Full_Scene_Temp(k) = mean2(FLIR_Data(:,:,k));
  %FLIR_Data(Y1:Y2,X1:X2,k));
  CS240_Black(k) = mean2(FLIR_Data(231:239,281:289,k)); % correct with CS240X_Avg(3 and 4)
  CS240_White(k) = mean2(FLIR_Data(283:292,283:291,k)); % correct with CS240X_Avg(1 and 2)
  Soil_Temp(k) = mean2(FLIR_Data(280:299,374:395,k));
  Wet_Soil_Temp(k) = mean2(FLIR_Data(412:425,343:361,k));
  FLIR_Time(k)= datetime(FLIRFiles(k).name(1:15),'InputFormat','yyyyMMdd_HHmmss');
end
for k = 1181:1474
  fullFLIRFileName = fullfile(FLIRDir, FLIRFiles(k).name);
  FLIR_Data(:,:,k) = imread(fullFLIRFileName);
  %imagesc(FLIR_Data(:,:,k))
  Full_Scene_Temp(k) = mean2(FLIR_Data(:,:,k));
  %FLIR_Data(Y1:Y2,X1:X2,k));
  CS240_Black(k) = mean2(FLIR_Data(231-nearest(134/470*(k-1180)):239-nearest(134/470*(k-1180)),281:289,k)); % correct with CS240X_Avg(3 and 4)
  CS240_White(k) = mean2(FLIR_Data(283-nearest(134/470*(k-1180)):292-nearest(134/470*(k-1180)),283:291,k)); % correct with CS240X_Avg(1 and 2)
  Soil_Temp(k) = mean2(FLIR_Data(280-nearest(134/470*(k-1180)):299-nearest(134/470*(k-1180)),374:395,k));
  Wet_Soil_Temp(k) = mean2(FLIR_Data(412-nearest(134/470*(k-1180)):425-nearest(134/470*(k-1180)),343:361,k));
  FLIR_Time(k)= datetime(FLIRFiles(k).name(1:15),'InputFormat','yyyyMMdd_HHmmss');
end
for k = 1475:1507
  fullFLIRFileName = fullfile(FLIRDir, FLIRFiles(k).name);
  FLIR_Data(:,:,k) = imread(fullFLIRFileName);
  %imagesc(FLIR_Data(:,:,k))
  Full_Scene_Temp(k) = mean2(FLIR_Data(:,:,k));
  %FLIR_Data(Y1:Y2,X1:X2,k));
  CS240_Black(k) = mean2(FLIR_Data(133:139,281:289,k)); % correct with CS240X_Avg(3 and 4)
  CS240_White(k) = mean2(FLIR_Data(187:193,283:291,k)); % correct with CS240X_Avg(1 and 2)
  Soil_Temp(k) = mean2(FLIR_Data(181:200,374:395,k));
  Wet_Soil_Temp(k) = mean2(FLIR_Data(313:326,343:361,k));
  FLIR_Time(k)= datetime(FLIRFiles(k).name(1:15),'InputFormat','yyyyMMdd_HHmmss');
end
for k = 1508:1515
  fullFLIRFileName = fullfile(FLIRDir, FLIRFiles(k).name);
  FLIR_Data(:,:,k) = imread(fullFLIRFileName);
  %imagesc(FLIR_Data(:,:,k))
  Full_Scene_Temp(k) = mean2(FLIR_Data(:,:,k));
  %FLIR_Data(Y1:Y2,X1:X2,k));
  CS240_Black(k) = mean2(FLIR_Data(114:120,281:289,k)); % correct with CS240X_Avg(3 and 4)
  CS240_White(k) = mean2(FLIR_Data(165:173,283:291,k)); % correct with CS240X_Avg(1 and 2)
  Soil_Temp(k) = mean2(FLIR_Data(161:180,374:395,k));
  Wet_Soil_Temp(k) = mean2(FLIR_Data(293:306,343:361,k));
  FLIR_Time(k)= datetime(FLIRFiles(k).name(1:15),'InputFormat','yyyyMMdd_HHmmss');
end
for k = 1516:1579
  fullFLIRFileName = fullfile(FLIRDir, FLIRFiles(k).name);
  FLIR_Data(:,:,k) = imread(fullFLIRFileName);
  %imagesc(FLIR_Data(:,:,k))
  Full_Scene_Temp(k) = mean2(FLIR_Data(:,:,k));
  %FLIR_Data(Y1:Y2,X1:X2,k));
  CS240_Black(k) = mean2(FLIR_Data(112:118,281:289,k)); % correct with CS240X_Avg(3 and 4)
  CS240_White(k) = mean2(FLIR_Data(165:173,283:291,k)); % correct with CS240X_Avg(1 and 2)
  Soil_Temp(k) = mean2(FLIR_Data(161:180,374:395,k));
  Wet_Soil_Temp(k) = mean2(FLIR_Data(293:306,343:361,k));
  FLIR_Time(k)= datetime(FLIRFiles(k).name(1:15),'InputFormat','yyyyMMdd_HHmmss');
end
for k = 1580:1650
  fullFLIRFileName = fullfile(FLIRDir, FLIRFiles(k).name);
  FLIR_Data(:,:,k) = imread(fullFLIRFileName);
  %imagesc(FLIR_Data(:,:,k))
  Full_Scene_Temp(k) = mean2(FLIR_Data(:,:,k));
  %FLIR_Data(Y1:Y2,X1:X2,k));
  CS240_Black(k) = mean2(FLIR_Data(231-nearest(134/470*(k-1180)):239-nearest(134/470*(k-1180)),281:289,k)); % correct with CS240X_Avg(3 and 4)
  CS240_White(k) = mean2(FLIR_Data(283-nearest(134/470*(k-1180)):292-nearest(134/470*(k-1180)),283:291,k)); % correct with CS240X_Avg(1 and 2)
  Soil_Temp(k) = mean2(FLIR_Data(280-nearest(134/470*(k-1180)):299-nearest(134/470*(k-1180)),374:395,k));
  Wet_Soil_Temp(k) = mean2(FLIR_Data(412-nearest(134/470*(k-1180)):425-nearest(134/470*(k-1180)),343:361,k));
  FLIR_Time(k)= datetime(FLIRFiles(k).name(1:15),'InputFormat','yyyyMMdd_HHmmss');
end
for k = 1651:2690
  fullFLIRFileName = fullfile(FLIRDir, FLIRFiles(k).name);
  FLIR_Data(:,:,k) = imread(fullFLIRFileName);
  %imagesc(FLIR_Data(:,:,k))
  Full_Scene_Temp(k) = mean2(FLIR_Data(:,:,k));
  %FLIR_Data(Y1:Y2,X1:X2,k));
  CS240_Black(k) = mean2(FLIR_Data(97:105,281:289,k)); % correct with CS240X_Avg(3 and 4)
  CS240_White(k) = mean2(FLIR_Data(149:158,283:291,k)); % correct with CS240X_Avg(1 and 2)
  Soil_Temp(k) = mean2(FLIR_Data(146:165,374:395,k));
  Wet_Soil_Temp(k) = mean2(FLIR_Data(278:291,343:361,k));
  FLIR_Time(k)= datetime(FLIRFiles(k).name(1:15),'InputFormat','yyyyMMdd_HHmmss');
end
for k = 2691:2700
  fullFLIRFileName = fullfile(FLIRDir, FLIRFiles(k).name);
  FLIR_Data(:,:,k) = imread(fullFLIRFileName);
  %imagesc(FLIR_Data(:,:,k))
  Full_Scene_Temp(k) = mean2(FLIR_Data(:,:,k));
  %FLIR_Data(Y1:Y2,X1:X2,k));    
  CS240_Black(k) = mean2(FLIR_Data(91:98,276:290,k)); % correct with CS240X_Avg(3 and 4)
  CS240_White(k) = mean2(FLIR_Data(147:154,279:293,k)); % correct with CS240X_Avg(1 and 2)
  Soil_Temp(k) = mean2(FLIR_Data(135:154,374:395,k));
  Wet_Soil_Temp(k) = mean2(FLIR_Data(269:284,343:361,k));
  FLIR_Time(k)= datetime(FLIRFiles(k).name(1:15),'InputFormat','yyyyMMdd_HHmmss');
end
for k = 2701:2769
  fullFLIRFileName = fullfile(FLIRDir, FLIRFiles(k).name);
  FLIR_Data(:,:,k) = imread(fullFLIRFileName);
  %imagesc(FLIR_Data(:,:,k))
  Full_Scene_Temp(k) = mean2(FLIR_Data(:,:,k));
  %FLIR_Data(Y1:Y2,X1:X2,k));    
  CS240_Black(k) = mean2(FLIR_Data(78:85,276:290,k)); % correct with CS240X_Avg(3 and 4)
  CS240_White(k) = mean2(FLIR_Data(133:140,279:293,k)); % correct with CS240X_Avg(1 and 2)
  Soil_Temp(k) = mean2(FLIR_Data(121:140,374:395,k));
  Wet_Soil_Temp(k) = mean2(FLIR_Data(255:270,343:361,k));
  FLIR_Time(k)= datetime(FLIRFiles(k).name(1:15),'InputFormat','yyyyMMdd_HHmmss');
end
for k = 2770:2923
  fullFLIRFileName = fullfile(FLIRDir, FLIRFiles(k).name);
  FLIR_Data(:,:,k) = imread(fullFLIRFileName);
  %imagesc(FLIR_Data(:,:,k))
  Full_Scene_Temp(k) = mean2(FLIR_Data(:,:,k));
  %FLIR_Data(Y1:Y2,X1:X2,k));    
  CS240_Black(k) = mean2(FLIR_Data(108-nearest(104/260*(k-2690)):114-nearest(104/260*(k-2690)),276:290,k)); % correct with CS240X_Avg(3 and 4)
  CS240_White(k) = mean2(FLIR_Data(151-nearest(100/260*(k-2690)):165-nearest(100/260*(k-2690)),279:293,k)); % correct with CS240X_Avg(1 and 2)
  Soil_Temp(k) = mean2(FLIR_Data(146-nearest(100/260*(k-2690)):165-nearest(100/260*(k-2690)),374:395,k));
  Wet_Soil_Temp(k) = mean2(FLIR_Data(278-nearest(100/260*(k-2690)):291-nearest(100/260*(k-2690)),343:361,k));
  FLIR_Time(k)= datetime(FLIRFiles(k).name(1:15),'InputFormat','yyyyMMdd_HHmmss');
end
for k = 2876:2879
  fullFLIRFileName = fullfile(FLIRDir, FLIRFiles(k).name);
  FLIR_Data(:,:,k) = imread(fullFLIRFileName);
  %imagesc(FLIR_Data(:,:,k))
  Full_Scene_Temp(k) = mean2(FLIR_Data(:,:,k));
  %FLIR_Data(Y1:Y2,X1:X2,k));    
  CS240_Black(k) = mean2(FLIR_Data(23:30,276:290,k)); % correct with CS240X_Avg(3 and 4)
  CS240_White(k) = mean2(FLIR_Data(82:88,279:293,k)); % correct with CS240X_Avg(1 and 2)
  Soil_Temp(k) = mean2(FLIR_Data(82:88,374:395,k));
  Wet_Soil_Temp(k) = mean2(FLIR_Data(212:222,343:361,k));
  FLIR_Time(k)= datetime(FLIRFiles(k).name(1:15),'InputFormat','yyyyMMdd_HHmmss');
end
for k = 2924:2934
  fullFLIRFileName = fullfile(FLIRDir, FLIRFiles(k).name);
  FLIR_Data(:,:,k) = imread(fullFLIRFileName);
  %imagesc(FLIR_Data(:,:,k))
  Full_Scene_Temp(k) = mean2(FLIR_Data(:,:,k));
  %FLIR_Data(Y1:Y2,X1:X2,k));    
  CS240_Black(k) = mean2(FLIR_Data(12:20,276:290,k)); % correct with CS240X_Avg(3 and 4)
  CS240_White(k) = mean2(FLIR_Data(72:80,279:293,k)); % correct with CS240X_Avg(1 and 2)
  Soil_Temp(k) = mean2(FLIR_Data(72:80,374:395,k));
  Wet_Soil_Temp(k) = mean2(FLIR_Data(205:212,343:361,k));
  FLIR_Time(k)= datetime(FLIRFiles(k).name(1:15),'InputFormat','yyyyMMdd_HHmmss');
end
for k = 2935:4018
  fullFLIRFileName = fullfile(FLIRDir, FLIRFiles(k).name);
  FLIR_Data(:,:,k) = imread(fullFLIRFileName);
  %imagesc(FLIR_Data(:,:,k))
  Full_Scene_Temp(k) = mean2(FLIR_Data(:,:,k));
  %FLIR_Data(Y1:Y2,X1:X2,k));    
  CS240_Black(k) = mean2(FLIR_Data(4:10,276:290,k)); % correct with CS240X_Avg(3 and 4)
  CS240_White(k) = mean2(FLIR_Data(51:65,279:293,k)); % correct with CS240X_Avg(1 and 2)
  Soil_Temp(k) = mean2(FLIR_Data(46:65,374:395,k));
  Wet_Soil_Temp(k) = mean2(FLIR_Data(178:191,343:361,k));
  FLIR_Time(k)= datetime(FLIRFiles(k).name(1:15),'InputFormat','yyyyMMdd_HHmmss');
end
for k = 4019:length(FLIRFiles)
  fullFLIRFileName = fullfile(FLIRDir, FLIRFiles(k).name);
  FLIR_Data(:,:,k) = imread(fullFLIRFileName);
  %imagesc(FLIR_Data(:,:,k))
  Full_Scene_Temp(k) = mean2(FLIR_Data(:,:,k));
  %FLIR_Data(Y1:Y2,X1:X2,k));    
  CS240_Black(k) = mean2(FLIR_Data(95:111,315:330,k)); % correct with CS240X_Avg(3 and 4)
  CS240_White(k) = mean2(FLIR_Data(51:65,279:293,k)); % correct with CS240X_Avg(1 and 2)
  Soil_Temp(k) = mean2(FLIR_Data(46:65,374:395,k));
  Wet_Soil_Temp(k) = mean2(FLIR_Data(178:191,343:361,k));
  FLIR_Time(k)= datetime(FLIRFiles(k).name(1:15),'InputFormat','yyyyMMdd_HHmmss');
end
toc

%% Plot Data

tstart=datetime(2021,05,11,14,15,0); 
tend=datetime(2021,05,14,10,45,0);

%FLIR surface temp
% figure(1)
% %X =1:1:length(FLIRFiles);
% %plot(FLIR_Time,Dry_Point_Temp(:,1)-Full_Scene_Temp(:,1));
% plot(FLIR_Time,Dry_Point_Temp(:,1));
% legend('Dry');
% xlim([tstart tend]);

%FLIR and sensor cal target temp
SBlackMean = mean([LoggerData.CS240T_C1 LoggerData.CS240T_C2],2);
SWhiteMean = mean([LoggerData.CS240T_C3 LoggerData.CS240T_C4],2);
figure(1)
plot(FLIR_Time,CS240_Black(:,1),FLIR_Time,CS240_White(:,1),LoggerData.TIMESTAMP,SBlackMean,LoggerData.TIMESTAMP,SWhiteMean);
legend('FLIRBlack','FLIRWhite','SBlack','SWhite');
xlim([tstart tend]);
xlabel('Temp (C)');

%Corrected FLIR Surface Temp
DrySurf = timetable(FLIR_Time',Soil_Temp(:,1));
WetSurf = timetable(FLIR_Time',Wet_Soil_Temp(:,1));
FLIRBlack = timetable(FLIR_Time',CS240_Black(:,1));
FLIRWhite = timetable(FLIR_Time',CS240_White(:,1));
% SensorBlack = timetable(LoggerData.TIMESTAMP,SBlackMean);
% SensorWhite = timetable(LoggerData.TIMESTAMP,SWhiteMean);
%SyncedVars = synchronize(FLIRBlack,SensorBlack,FLIRWhite,SensorWhite,DrySurf,WetSurf,'union','linear');
%SyncedVars = synchronize(FLIRBlack,SensorBlack,FLIRWhite,SensorWhite,DrySurf,'union','linear');
AllData = synchronize(LoggerData,FLIRBlack,FLIRWhite,DrySurf,WetSurf,'Minutely','linear');
SBlackMean = mean([AllData.CS240T_C1 AllData.CS240T_C2],2);
SWhiteMean = mean([AllData.CS240T_C3 AllData.CS240T_C4],2);
Noise = mean([AllData.Var1_FLIRBlack-SBlackMean,AllData.Var1_FLIRWhite-SWhiteMean],2);
figure(2)
plot(AllData.TIMESTAMP,Noise);
legend('FLIR Noise')
xlim([tstart tend]);
ylabel('Temp (C)');

Corrected_Dry_Point_Temp = AllData.Var1_DrySurf-Noise;
Corrected_Wet_Point_Temp = AllData.Var1_WetSurf-Noise;
figure(3)
plot(AllData.TIMESTAMP,Corrected_Dry_Point_Temp);
hold on
plot(AllData.TIMESTAMP,Corrected_Wet_Point_Temp);
plot(AllData.TIMESTAMP,AllData.T109_C1);
plot(AllData.TIMESTAMP,AllData.AirTC);
ylabel('Temp (C)');
yyaxis right
plot(AllData.TIMESTAMP,AllData.Rn_Avg);
%plot(AllData.TIMESTAMP,AllData.WS_ms_10);
legend('Corrected FLIR Dry', 'Corrected FLIR Wet','Ground Probe 1', 'Air Temp', 'Net Irradiance');
xlim([tstart tend]);
ylabel('Net Downward Irradiance (W/m^2)')
%ylabel('Wind Speed (m/s)');

figure(4)
plot(AllData.TIMESTAMP,AllData.WS_ms_10);
ylabel('Wind Speed (m/s)');
xlim([tstart tend]);


%% Resample data
TT = retime(AllData,'regular','mean','TimeStep',minutes(6));

%% Saved

%Corrected and uncorrected surface temp
% figure(4)
% plot(FLIR_Time,Soil_Temp(:,1));
% hold on
% plot(FLIR_Time,Soil_Temp(:,1)-Full_Scene_Temp(:,1));
% plot(AllData.Time,Corrected_Dry_Point_Temp);
% legend('Raw','Relative','Corrected');
% xlim([tstart tend]);
% xlabel('Temp (C)');

% %Soil and Air Temps
% figure(4)
% plot(LogData.TIMESTAMP,LogData.AirTC_Avg,'c',LogData.TIMESTAMP,LogData.T109_C_Avg1,'r',...
%     LogData.TIMESTAMP,LogData.T109_C_Avg3,'--r',LogData.TIMESTAMP,LogData.T109_C_Avg5,'-.r',...
%     LogData.TIMESTAMP,LogData.T109_C_Avg12,':r',LogData.TIMESTAMP,LogData.SoilTemp1,'g',...
%     LogData.TIMESTAMP,LogData.SoilTemp2,'--g',LogData.TIMESTAMP,LogData.SoilTemp4,'-.g',...
%     LogData.TIMESTAMP,LogData.SoilTemp5,':g',LogData.TIMESTAMP,LogData.SoilTemp3,'b',...
%     LogData.TIMESTAMP,LogData.SoilTemp6,'--b')
% L = legend('Air','DrySoil1','DrySoil2','DrySoil3','DrySoil4','DrySoil5*', 'DrySoil6*', 'DrySoil7*', 'DrySoil8*',...
%     'WetSoil1*','WetSoil2*');
% Ltitle = get(L,'Title');
% set(Ltitle,'String','Temp ^{\circ}C');
% xlim([tstart tend]);
% 
% %Soil Moisture
% figure(5)
% % plot(mindata.TIMESTAMP,mindata.VWC6,'r',mindata.TIMESTAMP,mindata.VWC3,'--r',...
% %     mindata.TIMESTAMP,mindata.VWC_51,'b',mindata.TIMESTAMP,mindata.VWC_54,'--b',...
% %     mindata.TIMESTAMP,mindata.VWC_101,'g',mindata.TIMESTAMP,mindata.VWC_104,'--g',...
% %     mindata.TIMESTAMP,mindata.VWC_201,'c',mindata.TIMESTAMP,mindata.VWC_204,'--c',...
% %     mindata.TIMESTAMP,mindata.VWC_401,'m',mindata.TIMESTAMP,mindata.VWC_404,'--m');
% % L = legend('DrySurface','WetSurface','Dry5d','Wet5d','Dry10d','Wet10d','Dry20d','Wet20d',...
% %     'Dry40d','Wet40d');
% plot(LogData.TIMESTAMP,LogData.VWC1,'r',LogData.TIMESTAMP,LogData.VWC3,'-b',...
%     LogData.TIMESTAMP,LogData.VWC_51,'--r',LogData.TIMESTAMP,LogData.VWC_54,'--b',...
%     LogData.TIMESTAMP,LogData.VWC_401,':r',LogData.TIMESTAMP,LogData.VWC_404,':b');
% L = legend('DrySurface','WetSurface','Dry5d','Wet5d','Dry40d','Wet40d');
% Ltitle = get(L,'Title');
% set(Ltitle,'String','VWC (%)');
% xlim([tstart tend]);

% Time Snaps
% figure(6)
% last = 214;
% idx1 = last - 45;
% idx2 = last - 35;
% idx3 = last - 3;
% depth = [0 5 10 20 30 40 50 60 75 100]; 
% DrySoilVue1 = [LogData.VWC1(idx1), LogData.VWC_51(idx1), LogData.VWC_101(idx1), LogData.VWC_201(idx1),...
%     LogData.VWC_301(idx1),LogData.VWC_401(idx1), LogData.VWC_501(idx1), LogData.VWC_601(idx1),...
%     LogData.VWC_751(idx1), LogData.VWC_1001(idx1)];
% WetSoilVue1 = [LogData.VWC3(idx1), LogData.VWC_54(idx1), LogData.VWC_104(idx1), LogData.VWC_204(idx1),...
%     LogData.VWC_304(idx1),LogData.VWC_404(idx1), LogData.VWC_504(idx1), LogData.VWC_604(idx1),...
%     LogData.VWC_754(idx1), LogData.VWC_1004(idx1)];
% plot(depth,DrySoilVue1,'-r',depth,WetSoilVue1,'-b');
% hold on 
% DrySoilVue2 = [LogData.VWC1(idx2), LogData.VWC_51(idx2), LogData.VWC_101(idx2), LogData.VWC_201(idx2),...
%     LogData.VWC_301(idx2),LogData.VWC_401(idx2), LogData.VWC_501(idx2), LogData.VWC_601(idx2),...
%     LogData.VWC_751(idx2), LogData.VWC_1001(idx2)];
% WetSoilVue2 = [LogData.VWC3(idx2), LogData.VWC_54(idx2), LogData.VWC_104(idx2), LogData.VWC_204(idx2),...
%     LogData.VWC_304(idx2),LogData.VWC_404(idx2), LogData.VWC_504(idx2), LogData.VWC_604(idx2),...
%     LogData.VWC_754(idx2), LogData.VWC_1004(idx2)];
% plot(depth,DrySoilVue2,'--r',depth,WetSoilVue2,'--b');
% 
% DrySoilVue3 = [LogData.VWC1(idx3), LogData.VWC_51(idx3), LogData.VWC_101(idx3), LogData.VWC_201(idx3),...
%     LogData.VWC_301(idx3),LogData.VWC_401(idx3), LogData.VWC_501(idx3), LogData.VWC_601(idx3),...
%     LogData.VWC_751(idx3), LogData.VWC_1001(idx3)];
% WetSoilVue3 = [LogData.VWC3(idx3), LogData.VWC_54(idx3), LogData.VWC_104(idx3), LogData.VWC_204(idx3),...
%     LogData.VWC_304(idx3),LogData.VWC_404(idx3), LogData.VWC_504(idx3), LogData.VWC_604(idx3),...
%     LogData.VWC_754(idx3), LogData.VWC_1004(idx3)];
% plot(depth,DrySoilVue3,':r',depth,WetSoilVue3,':b');
% 
% hold off
% str1 = char(LogData.TIMESTAMP(idx1));str2 = char(LogData.TIMESTAMP(idx2));
% str3 = char(LogData.TIMESTAMP(idx3));
% L = legend(['Dry ' str1],['Wet ' str1],['Dry ' str2],['Wet ' str2],['Dry ' str3],['Wet ' str3]);
% Ltitle = get(L,'Title');
% set(Ltitle,'String','VWC (%)');
% 
% % 109SS Temps
% figure(7)
% plot(x15mindata.TIMESTAMP,x15mindata.T109_C_Avg1,'c',x15mindata.TIMESTAMP,x15mindata.T109_C_Avg2,'r',...
%     x15mindata.TIMESTAMP,x15mindata.T109_C_Avg3,'--r',x15mindata.TIMESTAMP,x15mindata.T109_C_Avg4,'-.r',...
%     x15mindata.TIMESTAMP,x15mindata.T109_C_Avg5,':r',x15mindata.TIMESTAMP,x15mindata.T109_C_Avg6,'g',...
%     x15mindata.TIMESTAMP,x15mindata.T109_C_Avg7,'--g',x15mindata.TIMESTAMP,x15mindata.T109_C_Avg8,'-.g',...
%     x15mindata.TIMESTAMP,x15mindata.T109_C_Avg9,':g',x15mindata.TIMESTAMP,x15mindata.T109_C_Avg10,'b',...
%     x15mindata.TIMESTAMP,x15mindata.T109_C_Avg11,'--b',x15mindata.TIMESTAMP,x15mindata.T109_C_Avg12,'k')
% L = legend('1','2','3','4','5','6', '7', '8', '9','10','11','12');
% Ltitle = get(L,'Title');
% set(Ltitle,'String','Temp ^{\circ}C');
% xlim([tstart tend]);