clear; close all; clc;
delete(serialportfind);

lidarPort = '/dev/cu.usbserial-0001'; 
baudRate = 230400; 

try
    s = serialport(lidarPort, baudRate);
    pause(1);
    write(s, [165 96], "uint8"); 
    fprintf('🔥 Motor spinning. Initializing Live Heatmap...\n');
    pause(2);
catch ME
    error('Connection failed. Unplug and replug the USB.');
end

mapSize = 8; 
resolution = 50; 
gridPixels = mapSize * resolution;

heatGrid = zeros(gridPixels, gridPixels);

hFig = figure('Name', 'Live Spatial Heatmap', 'Color', 'w');

cmap = turbo(256);      
cmap(1, :) = [1 1 1];   
colormap(hFig, cmap);

while ishandle(hFig)
    
    if s.NumBytesAvailable < 4000
        pause(0.05); 
        continue; 
    end
    
    raw = read(s, s.NumBytesAvailable, "uint8");
    rawRow = raw(:)'; 
    headers = strfind(rawRow, [170 85]); 
    
    allX = [];
    allY = [];
    
    for h = 1:length(headers)-1
        startIdx = headers(h);
        if startIdx + 10 > length(rawRow), continue; end
        
        sampleQuantity = double(rawRow(startIdx+3));
        if sampleQuantity == 0 || startIdx + 10 + sampleQuantity*2 > length(rawRow)
            continue;
        end
        
        startAngle_raw = double(rawRow(startIdx+5))*256 + double(rawRow(startIdx+4));
        endAngle_raw = double(rawRow(startIdx+7))*256 + double(rawRow(startIdx+6));
        
        startAngle = bitshift(startAngle_raw, -1) / 64; 
        endAngle = bitshift(endAngle_raw, -1) / 64;
        if endAngle < startAngle, endAngle = endAngle + 360; end
        angleStep = (endAngle - startAngle) / max(1, sampleQuantity - 1);
        
        for k = 1:sampleQuantity
            distIdx = startIdx + 10 + (k-1)*2;
            dist_mm = (double(rawRow(distIdx+1))*256 + double(rawRow(distIdx))) / 4; 
            
            if dist_mm > 100 && dist_mm < 8000
                currentAngle = startAngle + angleStep * (k-1);
                allX = [allX; (dist_mm * cos(deg2rad(currentAngle))) / 1000];
                allY = [allY; (dist_mm * sin(deg2rad(currentAngle))) / 1000];
            end
        end
    end
    
    if ~isempty(allX)
        px = round(allX * resolution + (gridPixels / 2));
        py = round(allY * resolution + (gridPixels / 2));
        
        valid = px >= 1 & px <= gridPixels & py >= 1 & py <= gridPixels;
        px = px(valid); 
        py = py(valid);
        
        for i = 1:length(px)
            heatGrid(py(i), px(i)) = heatGrid(py(i), px(i)) + 1;
        end
        
        try
            renderGrid = imgaussfilt(heatGrid, 0.8);
        catch
            renderGrid = heatGrid;
        end
        
        imagesc([-mapSize/2 mapSize/2], [-mapSize/2 mapSize/2], renderGrid);
        
        set(gca, 'YDir', 'normal', 'Color', 'w', 'XColor', 'k', 'YColor', 'k');
        axis equal; xlim([-mapSize/2 mapSize/2]); ylim([-mapSize/2 mapSize/2]);
        
        colorbar; 
        
        title('Live Room Density Heatmap', 'Color', 'k');
        xlabel('X (Meters)', 'Color', 'k'); ylabel('Y (Meters)', 'Color', 'k');
        
        drawnow limitrate;
    end
end

try
    write(s, [165 101], "uint8"); 
    clear s;
    fprintf('✅ Window closed. Heatmap Session Ended.\n');
catch
end