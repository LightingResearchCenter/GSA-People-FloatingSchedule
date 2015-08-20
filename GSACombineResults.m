%% Reset
close all
clear
clc

%% Folder Paths
[buildingDir,summerParentDir,~,winterParentDir,~,~] = GSADirBuildingSelect;
summerDirObj = LRCDirInit(summerParentDir);
winterDirObj = LRCDirInit(winterParentDir);

%% Find and Load Results

% Summer Find the most recent results
lsResults = dir([summerDirObj.results,filesep,'results*.mat']);
[~,idxResults] = max([lsResults.datenum]);
lsResults = lsResults(idxResults);
summerResultsPath = fullfile(summerDirObj.results,lsResults.name);

% Winter Find the most recent results
lsResults = dir([winterDirObj.results,filesep,'results*.mat']);
[~,idxResults] = max([lsResults.datenum]);
lsResults = lsResults(idxResults);
winterResultsPath = fullfile(winterDirObj.results,lsResults.name);

summerStruct = load(summerResultsPath);
winterStruct = load(winterResultsPath);

% Summer: Expand struct
summerResultsStruct = summerStruct.output_args;
idxEmpty = cellfun(@isempty,summerResultsStruct);
summerResultsStruct(idxEmpty) = [];
summerResultsStruct = [summerResultsStruct{:}];

% Summer: Expand struct
winterResultsStruct = winterStruct.output_args;
idxEmpty = cellfun(@isempty,winterResultsStruct);
winterResultsStruct(idxEmpty) = [];
winterResultsStruct = [winterResultsStruct{:}];

%% Combine Summer and Winter Results
combinedTable = GSACombine(summerResultsStruct,winterResultsStruct);

%% Convert Table to Cell matrix
combinedCell = table2cell(combinedTable);

% Prepare header rows
varNames = combinedTable.Properties.VariableNames;
group = regexp(varNames,'[^_]*(?=_[^_]*_[^_]*$)','match');
lastGroup = '';
for iG = 1:numel(group)
    if isempty(group{iG})
        group{iG} = '';
    end
    if iscell(group{iG})
        group{iG} = group{iG}{1};
    end
    
    temp = group{iG};
    if strcmp(group{iG},lastGroup)
        group{iG} = '';
    end
    lastGroup = temp;
end
group = lower(regexprep(group,'([A-Z0-9])',' $1'));
varDesc = combinedTable.Properties.VariableDescriptions;
lastDesc = '';
for iD = 1:numel(varDesc)
    if isempty(varDesc{iD})
        varDesc{iD} = '';
    end
    if iscell(varDesc{iD})
        varDesc{iD} = varDesc{iD}{1};
    end
    
    temp = varDesc{iD};
    if strcmp(varDesc{iD},lastDesc)
        varDesc{iD} = '';
    end
    lastDesc = temp;
end
season = regexp(varNames,'summer|winter','match');
header = [group;varDesc;season];

% Add header to cell contents
combinedCell = [header;combinedCell];

%% Replace empty and NaN
[m,n] = size(combinedCell);
for im = 1:m
    for in = 1:n
        thisCell = combinedCell{im,in};
        if iscell(thisCell)
            if isempty(thisCell)
                combinedCell{im,in} = '';
            else
                combinedCell{im,in} = thisCell{1};
            end
        end
        if isempty(combinedCell{im,in})
            combinedCell{im,in} = '';
        end
        if isnan(combinedCell{im,in})
            combinedCell{im,in} = 'NaN';
        end
    end
end

%% Write cell matrix to file
timestamp = datestr(now,'yyyymmdd-HHMMSS-FFF');
name = ['combinedResults-',timestamp,'.xlsx'];
excelPath = fullfile(buildingDir,name);
if exist(excelPath,'file') == 2
    delete(excelPath);
end
xlswrite(excelPath,combinedCell);