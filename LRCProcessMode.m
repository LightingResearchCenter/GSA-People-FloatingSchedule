classdef LRCProcessMode
    %LRCPROCESSMODE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        mode
    end
    
    methods
        function obj = LRCProcessMode(modeStr)
            if nargin > 0
                switch lower(modeStr)
                    case 'update'
                        obj.mode = 'update';
                    case 'overwrite'
                        obj.mode = 'overwrite';
                    otherwise
                        error('Input of ''update'' or ''overwrite'' required.');
                end
            else
                obj = GUISelect(obj);
            end
        end
        
        function obj = GUISelect(obj)
            plainModeArray   = {'update','overwrite'};
            displayModeArray = {'Update (only process new items)',...
                'Overwrite (process all items, overwrite previous results)'};

            choice = menu('Choose a process mode',displayModeArray);

            obj.mode = plainModeArray{choice};
        end
        
    end
    
end

