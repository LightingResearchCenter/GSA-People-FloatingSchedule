function [interval, location, startTime, endTime] = LRCImportWork(file)
% imports the work log given by file.

% Import work log cell array
[~,~,workLogCell] = xlsread(file);

% Find rows with NaN and delete them
nanIdxCell = cellfun(@isnan,workLogCell,'UniformOutput',false);
nanIdxMat = cellfun(@any,nanIdxCell);
nanIdxVec = any(nanIdxMat,2);
workLogCell = workLogCell(~nanIdxVec,:);

% Split columns into variables and format
interval = cell2mat(workLogCell(2:end,1));
location = workLogCell(2:end,2);
startTime = datenum(workLogCell(2:end,3));
endTime = datenum(workLogCell(2:end,4));

end