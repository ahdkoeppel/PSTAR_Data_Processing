%% Code for Reading in and plotting ground station CR1000X  and FLIR duo Pro data
% Ari Koeppel - 2021
% Temperature positions change by +-nearest(#of pixels/# of images(indices)*(k-first index where change starts))
clear
close all;

%% Import Data
% Dir = input('Enter full FLIR Image Directory (i.e. "C:\\Users\\akoeppel\\Desktop\\"):  ','s');
LogDir1Min = uigetdir('X:\common\FIELD_CAMPAIGNS\Iceland_May2022\Thermophysical_Data\Lower_Fan\','Directory of 1 min Logger Data');%gets directory
FLIRDir = uigetdir('X:\common\FIELD_CAMPAIGNS\Iceland_May2022\Thermophysical_Data\Lower_Fan\FLIR_Corr','Directory of temp-corrected FLIR .tiffs');%gets directory
fprintf(1, 'Now reading files from %s and %s\n', LogDir1Min, FLIRDir);
tic

%Get data from CR1000X
LogFile1Min = dir(fullfile(LogDir1Min,'*.mat')); %gets all files
fullLogFileName1Min = fullfile(LogDir1Min, LogFile1Min.name);
LoggerData = struct2cell(load(fullfile(LogDir1Min, LogFile1Min.name)));
LoggerData = LoggerData{:,:};
%Correct from GMT-7 time (+7) --- Local time is GMT
LoggerData.TIMESTAMP = LoggerData.TIMESTAMP + hours(7);
LoggerData = table2timetable(LoggerData);

%Get data from FLIR images
FLIRFiles = dir(fullfile(FLIRDir,'*.tiff')); %gets all files
fullFLIRFileName = fullfile(FLIRDir, FLIRFiles(1).name);
first = imread(fullFLIRFileName);
FLIR_Data = zeros(size(first,1),size(first,2),length(FLIRFiles));
Full_Scene_Temp = zeros(size(FLIRFiles));
CS240 = zeros(size(FLIRFiles));
Soil_1to100cm_small = zeros(size(FLIRFiles));
Soil_100to200cm_large = zeros(size(FLIRFiles));
Vesicular_Basalt_Cobble = zeros(size(FLIRFiles));
Rounded_Dark_Cobble = zeros(size(FLIRFiles));
Broken_Light_Cobble = zeros(size(FLIRFiles));
Intact_Light_Cobble = zeros(size(FLIRFiles));

Center_Temp = zeros(size(FLIRFiles));
Corner = zeros(size(FLIRFiles));
Flat = zeros(size(first,1),size(first,2),length(FLIRFiles));
FLIR_Data_Corr = Flat;

%% Obtain Flat Field
% It is necessary to calculate and correct for a dynamic flat field
% since the instument temperature changes and affects the flat field
% differently during day and night.
for k = 1:length(FLIRFiles)
  fullFLIRFileName = fullfile(FLIRDir, FLIRFiles(k).name);
  FLIR_Data(:,:,k) = imread(fullFLIRFileName);
  %imagesc(FLIR_Data(:,:,k))
%   Center_Temp(k) = mean2(Box_filt(size(Box_filt,1)/2-5:size(Box_filt,1)/2+5,size(Box_filt,2)/2-5:size(Box_filt,2)/2+5,k));
  Box_filt = imboxfilt(FLIR_Data(:,:,k),191);
  Center_Temp(k) = mean2(Box_filt(size(Box_filt,1)/2-5:size(Box_filt,1)/2+5,size(Box_filt,2)/2-5:size(Box_filt,2)/2+5));
  Corner(k) = mean2(Box_filt(434:492,555:620));
  Flat(:,:,k) = Box_filt-Center_Temp(k);
  %FLIR_Data(Y1:Y2,X1:X2,k));
end


%Calculate average and median flat field pattern
Im_corr_mn = mean(Flat,3);
Center_Im_corr_mn = mean2(Im_corr_mn(size(Im_corr_mn,1)/2-5:size(Im_corr_mn,1)/2+5,size(Im_corr_mn,2)/2-5:size(Im_corr_mn,2)/2+5));
Corner_Im_corr_mn = mean2(Im_corr_mn(434:492,555:620));
Im_corr_md = median(Flat,3);
Center_Im_corr_md = mean2(Im_corr_md(size(Im_corr_md,1)/2-5:size(Im_corr_md,1)/2+5,size(Im_corr_md,2)/2-5:size(Im_corr_md,2)/2+5));
Corner_Im_corr_md = mean2(Im_corr_md(434:492,555:620));
imshowpair(Im_corr_mn,Im_corr_md,'montage');
%Calculate how intensly the flat field applies to each image 
Ratio = (Corner-Center_Temp)/(Corner_Im_corr_mn-Center_Im_corr_mn);

%Correct flat field and calculate FLIR temperature for ROIs
for k = 1:length(FLIRFiles)
    FLIR_Data_Corr(:,:,k) = FLIR_Data(:,:,k) - Im_corr_mn;%.*Ratio(k);
end

%% Extract temperatures of (moving) ROIs
for k = 1:length(FLIRFiles)
  %FLIR_Data(Y1:Y2,X1:X2,k));
  CS240(k) = mean2(FLIR_Data_Corr(192:227,289:325,k)); % correct with CS240X_Avg(1 and 2)
  Soil_1to100cm_small(k) = mean2(FLIR_Data_Corr(36:260,354:417,k));
  Soil_100to200cm_large(k) = mean2(FLIR_Data_Corr(346:389,293:410,k));
  Vesicular_Basalt_Cobble(k) = mean2(FLIR_Data_Corr(299:325,433:445,k));
  Rounded_Dark_Cobble(k) = mean2(FLIR_Data_Corr(374:394,558:563,k));
  Broken_Light_Cobble(k) = mean2(FLIR_Data_Corr(309:321,467:482,k));
  Intact_Light_Cobble(k) = mean2(FLIR_Data_Corr(414:423,384:398,k));
  FLIR_Time(k)= datetime(FLIRFiles(k).name(1:15),'InputFormat','yyyyMMdd_HHmmss');
end
toc

%% Plot Data

tstart=datetime(2022,05,24,13,50,0); 
tend=datetime(2022,05,28,10,39,0);

%FLIR surface temp
% figure(1)
% %X =1:1:length(FLIRFiles);
% %plot(FLIR_Time,Dry_Point_Temp(:,1)-Full_Scene_Temp(:,1));
% plot(FLIR_Time,Dry_Point_Temp(:,1));
% legend('Dry');
% xlim([tstart tend]);

%FLIR and sensor cal target temp
SBlackMean = mean([LoggerData.CS240T_C_Avg LoggerData.CS240T_C_2_Avg],2);
figure(1)
plot(FLIR_Time,CS240(:),LoggerData.TIMESTAMP,SBlackMean);
legend('FLIRBlack','SBlack');
xlim([tstart tend]);
xlabel('Temp (C)');


%Corrected FLIR Surface Temp
FLIR_Time = FLIR_Time - seconds(12); %to make it on the even minute
FLIR_CS240_Sync = timetable(FLIR_Time',CS240(:,1));
Soil_1to100cm_small_Sync = timetable(FLIR_Time',Soil_1to100cm_small(:,1));
Soil_100to200cm_large_Sync = timetable(FLIR_Time',Soil_100to200cm_large(:,1));
Vesicular_Basalt_Cobble_Sync = timetable(FLIR_Time',Vesicular_Basalt_Cobble(:,1));
Rounded_Dark_Cobble_Sync = timetable(FLIR_Time',Rounded_Dark_Cobble(:,1));
Broken_Light_Cobble_Sync = timetable(FLIR_Time',Broken_Light_Cobble(:,1));
Intact_Light_Cobble_Sync = timetable(FLIR_Time',Intact_Light_Cobble(:,1));

AllData = synchronize(LoggerData,FLIR_CS240_Sync,Soil_1to100cm_small_Sync,Soil_100to200cm_large_Sync,Vesicular_Basalt_Cobble_Sync,Rounded_Dark_Cobble_Sync,Broken_Light_Cobble_Sync,Intact_Light_Cobble_Sync,'Minutely','firstvalue');%'linear');

LoggerCS240Mean = mean([AllData.CS240T_C_Avg AllData.CS240T_C_2_Avg],2);
Noise = AllData.FLIR_CS240_Sync-LoggerCS240Mean;
figure(2)
plot(AllData.TIMESTAMP,Noise);
legend('FLIR Noise')
xlim([tstart tend]);
ylabel('Temp (C)');

AllData.Soil_1to100cm_small_Corr = AllData.Soil_1to100cm_small_Sync -Noise;
AllData.Soil_100to200cm_large_Corr = AllData.Soil_100to200cm_large_Sync - Noise;
AllData.Vesicular_Basalt_Cobble_Corr = AllData.Vesicular_Basalt_Cobble_Sync - Noise;
AllData.Rounded_Dark_Cobble_Corr = AllData.Rounded_Dark_Cobble_Sync - Noise;
AllData.Broken_Light_Cobble_Corr = AllData.Broken_Light_Cobble_Sync - Noise;
AllData.Intact_Light_Cobble_Corr = AllData.Intact_Light_Cobble_Sync - Noise;

figure(3)
plot(AllData.TIMESTAMP,AllData.Soil_1to100cm_small_Corr);
hold on
plot(AllData.TIMESTAMP,AllData.Soil_100to200cm_large_Corr);
plot(AllData.TIMESTAMP,AllData.Vesicular_Basalt_Cobble_Corr);
plot(AllData.TIMESTAMP,AllData.Broken_Light_Cobble_Corr);
plot(AllData.TIMESTAMP,AllData.T_Avg);
plot(AllData.TIMESTAMP,AllData.AirTC_Avg);
ylabel('Temp (C)');
% yyaxis right
% plot(AllData.TIMESTAMP,AllData.Rn_Avg);
%plot(AllData.TIMESTAMP,AllData.WS_ms_10);
legend('Soil_small', 'Soil_large','Vesicular Basalt', 'Broken Felsic', 'Logger Surf Temp', 'Air T')%, 'Rn');
xlim([tstart tend]);
ylabel('Net Downward Irradiance (W/m^2)')
%ylabel('Wind Speed (m/s)');

figure(4)
plot(AllData.TIMESTAMP,AllData.WS_ms_Avg);
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