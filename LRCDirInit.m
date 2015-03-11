classdef LRCDirInit
    %LRCDIRINIT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Dependent)
        parent
        original
        cropped
        logs
        plots
        results
    end
    
    properties (Access=private)
        privateParent
        privateOriginal
        privateCropped
        privateLogs
        privatePlots
        privateResults
    end
    
    methods
        function obj = LRCDirInit(parent)
            if nargin == 0
                parent = uigetdir;
            end
            obj.parent = parent;
        end
        
        function path = get.parent(obj)
            path = obj.privateParent;
        end
        function obj = set.parent(obj,path)
            obj.privateParent = path;
            obj.privateOriginal = fullfile(path,'originalData');
            obj.privateCropped = fullfile(path,'croppedData');
            obj.privateLogs = fullfile(path,'logs');
            obj.privatePlots = fullfile(path,'plots');
            obj.privateResults = fullfile(path,'results');
        end
        
        function path = get.original(obj)
            path = obj.privateOriginal;
        end
        
        function path = get.cropped(obj)
            path = obj.privateCropped;
        end
        
        function path = get.logs(obj)
            path = obj.privateLogs;
        end
        
        function path = get.plots(obj)
            path = obj.privatePlots;
        end
        
        function path = get.results(obj)
            path = obj.privateResults;
        end
    end
    
end

