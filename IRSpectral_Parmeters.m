%% Program to compute IR summary parameters from FTIR emission spectra
% Ari Koeppel - 2023
clear
close all;

%Load Spectra file
load('X:\common\FIELD_CAMPAIGNS\FTIR_General\Emissivity_Master.mat');
Data = Emissivity_Master;
wn_array = Data.Wavenumber;
Data_ud = flipud(Data);
wl = 10^4./Data_ud.Wavenumber;
% %Load sample names
% list = fileread('X:\common\FIELD_CAMPAIGNS\Lab_ASD_General\2023-PSTAR-FINESST-Samples\SampleNames.txt');
% snames = strsplit(list);

BandParams = Data_ud;
BandParams(4:end,:)=[];
BandParams.Properties.VariableNames{1} = 'Parameter';
BandParams.Parameter = char({'WAC', 'CF','FLIR_E'});

%% Copute Band Params
% loop through Samples
for g = 2:width(Data_ud)
% Find Ratioed spectrum    
    clearvars -except Data_ud g wl BandParams
    EMISS = Data_ud{:,g};
    BandParams{1,g} = WAC(EMISS,wl);  %WAC
    BandParams{2,g} = CF(EMISS,wl);  %CF
    BandParams{3,g} = FLIR_E(EMISS,wl);  %Emissivity Accross FLIR wl
end

%% Functions
function l_wac =  WAC(epsilon,lamda)
%REF: Smith et al 2013
%The WAC integrates between THEMIS bands 3 (7.93) micron and 8 (11.79)
%micron -- Salvatore et al. 2018
%Amador and Bandfield 2016 up to 12.57
%Smith et al 2013 up to 14.88
    [~,I_max] = min(abs(lamda-15));%15 micron = right edge of absorbtion
    [~,I_min] = min(abs(lamda-7)); %7 micron = left edge of absorbtion
    depth = 0;
    depth_g = 0;
    j = I_min;
    for i = I_min:1:I_max
        depth = 0.5*(1-epsilon(i))*((lamda(i)-lamda(i-1))/2+(lamda(i+1)-lamda(i))/2)+depth;
    end
    while depth_g < depth
        depth_g = (1-epsilon(j))*((lamda(j)-lamda(j-1))/2+(lamda(j+1)-lamda(j))/2)+depth_g;
        j = j+1;
    end
    l_wac =  lamda(j);
end

function CF_pos =  CF(epsilon,lamda)
%REF: Smith et al 2013
%The WAC integrates between THEMIS bands 3 (7.93) micron and 8 (11.79)
%micron -- Salvatore et al. 2018
%Amador and Bandfield 2016 up to 12.57
%Smith et al 2013 up to 14.88
    [~,I_max] = min(abs(lamda-12));%15 micron = right edge of absorbtion
    [~,I_min] = min(abs(lamda-7)); %7 micron = left edge of absorbtion
    [~,CF_ind] = min(epsilon(I_min:I_max));
    CF_pos = lamda(CF_ind+I_min-1);
end

function Emissivity =  FLIR_E(epsilon,lamda)
%REF: Smith et al 2013
%The WAC integrates between THEMIS bands 3 (7.93) micron and 8 (11.79)
%micron -- Salvatore et al. 2018
%Amador and Bandfield 2016 up to 12.57
%Smith et al 2013 up to 14.88
    [~,I_max] = min(abs(lamda-13.5));%15 micron = right edge of absorbtion
    [~,I_min] = min(abs(lamda-7.5)); %7 micron = left edge of absorbtion
    W = 0;
    for i = I_min:I_max
        W = epsilon(i)*((lamda(i)-lamda(i-1))/2+(lamda(i+1)-lamda(i))/2)+W;
    end
    Emissivity = W/(lamda(I_max)-lamda(I_min));
end