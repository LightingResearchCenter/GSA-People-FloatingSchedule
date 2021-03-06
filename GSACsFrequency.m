function GSACsFrequency
%GSACSFREQUENCY Summary of this function goes here
%   Detailed explanation goes here

close all

% Enable dependencies
[gitHubDir,~,~] = fileparts(pwd);
circadianDir = fullfile(gitHubDir,'circadian');
addpath(circadianDir);

dataStore = fullfile(pwd,'dataStore.mat');

if fileDoesExist(dataStore)
    load(dataStore,'data');
else
    % Map directories
    [dataDirArray,locationArray,sessionArray] = mapDirs;

    % Map data paths
    cdfArray = mapData(dataDirArray);

    % Load data
    data = loadData(cdfArray);
    
    % Save data to file
    save(dataStore,'data');
end

% Extract variables from table
cs = cell2mat(data.cs);
work = cell2mat(data.work);
bed = cell2mat(data.bed);
cs_work = cs(work);
cs_waking = cs(~bed);
cs_nonwork_waking = cs(~bed & ~work);

% Plot data
plotHist(cs_work,'During Work Hours');
plotHist(cs_waking,'During Waking Hours');
plotHist(cs_nonwork_waking,'During Non-Work Waking Hours');

end

%% MARK: Histogram
function plotHist(cs,histTitle)
hFig = figure;
hAx = axes;
binLimits = [0,0.7];
binEdges = 0:0.01:0.7;
hHist = histogram(hAx,cs,...
    'BinLimits',binLimits,...
    'BinEdges',binEdges,...
    'Normalization','probability');

hAx.Box = 'off';
hAx.TickDir = 'out';
hAx.YLim = [0,0.3];
hAx.YTick = 0:0.05:0.3;

title(hAx,{'Distribution of Circadian Stimulus (CS):';histTitle});
xlabel(hAx,'Circadian Stimulus (CS)');
ylabel(hAx,'Probability');

yTickLabel = cellstr(num2str(hAx.YTick'*100)); 
pct = char(ones(size(yTickLabel,1),1)*'%');
yTickLabel = [char(yTickLabel),pct];
hAx.YTickLabel = yTickLabel;

saveas(hFig,[histTitle,'.jpg']);
end

%% MARK: Read files

function data = loadData(cdfArray)

nCdf = numel(cdfArray);
temp = cell(nCdf,1);
vnames = {'subjectId','location','session','time','cs','work','bed'};
data = table(temp,temp,temp,temp,temp,temp,temp,'VariableNames',vnames);

for iCdf = 1:nCdf
    thisCdf = cdfArray{iCdf};
    [subjectId,location,session,time,cs,work,bed] = prepData(thisCdf);
    data.subjectId{iCdf} = subjectId;
    data.location{iCdf} = location;
    data.session{iCdf} = session;
    data.time{iCdf} = time;
    data.cs{iCdf} = cs;
    data.work{iCdf} = work;
    data.bed{iCdf} = bed;
end


end

function [subjectId,location,session,time,cs,work,bed] = prepData(cdfPath)

[location,session] = decomposePath(cdfPath);

rawData = daysimeter12.readcdf(cdfPath);

% Extract subject ID
subjectId = rawData.GlobalAttributes.subjectID;

% Convert masks to logical format
observation = logical(rawData.Variables.logicalArray(:));
compliance = logical(rawData.Variables.complianceArray(:));

% Crop data to observation and compliance
idxKeep = observation & compliance;

% Extract, crop, and convert bed
bed = logical(rawData.Variables.bedArray(idxKeep));

% Extract and crop CS
cs = rawData.Variables.CS(idxKeep);

% Extract, crop, and convert time
cdfTime = rawData.Variables.time(idxKeep);
timeVec = (cdflib.epochBreakdown(cdfTime))';
dateVec = timeVec(:,1:6);
time = datetime(dateVec);

% Construct log path
logPath = constructLogPath(cdfPath,subjectId);

% If log exists attempt to read it else use static work times
if fileDoesExist(logPath)
    [~, ~, startTimeArray, endTimeArray] = LRCImportWork(logPath);
    startTimeArray = datetime(startTimeArray,'ConvertFrom','datenum');
    endTimeArray = datetime(endTimeArray,'ConvertFrom','datenum');
else
    [startTimeArray, endTimeArray] = createWorkLog(time);
end

% Create work index
work = createWorkIndex(time,startTimeArray,endTimeArray);

end

%% MARK: Work log

function [startTimeArray, endTimeArray] = createWorkLog(time)

days_datevec = datevec(time);
days_datevec(:,4:6) = 0;
uniqueDays_datevec = unique(days_datevec,'rows');
uniqueDays_datetime = datetime(uniqueDays_datevec);

TF = isweekend(uniqueDays_datetime);
weekDays_datevec = uniqueDays_datevec(~TF,:);

startTime_datevec = weekDays_datevec;
endTime_datevec = weekDays_datevec;

startTime_datevec(:,4) = 8; % 8 AM
endTime_datevec(:,4) = 17;  % 5 PM

startTimeArray = datetime(startTime_datevec);
endTimeArray = datetime(endTime_datevec);

end

function work = createWorkIndex(time,startTimeArray,endTimeArray)

nInt = numel(startTimeArray);
nTime = numel(time);
temp = false(nTime,nInt);

for iInt = 1:nInt
    thisStart = startTimeArray(iInt);
    thisEnd = endTimeArray(iInt);
    temp(:,iInt) = time >= thisStart & time < thisEnd;
end

work = any(temp,2);

end

%% MARK: File path mapping

function [dataDirArray,locationArray,sessionArray] = mapDirs

GSADir = '\\ROOT\projects\GSA_Daysimeter';

buildingBase = {
    'WashingtonDC\Daysimeter_People_Data';...
    'WashingtonDC-RegionalOfficeBldg-7th&Dstreet\Daysimeter_People_Data';...
    'Seattle_Washington\Daysimeter_People_Data\FCS_Building_1201';...
    'Seattle_Washington\Daysimeter_People_Data\FCS_Building_1202';...
    'GrandJunction_Colorado_site_data\Daysimeter_People_Data';...
    'Portland_Oregon_site_data\Daysimeter_People_Data'
    };

buildingDir = fullfile(GSADir,buildingBase);



summerDir = fullfile(buildingDir,'summer');
winterDir = fullfile(buildingDir,'winter');
seasonDir = [summerDir;winterDir];

locationArray = {'DC-1800F','DC-ROB','Seattle-1201','Seattle-1202','Grand Junction','Portland'}';

sessionArray = [repmat({'summer'},size(locationArray));repmat({'winter'},size(locationArray))];
locationArray = [locationArray;locationArray];

dataDirArray = fullfile(seasonDir,'croppedData');

tfDir = dirDoesExist(dataDirArray);
if any(~tfDir)
    warning('Missing directories removed from list.');
    dataDirArray(~tfDir) = [];
    sessionArray(~tfDir) = [];
    locationArray(~tfDir) = [];
end

end

function cdfArray = mapData(dataDirArray)

tempCellArray = cellfun(@findCdf,dataDirArray,'UniformOutput',false);

cdfArray = vertcat(tempCellArray{:});

end

function pathArray = findCdf(dirPath)

listing = dir([dirPath,filesep,'*.cdf']);

pathArray = fullfile(dirPath,{listing.name}');

end

function logPath = constructLogPath(cdfPath,subjectId)

[cdfDir,~,~] = fileparts(cdfPath);
[buildingDir,~,~] = fileparts(cdfDir);
logName = ['workLog_subject',subjectId,'.xlsx'];
logPath = fullfile(buildingDir,'logs',logName);

end

function TF = dirDoesExist(dirArray)

if iscell(dirArray)
    TF = cellfun(@isdir,dirArray);
else
    TF = isdir(dirArray);
end

end

function TF = fileDoesExist(pathArray)

fun = @(x) exist(x,'file') == 2;

if iscell(pathArray)
    TF = cellfun(fun,pathArray);
else
    TF = fun(pathArray);
end

end

function [location,session] = decomposePath(filePath)

splitPath = regexp(filePath,['\',filesep],'split');

switch splitPath{6}
    case 'WashingtonDC'
        location = 'DC-1800F';
        session = splitPath{8};
    case 'WashingtonDC-RegionalOfficeBldg-7th&Dstreet'
        location = 'DC-ROB';
        session = splitPath{8};
    case 'Seattle_Washington'
        switch splitPath{8}
            case 'FCS_Building_1201'
                location = 'Seattle-1201';
            case 'FCS_Building_1202'
                location = 'Seattle-1202';
        end
        session = splitPath{9};
    case 'GrandJunction_Colorado_site_data'
        location = 'Grand Junction';
        session = splitPath{8};
    case 'Portland_Oregon_site_data'
        location = 'Portland';
        session = splitPath{8};
end

end
