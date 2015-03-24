function [status, output_args] = LRCAnalysisController(cdfPath, dirObj, plotSwitch)
%LRCANALYSISCONTROLLER Summary of this function goes here
%   Detailed explanation goes here

% Preallocate output_args
output_args = struct;

% Enable dependencies
[githubDir,~,~] = fileparts(pwd);
circadianDir = fullfile(githubDir,'circadian');
addpath(circadianDir);

% Import CDF
if exist(cdfPath,'file') == 2
    cdfData = daysimeter12.readcdf(cdfPath);
    [absTime,relTime,epoch,light,activity,masks,subjectID,deviceSN] = daysimeter12.convertcdf(cdfData);
else
    status = 'failure';
    return;
end

% Construct paths to logs
bedLog = fullfile(dirObj.logs,['bedLog_subject',subjectID,'.xlsx']);
workLog = fullfile(dirObj.logs,['workLog_subject',subjectID,'.xlsx']);

% Determine building from subject number
subjectNum = str2double(subjectID);
if subjectNum >= 100 && subjectNum < 200
    building = '1800F';
elseif subjectNum >= 200 && subjectNum < 300
    building = 'ROB';
else
    building = '';
end

% Construct identifier strings
displayLocation = ['Washington, D.C. ', building];
displaySession = 'Winter';

% Import logs
if exist(bedLog,'file') == 2 && exist(workLog,'file') == 2
    [bedTime, riseTime] = LRCImportBed(bedLog);
    [~, location, workStart, workStop] = LRCImportWork(workLog);
else
    status = 'failure';
    return;
end

% Limit time
startTime = min(absTime.localDateNum(masks.observation));
stopTime = max(absTime.localDateNum(masks.observation));
idx = absTime.localDateNum > floor(startTime(1)) & absTime.localDateNum < ceil(stopTime(1));
masks2 = masks;
masks2.observation = masks2.observation(idx);
masks2.compliance = masks2.compliance(idx);
masks2.bed = masks2.bed(idx);

% Regular Averages
try
    Average = reports.composite.daysimeteraverages(light,activity,masks);
    
    % Calculate viable days
    idx = masks.observation & masks.compliance & ~masks.bed;
    t = absTime.localDateNum(idx);
    d = unique(floor(t));
    n = numel(d);
    
    Average.nDays = n;
catch err
    warning(err.message)
    status = 'failure';
    return;
end

% Phasor Analysis
try
    Phasor = phasor.prep(absTime,epoch,light,activity,masks);
catch err
    warning(err.message)
    status = 'failure';
    return;
end

% Actigraphy Analysis
try
    Actigraphy = isiv.prep(absTime,epoch,activity,masks);
catch err
    warning(err.message)
    status = 'failure';
    return;
end

% Millerize Data
try
    Miller = struct('time',[],'cs',[],'activity',[]);
    [         ~,Miller.cs] = millerize.millerize(relTime,light.cs,masks);
    [Miller.time,Miller.activity] = millerize.millerize(relTime,activity,masks);
catch err
    warning(err.message)
    status = 'failure';
    return;
end

switch plotSwitch
    case 'on'
        % Daysigram
        try
            sheetTitle = ['GSA - ',displayLocation,' - ',displaySession,' - Subject ',subjectID];
            daysigramFileID = ['subjectID',subjectID,'_deviceSN',deviceSN];
            reports.daysigram.daysigram(2,sheetTitle,absTime.localDateNum(idx),masks2,activity(idx),light.cs(idx),'cs',[0,1],10,dirObj.plots,[daysigramFileID,'_CS']);
        catch err
            warning(err.message);
            status = 'failure';
            return;
        end

        % Light and Health Report
        try
            figTitle = ['GSA - ',displayLocation,' - ',displaySession];
            reports.composite.compositeReport(dirObj.plots,Phasor,Actigraphy,Average,Miller,subjectID,deviceSN,figTitle);
            clf;
        catch err
            warning(err.message);
            status = 'failure';
            return;
        end
end

% Sleep Analysis
try
    Sleep = sleepprep(absTime,epoch,activity,bedTime,riseTime,masks);
catch err
    warning(err.message);
    status = 'failure';
    return;
end

% Construct list of office locations
unqLoc = unique(location);
if isempty(unqLoc)
    status = 'failure';
    return;
end
nLoc = numel(unqLoc);
for iLoc = 1:nLoc
    
    thisLoc = unqLoc{iLoc};
    idxLoc = strcmp(thisLoc,location);
    theseWorkStart = workStart(idxLoc);
    theseWorkStop = workStop(idxLoc);
    
    % Work Averages
    try
        [WrkAverage,PstAverage,PreAverage] = workprep(absTime,light,activity,masks,bedTime,riseTime,theseWorkStart,theseWorkStop);
    catch err
        warning(err.message);
        status = 'failure';
        return;
    end
    
    % Sleep Analysis
    try
        PstSleep = postworksleepprep(absTime,epoch,activity,bedTime,riseTime,masks,theseWorkStop);
    catch err
        warning(err.message);
        status = 'failure';
        return;
    end
    
    output_args(iLoc).subjectID         = subjectID;
    output_args(iLoc).building          = building;
    output_args(iLoc).location          = thisLoc;
    
    output_args(iLoc).Miller            = Miller;
    output_args(iLoc).Phasor            = Phasor;
    output_args(iLoc).Actigraphy        = Actigraphy;
    output_args(iLoc).Average           = Average;
    output_args(iLoc).Sleep             = Sleep;
    
    output_args(iLoc).WorkAverage       = WrkAverage;
    output_args(iLoc).PostWorkAverage	= PstAverage;
    output_args(iLoc).PreWorkAverage	= PreAverage;
    output_args(iLoc).PostWorkSleep     = PstSleep;
    
end

status = 'success';


end

function tf = iswork(datenumArray,workStart,workStop)
tf = false(size(datenumArray));

for iWork = 1:numel(workStart)
    temp = datenumArray >= workStart(iWork) & datenumArray <= workStop(iWork);
    tf = tf | temp;
end

end

function tf = ispostwork(datenumArray,workStop,bedTime)
tf = false(size(datenumArray));
temp = tf;

for iWork = 1:numel(workStop)
    thisWorkStop = workStop(iWork);
    thisBedTime = min(bedTime(bedTime>thisWorkStop));
    if ~isempty(thisBedTime)
        temp = datenumArray > thisWorkStop & datenumArray < thisBedTime;
    end
    
    tf = tf | temp;
end

end

function tf = isprework(datenumArray,workStart,riseTime)
tf = false(size(datenumArray));
temp = tf;

for iWork = 1:numel(workStart)
    thisWorkStart = workStart(iWork);
    thisRiseTime = max(riseTime(riseTime<thisWorkStart));
    if ~isempty(thisRiseTime)
        temp = datenumArray > thisRiseTime & datenumArray < thisWorkStart;
    end
    
    tf = tf | temp;
end

end


function [WrkAverage,PstAverage,PreAverage] = workprep(absTime,light,activity,masks,bedTime,riseTime,workStart,workStop)
wrkIdx = iswork(absTime.localDateNum,workStart,workStop);
pstIdx = ispostwork(absTime.localDateNum,workStop,bedTime);
preIdx = isprework(absTime.localDateNum,workStart,riseTime);

idx = masks.observation & masks.compliance & ~masks.bed;

% Calculate viable days
wrkTime = absTime.localDateNum(wrkIdx & idx);
pstTime = absTime.localDateNum(pstIdx & idx);
pstTime = pstTime(mod(pstTime,1)>.5);
preTime = absTime.localDateNum(preIdx & idx);
preTime = preTime(mod(preTime,1)<.5);

wrkDays = unique(floor(wrkTime));
pstDays = unique(floor(pstTime));
preDays = unique(floor(preTime));

nWrkDays = numel(wrkDays);
nPstDays = numel(pstDays);
nPreDays = numel(preDays);


% Refactor light to work, pre-work, and post-work
wrkLight = LRCRefactorLight(light, wrkIdx);
pstLight = LRCRefactorLight(light, pstIdx);
preLight = LRCRefactorLight(light, preIdx);

% Refactor activity to work, pre-work, and post-work
wrkActivity = LRCRefactorActivity(activity, wrkIdx);
pstActivity = LRCRefactorActivity(activity, pstIdx);
preActivity = LRCRefactorActivity(activity, preIdx);

% Refactor masks to work, pre-work, and post-work
wrkMasks = LRCRefactorMasks(masks, wrkIdx);
pstMasks = LRCRefactorMasks(masks, pstIdx);
preMasks = LRCRefactorMasks(masks, preIdx);

% Take averages
WrkAverage = reports.composite.daysimeteraverages(wrkLight,wrkActivity,wrkMasks);
PstAverage = reports.composite.daysimeteraverages(pstLight,pstActivity,pstMasks);
PreAverage = reports.composite.daysimeteraverages(preLight,preActivity,preMasks);

% Add the number of days
WrkAverage.nDays = nWrkDays;
PstAverage.nDays = nPstDays;
PreAverage.nDays = nPreDays;

end

function Sleep = sleepprep(absTime,epoch,activity,bedTime,riseTime,masks)

absTime.localDateNum(~masks.compliance) = [];
activity(~masks.compliance) = [];

analysisStart = bedTime  - 20/(60*24);
analysisEnd   = riseTime + 20/(60*24);

nIntervals = numel(bedTime);
dailySleep = cell(nIntervals,1);
    
for i1 = 1:nIntervals
    % Perform analysis
    try
        dailySleep{i1} = sleep.sleep(absTime.localDateNum,activity,epoch,...
            analysisStart(i1),analysisEnd(i1),...
            bedTime(i1),riseTime(i1),'auto');
    catch err
        warning(err.message);
        continue;
    end
end

% Average results
Sleep = averageanalysis(dailySleep);

end


function PstSleep = postworksleepprep(absTime,epoch,activity,bedTime,riseTime,masks,workStop)

absTime.localDateNum(~masks.compliance) = [];
activity(~masks.compliance) = [];

nIntervals = numel(workStop);
dailySleep = cell(nIntervals,1);
    
for i1 = 1:nIntervals
    % Perform analysis
    try
        [thisBedTime,thisRiseTime] = nightAfter(workStop(i1),bedTime,riseTime);
        
        if ~isempty(thisBedTime)
            analysisStart = thisBedTime  - 20/(60*24);
            analysisEnd   = thisRiseTime + 20/(60*24);
            
            dailySleep{i1} = sleep.sleep(absTime.localDateNum,activity,epoch,...
                analysisStart,analysisEnd,...
                thisBedTime,thisRiseTime,'auto');
        end
    catch err
        warning(err.message);
        continue;
    end
end

% Average results
PstSleep = averageanalysis(dailySleep);

end


function [thisBedTime,thisRiseTime] = nightAfter(thisDatenum,bedTime,riseTime)

idx = bedTime > thisDatenum & bedTime < thisDatenum + 1;

thisBedTime = bedTime(idx);
thisRiseTime = riseTime(idx);

if any(idx)
    thisBedTime = thisBedTime(1);
    thisRiseTime = thisRiseTime(1);
    
    if thisBedTime > thisDatenum + 0.5
        warning('Late bed time');
    end
end

end
