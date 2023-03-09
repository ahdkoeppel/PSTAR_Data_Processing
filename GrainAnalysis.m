%% Grain Micrscope imaging processing Code
% Ari Koeppel - Feb 2023
%Method:
%1) Mask out around central circle
%2) Matlab image segmentation tool with global graph cut
%3) Fill holes
%4) erode pixelated edges with a diamond shape strel @ 1 pt and then blurr
%with conv2 window = 10; kernel = ones(windowSize) / windowSize ^ 2;
%5) delete any shapes w areas smaller than 100 px (unnoticed regions)
%6) check and edit by hand
%7) extract statistics for each shape and save to master file

%REFS: Cruz-Matías et al., 2019; Chmielowska, 2021
clear all
close all
fontSize = 14;

[file,path] = uigetfile('X:\common\FIELD_CAMPAIGNS\Grain_Microscopy_General\2023-PSTAR-FINESST-Samples\*.jpg');
fullImageFileName = fullfile(path,file);
[rgbImage storedColorMap] = imread(fullImageFileName); 
[rows columns numberOfColorBands] = size(rgbImage);
lowerGrainlim = 10; upperGrainlim = 800;


% Mask out black
clear maskedImage mask
[rows columns numberOfColorBands] = size(rgbImage);
Radius = 700;
xcenter = 805;
ycenter = 1020;
angles = linspace(0, 2*pi, 10000);
x = cos(angles) * Radius + xcenter;
y = sin(angles) * Radius + ycenter;
mask = poly2mask(x, y, rows, columns);
maskedImage = bsxfun(@times, rgbImage, cast(mask, class(rgbImage)));
% Crop the image to the bounding box.
props = regionprops(mask, 'BoundingBox');
maskedImage = imcrop(maskedImage, props.BoundingBox);

% a = figure;
% subplot(2, 2, 1);
% imshow(rgbImage);
% axis('on', 'image');
% title('Original Image');
% % Maximize the window to make it easier to draw.
% g = gcf;
% g.WindowState = 'maximized';
% title('Original Image');
% subplot(2, 2, 2);
% imshow(rgbImage);
% axis('on', 'image');
% hold on;
% plot(x, y, 'r-', 'LineWidth', 2);
% title('Original image with circle mask overlaid');
% % Get a mask of the circle
% subplot(2, 2, 3);
% imshow(mask);
% axis('on', 'image');
% title('Circle Mask');
% % Display it in the lower right plot.
% h1 = subplot(2, 2, 4);
% imshow(maskedImage, []);
% % Change imshow to image() if you don't have the Image Processing Toolbox.
% title('Image masked with the circle');


% Segmentation
close all
imageSegmenter(maskedImage)
[rows columns numberOfColorBands] = size(maskedImage); 
%Global Graph cut seems best
%% Display
BWf = imfill(BW, 'holes');
seD = strel('diamond',2);
BWe = imerode(BWf,seD);
windowSize = 10;
kernel = ones(windowSize) / windowSize ^ 2;
blurryImage = conv2(single(BWe), kernel, 'same');
BWe = blurryImage > 0.5; % Rethreshold
newbinaryImage = bwareaopen(BWe,100);
% BWb = imerode(BWb,seD);
h = figure;
subplot(1, 2, 1);
imshow(maskedImage);
axis('on', 'image');
title('Original Image');
subplot(1, 2, 2);
matchingColors = bsxfun(@times, maskedImage, cast(newbinaryImage, class(maskedImage)));
imshow(matchingColors);
title('Binary Image, obtained by thresholding');
set(gcf, 'Position', get(0,'Screensize'));
% Repeat as many times as needed to separate grains
% h.CurrentCharacter = 's';
while true
    if ~ishghandle(h)%||strcmp(h.CurrentCharacter,'q')
        break;
    end
    roi_remove = drawfreehand('Color','r');
    if ~ishghandle(h)
        break;
    end
    mask_remove = createMask(roi_remove);
    newbinaryImage = newbinaryImage-mask_remove;
    newbinaryImage(newbinaryImage>0)=1;
    newbinaryImage(newbinaryImage<0)=0;
    newbinaryImage = bwareaopen(newbinaryImage,20);
    newbinaryImage = imfill(newbinaryImage, 'holes');
    matchingColors = bsxfun(@times, maskedImage, cast(newbinaryImage, class(maskedImage)));
    imshow(matchingColors);
    set(gcf, 'Position', get(0,'Screensize'));
end
%% Grab Grain Statistics
% newbinaryImage = imfill(BW, 'holes');
[B,L] = bwboundaries(newbinaryImage,'noholes');
stats = regionprops(L,'Area','Centroid','MajorAxisLength','MinorAxisLength','Circularity','Solidity','MaxFeretProperties','MinFeretProperties','ConvexImage','Perimeter');
figure
imshow(maskedImage, []);
hold on
GrainCount = 1;
Circularity = NaN(1,length(B));
AspectRatio = NaN(1,length(B));
AspectRatio_Feret = NaN(1,length(B));
Solidity = NaN(1,length(B));
ASTM_Roundness = NaN(1,length(B));
Convexity = NaN(1,length(B));
for k = 1:length(B)
  % obtain (X,Y) boundary coordinates corresponding to label 'k'
  boundary = B{k};
  % compute a simple estimate of the object's perimeter
%   delta_sq = diff(boundary).^2;    
%   perimeter = sum(sqrt(sum(delta_sq,2)));
     % compute the roundness metric
  Circularity(k) = stats(k).Circularity;%4*pi*stats(k).Area/perimeter^2;
  AspectRatio(k) = stats(k).MinorAxisLength/stats(k).MajorAxisLength;
  AspectRatio_Feret(k) = stats(k).MinFeretDiameter/stats(k).MaxFeretDiameter;
  Solidity(k) = stats(k).Solidity;
  ASTM_Roundness(k) = 4*stats(k).Area/(pi*stats(k).MajorAxisLength^2);
  clear BC LC
  [BC,LC] = bwboundaries(stats(k).ConvexImage,'noholes');
  delta_sq = diff(BC{:}).^2;    
  Con_perimeter = sum(sqrt(sum(delta_sq,2)));
  Convexity(k) = Con_perimeter/stats(k).Perimeter;
  %if the identified grains are too big or too small, they're not grains
  if stats(k).MinorAxisLength > upperGrainlim || stats(k).MinorAxisLength < lowerGrainlim
    AspectRatio(k) = NaN;
    AspectRatio_Feret(k) = NaN;
    Circularity(k) = NaN;
    Solidity(k) = NaN;
    ASTM_Roundness(k) = NaN;
    Convexity(k) = NaN;
  else
    plot(boundary(:,2),boundary(:,1),'r','LineWidth',2)
    text(boundary(1,2)-35,boundary(1,1)+13,sprintf('%2g',GrainCount),'Color','y',...
       'FontSize',14,'FontWeight','bold')
    GrainCount = GrainCount + 1;
  end  
end
AspectRatio(isnan(AspectRatio)) = [];
AspectRatio_Feret(isnan(AspectRatio_Feret)) = [];
Circularity(isnan(Circularity)) = [];
Solidity(isnan(Solidity)) = [];
ASTM_Roundness(isnan(ASTM_Roundness)) = [];
Convexity(isnan(Convexity)) = [];

%% Save results to table
Grain_ID = 1:GrainCount-1;
names = {'FILE';'GrainID';'Aspect_Ratio';'AspectRatio_Feret';'Circularity';'Solidity';'ASTM_Roundness';'Convexity'};
for i = Grain_ID
    FILES{i} = file;
end
Output = table(FILES',Grain_ID', AspectRatio', AspectRatio_Feret', Circularity', Solidity', ASTM_Roundness', Convexity','VariableNames',names);
if isfile('X:\common\FIELD_CAMPAIGNS\Grain_Microscopy_General\2023-PSTAR-FINESST-Samples\GrainData.xls')
    Grain_Data = readtable('X:\common\FIELD_CAMPAIGNS\Grain_Microscopy_General\2023-PSTAR-FINESST-Samples\GrainData.xls');
    Grain_Data = [Grain_Data;Output];
else
    Grain_Data = Output;
end
writetable(Grain_Data,'X:\common\FIELD_CAMPAIGNS\Grain_Microscopy_General\2023-PSTAR-FINESST-Samples\GrainData.xls')

