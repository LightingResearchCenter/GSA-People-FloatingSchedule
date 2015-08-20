function LRCDataInventory(startingDir)
%LRCDATAINVENTORY Summary of this function goes here
%   Detailed explanation goes here

% Enable dependencies
circadianDir = 'C:\Users\jonesg5\Documents\GitHub\circadian';
addpath(circadianDir);

% Select input directory
selectedDir = uigetdir(startingDir);

% Find CDFs
listing = dir([selectedDir,filesep,'*.cdf']);

% Initialize variables
nCdf = numel(listing);
subjectID = cell(nCdf,1);
deviceSN = cell(nCdf,1);
fileName = {listing.name}';
filePath = fullfile(selectedDir,fileName);

% Inspect each CDF
for iCdf = 1:nCdf
    thisFilePath = filePath{iCdf};
    % Read CDF
    cdfData = daysimeter12.readcdf(thisFilePath);
    % Assign variables
    subjectID{iCdf,1} = cdfData.GlobalAttributes.subjectID;
    deviceSN{iCdf,1} = cdfData.GlobalAttributes.deviceSN;
end

% Assign information to table
unsortedTable = table(subjectID,deviceSN,fileName);
[~,idx] = sort(unsortedTable.subjectID);
sortedTable = unsortedTable(idx,:);
sortedCell = table2cell(sortedTable);
inventoryCell = [sortedTable.Properties.VariableNames;sortedCell];

[~,dirName,~] = fileparts(selectedDir);
excelName = ['inventory_',datestr(now,'yyyy-mm-dd_MMSS'),'_',dirName,'.xlsx'];
inventoryPath = fullfile(selectedDir,excelName);
xlswrite(inventoryPath,inventoryCell);

winopen(inventoryPath);

end

