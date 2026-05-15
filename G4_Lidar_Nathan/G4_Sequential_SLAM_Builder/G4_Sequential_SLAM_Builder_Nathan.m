if ~exist('lidarPointClouds', 'var') || isempty(lidarPointClouds)
    error('Timetable "lidarPointClouds" is missing or empty. Run your capture script first.');
end

params = struct(...
    'DownsampleGridStep', 0.05, ...
    'RegistrationInlierRatio', 0.1, ...
    'MergeGridStep', 0.02);

mapBuilder = helperLidarMapBuilder(...
    'DownsampleGridStep', params.DownsampleGridStep, ...
    'RegistrationInlierRatio', params.RegistrationInlierRatio, ...
    'MergeGridStep', params.MergeGridStep);

numFrames = height(lidarPointClouds);
tform = rigidtform3d;
fprintf('Starting SLAM mapping for %d frames...\n', numFrames);

lidarPath = zeros(numFrames, 2); 

for n = 1 : numFrames
    
    ptCloud = lidarPointClouds.PointCloud{n}; 
    
    if ptCloud.Count < 30
        lidarPath(n, :) = lidarPath(max(1, n-1), :); 
        continue;
    end
    
    ptCloudClean = pcdenoise(ptCloud, 'NumNeighbors', 4, 'Threshold', 0.5);
    locations = ptCloudClean.Location;
    locations(:,3) = 0; 
    ptCloudFlat = pointCloud(locations);
    
    try
        tform = updateMap(mapBuilder, ptCloudFlat, tform);
    catch ME
        fprintf('Skipping frame %d due to mismatch...\n', n);
    end
    
    lidarPath(n, :) = tform.Translation(1:2);
end

finalMap = mapBuilder.Map;
fprintf('Mapping complete. Final map contains %d points.\n', finalMap.Count);

wallPoints = finalMap.Location;
x_walls = wallPoints(:, 1);
y_walls = wallPoints(:, 2);

figure('Name', 'Final 2D SLAM Map (Light Theme)', 'Color', 'w');

plot(x_walls, y_walls, '.', 'Color', '#2C3E50', 'MarkerSize', 8);
hold on;

plot(lidarPath(:,1), lidarPath(:,2), '-', 'Color', '#3498DB', 'LineWidth', 1.5);

plot(lidarPath(1,1), lidarPath(1,2), 'go', 'MarkerSize', 8, 'MarkerFaceColor', 'g');

plot(lidarPath(end,1), lidarPath(end,2), 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'r');

title('YDLIDAR G4 Reconstructed Blueprint', 'Color', 'k');
xlabel('X (m)', 'Color', 'k'); 
ylabel('Y (m)', 'Color', 'k'); 
legend('Detected Walls', 'LiDAR Path', 'Start Position', 'Current Position', 'Location', 'best');

axis equal; 
grid on;
set(gca, 'Color', 'w', 'GridColor', '#AAAAAA', 'GridAlpha', 0.5);

xlim([-6 6]); ylim([-6 6]);
hold off;