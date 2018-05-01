%imshow(I);
%c1 = rand(5,5,3);
%cStitched = c1; % Initialize with the first one.
%subplot(1,2,2);%this just tells you where in the frame you want the image
%imshow(c1)

testImage = cat(3, [1 1 0; 0 0 0; 1 0 0],[0 1 0; 0 0 0; 0 1 0],[0 1 1; 0 0 0; 0 0 1]);
testCat = cat(3, testImage, [0 1 1; 0 0 0; 0 0 1],[0 1 1; 0 0 0; 0 0 1]);

testConnectivity = bwconncomp(testImage);%this identifies the objects in an image
testPixelArray = testConnectivity.PixelIdxList;%to access items in structure created use a structure.x syntax
testReferenceCell = testPixelArray{1};

%imshow(testStitchImage2);

testStitchImage2 = stitchImage('t3_p4_s15', 1);
testCatImage = cat(3, imageTop ,imageMid, imageBot);
testGet3DImage = Get3DImage('t3_p4_s',1);
testImagePixelArray = testGet3DImage.PixelIdxList;%this item contains an array where each cell contains the pixel coordinates of each elemnent in the object
testImageIndObjCoords = testImagePixelArray{2};
size = [1024,1024,18];
[Xc, Yc, Zc] = ind2sub(size,testImageIndObjCoords);
testNormalizeCoords = NormalizeCoords(Xc, Yc, Zc);
testImageSubObjectCoordinates = cat(2, Xc, Yc, Zc);
testGetDisances = GetDistances(testImageSubObjectCoordinates(1,1:3),testImageSubObjectCoordinates(8,1:3));%this works, computes the distance between two points

testGetAggregateCoordinates = GetAggregateCoordinates(testGet3DImage,2);%this works!
testImageGetDistances = GetDistances(testGetAggregateCoordinates(1,1:3),testGetAggregateCoordinates(5,1:3));
aggregate1 = GetAggregateCoordinates(testGet3DImage,1);
aggregate2 = GetAggregateCoordinates(testGet3DImage,2);
pixel1 = aggregate2(1,1:3);
shortestdist = 20000;%for testing shortest distance bit
for pixel = 1:numel(aggregate2(:,1))
    distance = GetDistances(aggregate1(1,1:3),aggregate2(pixel,1:3));
    if (distance<shortestdist)
        shortestdist = distance;
    end
end
    
testGetAllObjectsSizes = GetAllObjectsSizes(testGet3DImage);%this works
testGetObjectSize = GetObjectSize(testGet3DImage,1);%this works
testGetShortestDistance = GetShortestDistance(testGet3DImage,1,1,testGet3DImage,2);%this works!
testGetShortestInterAggregateDist = GetShortestInterAggregateDist (testGet3DImage,1,testGet3DImage,2);%this works, but I haven't confirmed it independently

testCount = GetAllShortestInterAggregateDist(testGet3DImage,testGet3DImage);

timepoints = 11;
positions = 4;
slices = 139;

for position =0:positions
    for timePoint = 0:timepoints
        testGet3DImage = Get3DImage('t3_p4_s',1);
        name = strcat('images/t',num2str(timePoint),'_p',num2str(position),'_s');
        redStructure = Get3DImage(name, 1);
        greenStructure = Get3DImage(name, 2);
        distanceDataRG = GetAllShortestInterAggregateDist(redStructure,greenStructure);  
        fileName = strcat('interAggegateDistanceRG',num2str(timempoint),'_p',num2str(position),'.csv');
        csvwrite(fileName,results)
        distanceDataRR = GetAllShortestInterAggregateDist(redStructure,redStructure);  
        fileName = strcat('interAggegateDistanceRR',num2str(timempoint),'_p',num2str(position),'.csv');
        csvwrite(fileName,results)
        distanceDataGG = GetAllShortestInterAggregateDist(greenStructure,greenStructure);        
        fileName = strcat('interAggegateDistanceGG',num2str(timempoint),'_p',num2str(position),'.csv');
        csvwrite(fileName,results)
    end
end

function shortDistanceList = GetAllShortestInterAggregateDist(threeDStructure1,threeDStructure2) %this function has input two 3D structures and outputs a list of shortest interaggregate distance between all aggregates
%shortDistanceList = zeros(threeDStructure1.NumObjects*threeDStructure1.NumObjects,5);
shortDistanceList = zeros (16,5);
%for agg1 = 1:threeDStructure1.NumObjects
for agg1 = 1:4
    %for agg2 = 1:threeDStructure2.NumObjects
    for agg2 = 1:4
        count = ((agg1-1)*4)+agg2;
        shortDistanceList(count,1)= agg1;%aggregate 1 number
        shortDistanceList(count,2)= GetObjectSize(threeDStructure1,agg1);%volume aggregate 1
        shortDistanceList(count,3)= agg2;%aggregate 2 number
        shortDistanceList(count,4)= GetObjectSize(threeDStructure2,agg2);%volume aggregate 2
        shortDistanceList(count,5)= GetShortestInterAggregateDist(threeDStructure1,agg1,threeDStructure2,agg2);%inter-aggregate shortest distance
    end
end
end

function shortestInterAggregateDist = GetShortestInterAggregateDist (threeDStructure1, agg1,threeDStructure2,agg2)
samplingAgg = GetAggregateCoordinates(threeDStructure1,agg1);
shortestdist = 20000;
for pixel = 1:numel(samplingAgg(:,1))
    distance = GetShortestDistance(threeDStructure1,agg1,pixel,threeDStructure2,agg2);%this will get the shortest distance from pixel "pixel" in agg1 to all pixels in agg2
    if (distance<shortestdist)
        shortestdist = distance;
    end
end
shortestInterAggregateDist = shortestdist;
end

function shortestDist = GetShortestDistance(threeDStructureFocal,focalAggregate,focalPixel,threeDStructureTarget,targetAggregate)%this function calculates shortest distance of an aggregate to a point
focalAggregate = GetAggregateCoordinates(threeDStructureFocal,focalAggregate);
focus = focalAggregate(focalPixel,1:3);
target = GetAggregateCoordinates(threeDStructureTarget,targetAggregate);
shortestdist = 20000;
for pixel = 1:numel(target(:,1))
    distance = GetDistances(focus,target(pixel,1:3));
    if (distance<shortestdist)
        shortestdist = distance;
    end
end
shortestDist = shortestdist;
end

function objectSizes = GetAllObjectsSizes(threeDStructure)
objectSizes = cellfun(@numel,threeDStructure.PixelIdxList);
end

function objectSize = GetObjectSize(threeDStructure,aggNumber)
objectSize = numel(threeDStructure.PixelIdxList{aggNumber});
objectSize = objectSize*.264*.264*.433;
end

function distance = GetDistances(A, B)
pairwiseArray = cat(1, A,B);
distance = pdist(pairwiseArray);
end

function ObjectCoordinates = GetAggregateCoordinates (threeDStructure,aggNumber)%this gives you the pixel coordinates of the aggregate "aggnumber"
linearPixelCoordsArray = threeDStructure.PixelIdxList;%this item contains an array where each cell contains the pixel coordinates of each elemnent in the object
size = [1024,1024,18];%this is necessary to convert from single digit coordinates to cartesian
objectCoords = linearPixelCoordsArray{aggNumber};%pick aggregate from structure
[Xcoord, Ycoord, Zcoord] = ind2sub(size,objectCoords);%converts single digit coordinates to cartesian
ObjectCoordinates = NormalizeCoords(Xcoord, Ycoord, Zcoord);%get real coordinates
end

function ObjectCoordinates = NormalizeCoords(X,Y,Z)% get real coordinates, translate from pixels to microns
Xnorm = (X-1)*0.264;%x scale
Ynorm = (Y-1)*0.264;%y scale
Znorm = (Z-1)*0.433;%z scale
ObjectCoordinates = cat(2, Xnorm, Ynorm, Znorm);
end

function threeDStructure = Get3DImage(name, channel)%this function creates a 3D matrix of a single channel containing all the objects in the confocal stack
%the x increases to the right, left increases down and z starts at the
%bottom, reverse right-hand rule coordinates
threeDimage = stitchImage(strcat(name, '0'), channel);
for slice = 1:17
    currentImage = stitchImage(strcat(name,num2str(slice)), channel);
    threeDimage = cat(3,threeDimage,currentImage);
end
threeDStructure = bwconncomp(threeDimage);%this item contains all the info from the 3D objects generated from the image stack
end

function I = stitchImage(name,channel) %This function stitches the tiles and returns a 2D matrix of channel specified,
IA = im2double(imread(strcat(name,'_m0.tiff')));
IB = im2double(imread(strcat(name,'_m1.tiff')));
top = cat(2, IA,IB);
IC = im2double(imread(strcat(name,'_m2.tiff')));
ID = im2double(imread(strcat(name,'_m3.tiff')));
bottom = cat(2, IC,ID);
Im = cat(1,top,bottom);
I = squeeze(Im(:,:,channel));
end

