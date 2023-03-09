%% Code for Reading in and plotting ground station CR1000X  and FLIR duo Pro data
% Ari Koeppel - 2021
% Temperature positions change by +-nearest(#of pixels/# of images(indices)*(k-first index where change starts))
clear
close all;

%% Import Data
% Dir = input('Enter full FLIR Image Directory (i.e. "C:\\Users\\akoeppel\\Desktop\\"):  ','s');
LogDir1Min = uigetdir('X:\common\','Directory of 1 min Logger Data');%gets directory
FLIRDir = uigetdir('X:\common\','Directory of temp-corrected FLIR .tiffs');%gets directory
fprintf(1, 'Now reading files from %s and %s\n', LogDir1Min, FLIRDir);
tic

%Get data from CR1000X
LogFile1Min = dir(fullfile(LogDir1Min,'*.mat')); %gets all files
fullLogFileName1Min = fullfile(LogDir1Min, LogFile1Min.name);
LoggerData = struct2cell(load(fullfile(LogDir1Min, LogFile1Min.name)));
LoggerData = LoggerData{:,:};
%Correct GMT time (-7)
LoggerData.TIMESTAMP = LoggerData.TIMESTAMP - hours(7);
%LoggerData = table2timetable(LoggerData);

%Get data from FLIR images
FLIRFiles = dir(fullfile(FLIRDir,'*TempC.tiff')); %gets all files
fullFLIRFileName = fullfile(FLIRDir, FLIRFiles(1).name);
first = imread(fullFLIRFileName);
FLIR_Data = zeros(size(first,1),size(first,2),length(FLIRFiles));
Full_Scene_Temp = zeros(size(FLIRFiles));
CS240 = zeros(size(FLIRFiles));
Soil_11 = zeros(size(FLIRFiles));
Soil_12 = zeros(size(FLIRFiles));
Soil_13 = zeros(size(FLIRFiles));
PHH_21 = zeros(size(FLIRFiles));
PHH_22 = zeros(size(FLIRFiles));
Basalt_22 = zeros(size(FLIRFiles));
Tuff_23 = zeros(size(FLIRFiles));
Soil_bw_rock_23 = zeros(size(FLIRFiles));

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
for k = 1:40
  %FLIR_Data(Y1:Y2,X1:X2,k));
  CS240(k) = mean2(FLIR_Data_Corr(462:485,138:159,k)); % correct with CS240X_Avg(1 and 2)
  Soil_11(k) = mean2(FLIR_Data_Corr(31:70,509:607,k));
  Soil_12(k) = mean2(FLIR_Data_Corr(170:250,525:620,k));
  Soil_13(k) = mean2(FLIR_Data_Corr(309:402,525:620,k));
  PHH_21(k) = mean2(FLIR_Data_Corr(16:30,376:398,k));
  PHH_22(k) = NaN;
  Basalt_22(k) = NaN;
  Tuff_23(k) = NaN;
  Soil_bw_rock_23(k) = NaN;
  FLIR_Time(k)= datetime(FLIRFiles(k).name(1:15),'InputFormat','yyyyMMdd_HHmmss');
end
for k = 41
  %FLIR_Data(Y1:Y2,X1:X2,k));
  CS240(k) = mean2(FLIR_Data_Corr(336:356,89:105,k)); % correct with CS240X_Avg(1 and 2)
  Soil_11(k) = mean2(FLIR_Data_Corr(31:70,509:607,k));
  Soil_12(k) = mean2(FLIR_Data_Corr(170:250,525:620,k));
  Soil_13(k) = mean2(FLIR_Data_Corr(309:402,525:620,k));
  PHH_21(k) = mean2(FLIR_Data_Corr(16:30,376:398,k));
  PHH_22(k) = NaN;
  Basalt_22(k) = NaN;
  Tuff_23(k) = NaN;
  Soil_bw_rock_23(k) = NaN;
  FLIR_Time(k)= datetime(FLIRFiles(k).name(1:15),'InputFormat','yyyyMMdd_HHmmss');
end
for k = 42:366
  %FLIR_Data(Y1:Y2,X1:X2,k));
  CS240(k) = mean2(FLIR_Data_Corr(335:362,132:163,k)); % correct with CS240X_Avg(1 and 2)
  Soil_11(k) = mean2(FLIR_Data_Corr(31:70,509:607,k));
  Soil_12(k) = mean2(FLIR_Data_Corr(170:250,525:620,k));
  Soil_13(k) = mean2(FLIR_Data_Corr(309:402,525:620,k));
  PHH_21(k) = mean2(FLIR_Data_Corr(16:30,376:398,k));
  PHH_22(k) = NaN;
  Basalt_22(k) = NaN;
  Tuff_23(k) = NaN;
  Soil_bw_rock_23(k) = NaN;
  FLIR_Time(k)= datetime(FLIRFiles(k).name(1:15),'InputFormat','yyyyMMdd_HHmmss');
end
for k = 367:392
  %FLIR_Data(Y1:Y2,X1:X2,k));
  CS240(k) = NaN; % correct with CS240X_Avg(1 and 2)
  Soil_11(k) = NaN;
  Soil_12(k) = NaN;
  Soil_13(k) = NaN;
  PHH_21(k) = NaN;
  PHH_22(k) = NaN;
  Basalt_22(k) = NaN;
  Tuff_23(k) = NaN;
  Soil_bw_rock_23(k) = NaN;
  FLIR_Time(k)= datetime(FLIRFiles(k).name(1:15),'InputFormat','yyyyMMdd_HHmmss');
end
for k = 393:1139
  %FLIR_Data_Corr(Y1:Y2,X1:X2,k));
  CS240(k) = mean2(FLIR_Data_Corr(384:412,103:134,k)); % correct with CS240X_Avg(1 and 2)
  Soil_11(k) = mean2(FLIR_Data_Corr(160:232,436:502,k));
  Soil_12(k) = mean2(FLIR_Data_Corr(280:335,435:500,k));
  Soil_13(k) = mean2(FLIR_Data_Corr(395:485,435:500,k));
  PHH_21(k) = mean2(FLIR_Data_Corr(56:110,274:404,k));
  PHH_22(k) = mean2(FLIR_Data_Corr(229:273,137:186,k));
  Basalt_22(k) = mean2(FLIR_Data_Corr(339:350,159:177,k));
  Tuff_23(k) = mean2(FLIR_Data_Corr(300:322,90:110,k));
  Soil_bw_rock_23(k) = NaN;
  FLIR_Time(k)= datetime(FLIRFiles(k).name(1:15),'InputFormat','yyyyMMdd_HHmmss');
end
for k = 1140:1142
  %FLIR_Data(Y1:Y2,X1:X2,k));
  CS240(k) = mean2(FLIR_Data_Corr(414:442,213:242,k)); % correct with CS240X_Avg(1 and 2)
  Soil_11(k) = mean2(FLIR_Data_Corr(160:232,436:502,k));
  Soil_12(k) = mean2(FLIR_Data_Corr(280:335,435:500,k));
  Soil_13(k) = mean2(FLIR_Data_Corr(395:485,435:500,k));
  PHH_21(k) = mean2(FLIR_Data_Corr(56:110,274:404,k));
  PHH_22(k) = NaN;
  Basalt_22(k) = NaN;
  Tuff_23(k) = NaN;
  Soil_bw_rock_23(k) = mean2(FLIR_Data_Corr(403:444,176:187,k));
  FLIR_Time(k)= datetime(FLIRFiles(k).name(1:15),'InputFormat','yyyyMMdd_HHmmss');
end
for k = 1143:1347
  %FLIR_Data(Y1:Y2,X1:X2,k));
  CS240(k) = mean2(FLIR_Data(414:442,213:242,k)); % correct with CS240X_Avg(1 and 2)
  Soil_11(k) = mean2(FLIR_Data_Corr(160:232,436:502,k));
  Soil_12(k) = mean2(FLIR_Data_Corr(280:335,435:500,k));
  Soil_13(k) = mean2(FLIR_Data_Corr(395:485,435:500,k));
  PHH_21(k) = mean2(FLIR_Data_Corr(56:110,274:404,k));
  PHH_22(k) = mean2(FLIR_Data_Corr(239:293,219:264,k));
  Basalt_22(k) = mean2(FLIR_Data_Corr(335:350,187:208,k));
  Tuff_23(k) = mean2(FLIR_Data_Corr(418:442,133:158,k));
  Soil_bw_rock_23(k) = mean2(FLIR_Data_Corr(406:447,179:189,k));
  FLIR_Time(k)= datetime(FLIRFiles(k).name(1:15),'InputFormat','yyyyMMdd_HHmmss');
end
for k = 1348:1357
  %FLIR_Data(Y1:Y2,X1:X2,k));
  CS240(k) = mean2(FLIR_Data_Corr(408:432,215:243,k)); % correct with CS240X_Avg(1 and 2)
  Soil_11(k) = mean2(FLIR_Data_Corr(147:200,419:536,k));
  Soil_12(k) = mean2(FLIR_Data_Corr(260:350,419:536,k));
  Soil_13(k) = mean2(FLIR_Data_Corr(391:500,419:536,k));
  PHH_21(k) = mean2(FLIR_Data_Corr(48:89,263:386,k));
  PHH_22(k) = mean2(FLIR_Data_Corr(234:284,224:257,k));
  Basalt_22(k) = mean2(FLIR_Data_Corr(330:352,185:209,k));
  Tuff_23(k) = mean2(FLIR_Data_Corr(410:443,146:168,k));
  Soil_bw_rock_23(k) = mean2(FLIR_Data_Corr(393:443,179:193,k));
  FLIR_Time(k)= datetime(FLIRFiles(k).name(1:15),'InputFormat','yyyyMMdd_HHmmss');
end
for k = 1358:1367
  %FLIR_Data(Y1:Y2,X1:X2,k));
  CS240(k) = mean2(FLIR_Data_Corr(401:427,217:251,k)); % correct with CS240X_Avg(1 and 2)
  Soil_11(k) = mean2(FLIR_Data_Corr(147:200,419:540,k));
  Soil_12(k) = mean2(FLIR_Data_Corr(260:350,419:540,k));
  Soil_13(k) = mean2(FLIR_Data_Corr(390:495,419:540,k));
  PHH_21(k) = mean2(FLIR_Data_Corr(40:77,253:387,k));
  PHH_22(k) = mean2(FLIR_Data_Corr(228:277,210:265,k));
  Basalt_22(k) = mean2(FLIR_Data_Corr(328:346,186:210,k));
  Tuff_23(k) = mean2(FLIR_Data_Corr(403:440,148:170,k));
  Soil_bw_rock_23(k) = mean2(FLIR_Data_Corr(392:437,182:194,k));
  FLIR_Time(k)= datetime(FLIRFiles(k).name(1:15),'InputFormat','yyyyMMdd_HHmmss');
end
for k = 1368:2730
  %FLIR_Data(Y1:Y2,X1:X2,k));
  CS240(k) = mean2(FLIR_Data_Corr(392:421,220:256,k)); % correct with CS240X_Avg(1 and 2)
  Soil_11(k) = mean2(FLIR_Data_Corr(130:185,411:519,k));
  Soil_12(k) = mean2(FLIR_Data_Corr(240:327,407:540,k));
  Soil_13(k) = mean2(FLIR_Data_Corr(400:495,407:540,k));
  PHH_21(k) = mean2(FLIR_Data_Corr(34:69,249:378,k));
  PHH_22(k) = mean2(FLIR_Data_Corr(222:270,213:264,k));
  Basalt_22(k) = mean2(FLIR_Data_Corr(322:341,184:210,k));
  Tuff_23(k) = mean2(FLIR_Data_Corr(402:433,150:175,k));
  Soil_bw_rock_23(k) = mean2(FLIR_Data_Corr(385:431,186:199,k));
  FLIR_Time(k)= datetime(FLIRFiles(k).name(1:15),'InputFormat','yyyyMMdd_HHmmss');
end
for k = 2731:2792
  %FLIR_Data(Y1:Y2,X1:X2,k));
  CS240(k) = mean2(FLIR_Data_Corr(381:412,221:252,k)); % correct with CS240X_Avg(1 and 2)
  Soil_11(k) = mean2(FLIR_Data_Corr(129:171,400:507,k));
  Soil_12(k) = mean2(FLIR_Data_Corr(214:338,395:519,k));
  Soil_13(k) = mean2(FLIR_Data_Corr(376:477,392:519,k));
  PHH_21(k) = mean2(FLIR_Data_Corr(34:49,237:350,k));
  PHH_22(k) = mean2(FLIR_Data_Corr(200:257,213:264,k));
  Basalt_22(k) = mean2(FLIR_Data_Corr(317:334,182:206,k));
  Tuff_23(k) = mean2(FLIR_Data_Corr(384:426,154:178,k));
  Soil_bw_rock_23(k) = mean2(FLIR_Data_Corr(376:423,189:203,k));
  FLIR_Time(k)= datetime(FLIRFiles(k).name(1:15),'InputFormat','yyyyMMdd_HHmmss');
end
for k = 2793:2830
  %FLIR_Data(Y1:Y2,X1:X2,k));
  CS240(k) = mean2(FLIR_Data_Corr(369:401,217:266,k)); % correct with CS240X_Avg(1 and 2)
  Soil_11(k) = mean2(FLIR_Data_Corr(98:158,383:496,k));
  Soil_12(k) = mean2(FLIR_Data_Corr(196:319,375:491,k));
  Soil_13(k) = mean2(FLIR_Data_Corr(365:461,389:539,k));
  PHH_21(k) = mean2(FLIR_Data_Corr(8:34,222:345,k));
  PHH_22(k) = mean2(FLIR_Data_Corr(191:253,199:258,k));
  Basalt_22(k) = mean2(FLIR_Data_Corr(303:320,183:211,k));
  Tuff_23(k) = mean2(FLIR_Data_Corr(376:412,159:184,k));
  Soil_bw_rock_23(k) = mean2(FLIR_Data_Corr(375:414,192:208,k));
  FLIR_Time(k)= datetime(FLIRFiles(k).name(1:15),'InputFormat','yyyyMMdd_HHmmss');
end
for k = 2831:2855
  %FLIR_Data(Y1:Y2,X1:X2,k));
  CS240(k) = mean2(FLIR_Data_Corr(360:396,218:265,k)); % correct with CS240X_Avg(1 and 2)
  Soil_11(k) = mean2(FLIR_Data_Corr(92:154,383:499,k));
  Soil_12(k) = mean2(FLIR_Data_Corr(190:317,381:502,k));
  Soil_13(k) = mean2(FLIR_Data_Corr(354:439,389:539,k));
  PHH_21(k) = mean2(FLIR_Data_Corr(7:30,212:337,k));
  PHH_22(k) = mean2(FLIR_Data_Corr(183:246,199:254,k));
  Basalt_22(k) = mean2(FLIR_Data_Corr(297:318,185:209,k));
  Tuff_23(k) = mean2(FLIR_Data_Corr(369:410,161:181,k));
  Soil_bw_rock_23(k) = mean2(FLIR_Data_Corr(365:410,195:206,k));
  FLIR_Time(k)= datetime(FLIRFiles(k).name(1:15),'InputFormat','yyyyMMdd_HHmmss');
end
for k = 2856:2907
  %FLIR_Data(Y1:Y2,X1:X2,k));
  CS240(k) = mean2(FLIR_Data_Corr(361:389,224:266,k)); % correct with CS240X_Avg(1 and 2)
  Soil_11(k) = mean2(FLIR_Data_Corr(43:144,375:537,k));
  Soil_12(k) = mean2(FLIR_Data_Corr(176:302,380:526,k));
  Soil_13(k) = mean2(FLIR_Data_Corr(351:455,377:532,k));
  PHH_21(k) = mean2(FLIR_Data_Corr(7:28,208:338,k));
  PHH_22(k) = mean2(FLIR_Data_Corr(187:240,197:253,k));
  Basalt_22(k) = mean2(FLIR_Data_Corr(295:312,182:210,k));
  Tuff_23(k) = mean2(FLIR_Data_Corr(370:408,159:188,k));
  Soil_bw_rock_23(k) = mean2(FLIR_Data_Corr(362:408,195:210,k));
  FLIR_Time(k)= datetime(FLIRFiles(k).name(1:15),'InputFormat','yyyyMMdd_HHmmss');
end
for k = 2908:2915
  %FLIR_Data(Y1:Y2,X1:X2,k));
  CS240(k) = mean2(FLIR_Data_Corr(357:387,224:267,k)); % correct with CS240X_Avg(1 and 2)
  Soil_11(k) = mean2(FLIR_Data_Corr(75:132,366:521,k));
  Soil_12(k) = mean2(FLIR_Data_Corr(172:319,358:501,k));
  Soil_13(k) = mean2(FLIR_Data_Corr(339:435,362:541,k));
  PHH_21(k) = mean2(FLIR_Data_Corr(6:46,197:304,k));
  PHH_22(k) = mean2(FLIR_Data_Corr(185:240,191:252,k));
  Basalt_22(k) = mean2(FLIR_Data_Corr(293:312,184:211,k));
  Tuff_23(k) = mean2(FLIR_Data_Corr(364:404,164:189,k));
  Soil_bw_rock_23(k) = mean2(FLIR_Data_Corr(358:406,198:211,k));
  FLIR_Time(k)= datetime(FLIRFiles(k).name(1:15),'InputFormat','yyyyMMdd_HHmmss');
end
for k = 2916:2930
  %FLIR_Data(Y1:Y2,X1:X2,k));
  CS240(k) = mean2(FLIR_Data_Corr(349:363,223:269,k)); % correct with CS240X_Avg(1 and 2)
  Soil_11(k) = mean2(FLIR_Data_Corr(68:122,353:504,k));
  Soil_12(k) = mean2(FLIR_Data_Corr(168:209,352:511,k));
  Soil_13(k) = mean2(FLIR_Data_Corr(351:423,360:537,k));
  PHH_21(k) = mean2(FLIR_Data_Corr(6:32,193:248,k));
  PHH_22(k) = mean2(FLIR_Data_Corr(181:223,191:241,k));
  Basalt_22(k) = mean2(FLIR_Data_Corr(287:295,184:209,k));
  Tuff_23(k) = mean2(FLIR_Data_Corr(364:388,162:196,k));
  Soil_bw_rock_23(k) = mean2(FLIR_Data_Corr(355:379,200:217,k));
  FLIR_Time(k)= datetime(FLIRFiles(k).name(1:15),'InputFormat','yyyyMMdd_HHmmss');
end
for k = 2931:2951
  %FLIR_Data(Y1:Y2,X1:X2,k));
  CS240(k) = mean2(FLIR_Data_Corr(336:351,227:272,k)); % correct with CS240X_Avg(1 and 2)
  Soil_11(k) = mean2(FLIR_Data_Corr(47:120,344:485,k));
  Soil_12(k) = mean2(FLIR_Data_Corr(133:221,337:533,k));
  Soil_13(k) = mean2(FLIR_Data_Corr(298:309,391:605,k));
  PHH_21(k) = mean2(FLIR_Data_Corr(5:24,174:235,k));
  PHH_22(k) = mean2(FLIR_Data_Corr(169:212,177:232,k));
  Basalt_22(k) = mean2(FLIR_Data_Corr(277:287,183:208,k));
  Tuff_23(k) = mean2(FLIR_Data_Corr(352:382,168:199,k));
  Soil_bw_rock_23(k) = mean2(FLIR_Data_Corr(342:374,204:220,k));
  FLIR_Time(k)= datetime(FLIRFiles(k).name(1:15),'InputFormat','yyyyMMdd_HHmmss');
end
for k = 2952:4078
  %FLIR_Data(Y1:Y2,X1:X2,k));
  CS240(k) = mean2(FLIR_Data_Corr(326:354,228:269,k)); % correct with CS240X_Avg(1 and 2)
  Soil_11(k) = mean2(FLIR_Data_Corr(19:43,335:495,k));
  Soil_12(k) = mean2(FLIR_Data_Corr(111:196,375:540,k));
  Soil_13(k) = mean2(FLIR_Data_Corr(282:334,419:584,k));
  PHH_21(k) = mean2(FLIR_Data_Corr(5:24,160:232,k));
  PHH_22(k) = mean2(FLIR_Data_Corr(162:206,175:233,k));
  Basalt_22(k) = mean2(FLIR_Data_Corr(267:288,178:210,k));
  Tuff_23(k) = mean2(FLIR_Data_Corr(342:383,167:194,k));
  Soil_bw_rock_23(k) = mean2(FLIR_Data_Corr(334:381,206:217,k));
  FLIR_Time(k)= datetime(FLIRFiles(k).name(1:15),'InputFormat','yyyyMMdd_HHmmss');
end
for k = 4079:4084
  %FLIR_Data(Y1:Y2,X1:X2,k));
  CS240(k) = NaN; % correct with CS240X_Avg(1 and 2)
  Soil_11(k) = NaN;
  Soil_12(k) = NaN;
  Soil_13(k) = NaN;
  PHH_21(k) = NaN;
  PHH_22(k) = NaN;
  Basalt_22(k) = NaN;
  Tuff_23(k) = NaN;
  Soil_bw_rock_23(k) = NaN;
  FLIR_Time(k)= datetime(FLIRFiles(k).name(1:15),'InputFormat','yyyyMMdd_HHmmss');
end
for k = 4085:4657
  %FLIR_Data_Corr(Y1:Y2,X1:X2,k));
  CS240(k) = mean2(FLIR_Data_Corr(378:418,210:259,k)); % correct with CS240X_Avg(1 and 2)
  Soil_11(k) = mean2(FLIR_Data_Corr(122:185,413:547,k));
  Soil_12(k) = mean2(FLIR_Data_Corr(203:342,409:539,k));
  Soil_13(k) = mean2(FLIR_Data_Corr(381:472,411:570,k));
  PHH_21(k) = mean2(FLIR_Data_Corr(10:57,244:374,k));
  PHH_22(k) = mean2(FLIR_Data_Corr(209:267,203:262,k));
  Basalt_22(k) = mean2(FLIR_Data_Corr(314:334,181:210,k));
  Tuff_23(k) = mean2(FLIR_Data_Corr(379:425,150:178,k));
  Soil_bw_rock_23(k) = mean2(FLIR_Data_Corr(383:430,186:199,k));
  FLIR_Time(k)= datetime(FLIRFiles(k).name(1:15),'InputFormat','yyyyMMdd_HHmmss');
end
for k = 4658:4668
  %FLIR_Data_Corr(Y1:Y2,X1:X2,k));
  CS240(k) = NaN; % correct with CS240X_Avg(1 and 2)
  Soil_11(k) = NaN;
  Soil_12(k) = NaN;
  Soil_13(k) = NaN;
  PHH_21(k) = NaN;
  PHH_22(k) = NaN;
  Basalt_22(k) = NaN;
  Tuff_23(k) = NaN;
  Soil_bw_rock_23(k) = NaN;
  FLIR_Time(k)= datetime(FLIRFiles(k).name(1:15),'InputFormat','yyyyMMdd_HHmmss');
end
for k = 4669:5643
  %FLIR_Data(Y1:Y2,X1:X2,k));
  CS240(k) = mean2(FLIR_Data_Corr(377:417,213:259,k)); % correct with CS240X_Avg(1 and 2)
  Soil_11(k) = mean2(FLIR_Data_Corr(119:187,407:542,k));
  Soil_12(k) = mean2(FLIR_Data_Corr(213:346,395:547,k));
  Soil_13(k) = mean2(FLIR_Data_Corr(385:479,396:557,k));
  PHH_21(k) = mean2(FLIR_Data_Corr(11:60,240:373,k));
  PHH_22(k) = mean2(FLIR_Data_Corr(205:266,205:268,k));
  Basalt_22(k) = mean2(FLIR_Data_Corr(313:336,184:212,k));
  Tuff_23(k) = mean2(FLIR_Data_Corr(380:424,155:179,k));
  Soil_bw_rock_23(k) = mean2(FLIR_Data_Corr(377:428,187:202,k));
  FLIR_Time(k)= datetime(FLIRFiles(k).name(1:15),'InputFormat','yyyyMMdd_HHmmss');
end
for k = 5644:length(FLIRFiles)
  %FLIR_Data(Y1:Y2,X1:X2,k));
  CS240(k) = NaN; % correct with CS240X_Avg(1 and 2)
  Soil_11(k) = NaN;
  Soil_12(k) = NaN;
  Soil_13(k) = NaN;
  PHH_21(k) = NaN;
  PHH_22(k) = NaN;
  Basalt_22(k) = NaN;
  Tuff_23(k) = NaN;
  Soil_bw_rock_23(k) = NaN;
  FLIR_Time(k)= datetime(FLIRFiles(k).name(1:15),'InputFormat','yyyyMMdd_HHmmss');
end
toc

%% Plot Data

tstart=datetime(2021,08,12,12,48,0); 
tend=datetime(2021,08,16,10,11,0);

%FLIR surface temp
% figure(1)
% %X =1:1:length(FLIRFiles);
% %plot(FLIR_Time,Dry_Point_Temp(:,1)-Full_Scene_Temp(:,1));
% plot(FLIR_Time,Dry_Point_Temp(:,1));
% legend('Dry');
% xlim([tstart tend]);

%FLIR and sensor cal target temp
SBlackMean = mean([LoggerData.CS240T_C_3_Avg LoggerData.CS240T_C_4_Avg],2);
figure(1)
plot(FLIR_Time,CS240(:,1),LoggerData.TIMESTAMP,SBlackMean);
legend('FLIRBlack','SBlack');
xlim([tstart tend]);
xlabel('Temp (C)');

%Corrected FLIR Surface Temp
FLIR_Time = FLIR_Time + seconds(6); %to make it on the even minute
FLIR_CS240_Sync = timetable(FLIR_Time',CS240(:,1));
Soil_11_Sync = timetable(FLIR_Time',Soil_11(:,1));
Soil_12_Sync = timetable(FLIR_Time',Soil_12(:,1));
Soil_13_Sync = timetable(FLIR_Time',Soil_13(:,1));
PHH_21_Sync = timetable(FLIR_Time',PHH_21(:,1));
PHH_22_Sync = timetable(FLIR_Time',PHH_22(:,1));
Basalt_22_Sync = timetable(FLIR_Time',Basalt_22(:,1));
Tuff_23_Sync = timetable(FLIR_Time',Tuff_23(:,1));
Soil_bw_rock_23_Sync = timetable(FLIR_Time',Soil_bw_rock_23(:,1));

AllData = synchronize(LoggerData,FLIR_CS240_Sync,Soil_11_Sync,Soil_12_Sync,Soil_13_Sync,PHH_21_Sync,PHH_22_Sync,Basalt_22_Sync,Tuff_23_Sync,Soil_bw_rock_23_Sync,'Minutely','firstvalue');%'linear');

LoggerCS240Mean = mean([AllData.CS240T_C_3_Avg AllData.CS240T_C_4_Avg],2);
Noise = AllData.FLIR_CS240_Sync-LoggerCS240Mean;
figure(2)
plot(AllData.TIMESTAMP,Noise);
legend('FLIR Noise')
xlim([tstart tend]);
ylabel('Temp (C)');

AllData.FLIR_Soil_11_Corr = AllData.FLIR_Soil_11_Sync -Noise;
AllData.FLIR_Soil_12_Corr = AllData.FLIR_Soil_12_Sync - Noise;
AllData.FLIR_Soil_13_Corr = AllData.FLIR_Soil_13_Sync - Noise;
AllData.FLIR_Tuff_23_Corr = AllData.FLIR_Tuff_23_Sync - Noise;
AllData.FLIR_Soil_bw_rock_23_Corr = AllData.FLIR_Soil_bw_rock_23_Sync - Noise;
AllData.FLIR_Basalt_22_Corr = AllData.FLIR_Basalt_22_Sync - Noise;
AllData.FLIR_PHH_22_Corr = AllData.FLIR_PHH_22_Sync - Noise;
AllData.FLIR_PHH_21_Corr = AllData.FLIR_PHH_21_Sync - Noise;

figure(3)
plot(AllData.TIMESTAMP,AllData.FLIR_Soil_11_Corr);
hold on
plot(AllData.TIMESTAMP,AllData.FLIR_Soil_12_Corr);
plot(AllData.TIMESTAMP,AllData.FLIR_Soil_13_Corr);
plot(AllData.TIMESTAMP,AllData.FLIR_Soil_bw_rock_23_Corr);
plot(AllData.TIMESTAMP,AllData.T_Avg);
plot(AllData.TIMESTAMP,AllData.AirTC_Avg);
ylabel('Temp (C)');
yyaxis right
plot(AllData.TIMESTAMP,AllData.Rn_Avg);
%plot(AllData.TIMESTAMP,AllData.WS_ms_10);
legend('Soil_1,1', 'Soil_1,2','Soil_1,3', 'Soil between rocks', 'Logger Surf Temp 1,3', 'Air T', 'Rn');
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