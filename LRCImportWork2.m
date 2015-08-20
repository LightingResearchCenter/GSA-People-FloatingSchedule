function workDay = LRCImportWork2(file)
% imports the work log given by file.

% Import work log cell array
[~,~,workLogCell] = xlsread(file,'A1:D101');

% Find rows with NaN and delete them
nanIdxCell = cellfun(@isnan,workLogCell,'UniformOutput',false);
nanIdxMat = cellfun(@any,nanIdxCell);
nanIdxVec = any(nanIdxMat,2);
workLogCell = workLogCell(~nanIdxVec,:);

% Split columns into variables and format
if isempty(workLogCell(2:end,3))
    workDay = [];
else
    workDay = floor(datenum(workLogCell(2:end,3)));
end

end