clear; close all; clc;
delete(serialportfind);

lidarPort = '/dev/cu.usbserial-0001'; 
baudRate = 230400; 

try
    s = serialport(lidarPort, baudRate);
    pause(1);
    write(s, [165 96], "uint8"); 
    fprintf('Motor spinning. Initializing High-Res Capture...\n');
    pause(2);
catch ME
    error('Connection failed. Unplug and replug the USB.');
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
        if sampleQuantity == 0 || startIdx + 10 + sampleQuantity*2 > length(rawRow), continue; end
        
        startAngle_raw = double(rawRow(startIdx+5))*256 + double(rawRow(startIdx+4));
        endAngle_raw = double(rawRow(startIdx+7))*256 + double(rawRow(startIdx+6));
        
        startAngle = bitshift(startAngle_raw, -1) / 64; 
        endAngle = bitshift(endAngle_raw, -1) / 64;
        if endAngle < startAngle, endAngle = endAngle + 360; end
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

write(s, [165 101], "uint8"); 
clear s;

fprintf('Constructing Professional Occupancy Grid Map...\n');
finalMap = lidarPointClouds.PointCloud{1}; 

for n = 2:height(lidarPointClouds)
    finalMap = pcmerge(finalMap, lidarPointClouds.PointCloud{n}, 0.01);
end

points = finalMap.Location;
x_2d = double(points(:, 1));
y_2d = double(points(:, 2));

map = occupancyMap(10, 10, 200);
map.GridLocationInWorld = [-5, -5]; 

insertRay(map, [0, 0], [x_2d, y_2d]);

bgColor = [0.2 0.2 0.2];
hFig = figure('Name', 'Professional Stationary Map', 'Color', bgColor, 'Position', [100, 100, 900, 800]);
ax = axes('Parent', hFig, 'Color', bgColor);

show(map, 'Parent', ax); 
hold(ax, 'on');

grid(ax, 'on');
set(ax, 'GridColor', 'w', 'GridAlpha', 0.15, 'GridLineStyle', '--');

plot(ax, 0, 0, 'gs', 'MarkerSize', 14, 'MarkerFaceColor', '#00FF00', 'HandleVisibility', 'off'); 

plot(ax, NaN, NaN, 'ks', 'MarkerFaceColor', 'k', 'MarkerSize', 10, 'DisplayName', 'Wall / Obstacle');
plot(ax, NaN, NaN, 'ws', 'MarkerFaceColor', 'w', 'MarkerSize', 10, 'DisplayName', 'Clear Space');
plot(ax, NaN, NaN, 'gs', 'MarkerFaceColor', '#00FF00', 'MarkerSize', 10, 'DisplayName', 'LiDAR Sensor');
legend(ax, 'show', 'Location', 'northeast', 'Color', [0.3 0.3 0.3], 'TextColor', 'w', 'EdgeColor', '#555555');

title(ax, 'Ultra High-Resolution Room Map', 'Color', 'w', 'FontSize', 14);
xlabel(ax, 'X (meters)', 'Color', 'w');
ylabel(ax, 'Y (meters)', 'Color', 'w');

zoomLimit = 3.5; 
xlim(ax, [-zoomLimit zoomLimit]);
ylim(ax, [-zoomLimit zoomLimit]);

fprintf('✅ Map rendering complete!\n');
