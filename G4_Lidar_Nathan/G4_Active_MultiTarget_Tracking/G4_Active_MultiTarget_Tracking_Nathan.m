clear; close all; clc;
delete(serialportfind);

lidarPort = '/dev/cu.usbserial-0001'; 
baudRate = 230400; 

try
    s = serialport(lidarPort, baudRate);
    pause(1);
    write(s, [165 96], "uint8");
    fprintf('🎯 Motor spinning. Initializing Multi-Target Radar...\n');
    pause(2);
catch ME
    error('Connection failed. Unplug and replug the USB.');
end

greyColor = [0.2 0.2 0.2];
hFig = figure('Name', 'Live Multi-Target Radar', 'Color', greyColor, 'Position', [100, 100, 800, 800]);
ax = axes('Parent', hFig, 'Color', greyColor, 'XColor', 'w', 'YColor', 'w');
hold(ax, 'on');
axis(ax, 'equal'); 
grid(ax, 'on');
set(ax, 'GridColor', '#555555', 'GridAlpha', 0.7);

% --- ZOOM ADJUSTMENT ---
% Reduced from 4 to 1.5 to zoom in on close-range targets
scanRadius = 1.5; 
maxTargets = 5;       
clearRadius = 0.3;    

xlim(ax, [-scanRadius scanRadius]); 
ylim(ax, [-scanRadius scanRadius]);
title(ax, 'Active Multi-Target Tracking', 'Color', 'w', 'FontSize', 14);

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
    allAngles = [];
    allDistances = [];
    
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
                dist_m = dist_mm / 1000; 
                
                allX = [allX; dist_m * cos(deg2rad(currentAngle))];
                allY = [allY; dist_m * sin(deg2rad(currentAngle))];
                allAngles = [allAngles; currentAngle];
                allDistances = [allDistances; dist_m];
            end
        end
    end
    
    if ~isempty(allX)
        cla(ax);
        
        plot(ax, allX, allY, '.', 'Color', '#00FFFF', 'MarkerSize', 5);
        
        plot(ax, 0, 0, 'g.', 'MarkerSize', 20);
        
        tempDistances = allDistances;
        
        for t = 1:maxTargets
            [minDist, idx] = min(tempDistances);
            
            if minDist > 0 && minDist < scanRadius
                closestX = allX(idx);
                closestY = allY(idx);
                closestAngle = allAngles(idx);
                
                plot(ax, [0, closestX], [0, closestY], '-', 'Color', '#FF3333', 'LineWidth', 1.2);
                
                plot(ax, closestX, closestY, 'ro', 'MarkerSize', 10, 'LineWidth', 2);
                
                readout = sprintf('  %.2fm @ %.0f%c', minDist, closestAngle, char(176));
                text(ax, closestX, closestY, readout, 'Color', '#FFFF00', 'FontSize', 11, 'FontWeight', 'bold');
                
                distToTarget = sqrt((allX - closestX).^2 + (allY - closestY).^2);
                tempDistances(distToTarget < clearRadius) = Inf; 
            else
                break;
            end
        end
        
        axis(ax, 'equal'); 
        xlim(ax, [-scanRadius scanRadius]); 
        ylim(ax, [-scanRadius scanRadius]);
        grid(ax, 'on');
        
        drawnow limitrate;
    end
end

try
    write(s, [165 101], "uint8");
    clear s;
    fprintf('✅ Proximity Radar Session Ended.\n');
catch
end
