delete(serialportfind);
clear s; 
lidarPort = '/dev/cu.usbserial-0001'; 
baudRate = 230400;

try
    s = serialport(lidarPort, baudRate);
    pause(1);
    write(s, [165 96], "uint8"); 
    fprintf('Motor spinning. Initializing High-Res Parser...\n');
    pause(2);
catch ME
    error('Connection failed. Please unplug and replug the LiDAR.');
end

numScans = 80; 
lidarPointClouds = timetable(); 

for i = 1:numScans
    while s.NumBytesAvailable < 4000, pause(0.05); end
    
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
        
        if endAngle < startAngle
            endAngle = endAngle + 360;
        end
        angleStep = (endAngle - startAngle) / max(1, sampleQuantity - 1);
        
        for k = 1:sampleQuantity
            distIdx = startIdx + 10 + (k-1)*2;
            dist_raw = double(rawRow(distIdx+1))*256 + double(rawRow(distIdx));
            dist_mm = dist_raw / 4; 
            
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
        fprintf('Scan %d/%d: Decoded %d perfectly aligned points\n', i, numScans, length(allX));
    end
end

fprintf('Constructing High-Resolution Occupancy Grid Map...\n');
finalMap = lidarPointClouds.PointCloud{1}; 

for n = 2:height(lidarPointClouds)
    finalMap = pcmerge(finalMap, lidarPointClouds.PointCloud{n}, 0.01);
end

points = finalMap.Location;
x_2d = double(points(:, 1));
y_2d = double(points(:, 2));

map = occupancyMap(10, 10, 40);

map.GridLocationInWorld = [-5, -5]; 

lidarStartPt = [0, 0]; 
endpoints = [x_2d, y_2d]; 

insertRay(map, lidarStartPt, endpoints);

figure('Name', 'High-Res Occupancy Grid Map', 'Color', [0.3 0.3 0.3]);

show(map); 
hold on;

grid on;
set(gca, 'GridColor', 'w', 'GridAlpha', 0.2);

plot(0, 0, 'gs', 'MarkerSize', 14, 'MarkerFaceColor', '#00FF00'); 

title('High-Resolution Probabilistic Occupancy Map', 'Color', 'w');
xlabel('X (meters)', 'Color', 'w');
ylabel('Y (meters)', 'Color', 'w');