clear; close all; clc;
delete(serialportfind);

port = "/dev/cu.usbserial-0001";
baudRate = 115200; 

try
    s = serialport(port, baudRate);
    
    write(s, [165 37], "uint8"); 
    pause(0.5);
    flush(s);
    
    write(s, [165 32], "uint8"); 
    fprintf('🚀 RPLIDAR Started. Initializing custom parser...\n');
    pause(1);
catch ME
    error('Cannot connect. Ensure the port name is correct and unplug/replug the USB.');
end

map = occupancyMap(10, 10, 40);
map.GridLocationInWorld = [-5, -5];
hFig = figure('Name', 'RPLIDAR Direct Map', 'Color', [0.3 0.3 0.3]);

while ishandle(hFig)
    if s.NumBytesAvailable < 1500
        pause(0.05);
        continue;
    end
    
    raw = read(s, s.NumBytesAvailable, "uint8");
    rawRow = raw(:)';
    
    b1_sync = bitand(rawRow(1:end-4), 3); 
    b2_sync = bitand(rawRow(2:end-3), 1); 
    
    validIdx = find((b1_sync == 1 | b1_sync == 2) & b2_sync == 1);
    
    if isempty(validIdx)
        continue;
    end
    
    dist_mm = (double(rawRow(validIdx+4)) * 256 + double(rawRow(validIdx+3))) / 4;
    angles_deg = (double(rawRow(validIdx+2)) * 128 + floor(double(rawRow(validIdx+1)) / 2)) / 64;
    
    good = dist_mm > 150 & dist_mm < 8000;
    dist_m = dist_mm(good) / 1000; 
    angles = angles_deg(good);
    
    x = dist_m .* cos(deg2rad(angles));
    y = dist_m .* sin(deg2rad(angles));
    
    if ~isempty(x)
        insertRay(map, [0,0], [x', y']);
        
        show(map, 'Parent', gca); hold on;
        
        plot(0, 0, 'gs', 'MarkerSize', 14, 'MarkerFaceColor', '#00FF00'); 
        
        title('Live Custom RPLIDAR Occupancy Map', 'Color', 'w');
        xlabel('X (m)', 'Color', 'w'); ylabel('Y (m)', 'Color', 'w');
        grid on; set(gca, 'GridColor', 'w', 'GridAlpha', 0.2);
        hold off;
        
        drawnow limitrate;
    end
end

write(s, [165 37], "uint8"); 
clear s;
fprintf('LiDAR stopped and disconnected.\n');