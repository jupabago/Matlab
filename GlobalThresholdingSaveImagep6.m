timepoints = 11;
positions = 5;
slices = 139;
filename = '/62x_SaLac-PAO1-PA14-SaPa01-SaPa14-bkgd_co_SCFM2_18hrTimeLapse_tile2x2_3-19-18_z';
for position = 0:positions
collectThresholdGreen = zeros(timepoints+1, 1);%this is a list where the threshold of each stack is stored
collectThresholdRed = zeros(timepoints+1, 1);
for timempoint = 0:timepoints
    totalCountsR = zeros(256,1);%creates array to store histograms
    totalCountsG = zeros(256,1);
    for slice = 0:slices
         if (slice<10)
            if(timempoint<10)
                for tile = 0:3
                    name = strcat('p',num2str(position),'/t0',num2str(timempoint),filename,'00',num2str(slice),'_t0',num2str(timempoint),'_p',num2str(position),'_m',num2str(tile),'.tif');
                end
            else
                for tile = 0:3
                    name = strcat('p',num2str(position),'/t',num2str(timempoint),filename,'00',num2str(slice),'_t',num2str(timempoint),'_p',num2str(position),'_m',num2str(tile),'.tif');
                end
            end
        elseif (slice>=10) && (slice<=99)
            if(timempoint<10)
                for tile = 0:3
                    name = strcat('p',num2str(position),'/t0',num2str(timempoint),filename,num2str(0),num2str(slice),'_t0',num2str(timempoint),'_p',num2str(position),'_m',num2str(tile),'.tif');
                end
            else
                for tile = 0:3
                    name = strcat('p',num2str(position),'/t',num2str(timempoint),filename,num2str(0),num2str(slice),'_t',num2str(timempoint),'_p',num2str(position),'_m',num2str(tile),'.tif');
                end
            end
       
        elseif (slice>99)
            if(timempoint<10)
                for tile = 0:3
                    name = strcat('p',num2str(position),'/t0',num2str(timempoint),filename,num2str(slice),'_t0',num2str(timempoint),'_p',num2str(position),'_m',num2str(tile),'.tif');
                end
            else
                for tile = 0:3
                    name = strcat('p',num2str(position),'/t',num2str(timempoint),filename,num2str(slice),'_t',num2str(timempoint),'_p',num2str(position),'_m',num2str(tile),'.tif');
                end
            end            
        end
        disp(name);
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

for timempoint = 0:timepoints
    totalSegments=0;
    results = zeros(1,5);
    for slice = 0:slices
        if (slice<10)
            if(timempoint<10)
                for tile = 0:3
                    name = strcat('p',num2str(position),'/t0',num2str(timempoint),filename,'00',num2str(slice),'_t0',num2str(timempoint),'_p',num2str(position),'_m',num2str(tile),'.tif');
                end
            else
                for tile = 0:3
                    name = strcat('p',num2str(position),'/t',num2str(timempoint),filename,'00',num2str(slice),'_t',num2str(timempoint),'_p',num2str(position),'_m',num2str(tile),'.tif');
                end
            end
        elseif (slice>=10) && (slice<=99)
            if(timempoint<10)
                for tile = 0:3
                    name = strcat('p',num2str(position),'/t0',num2str(timempoint),filename,'0',num2str(slice),'_t0',num2str(timempoint),'_p',num2str(position),'_m',num2str(tile),'.tif');
                end
            else
                for tile = 0:3
                    name = strcat('p',num2str(position),'/t',num2str(timempoint),filename,'0',num2str(slice),'_t',num2str(timempoint),'_p',num2str(position),'_m',num2str(tile),'.tif');
                end
            end    
        elseif (slice>99)
            if(timempoint<10)
                for tile = 0:3
                    name = strcat('p',num2str(position),'/t0',num2str(timempoint),filename,num2str(slice),'_t0',num2str(timempoint),'_p',num2str(position),'_m',num2str(tile),'.tif');
                end
            else
                for tile = 0:3
                    name = strcat('p',num2str(position),'/t',num2str(timempoint),filename,num2str(slice),'_t',num2str(timempoint),'_p',num2str(position),'_m',num2str(tile),'.tif');
                end
            end            
        end
        disp(name);
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
        [labels1,numLabels1] = bwlabel(rgbImBi);%combined image
        [labelsR,numLabelsR] = bwlabel(ImNeR);%red image
        [labelsG,numLabelsG] = bwlabel(ImNeG);%green image
        imageName = strcat('images/t',num2str(timempoint),'_p',num2str(position),'_s',num2str(slice),'_m',num2str(tile),'.tiff');
        imwrite(rgbImG,imageName);
        
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
    fileName = strcat('results/t',num2str(timempoint),'_p',num2str(position),'_m',num2str(tile),'.csv');
    csvwrite(fileName,results)
end
end