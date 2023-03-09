%% Code for converting raw thermal data to temperatures (C) using adjustable observation/atmospheric variables
% Ari Koeppel - 2021
clear
close all;

%% Load Metadata into table, Enter these parameters by hand or read them in from a file
        Emissivity = 1;% 0 to 1
        ObjectDistance = 0; %meters
        ReflectedApparentTemperature = 20; %Of surface of interest in C
        AtmosphericTemperature = 0; %Essentially 0 in space
        RelativeHumidity= 0; %Essentially 0 in space
        PlanckR1=21106.77; %Change to calibration constant for specific instrument
        PlanckB=1501; %Change to calibration constant for specific instrument
        PlanckF=1; %Change to calibration constant for specific instrument
        PlanckO=-7340; %Change to calibration constant for specific instrument
        PlanckR2=0.012545258; %Change to calibration constant for specific instrument
        IRWindowTemperature = 273; %Lens Temperature
        IRWindowTransmission = 1; %should be 1 for no lens/window
        ATA1 = 0.006569; %constant of specific instrument for calculating humidity effects on transmission
        ATA2 = 0.01262; %constant of specific instrument for calculating humidity effects on transmission
        ATB1 = -0.002276; %constant of specific instrument for calculating humidity effects on transmission
        ATB2 = -0.00667; %constant of specific instrument for calculating humidity effects on transmission
        ATX = 1.9; %constant of specific instrument for calculating humidity effects on transmission
        
        Metadata = table(Emissivity,ObjectDistance,ReflectedApparentTemperature,AtmosphericTemperature,RelativeHumidity,PlanckR1,...
            PlanckB,PlanckF,PlanckO,PlanckR2,IRWindowTemperature,IRWindowTransmission,ATA1,ATA2,ATB1,ATB2,ATX);


%% Convert R.JPGs to tiffs with temperature
%NOTE: This section assumes the data array is saved as a .tiff (Can be saved using Flirpy Python Package)
%metadata must be loaded into 
FLIRDir = uigetdir('~','Directory of FLIR .tiff files');%gets directory
FLIRFiles = dir(fullfile(FLIRDir,'*.tiff')); %gets all files
for k = 1:length(FLIRFiles) % loops through each .tiff file
    raw_thermal = fullfile(FLIRDir, FLIRFiles(k).name); %Loads full filename
    thermal_C = [raw_thermal(1:end-5),'_TempC',raw_thermal(end-4:end)]; %Makes a new filename
    status = copyfile(raw_thermal,thermal_C,'f'); %Copies orignal data into new filename to prep the array
    t = Tiff(thermal_C,'r+'); %Loads raw array data
    RAW = single(read(t));%Formats raw data to "single" array data
    %****
    T_Calibrated = Thermal_Calibration(RAW,Metadata); %Function (See bottom of script) derives calibrated temperatures in Celsius using metadata table
    %******
    setTag(t,'BitsPerSample',32); %An internal note to program to treat data as 32 Bit float rather than uint16 -not actually written to file
    setTag(t,'SampleFormat',Tiff.SampleFormat.IEEEFP); %An internal note to program to treat data as ~float rather than uint16 -not actually written to file
    write(t,single(T_Calibrated)); %Writes calibrated data to tiff array
    close(t); %Saves tiff
end

%% Functions
function [temp_celcius] = Thermal_Calibration(DATA,tbl)
        %Temperature calibration based on https://github.com/gtatters/Thermimage/blob/master/R/raw2temp.R
        % raw: A/D bit signal from FLIR file
        % FLIR .seq files and .fcf files store data in a 16-bit encoded value. 
       % This means it can range from 0 up to 65535.  This is referred to as the raw value.  
       % The raw value isactually what the sensor detects which is related to the radiance hitting 
       % the sensor.
       % At the factory, each sensor has been calibrated against a blackbody radiation source so 
       % calibration values to conver the raw signal into the expected temperature of a blackbody 
       % radiator are provided.
       % Since the sensors do not pick up all wavelengths of light, the calibration can be estimated
       % using a limited version of Planck's law.  But the blackbody calibration is still critical
       % to this.
       
       % E: Emissivity - default 1, should be ~0.95 to 0.97 depending on source
       % OD: Object distance in metres
       % RTemp: apparent reflected temperature - one value from FLIR file (oC), default 20C
       % ATemp: atmospheric temperature for tranmission loss - one value from FLIR file (oC) - default = RTemp
       % IRWinT: Infrared Window Temperature - default = RTemp (oC)
       % IRT: Infrared Window transmission - default 1.  likely ~0.95-0.96. Should be empirically determined.
       % RH: Relative humidity
  
       % Note: PR1, PR2, PB, PF, and PO are specific to each camera and result from the calibration at factory
       % of the camera's Raw data signal recording from a blackbody radiation source
       
       % ATA1: Atmospheric Trans Alpha 1  0.006569 constant for calculating humidity effects on transmission 
       % ATA2: Atmospheric Trans Alpha 2  0.012620 constant for calculating humidity effects on transmission
       % ATB1: Atmospheric Trans Beta 1  -0.002276 constant for calculating humidity effects on transmission
       % ATB2: Atmospheric Trans Beta 2  -0.006670 constant for calculating humidity effects on transmission
       % ATX:  Atmospheric Trans X        1.900000 constant for calculating humidity effects on transmission
       
       % Equations to convert to temperature
       % See http://130.15.24.88/exiftool/forum/index.php/topic,4898.60.html
       % Standard equation: temperature<-PB/log(PR1/(PR2*(raw+PO))+PF)-273.15
       % Other source of information: Minkina and Dudzik's Infrared Thermography: Errors and Uncertainties
  
        E=tbl.Emissivity;
        OD=sscanf(tbl.ObjectDistance{:}, '%d'); 
        RTemp=sscanf(tbl.ReflectedApparentTemperature{:}, '%d');
        ATemp=tbl.AtmosphericTemperature;
        RH=tbl.RelativeHumidity;
        PR1=tbl.PlanckR1;
        PB=tbl.PlanckB;
        PF=tbl.PlanckF;
        PO=tbl.PlanckO;
        PR2=tbl.PlanckR2;

        IRWTemp=sscanf(tbl.IRWindowTemperature{:}, '%d');%FlirImageExtractor.extract_float(meta["IRWindowTemperature"]),
        IRT=tbl.IRWindowTransmission; %should be 1 for no lens/window

        ATA1 = tbl.ATA1;
        ATA2 = tbl.ATA2;
        ATB1 = tbl.ATB1;
        ATB2 = tbl.ATB2;
        ATX = tbl.ATX;

% transmission through window (calibrated)
        emiss_wind = 1 - IRT;
        refl_wind = 0;
% transmission through the air
        h2o = (RH/100)*exp(1.5587+0.06939*ATemp-0.00027816*ATemp^2+0.00000068455*ATemp^3);
        tau1 = ATX*exp(-sqrt(OD/2)*(ATA1+ATB1*sqrt(h2o)))+(1-ATX)*exp(...
            -sqrt(OD/2)*(ATA2+ATB2*sqrt(h2o)));
        tau2 = ATX*exp(-sqrt(OD/2)*(ATA1+ATB1*sqrt(h2o)))+(1-ATX)*exp(...
            -sqrt(OD/2)*(ATA2+ATB2*sqrt(h2o))); 
% radiance from the environment
        raw_refl1 = PR1 / (PR2 * (exp(PB / (RTemp + 273.15)) - PF)) - PO;
        raw_refl1_attn = (1 - E) / E * raw_refl1;
        raw_atm1 = PR1 / (PR2 * (exp(PB / (ATemp + 273.15)) - PF)) - PO;
        raw_atm1_attn = (1 - tau1) / E / tau1 * raw_atm1;
        raw_wind = PR1 / (PR2 * (exp(PB / (IRWTemp + 273.15)) - PF)) -PO;
        raw_wind_attn = emiss_wind / E / tau1 / IRT * raw_wind;
        raw_refl2 = PR1 / (PR2 * (exp(PB / (RTemp + 273.15)) - PF)) -PO;
        raw_refl2_attn = refl_wind / E / tau1 / IRT * raw_refl2;
        raw_atm2 = PR1 / (PR2 * (exp(PB / (ATemp + 273.15)) - PF)) - PO;
        raw_atm2_attn = (1 - tau2) / E / tau1 / IRT / tau2 * raw_atm2;


        raw_obj = (DATA./E./tau1./IRT./tau2-raw_atm1_attn-raw_atm2_attn-raw_refl1_attn-raw_wind_attn-raw_refl2_attn);

%  temperature from radiance
        temp_celcius = PB./log(PR1./(PR2.*(raw_obj+PO))+PF)-273.15;
end