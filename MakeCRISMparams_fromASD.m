%% Program to compute CRISM summary params from input ASD spectra
%Params from Viviano-Beck, 2014
%Initial inputs from Lulu Pan Denoising script
%Param Code adapted from CRISM CAT IDL code
% Ari Koeppel - 2023
clear
close all;

%Load Spectra file
load('X:\common\FIELD_CAMPAIGNS\Lab_ASD_General\2023-PSTAR-FINESST-Samples\FINESST_PSTAR_LabASD_2023_WRCalibrated.mat');
Data = VNIR_Refl_Calibrated;
wl_array = Data.Wavelength./1000;
% %Load sample names
% list = fileread('X:\common\FIELD_CAMPAIGNS\Lab_ASD_General\2023-PSTAR-FINESST-Samples\SampleNames.txt');
% snames = strsplit(list);

BandParams = Data;
BandParams(35:end,:)=[];
BandParams.Properties.VariableNames{1} = 'Parameter';
BandParams.Parameter = char({'OLINDEX3', 'SINDEX2', 'BDCARB', 'LCPINDEX2', 'HCPINDEX2', 'ISLOPE1', 'BD1900_2', 'BD1900R2', 'BD2100_2', 'BD2165', 'BD2190', 'D2200', 'MIN2200', 'BD2230', 'MIN2250', 'BD2250', 'BD2265', 'BD2290', 'D2300', 'BD2355', 'R1330', 'VAR','R770','RBR','BD530_2','SH600_2','SH770','BD640_2','BD860_2','BD920_2','BD1300','BD1400','BD1435','BD1750_2'});

%% Copute Band Params
% loop through Samples
for g = 2:width(Data)
% Find Ratioed spectrum    
    clearvars -except Data g wl_array BandParams
    Refl = Data{:,g};
    BandParams{1,g} = crism_summary_olindex3(Refl,wl_array);  %OLINDEX3
    BandParams{2,g} = crism_sumutil_band_depth_invert(Refl,wl_array, 2.120, 2.290, 2.400,5,7,3); %SINDEX2 band depth of the continuum between the 2.1 and 2.4 micron mono- and poly-hydrated sulfate features                                           
    BandParams{3,g} = crism_summary_bdcarb(Refl,wl_array); %BDCARB Carbonate band overtone
    BandParams{4,g} = crism_summary_lcpindex2(Refl,wl_array); %LCPINDEX2 Low-Ca Pyroxene                       
    BandParams{5,g} = crism_summary_hcpindex2(Refl,wl_array); %HCPINDEX2 Hi-Ca Pyroxene
    BandParams{6,g} = crism_summary_islope1(Refl,wl_array); %ISLOPE1 Spectral Slope
    BandParams{7,g} = crism_sumutil_band_depth(Refl,wl_array,1.850,1.930,2.067,5,5,5); %BD1900_2 Hydration
    BandParams{8,g} = crism_summary_bd1900r2(Refl,wl_array); %BD1900R2 H2O Continuum removed ratios so it is not longer sensitive to slope effects
    BandParams{9,g} = crism_sumutil_band_depth(Refl,wl_array, 1.930, 2.132, 2.250,3,5,3); %BD2100_2 H2O
    BandParams{10,g} = crism_sumutil_band_depth(Refl,wl_array,2.120, 2.165, 2.230,5,3,3); %BD2165 kaolinite group
    BandParams{11,g} = crism_sumutil_band_depth(Refl,wl_array,2.120, 2.185, 2.250,5,3,3); %BD2190 (Beidellite, Allophane)
    BandParams{12,g} = crism_summary_d2200(Refl,wl_array); %     D2200                                          
    BandParams{13,g} = crism_sumutil_band_depth_min(Refl,wl_array, 2.120, 2.165, 2.350,2.120, 2.210,2.350,5,3,5,5,3,5); %MIN2200 2.16 and 2.21 micron band depth (DOUB2200): (Kaolinite) 
    BandParams{14,g} = crism_sumutil_band_depth(Refl,wl_array,2.210, 2.235, 2.252,3,3,3); %BD2230 Hydroxylated Ferric Sulfate
    BandParams{15,g} = crism_sumutil_band_depth_min(Refl,wl_array,2.165, 2.210, 2.350,2.165, 2.265, 2.350, 5,3,5,5,3,5); %MIN2250 2.21 and 2.26 micron band depth (DOUB2250): (Opal)
    BandParams{16,g} = crism_sumutil_band_depth(Refl,wl_array,2.120, 2.245, 2.340,5,7,3); %BD2250 opal
    BandParams{17,g} = crism_sumutil_band_depth(Refl,wl_array,2.210, 2.265, 2.340,5,3,5); %BD2265 (jarosite, gibbsite)
    BandParams{18,g} = crism_sumutil_band_depth(Refl,wl_array,2.250, 2.290, 2.350,5,5,5); %BD2290 Fe-OH & CO2 Ice
    BandParams{19,g} = crism_summary_d2300(Refl,wl_array); %D2300 
    BandParams{20,g} = crism_sumutil_band_depth(Refl,wl_array,2.300, 2.355, 2.450,5,5,5); %BD2355 CHLORITE              
    BandParams{21,g} = crism_sumutil_single(Refl,wl_array,1.330,11); %R1330
    BandParams{22,g} = crism_summary_var(Refl,wl_array); %VAR spectral variance parameter
    BandParams{23,g} = crism_sumutil_single(Refl,wl_array,0.77,5); %R770
    BandParams{24,g} = BandParams{23,g}/crism_sumutil_single(Refl,wl_array,0.44,5); %RBR
    BandParams{25,g} = crism_sumutil_band_depth(Refl,wl_array,0.44,0.53,0.614,5,5,5); %BD530_2
    BandParams{26,g} = crism_sumutil_band_depth_invert(Refl,wl_array,0.533,0.6,0.716,5,5,3); %SH600_2
    BandParams{27,g} = crism_sumutil_band_depth_invert(Refl,wl_array,0.716,0.775,0.86,3,5,5); %SH770
    BandParams{28,g} = crism_sumutil_band_depth(Refl,wl_array,0.6,0.624,0.76,5,3,5); %BD640_2
    BandParams{29,g} = crism_sumutil_band_depth(Refl,wl_array,0.755,0.86,0.977,5,5,5); %BD860_2
    BandParams{30,g} = crism_sumutil_band_depth(Refl,wl_array,0.807,0.92,0.984,5,5,5); %BD920_2
    BandParams{31,g} = crism_sumutil_band_depth(Refl,wl_array,1.08,1.32,1.75,5,15,5); %BD1300
    BandParams{32,g} = crism_sumutil_band_depth(Refl,wl_array,1.33,1.395,1.467,5,3,5); %BD1400
    BandParams{33,g} = crism_sumutil_band_depth(Refl,wl_array,1.37,1.435,1.47,5,1,5); %BD1435
    BandParams{34,g} = crism_sumutil_band_depth(Refl,wl_array,1.69,1.75,1.815,5,3,5); %BD1750_2
    %     BandParams{8,g} = crism_sumutil_band_depth_min(Refl,wl_array, 2.250, 2.345, 2.430,2.430, 2.537, 2.602,5,5,5,5,5,5); %MIN2345_2537 Fe/Ca-carbonate overtone band depth (MIN2342_2537): (Fe/Ca-Carbonate)
    %     BandParams{23,g} = crism_sumutil_band_depth(Refl,wl_array,2.364, 2.480, 2.570,5,5,5); %BD2500_2 (Mg-Carbonate)   
        %BD1300 = crism_sumutil_band_depth(Data,wl_array,1.080,1.320,1.750,5,15,5); %Fe2+ in Plag
                %BD2210_2=crism_sumutil_band_depth(Data,wl_array,2.165, 2.210, 2.290,5,5,5); %Not Kaolanite
                        %BD1750_2=crism_sumutil_band_depth(Data,wl_array,1.690, 1.750, 1.815,5,3,5);     
                        %     BandParams{6,g} = crism_sumutil_band_depth_min(Refl,wl_array, 2.165, 2.295, 2.364,2.364, 2.480, 2.570,5,5,5,5,5,5); % MIN2295_2480 Mg-carbonate overtone band depth (MIN2295_2480): (Mg-Carbonate)             

end

%% Functions
function BD = crism_sumutil_band_depth(spectrum,wvt,low,mid,hi,low_width,mid_width,hi_width) 
%extract single bands from the spectrum, replacing CRISM_NAN with IEEE NAN
    Rlow = crism_sumutil_single(spectrum,wvt,low,low_width);
    Rmid = crism_sumutil_single(spectrum,wvt,mid,mid_width);
    Rhi = crism_sumutil_single(spectrum,wvt,hi,hi_width);

    % determine wavelength values for closest crism channels
    WL = wvt(ASD_lookupwv(low,wvt));
    WC = wvt(ASD_lookupwv(mid,wvt));
    WH = wvt(ASD_lookupwv(hi,wvt));
    a = (WC-WL)./(WH-WL);     %a gets multipled by the longer band
    b = 1.0-a;               %b gets multiplied by the shorter band

    %compute the band depth using precomputed a and b
    BD = 1.0-(Rmid./(b.*Rlow+a.*Rhi));
end

function img = crism_sumutil_band_depth_invert(spectrum,wvt,low,mid,hi,low_width,mid_width,hi_width)
    %extract single bands from the spectrum, replacing CRISM_NAN with IEEE NAN
    Rlow = crism_sumutil_single(spectrum,wvt,low,low_width);
    Rmid = crism_sumutil_single(spectrum, wvt,mid,mid_width);
    Rhi = crism_sumutil_single(spectrum, wvt,hi,hi_width);

    %determine wavelength values for closest crism channels
    WL = wvt(ASD_lookupwv(low,wvt));
    WC = wvt(ASD_lookupwv(mid,wvt));
    WH = wvt(ASD_lookupwv(hi, wvt));
    a = (WC-WL)./(WH-WL);     % a gets multipled by the longer band
    b = 1.0-a;               % b gets multiplied by the shorter band

    %compute the band depth using precomputed a and b
    img = 1.0 - (( b.*Rlow + a.* Rhi )./ Rmid );
end

function low = crism_sumutil_band_depth_min(spectrum,wvt,low1,mid1,hi1,low2,mid2,hi2,low_width1,mid_width1,hi_width1,low_width2,mid_width2,hi_width2)
    spot1=crism_sumutil_band_depth(spectrum, wvt, low1, mid1, hi1,low_width1,mid_width1,hi_width1);
    spot2=crism_sumutil_band_depth(spectrum, wvt, low2, mid2, hi2,low_width2,mid_width2,hi_width2);
    low = min([spot1,spot2]);
end

function single = crism_sumutil_single(spectrum,wvt,band_wavelength,kernel_width)
    if nargin < 4
        kernel_width = 5;
    end
    R_indx = ASD_lookupwv(band_wavelength,wvt);
    half_width = fix(kernel_width/2);
    if (R_indx-half_width)<0
        minidx = 0;  %clamp to 0 if R-half_width is less than 0
        maxidx = R_indx+half_width;
    elseif (R_indx+half_width) > (length(wvt)-1)
    	maxidx = (length(wvt)-1); %clamp to max index if R+half_width is past the end
        minidx = R_indx-half_width;
    else
        minidx = R_indx-half_width;
        maxidx = R_indx+half_width;
    end
%check the wavelength extremes to ensure there are no gaps in wavelength within the kernel
    wavelength_coverage = abs(wvt(minidx)-wvt(maxidx));
    mean_wavelength_per_channel = 6.55e-3; %um/channel
    max_allowable_missing_channels = 2.0; 
    wavelength_gap_tolerance = mean_wavelength_per_channel*(kernel_width + max_allowable_missing_channels);
    if wavelength_coverage > wavelength_gap_tolerance
        fprintf('kernel wavelength coverage exceeds max wavelength gap tolerance. (%.2f um < %.2f um)',wavelength_coverage,wavelength_gap_tolerance);
        fprint('    kernel width = %.2f',kernel_width);
        fprint('    center wavelength = %.2f',wvt(R_indx))
        fprint('    wavelength table index = %.2f',R_indx)
        fprint('    kernel wavelengths: %.2f, %.2f, %.2f, %.2f, %.2f', wvt(minidx:maxidx));
    end
    %create a subsetted wavelength table and find the corresponding index in the subsetted table
    wvt_n=wvt(minidx:maxidx);  
    R_indx_n=ASD_lookupwv(band_wavelength,wvt_n);
    %subset the "kernel_width" spectral pixels centered on the base wavelength and
    %filter the subsetted spectrum using either boxcar or median filtering
    smthspectrum = smooth(spectrum(minidx:maxidx), kernel_width);
    single = smthspectrum(R_indx_n);
end

function index = ASD_lookupwv(lam, wvlarr)
[val,index] = min(abs(wvlarr-lam));
end

function img = crism_summary_olindex3(spectrum, wvt)
    R1210 = crism_sumutil_single(spectrum, wvt, 1.210,7);
    R1250 = crism_sumutil_single(spectrum, wvt, 1.250,7);
    R1263 = crism_sumutil_single(spectrum, wvt, 1.263,7);
    R1276 = crism_sumutil_single(spectrum, wvt, 1.276,7);
    R1330 = crism_sumutil_single(spectrum, wvt, 1.330,7); 
    R1750 = crism_sumutil_single(spectrum, wvt, 1.750,7); 
    R1862 = crism_sumutil_single(spectrum, wvt, 1.862,7);
    
    %identify nearest CRISM wavelength
    W1210 = wvt(ASD_lookupwv(1.210,wvt));
    W1250 = wvt(ASD_lookupwv(1.250,wvt));
    W1263 = wvt(ASD_lookupwv(1.263,wvt));
    W1276 = wvt(ASD_lookupwv(1.276,wvt));
    W1330 = wvt(ASD_lookupwv(1.330,wvt));
    W1750 = wvt(ASD_lookupwv(1.750,wvt));
    W1862 = wvt(ASD_lookupwv(1.862,wvt));
    
    %compute the corrected reflectance interpolating 
    slope = (R1862-R1750)./(W1862-W1750);   %slope = ( R2120 - R1690 ) / ( W2120 - W1690 )
    intercept = R1862-slope.*W1862;              %intercept = R2120 - slope * W2120

    %weighted sum of relative differences

    Rc1210 = slope.*W1210+intercept;
    Rc1250 = slope.*W1250+intercept;
    Rc1263 = slope.*W1263+intercept;
    Rc1276 = slope.*W1276+intercept;
    Rc1330 = slope.*W1330+intercept;

    img = (((Rc1210-R1210)./(abs(Rc1210))).*0.1)+(((Rc1250-R1250)./(abs(Rc1250))).*0.1)+...
        (((Rc1263-R1263)./(abs(Rc1263))).*0.2)+(((Rc1276-R1276)./(abs(Rc1276))).*0.2)+(((Rc1330-R1330)./(abs(Rc1330))).* 0.4);  
end

function img = crism_summary_lcpindex2(spectrum,wvt)
    % extract channels from spectrum replacing CRISM_NAN with IEEE_NaN
    R1690 = crism_sumutil_single(spectrum, wvt, 1.690,7);
    R1750 = crism_sumutil_single(spectrum, wvt, 1.750,7);
    R1810 = crism_sumutil_single(spectrum, wvt, 1.810,7);
    R1870 = crism_sumutil_single(spectrum, wvt, 1.870,7);
    R1560 = crism_sumutil_single(spectrum, wvt, 1.560,7); 
    R2450 = crism_sumutil_single(spectrum, wvt, 2.450,7);
    
    %identify nearest CRISM wavelength
    W1690 = wvt(ASD_lookupwv(1.690,wvt));
    W1750 = wvt(ASD_lookupwv(1.750,wvt));
    W1810 = wvt(ASD_lookupwv(1.810,wvt));
    W1870 = wvt(ASD_lookupwv(1.870,wvt));   
    W1560 = wvt(ASD_lookupwv(1.560,wvt));
    W2450 = wvt(ASD_lookupwv(2.450,wvt));
            
    %compute the corrected reflectance interpolating 
    slope = (R2450-R1560)./(W2450-W1560);
    intercept = R2450-slope.*W2450;

    %weighted sum of relative differences
    Rc1690 = slope.* W1690 + intercept;
    Rc1750 = slope.* W1750 + intercept;
    Rc1810 = slope.* W1810 + intercept;
    Rc1870 = slope.* W1870 + intercept;
       
    img=((1-(R1690./Rc1690)).*0.2) + ((1-(R1750./Rc1750)).*0.2) + ((1-(R1810./Rc1810)).*0.3) + ((1-(R1870./Rc1870)).*0.3);    
end

function img = crism_summary_hcpindex2(spectrum,wvt)
    %extract channels from spectrum replacing CRISM_NAN with IEEE_NaN
    R2120 = crism_sumutil_single(spectrum, wvt, 2.120,5); 
    R2140 = crism_sumutil_single(spectrum, wvt, 2.140,7);
    R2230 = crism_sumutil_single(spectrum, wvt, 2.230,7);
    R2250 = crism_sumutil_single(spectrum, wvt, 2.250,7);
    R2430 = crism_sumutil_single(spectrum, wvt, 2.430,7);
    R2460 = crism_sumutil_single(spectrum, wvt, 2.460,7);
    R1690 = crism_sumutil_single(spectrum, wvt, 1.690,7);
    %R1810 = crism_sumutil_single(spectrum, wvt, 1.810,7);
    R2530 = crism_sumutil_single(spectrum, wvt, 2.530,7);
        
    %identify nearest CRISM wavelength
    W2120 = wvt(ASD_lookupwv(2.120,wvt));
    W2140 = wvt(ASD_lookupwv(2.140,wvt));
    W2230 = wvt(ASD_lookupwv(2.230,wvt));
    W2250 = wvt(ASD_lookupwv(2.250,wvt));
    W2430 = wvt(ASD_lookupwv(2.430,wvt));
    W2460 = wvt(ASD_lookupwv(2.460,wvt));
    W1690 = wvt(ASD_lookupwv(1.690,wvt));
    %W1810 = wvt(ASD_lookupwv(1.810,wvt));
    W2530 = wvt(ASD_lookupwv(2.530,wvt));
        
	%compute the corrected reflectance interpolating 
	%slope = ( R2530 - R1810 ) / ( W2530 - W1810 )         
    slope = ( R2530 - R1690 )./( W2530 - W1690 );      
    intercept = R2530 - slope.* W2530;

	%weighted sum of relative differences
    Rc2120 = slope.* W2120 + intercept;
    Rc2140 = slope.* W2140 + intercept;
    Rc2230 = slope.* W2230 + intercept;
    Rc2250 = slope.* W2250 + intercept;
    Rc2430 = slope.* W2430 + intercept;
    Rc2460 = slope.* W2460 + intercept;

    img=((1-(R2120./Rc2120)).*0.1) + ((1-(R2140./Rc2140)).*0.1) + ((1-(R2230./Rc2230)).*0.15) + ((1-(R2250./Rc2250)).*0.3) + ((1-(R2430./Rc2430)).*0.2) + ((1-(R2460./Rc2460)).*0.15);
end

function img = crism_summary_islope1(spectrum,wvt)
    %extract individual bands with CRISM_NAN replaced with IEEE NaN
    R1815 = crism_sumutil_single(spectrum, wvt,1.815,5);
    R2530 = crism_sumutil_single(spectrum, wvt,2.530,5);
    W1815 = wvt(ASD_lookupwv(1.815,wvt));
    W2530 = wvt(ASD_lookupwv(2.530,wvt));

    %want in units of reflectance / um
    img = 1000.*(R1815-R2530)./(W2530-W1815);
end

function img = crism_summary_bd1900r2(spectrum,wvt)
    %extract individual channels, replacing CRISM_NANs with IEEE_NaNs
    R1908 = crism_sumutil_single(spectrum, wvt, 1.908,1); 
    R1914 = crism_sumutil_single(spectrum, wvt, 1.914,1); 
    R1921 = crism_sumutil_single(spectrum, wvt, 1.921,1); 
    R1928 = crism_sumutil_single(spectrum, wvt, 1.928,1); 
    R1934 = crism_sumutil_single(spectrum, wvt, 1.934,1); 
    R1941 = crism_sumutil_single(spectrum, wvt, 1.941,1); 
    R1862 = crism_sumutil_single(spectrum, wvt, 1.862,1); 
    R1869 = crism_sumutil_single(spectrum, wvt, 1.869,1); 
    R1875 = crism_sumutil_single(spectrum, wvt, 1.875,1); 
    R2112 = crism_sumutil_single(spectrum, wvt, 2.112,1); 
    R2120 = crism_sumutil_single(spectrum, wvt, 2.120,1); 
    R2126 = crism_sumutil_single(spectrum, wvt, 2.126,1); 
    R1815 = crism_sumutil_single(spectrum, wvt, 1.815,5);
    R2132 = crism_sumutil_single(spectrum, wvt, 2.132,5); 
    
    %retrieve the CRISM wavelengths nearest the requested values
    W1908 = wvt(ASD_lookupwv(1.908, wvt)); 
    W1914 = wvt(ASD_lookupwv(1.914, wvt));
    W1921 = wvt(ASD_lookupwv(1.921, wvt));
    W1928 = wvt(ASD_lookupwv(1.928, wvt));
    W1934 = wvt(ASD_lookupwv(1.934, wvt));
    W1941 = wvt(ASD_lookupwv(1.941, wvt));
    W1862 = wvt(ASD_lookupwv(1.862, wvt));
    W1869 = wvt(ASD_lookupwv(1.869, wvt));
    W1875 = wvt(ASD_lookupwv(1.875, wvt));
    W2112 = wvt(ASD_lookupwv(2.112, wvt));
    W2120 = wvt(ASD_lookupwv(2.120, wvt));
    W2126 = wvt(ASD_lookupwv(2.126, wvt));
    W1815 = wvt(ASD_lookupwv(1.815, wvt));    
    W2132 = wvt(ASD_lookupwv(2.132, wvt));   
    
    %compute the interpolated continuum values at selected wavelengths between 1815 and 2530
    slope = ( R2132 - R1815 )./( W2132 - W1815 );
    CR1908 = R1815 + slope .* ( W1908 - W1815 );
    CR1914 = R1815 + slope .* ( W1914 - W1815 );
    CR1921 = R1815 + slope .* ( W1921 - W1815 ); 
    CR1928 = R1815 + slope .* ( W1928 - W1815 );
    CR1934 = R1815 + slope .* ( W1934 - W1815 );
    CR1941 = R1815 + slope .* ( W1941 - W1815 ); 
    CR1862 = R1815 + slope .* ( W1862 - W1815 );
    CR1869 = R1815 + slope .* ( W1869 - W1815 );
    CR1875 = R1815 + slope .* ( W1875 - W1815 );   
    CR2112 = R1815 + slope .* ( W2112 - W1815 );
    CR2120 = R1815 + slope .* ( W2120 - W1815 );
    CR2126 = R1815 + slope .* ( W2126 - W1815 );
    
    img= 1.0-((R1908./CR1908+R1914./CR1914+R1921./CR1921+R1928./CR1928+R1934./CR1934+R1941./CR1941)./(R1862./CR1862+R1869./CR1869+R1875./CR1875+R2112./CR2112+R2120./CR2120+R2126./CR2126));
end

function img = crism_summary_d2200(spectrum, wvt)
    % extract individual channels, replacing CRISM_NANs with IEEE_NaNs
    R1815 = crism_sumutil_single(spectrum, wvt, 1.815,7);
    R2165 = crism_sumutil_single(spectrum, wvt, 2.165,5); 
    R2210 = crism_sumutil_single(spectrum, wvt, 2.210,7);     
    R2230 = crism_sumutil_single(spectrum, wvt, 2.230,7); 
    R2430 = crism_sumutil_single(spectrum, wvt, 2.430,7); %2530


    %retrieve the CRISM wavelengths nearest the requested values
    W1815 = (ASD_lookupwv(1.815, wvt));
    W2165 = (ASD_lookupwv(2.165, wvt));  
    W2210 = (ASD_lookupwv(2.210, wvt));
    W2230 = (ASD_lookupwv(2.230, wvt));
    W2430 = (ASD_lookupwv(2.430, wvt));

    %compute the interpolated continuum values at selected wavelengths between 1815 and 2530
    slope = ( R2430 - R1815 ) ./ ( W2430 - W1815 );
    CR2165 = R1815 + slope .* ( W2165 - W1815 );
    CR2210 = R1815 + slope .* ( W2210 - W1815 );
    CR2230 = R1815 + slope .* ( W2230 - W1815 );
    %compute d2300 with IEEE NaN values in place of CRISM NaN
    img = 1-(((R2210./CR2210)+(R2230./CR2230))./(2.*(R2165./CR2165)));    
end

function img = crism_summary_bdcarb(spectrum,wvt)
    % extract channels, replacing CRISM_NAN with IEEE NAN
    R2230 = crism_sumutil_single( spectrum, wvt,2.230,5);
    R2320 = crism_sumutil_single( spectrum, wvt,2.320,5);
    R2330 = crism_sumutil_single( spectrum, wvt,2.330,5);
    R2390 = crism_sumutil_single( spectrum, wvt,2.390,5);
    R2520 = crism_sumutil_single( spectrum, wvt,2.520,5);
    R2530 = crism_sumutil_single( spectrum, wvt,2.530,5);
    R2600 = crism_sumutil_single( spectrum, wvt,2.600,5);

    %identify nearest CRISM wavelengths
    WL1 = wvt(ASD_lookupwv(2.230,wvt));
    WC1 = (wvt(ASD_lookupwv(2.330,wvt))+wvt(ASD_lookupwv(2.320,wvt))).*0.5;
    WH1 =  wvt(ASD_lookupwv(2.390,wvt));
    a =  ( WC1 - WL1 )./ ( WH1 - WL1 );  % a gets multipled by the longer (higher wvln)  band
    b = 1.0-a;                          % b gets multiplied by the shorter (lower wvln) band

    WL2 =  wvt(ASD_lookupwv(2.390,wvt));
    WC2 = (wvt(ASD_lookupwv(2.530,wvt))+wvt(ASD_lookupwv(2.520,wvt))).*0.5;
    WH2 =  wvt(ASD_lookupwv(2.600,wvt));
    c = ( WC2 - WL2 ) ./ ( WH2 - WL2 );  % c gets multipled by the longer (higher wvln)  band
    d = 1.0-c;                           % d gets multiplied by the shorter (lower wvln) band

    %compute bdcarb
    img = 1.0-(sqrt((((R2320 + R2330).*0.5)./(b.*R2230+a.*R2390)).*(((R2520+R2530).*0.5)./(d.*R2390+c.*R2600))));  %MISTAKE d was accidently multiplied by 2230 instead of 2390  (CEV 4/12)
end

function img = crism_summary_d2300(spectrum, wvt)
    % extract individual channels, replacing CRISM_NANs with IEEE_NaNs
    R1815 = crism_sumutil_single(spectrum, wvt, 1.815,5);
    R2120 = crism_sumutil_single(spectrum, wvt, 2.120,5); 
    R2170 = crism_sumutil_single(spectrum, wvt, 2.170,5); 
    R2210 = crism_sumutil_single(spectrum, wvt, 2.210,5); 
    R2290 = crism_sumutil_single(spectrum, wvt, 2.290,3); 
    R2320 = crism_sumutil_single(spectrum, wvt, 2.320,3); 
    R2330 = crism_sumutil_single(spectrum, wvt, 2.330,3); 
    R2530 = crism_sumutil_single(spectrum, wvt, 2.530,5); %2530


    %retrieve the CRISM wavelengths nearest the requested values
    W1815 = wvt(ASD_lookupwv(1.815, wvt));
    W2120 = wvt(ASD_lookupwv(2.120, wvt));
    W2170 = wvt(ASD_lookupwv(2.170, wvt));
    W2210 = wvt(ASD_lookupwv(2.210, wvt));
    W2290 = wvt(ASD_lookupwv(2.290, wvt));
    W2320 = wvt(ASD_lookupwv(2.320, wvt));
    W2330 = wvt(ASD_lookupwv(2.330, wvt));
    W2530 = wvt(ASD_lookupwv(2.530, wvt));

    %compute the interpolated continuum values at selected wavelengths between 1815 and 2530
    slope = ( R2530 - R1815 )./ ( W2530 - W1815 );
    CR2120 = R1815 + slope.* ( W2120 - W1815 );
    CR2170 = R1815 + slope.* ( W2170 - W1815 );
    CR2210 = R1815 + slope.* ( W2210 - W1815 );
    CR2290 = R1815 + slope .* ( W2290 - W1815 );
    CR2320 = R1815 + slope .* ( W2320 - W1815 );
    CR2330 = R1815 + slope .* ( W2330 - W1815 );
    %compute d2300 with IEEE NaN values in place of CRISM NaN
    img = 1 - (((R2290./CR2290) + (R2320./CR2320) + (R2330./CR2330))./((R2120./CR2120) + (R2170./CR2170) + (R2210./CR2210))); 
end

function var = crism_summary_var(spectrum,wvt)
    R1021_indx = ASD_lookupwv(1.021, wvt);
    R2253_indx = ASD_lookupwv(2.253, wvt);
    wvs=wvt(R1021_indx:R2253_indx);
    varslopelams = [wvt(ASD_lookupwv(1.014,wvt)), wvt(ASD_lookupwv(2.287,wvt))];
    varslopewl   = [ASD_lookupwv(1.014,wvt), ASD_lookupwv(2.287,wvt)];
                    
    varslopers = zeros(length(varslopelams),1);

    for k = 1:length(varslopelams)
        varslopers(k) = spectrum(varslopewl(k));
    end    
 
    %Find the actual reflectances
    obsrs = NaN(length(wvs),1);
    for  k = 1:length(wvs)
        indx = ASD_lookupwv(wvs(k),wvt);
        obsrs(k) = spectrum(indx);
    end

    %Fit a line and find the variance:
    fit = fitlm(varslopelams, varslopers); %THIS NEEDS to be FIXED
    predrs = fit.Coefficients{1,1} + fit.Coefficients{2,1}.*wvs;
    var = sum((predrs - obsrs).^2);
end
