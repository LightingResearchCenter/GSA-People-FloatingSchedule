function GSAMeanCsFrequency
%GSACSFREQUENCY Summary of this function goes here
%   Detailed explanation goes here

close all

% Enable dependencies
[gitHubDir,~,~] = fileparts(pwd);
circadianDir = fullfile(gitHubDir,'circadian');
addpath(circadianDir);

dataStore = fullfile(pwd,'dataStore-mean2.mat');

if fileDoesExist(dataStore)
    load(dataStore,'data');
else
    % Map directories
    dataDirArray = mapDirs;

    % Map data paths
    cdfArray = mapData(dataDirArray);
    [location,session] = path2loc(cdfArray);
    
    % Load data
    data = loadData(cdfArray);
    data.location = location;
    data.session = session;
    
    % Save data to file
    save(dataStore,'data');
end

% Plot data
plotHist(data.cs_work,'During Work Hours');
plotHist(data.cs_waking,'During Waking Hours');
plotHist(data.cs_nonwork_waking,'During Non-Work Waking Hours');

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
    'Normalization','count');

hAx.Box = 'off';
hAx.TickDir = 'out';
%hAx.YLim = [0,0.3];
%hAx.YTick = 0:0.05:0.3;

title(hAx,{'Distribution of Mean Circadian Stimulus (CS):';histTitle});
xlabel(hAx,'Mean Circadian Stimulus (CS)');
ylabel(hAx,'Number of Subjects');

saveas(hFig,['Mean CS ',histTitle,'.jpg']);
end

%% MARK: Read files

function data = loadData(cdfArray)

nCdf = numel(cdfArray);
tempCell = cell(nCdf,1);
tempMat = NaN(nCdf,1);
vnames = {'location','session','subjectId','cs_work','cs_waking','cs_nonwork_waking'};
data = table(tempCell,tempCell,tempCell,tempMat,tempMat,tempMat,'VariableNames',vnames);

for iCdf = 1:nCdf
    thisCdf = cdfArray{iCdf};
    [subjectId,~,cs,work,bed] = prepData(thisCdf);
    data.subjectId{iCdf} = subjectId;
    
    data.cs_work(iCdf) = mean(cs(work));
    data.cs_waking(iCdf) = mean(cs(~bed));
    data.cs_nonwork_waking(iCdf) = mean(cs(~bed & ~work));
end


end

function [subjectId,time,cs,work,bed] = prepData(cdfPath)

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

function dataDirArray = mapDirs

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

dataDirArray = fullfile(seasonDir,'croppedData');

tfDir = dirDoesExist(dataDirArray);
if any(~tfDir)
    warning('Missing directories removed from list.');
    dataDirArray(~tfDir) = [];
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

function [location,session] = path2loc(cdfArray)
f = @(C)strsplit(C,filesep);
parts = cellfun(f,cdfArray,'UniformOutput',false);

location = cell(size(cdfArray));
session = cell(size(cdfArray));

for iC = 1:numel(cdfArray)
    theseParts = parts{iC};
    if numel(theseParts) == 10
        location{iC} = theseParts{7};
        session{iC} = theseParts{8};
    elseif numel(theseParts) == 9
        location{iC} = theseParts{5};
        session{iC} = theseParts{7};
    else
        error('Unknown file pattern');
    end
end

location = regexprep(location,'^WashingtonDC$','DC 1800F','ignorecase');
location = regexprep(location,'^WashingtonDC-RegionalOfficeBldg-7th&Dstreet$','DC ROB','ignorecase');
location = regexprep(location,'^FCS_Building_1201$','Seattle FCS 1201','ignorecase');
location = regexprep(location,'^FCS_Building_1202$','Seattle FCS 1202','ignorecase');
location = regexprep(location,'^GrandJunction_Colorado_site_data$','Grand Junction','ignorecase');
location = regexprep(location,'^Portland_Oregon_site_data$','Portland','ignorecase');
end
