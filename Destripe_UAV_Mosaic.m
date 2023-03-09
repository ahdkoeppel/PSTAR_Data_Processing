%% Code for Geo-aligning FLIR Duo/Vue Pro rjpg images with DJI VIS images ... 
% and converting raw thermal data to temperatures (C) using adjustable observation/atmospheric variables
% Ari Koeppel - 2021-2023
% Requires exiftool.exe to be installed on system
clear
close all;

%% Import Data
Dir = uigetdir('X:\common\FIELD_CAMPAIGNS\','Directory of raw multispectral .tiffs');%gets directory
NUM_BANDS = 10;

%% Destripe rows
for j = 1:NUM_BANDS %number of bands
    str = sprintf('*_%g.tif',j)
    Files = dir(fullfile(Dir,str)); %gets all files
    fprintf(1, 'Now reading %s\n', Dir);
    FileName = fullfile(Dir, Files(1).name);
    RAW = imread(FileName);
    % Destripe rows
    tic
    Box_filt = zeros([size(RAW),length(Files)]);
    for k = 1:length(Files)
        FileName = fullfile(Dir, Files(k).name);
        RAW = imread(FileName);
    %     RAW(abs(RAW)>1000) = NaN;
    %     imagesc(RAW);colorbar
        Box_filt(:,:,k) = imboxfilt(RAW,191);
%         im_mean(j,k) = mean(Box_filt(:,:,k),'all');        
    end
    band_mean(:,:,j) = mean(Box_filt,3);
end
% plot(im_mean(1,:))
% hold on
% for j = 2:NUM_BANDS
%     plot(im_mean(j,:))
% end
for i = 1:10
    Center_Temp(i) = mean2(band_mean(size(band_mean,1)/2-5:size(band_mean,1)/2+5,size(band_mean,2)/2-5:size(band_mean,2)/2+5,i));
    band_flat(:,:,i) = band_mean(:,:,i)-Center_Temp(i);
end
%% Correct images
% g = im_mean(1,:);
% median(g(g<15000))
% corr_factor = [12704.195, 12714.229, 12983.799, 12932.759, 12997.900, 13028.327, 12659.634, 12979.350, 12995.667, 13098.056];
for j = 1:NUM_BANDS %number of bands
    str = sprintf('*_%g.tif',j)
    Files = dir(fullfile(Dir,str)); %gets all files
    fprintf(1, 'Now reading %s\n', Dir);
    for k = 1:length(Files)
        FileName = fullfile(Dir, Files(k).name);
        newFile = [FileName(1:end-4),'_FFC.tiff'];
        status = copyfile(FileName,newFile,'f');
        Cal = Tiff(newFile,'r+');
%         RAW = single(read(Cal));
        RAW = imread(FileName);
        %Processing
        Calibrated = RAW - band_flat(:,:,j);
        %
        setTag(Cal,'BitsPerSample',32); %An internal note to program to treat data as 32 Bit float rather than uint16 -not actually written to file
        setTag(Cal,'SampleFormat',Tiff.SampleFormat.IEEEFP); %An internal note to program to treat data as ~float rather than uint16 -not actually written to file
        write(Cal,single(Calibrated));
        close(Cal);
    end
end
