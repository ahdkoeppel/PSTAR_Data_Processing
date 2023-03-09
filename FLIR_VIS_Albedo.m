%FLIR_VIS_Albedo.m
%Ari Koeppel 2022
% Script to access FLIR Duo visible JPEG images and estimate dynamic
% surface albedos using albedo from a radiometer + known reflectances of
% calibration targets.

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