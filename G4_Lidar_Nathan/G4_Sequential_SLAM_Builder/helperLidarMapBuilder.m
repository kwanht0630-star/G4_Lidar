classdef helperLidarMapBuilder < handle

    %helperLidarMapBuilder Build a map from Lidar data
    
    properties (Access = public)
        DownsampleGridStep(1,1)  double = 0.2
        RegistrationInlierRatio(1,1) double = 0.35
        MergeGridStep(1,1) double = 0.5
    end
    
    properties (SetAccess = protected)
        Map(1,1) pointCloud = pointCloud(zeros(0,0,3,'single'));
        AccumTform(1,1) rigidtform3d = rigidtform3d();
        RelativePositions = zeros(0,3);
        Axes
        ViewSet(1,1) pcviewset = pcviewset();
        LoopDetector(1,1) scanContextLoopDetector = scanContextLoopDetector();
    end
    
    properties (Access = protected)
        Fixed(1,1) pointCloud = pointCloud(zeros(0,0,3,'single'));
        Moving(1,1) pointCloud = pointCloud(zeros(0,0,3,'single'));
        PreviousTform(1,1) rigidtform3d = rigidtform3d();
        IsInitialized(1,1) logical = false;
        LoopDetectorParameters
        LoopConfirmationRMSE(1,1) double = 4.5;
        ScatterPoints
        ScatterTrajectory
        ViewId
        Verbose
        DetectLoops(1,1) logical = false;
    end
    
    methods
        function this = helperLidarMapBuilder(varargin)

            % Use inputParser to handle Name-Value pairs

            parser = inputParser;
            parser.addParameter('DownsampleGridStep', 0.2);
            parser.addParameter('RegistrationInlierRatio', 0.35);
            parser.addParameter('MergeGridStep', 0.5);
            parser.addParameter('Verbose', false);
            parse(parser, varargin{:});
            params = parser.Results;

            this.DownsampleGridStep      = params.DownsampleGridStep;
            this.RegistrationInlierRatio = params.RegistrationInlierRatio;
            this.MergeGridStep           = params.MergeGridStep;
            this.Verbose                 = params.Verbose;
            
            reset(this);
        end
        
        function tform = updateMap(this, ptCloudIn, varargin)
            if nargin > 2
                tformInit = varargin{1};
            else
                if ~this.IsInitialized
                    tformInit = rigidtform3d;
                else
                    tformInit = this.PreviousTform;
                end
            end
            
            if all(isnan(ptCloudIn.Location), 'all')
                tform = rigidtform3d; 
                return; 
            end
            
            ptCloud = pcdownsample(ptCloudIn, 'gridAverage', this.DownsampleGridStep);
            origin = [0 0 0];
            
            if ~this.IsInitialized
                this.Moving = ptCloud;
                this.Map    = ptCloud;
                this.ViewId = 1;
                this.RelativePositions = origin;
                this.ViewSet = addView(this.ViewSet, this.ViewId, this.AccumTform, 'PointCloud', ptCloudIn);
                this.ViewId = this.ViewId + 1;
                this.IsInitialized = true;
                tform = rigidtform3d;
            else
                this.Fixed  = this.Moving;
                this.Moving = ptCloud;
                
                % ICP Registration

                tform = pcregistericp(this.Moving, this.Fixed, 'Metric', 'planeToPlane', ...
                    'InitialTransform', tformInit, 'InlierRatio', this.RegistrationInlierRatio);
                    
                this.AccumTform = rigidtform3d(this.AccumTform.A * tform.A);
                this.ViewSet = addView(this.ViewSet, this.ViewId, this.AccumTform, 'PointCloud', ptCloudIn);
                this.ViewSet = addConnection(this.ViewSet, this.ViewId-1, this.ViewId, tform);
                
                this.RelativePositions(end+1,:) = transformPointsForward(this.AccumTform, origin);
                movingReg = pctransform(this.Moving, this.AccumTform);
                this.Map = pcmerge(this.Map, movingReg, this.MergeGridStep);
                
                this.PreviousTform = tform;
                this.ViewId = this.ViewId + 1;
            end
        end
        
        function isDisplayOpen = updateDisplay(this, closeDisplay)
            if closeDisplay
                closeFigureDisplay(this); 
                isDisplayOpen = false; 
                return; 
            end
            if isempty(this.Axes) || ~isvalid(this.Axes)
                setupFigureDisplay(this); 
            end
            
            xyzPoints = this.Map.Location;
            set(this.ScatterPoints, 'XData', xyzPoints(:,1), 'YData', xyzPoints(:,2), 'CData', xyzPoints(:,3));
            set(this.ScatterTrajectory, 'XData', this.RelativePositions(:,1), 'YData', this.RelativePositions(:,2));
            drawnow limitrate
            isDisplayOpen = isvalid(this.Axes);
        end

        function reset(this)
            this.IsInitialized = false;
            this.Map = pointCloud(zeros(0,0,3,'single'));
            this.ViewSet = pcviewset;
            this.AccumTform = rigidtform3d;
            this.RelativePositions = zeros(0,3);
            this.Axes = [];
        end
    end
    
    methods (Access = protected)
        function setupFigureDisplay(this)
            hFig = figure('Name', 'Lidar Map Builder', 'Color', 'k');
            this.Axes = axes('Parent', hFig, 'Color', 'k', 'XColor', 'w', 'YColor', 'w');
            axis(this.Axes, 'equal');
            hold(this.Axes, 'on');
            this.ScatterPoints = scatter(this.Axes, NaN, NaN, 6, NaN, '.');
            this.ScatterTrajectory = scatter(this.Axes, NaN, NaN, 25, 'w', 'filled');
            xlabel(this.Axes, 'X (m)'); ylabel(this.Axes, 'Y (m)');
        end

        function closeFigureDisplay(this)
            if ~isempty(this.Axes) && isvalid(this.Axes)
                close(this.Axes.Parent); 
            end
        end
    end
end