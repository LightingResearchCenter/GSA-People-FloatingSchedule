function param = averageanalysis(dailyParam)
%AVERAGEANALYSIS Summary of this function goes here
%   Detailed explanation goes here

% Unnest parameters
flatParam = cat(1,dailyParam{:});
if isempty(flatParam)
    param = struct;
    return;
end

varNames = fieldnames(flatParam)';
tempCell = struct2cell(flatParam)';

% Remove empty rows
emptyIdx = cellfun(@isempty,tempCell);
emptyRow = any(emptyIdx,2);
tempCell1 = tempCell(~emptyRow,:);

% Separate numeric parameters
idx1 = cellfun(@isnumeric,tempCell1);
idx2 = ~any(~idx1,1);
varNames2 = varNames(idx2);
tempCell2 = tempCell1(:,idx2);

% Average numeric parameters
tempMat = cell2mat(tempCell2);
tempMat2 = mean(tempMat,1);

% Create structure for output
tempCell3 = num2cell(tempMat2);
if isempty(tempCell3)
    param = struct;
else
    param = cell2struct(tempCell3,varNames2,2);

    % Intervals averaged
    param.nIntervalsAveraged = size(tempMat,1);
end

end

