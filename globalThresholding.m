timepoints = 10;
positions = 9;%this number is actually posisions-1, because the zero is not counted here
for position = 0:positions;
collectThresholdGreen = zeros(timepoints+1, 1);%this is a list where the threshold of each stack is stored
collectThresholdRed = zeros(timepoints+1, 1);
for timempoint = 0:timepoints;
    totalCountsR = zeros(256,1);%creates array to store histograms
    totalCountsG = zeros(256,1);
    for slice = 0:89;
        if (slice>=10) && (slice<=99)
            if(timempoint<10)
                name = strcat('p',num2str(position),'/t0',num2str(timempoint),'/11-8-17_z',num2str(slice),'_t0',num2str(timempoint),'_p',num2str(position),'.tif');
            else
                name = strcat('p',num2str(position),'/t',num2str(timempoint),'/11-8-17_z',num2str(slice),'_','t',num2str(timempoint),'_p',num2str(position),'.tif');
            end
        elseif (slice<10)
            if(timempoint<10)
                name = strcat('p',num2str(position),'/t0',num2str(timempoint),'/11-8-17_z0',num2str(slice),'_t0',num2str(timempoint),'_p',num2str(position),'.tif');
            else
                name = strcat('p',num2str(position),'/t',num2str(timempoint),'/11-8-17_z0',num2str(slice),'_','t',num2str(timempoint),'_p',num2str(position),'.tif');
            end
            
        end
        I = im2double(imread(name));
        %extract individual channels
        %(not necessary in this case since this images are monochromatic
        ImR = squeeze(I(:,:,1));
        ImG = squeeze(I(:,:,2));
        ImB = squeeze(I(:,:,3));
        %change range
        ImR1 = mat2gray(ImR);
        ImG1 = mat2gray(ImG);
        %get histogram
        [countsR,xR] = imhist(ImR1);
        [countsG,xG] = imhist(ImG1);
        %add pixels of stack to total pixels
        totalCountsR= totalCountsR+countsR;
        totalCountsG= totalCountsG+countsG;
        %binarize using "global" algorithm
        Tr=otsuthresh(totalCountsR);%this threshold keeps getting optomized until the loop ends.
        Tg=otsuthresh(totalCountsG);
    end
    collectThresholdRed(timempoint+1)=Tr;%this correction is because matlab starts at 1 and timepoints at 0
    collectThresholdGreen(timempoint+1)=Tg;
end

for timempoint = 0:timepoints;
    totalSegments=0;
    results = zeros(1,5);
    for slice = 0:89;
        if (slice>=10) && (slice<=99)
            if(timempoint<10)
                name = strcat('p',num2str(position),'/t0',num2str(timempoint),'/11-8-17_z',num2str(slice),'_t0',num2str(timempoint),'_p',num2str(position),'.tif');
            else
                name = strcat('p',num2str(position),'/t',num2str(timempoint),'/11-8-17_z',num2str(slice),'_','t',num2str(timempoint),'_p',num2str(position),'.tif');
            end
        elseif (slice<10)
            if(timempoint<10)
                name = strcat('p',num2str(position),'/t0',num2str(timempoint),'/11-8-17_z0',num2str(slice),'_t0',num2str(timempoint),'_p',num2str(position),'.tif');
            else
                name = strcat('p',num2str(position),'/t',num2str(timempoint),'/11-8-17_z0',num2str(slice),'_','t',num2str(timempoint),'_p',num2str(position),'.tif');
            end
        end
        I = im2double(imread(name));
        [r, c, p] = size(I);%store size of picture
        %extract individual channels...
        %single channel
        ImR = squeeze(I(:,:,1));
        ImG = squeeze(I(:,:,2));
        ImG1 = mat2gray(ImG);
        ImR1 = mat2gray(ImR);

        %binarize using "global" algorithm and global threshold
        ImRiB = imbinarize(ImR1,collectThresholdRed(timempoint+1));
        ImGiB = imbinarize(ImG1,collectThresholdGreen(timempoint+1));
        %clean up image using maximum object size
        ImNeR = (bwareaopen(ImRiB,10));%Global algorithm
        ImNeG = (bwareaopen(ImGiB,10));
        %combine channels
        rgbImG = cat(3,ImNeR,ImNeG,ImB);%Global algorithm
        %get objects
        rgbImBi = im2bw(rgbImG, 0.01);
        [labels1,numLabels1] = bwlabel(rgbImBi);
        [labelsR,numLabelsR] = bwlabel(ImNeR);
        [labelsG,numLabelsG] = bwlabel(ImNeG);

        results = [results;zeros(numLabels1, 5)];
        for item = totalSegments+1:totalSegments+numLabels1
            labels = zeros(r,c);%zero array to imprint each combined aggregate
            zeroG = zeros(r,c);%zero array to imprint red portion of the aggregate
            zeroR = zeros(r,c);%zero array to imprint green portion of the aggregate
            labels(labels1==(item-totalSegments))=1;%pick the aggregate 
            redInt = labels+ImNeR;%add red and combined binary images
            greenInt = labels+ImNeG;%add green and combined binary images
            aggregateSize = nnz(labels);%declare meaningful variable names

            zeroG(greenInt==2)=1;%store green overlaping pixels on an array
            zeroR(redInt==2)=1;%store blue overlaping pixels on an array
            greenPixels = nnz(zeroG);%store amount of green overlap
            redPixels = nnz(zeroR);%store amount of red overlap
            overlap = redPixels+greenPixels-aggregateSize;
            %add results to table
            results(item,1)= aggregateSize;
            results(item,2)= redPixels;
            results(item,3)= greenPixels;
            results(item,4)= overlap;
            results(item,5)= slice;
        end
        totalSegments= totalSegments+numLabels1;
    end
    fileName = strcat('results/t',num2str(timempoint),'_p',num2str(position),'.csv');
    csvwrite(fileName,results)
end
end