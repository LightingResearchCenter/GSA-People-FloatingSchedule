function workDay = LRCImportWork2(file)
% imports the work log given by file.

% Import work log cell array
[~,~,workLogCell] = xlsread(file,'A1:D101');

% Find rows with NaN and delete them
temp = workLogCell(:,3);
nanIdxCell = cellfun(@isnan,temp,'UniformOutput',false);
nanIdxVec = cellfun(@any,nanIdxCell);
workLogCell = workLogCell(~nanIdxVec,:);

% Split columns into variables and format
workDay = floor(datenum(workLogCell(2:end,3)));


end