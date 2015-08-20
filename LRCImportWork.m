function [interval, location, startTime, endTime] = LRCImportWork(file)
% imports the work log given by file.

% Import work log cell array
[~,~,workLogCell] = xlsread(file,'A1:D101');

% Find rows with NaN and delete them
nanIdxCell = cellfun(@isnan,workLogCell,'UniformOutput',false);
nanIdxMat = cellfun(@any,nanIdxCell);
nanIdxVec = any(nanIdxMat,2);
workLogCell = workLogCell(~nanIdxVec,:);

% Split columns into variables and format
if isempty(workLogCell(2:end,3)) || isempty(workLogCell(2:end,4))
    interval = [];
    location = {};
    startTime = [];
    endTime = [];
else
    interval = cell2mat(workLogCell(2:end,1));
    location = workLogCell(2:end,2);
    startTime = datenum(workLogCell(2:end,3));
    endTime = datenum(workLogCell(2:end,4));

    % Make sure locations are strings
    strIdx = cellfun(@ischar,location);
    numIdx = ~strIdx;
    if any(numIdx)
        for iLoc = 1:numel(location)
            thisLoc = location{iLoc};
            if ~ischar(thisLoc)
                location{iLoc} = num2str(thisLoc);
            end
        end
    end
end
end