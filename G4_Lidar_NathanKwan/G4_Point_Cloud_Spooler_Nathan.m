clearvars -except lidarPointClouds; close all; clc;
delete(serialportfind);

lidarPort = '/dev/cu.usbserial-0001'; 
baudRate = 230400; 

try
    s = serialport(lidarPort, baudRate);
    pause(1);
    write(s, [165 96], "uint8"); 
    fprintf('Lidar spinning. Initializing capture...\n');
    pause(2);
catch ME
    error('Connection failed. Unplug and replug the USB.');
end

numScansToRecord = 60; 
lidarPointClouds = timetable(); 

fprintf('Capturing %d frames. Move the Lidar SLOWLY...\n', numScansToRecord);

for i = 1:numScansToRecord
    while s.NumBytesAvailable < 4000
        pause(0.05); 
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
        ptCloud = pointCloud([allX, allY, zeros(size(allX))]);
        
        newEntry = timetable(seconds(i*0.1), {ptCloud}, 'VariableNames', {'PointCloud'});
        lidarPointClouds = [lidarPointClouds; newEntry];
        
        fprintf('Captured Frame %d/%d (%d points)\n', i, numScansToRecord, length(allX));
    end
end

write(s, [165 101], "uint8"); 
clear s;
fprintf('✅ Capture complete! The "lidarPointClouds" variable is now in your Workspace.\n');
fprintf('👉 You can now run your Map Builder script.\n');