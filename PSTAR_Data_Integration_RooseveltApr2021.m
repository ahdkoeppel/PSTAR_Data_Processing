%% Code for Reading in and plotting ground station CR1000X  and FLIR duo Pro data
% Ari Koeppel - 2020
clear
close all;

%% Import Data
% Dir = input('Enter full FLIR Image Directory (i.e. "C:\\Users\\akoeppel\\Desktop\\"):  ','s');
FLIRDir = uigetdir('X:\common\','Directory of temp-corrected FLIR .tiffs');%gets directory
LogDir = uigetdir('X:\common\','Directory of 1 min Logger Data');%gets directory
fprintf(1, 'Now reading files from %s and %s\n', LogDir, FLIRDir);
tic

%Get data from CR1000X
LogFile = dir(fullfile(LogDir,'*.mat')); %gets all files
fullLogFileName = fullfile(LogDir, LogFile.name);
load(fullfile(LogDir, LogFile.name))

%Correct GMT time (-7)
%LogData.TIMESTAMP = LogData.TIMESTAMP - hours(7);


%Get data from FLIR images
FLIRFiles = dir(fullfile(FLIRDir,'*.tiff')); %gets all files
fullFLIRFileName = fullfile(FLIRDir, FLIRFiles(1).name);
first = imread(fullFLIRFileName);
FLIR_Data = zeros(size(first,1),size(first,2),length(FLIRFiles));
Soil_Temp = zeros(length(FLIRFiles));
Full_Scene_Temp = zeros(length(FLIRFiles));
CS240_Black = zeros(length(FLIRFiles));
CS240_White = zeros(length(FLIRFiles));
for k = 1:length(FLIRFiles)
  fullFLIRFileName = fullfile(FLIRDir, FLIRFiles(k).name);
  FLIR_Data(:,:,k) = imread(fullFLIRFileName);
  Full_Scene_Temp(k) = mean2(FLIR_Data(:,:,k));
  %FLIR_Data(Y1:Y2,X1:X2,k));
  Soil_Temp(k) = mean2(FLIR_Data(325:380,170:231,k));
  CS240_Black(k) = mean2(FLIR_Data(357:392,266:303,k)); % correct with CS240X_Avg(3 and 4)
  CS240_White(k) = mean2(FLIR_Data(283:306,259:295,k)); % correct with CS240X_Avg(1 and 2)
  FLIR_Time(k)= datetime(FLIRFiles(k).name(1:15),'InputFormat','yyyyMMdd_HHmmss')-hours(1);
end
toc

%% Resample data

%% Plot Data

tstart=datetime(2021,04,06,13,00,0); 
tend=datetime(2021,04,07,12,52,0);

%FLIR surface temp
% figure(1)
% %X =1:1:length(FLIRFiles);
% %plot(FLIR_Time,Dry_Point_Temp(:,1)-Full_Scene_Temp(:,1));
% plot(FLIR_Time,Dry_Point_Temp(:,1));
% legend('Dry');
% xlim([tstart tend]);

%FLIR and sensor cal target temp
SBlackMean = mean([LogData.CS240T_C_3_Avg LogData.CS240T_C_4_Avg],2);
SWhiteMean = mean([LogData.CS240T_C_Avg LogData.CS240T_C_2_Avg],2);
figure(1)
plot(FLIR_Time,CS240_Black(:,1),FLIR_Time,CS240_White(:,1),LogData.TIMESTAMP,SBlackMean,LogData.TIMESTAMP,SWhiteMean);
legend('FLIRBlack','FLIRWhite','SBlack','SWhite');
xlim([tstart tend]);
xlabel('Temp (C)');

%Corrected FLIR Surface Temp
DrySurf = timetable(FLIR_Time',Soil_Temp(:,1));
% WetSurf = timetable(FLIR_Time',Wet_Point_Temp(:,1));
FLIRBlack = timetable(FLIR_Time',CS240_Black(:,1));
FLIRWhite = timetable(FLIR_Time',CS240_White(:,1));
SensorBlack = timetable(LogData.TIMESTAMP,SBlackMean);
SensorWhite = timetable(LogData.TIMESTAMP,SWhiteMean);
%SyncedVars = synchronize(FLIRBlack,SensorBlack,FLIRWhite,SensorWhite,DrySurf,WetSurf,'union','linear');
SyncedVars = synchronize(FLIRBlack,SensorBlack,FLIRWhite,SensorWhite,DrySurf,'Minutely','linear');
Noise = mean([SyncedVars.Var1_FLIRBlack-SyncedVars.Var1_SensorBlack,SyncedVars.Var1_FLIRWhite-SyncedVars.Var1_SensorWhite],2);
figure(2)
plot(SyncedVars.Time,Noise);
legend('FLIR Noise')
xlim([tstart tend]);
xlabel('Temp (C)');

Corrected_Dry_Point_Temp = SyncedVars.Var1_DrySurf-Noise;
Corr_Dry_Point_Temp = timetable(SyncedVars.Time,Corrected_Dry_Point_Temp);
% Corrected_Wet_Point_Temp = SyncedVars.Var1_WetSurf-Noise;
figure(3)
plot(SyncedVars.Time,Corrected_Dry_Point_Temp);
hold on
% plot(SyncedVars.Time,Corrected_Wet_Point_Temp);
plot(LogData.TIMESTAMP,LogData.T_Avg);
plot(LogData.TIMESTAMP,LogData.T_2_Avg);
plot(LogData.TIMESTAMP,LogData.AirTC_Avg);
legend('Corrected FLIR Dry', 'Ground Probe 1', 'Ground Probe 2', 'Air');
xlim([tstart tend]);
xlabel('Temp (C)');

%Corrected and uncorrected surface temp
figure(4)
plot(FLIR_Time,Soil_Temp(:,1));
hold on
plot(FLIR_Time,Soil_Temp(:,1)-Full_Scene_Temp(:,1));
plot(SyncedVars.Time,Corrected_Dry_Point_Temp);
legend('Raw','Relative','Corrected');
xlim([tstart tend]);
xlabel('Temp (C)');

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