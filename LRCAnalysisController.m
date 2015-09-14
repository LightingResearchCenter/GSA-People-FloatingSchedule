function [status, output_args] = LRCAnalysisController(cdfPath, dirObj, plotSwitch, sessionTitle, building)
%LRCANALYSISCONTROLLER Summary of this function goes here
%   Detailed explanation goes here

% Preallocate output_args
output_args = struct;
status = 'success';

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

if isempty(building)
    % Determine building from subject number
    subjectNum = str2double(subjectID);
    if subjectNum >= 100 && subjectNum < 200
        building = '1800F';
    elseif subjectNum >= 200 && subjectNum < 300
        building = 'ROB';
    else
        building = '';
    end
end

% Import bed log
if exist(bedLog,'file') == 2
    [bedTime, riseTime] = LRCImportBed(bedLog);
else
    status = 'failure';
    return;
end

% Import or make work log
if exist(workLog,'file') == 2
    [~, location, workStart, workStop] = LRCImportWork(workLog);
    if isempty(location)
        status = 'warning';
        location = {'NA'};
        workStart = 0;
        workStop = 0;
    end
else
    [~, location, workStart, workStop] = makeWorkLog(absTime,'NA');
end

% Limit time
try
    startTime = min(absTime.localDateNum(masks.observation));
    stopTime = max(absTime.localDateNum(masks.observation));
    idx1 = absTime.localDateNum > floor(startTime(1)) & absTime.localDateNum < ceil(stopTime(1));
    masks2 = masks;
    masks2.observation = masks2.observation(idx1);
    masks2.compliance = masks2.compliance(idx1);
    masks2.bed = masks2.bed(idx1);
catch err
    status = 'failure';
    return;
end

% Regular Averages
try
    Average = reports.composite.daysimeteraverages(light,activity,masks);
    
    % Calculate viable days
    idx2 = masks.observation & masks.compliance & ~masks.bed;
    t = absTime.localDateNum(idx2);
    d = unique(floor(t));
    n = numel(d);
    
    Average.nDays = n;
catch err
    warning(err.message)
    status = 'warning';
    % return;
end

% NonWork Averages
try
    if exist(workLog,'file') == 2
        workDay = LRCImportWork2(workLog);
    else
        workDay = makeWorkLog2(absTime);
    end
    nonIdx = isnonwork(absTime.localDateNum,workDay);
    idx3 = masks.observation & masks.compliance & ~masks.bed;
    nonTime = absTime.localDateNum(nonIdx & idx3);
    nonDays = unique(floor(nonTime));
    nonLight = LRCRefactorLight(light, nonIdx);
    nonActivity = LRCRefactorActivity(activity, nonIdx);
    nonMasks = LRCRefactorMasks(masks, nonIdx);
    
    NonWrkAverage = reports.composite.daysimeteraverages(nonLight,nonActivity,nonMasks);
    NonWrkAverage.nDays = numel(nonDays);
catch err
    warning(err.message)
    status = 'warning';
    % return;
end

% Phasor Analysis
try
    Phasor = phasor.prep(absTime,epoch,light,activity,masks);
catch err
    warning(err.message)
    status = 'warning';
    % return;
end

% Actigraphy Analysis
try
    Actigraphy = isiv.prep(absTime,epoch,activity,masks);
catch err
    warning(err.message)
    status = 'warning';
    % return;
end

% Millerize Data
try
    Miller = struct('time',[],'cs',[],'activity',[]);
    [         ~,Miller.cs] = millerize.millerize(relTime,light.cs,masks);
    [Miller.time,Miller.activity] = millerize.millerize(relTime,activity,masks);
catch err
    warning(err.message)
    status = 'warning';
    % return;
end

% Millerize Non-Work Data
try
    nonMasks = masks;
    nonMasks.observation = nonIdx & nonMasks.observation;
    
    NonWrkMiller = struct('time',[],'cs',[],'activity',[]);
    [             ~,NonWrkMiller.cs] = millerize.millerize(relTime,light.cs,nonMasks);
    [NonWrkMiller.time,NonWrkMiller.activity] = millerize.millerize(relTime,activity,nonMasks);
catch err
    warning(err.message)
    status = 'warning';
    % return;
end



switch plotSwitch
    case 'on'
        % Daysigram
        try
            sheetTitle = [sessionTitle,' - Subject ',subjectID];
            daysigramFileID = ['subjectID',subjectID,'_deviceSN',deviceSN];
            reports.daysigram.daysigram(2,sheetTitle,absTime.localDateNum(idx1),masks2,activity(idx1),light.cs(idx1),'cs',[0,1],10,dirObj.plots,[daysigramFileID,'_CS']);
        catch err
            warning(err.message);
            status = 'warning';
            % return;
        end

        % Light and Health Report
        try
            figTitle = sessionTitle;
            reports.composite.compositeReport(dirObj.plots,Phasor,Actigraphy,Average,Miller,subjectID,deviceSN,figTitle);
            clf;
        catch err
            warning(err.message);
            status = 'warning';
            % return;
        end
end

% Sleep Analysis
try
    Sleep = sleepprep(absTime,epoch,activity,bedTime,riseTime,masks);
catch err
    warning(err.message);
    status = 'warning';
    % return;
end

% Construct list of office locations
unqLoc = unique(location);
if isempty(unqLoc)
    status = 'warning';
    unqLoc = {'NA'};
    % return;
end 
nLoc = numel(unqLoc);
for iLoc = 1:nLoc
    
    thisLoc = unqLoc{iLoc};
    idxLoc = strcmp(thisLoc,location);
    theseWorkStart = workStart(idxLoc);
    theseWorkStop = workStop(idxLoc);
    
    % Millerize Work Data
    try
        wrkDays = floor(theseWorkStart);
        days = floor(absTime.localDateNum);
        wrkIdx = ismember(days,wrkDays);
        wrkMasks = masks;
        wrkMasks.observation = wrkIdx & wrkMasks.observation;

        WrkMiller = struct('time',[],'cs',[],'activity',[]);
        [             ~,WrkMiller.cs] = millerize.millerize(relTime,light.cs,wrkMasks);
        [WrkMiller.time,WrkMiller.activity] = millerize.millerize(relTime,activity,wrkMasks);
    catch err
        warning(err.message)
        status = 'warning';
        % return;
    end
    
    % Work Averages
    try
        [WrkAverage,PstAverage,PreAverage] = workprep(absTime,light,activity,masks,bedTime,riseTime,theseWorkStart,theseWorkStop);
        csHist(absTime,light,masks,theseWorkStart,theseWorkStop,building,thisLoc,subjectID,dirObj.plots);
    catch err
        warning(err.message);
        status = 'warning';
        % return;
    end
    
    % Sleep Analysis
    try
        PstSleep = postworksleepprep(absTime,epoch,activity,bedTime,riseTime,masks,theseWorkStop);
    catch err
        warning(err.message);
        status = 'warning';
        % return;
    end
    
    if exist('subjectID','var') == 1
        output_args(iLoc).subjectID = subjectID;
    else
        output_args(iLoc).subjectID = 'NA';
    end
    
    if exist('building','var') == 1
        output_args(iLoc).building = building;
    else
        output_args(iLoc).building = 'NA';
    end
    
    if exist('thisLoc','var') == 1
        output_args(iLoc).location = thisLoc;
    else
        output_args(iLoc).location = 'NA';
    end
    
    if exist('Miller','var') == 1
        output_args(iLoc).Miller = Miller;
    else
        output_args(iLoc).Miller = struct;
    end
    
    if exist('WrkMiller','var') == 1
        output_args(iLoc).WorkMiller = WrkMiller;
    else
        output_args(iLoc).WorkMiller = struct;
    end
    
    if exist('NonWrkMiller','var') == 1
        output_args(iLoc).NonWorkMiller = NonWrkMiller;
    else
        output_args(iLoc).NonWorkMiller = struct;
    end
    
    if exist('Phasor','var') == 1
        output_args(iLoc).Phasor = Phasor;
    else
        output_args(iLoc).Phasor = struct;
    end
    
    if exist('Actigraphy','var') == 1
        output_args(iLoc).Actigraphy = Actigraphy;
    else
        output_args(iLoc).Actigraphy = struct;
    end
    
    if exist('Average','var') == 1
        output_args(iLoc).Average = Average;
    else
        output_args(iLoc).Average = struct;
    end
    
    if exist('Sleep','var') == 1
        output_args(iLoc).Sleep = Sleep;
    else
        output_args(iLoc).Sleep = struct;
    end
    
    if exist('NonWrkAverage','var') == 1
        output_args(iLoc).NonWorkAverage = NonWrkAverage;
    else
        output_args(iLoc).NonWorkAverage = struct;
    end
    
    if exist('WrkAverage','var') == 1
        output_args(iLoc).WorkAverage = WrkAverage;
    else
        output_args(iLoc).WorkAverage = struct;
    end
    
    if exist('PstAverage','var') == 1
        output_args(iLoc).PostWorkAverage = PstAverage;
    else
        output_args(iLoc).PostWorkAverage = struct;
    end
    
    if exist('PreAverage','var') == 1
        output_args(iLoc).PreWorkAverage = PreAverage;
    else
        output_args(iLoc).PreWorkAverage = struct;
    end
    
    if exist('PstSleep','var') == 1
        output_args(iLoc).PostWorkSleep = PstSleep;
    else
        output_args(iLoc).PostWorkSleep = struct;
    end
end

% status = 'success';


end

function tf = isnonwork(datenumArray,workDay)
tf = true(size(datenumArray));

dateArray = floor(datenumArray);
weekdayArray = weekday(datenumArray);

for iWork = 1:numel(workDay)
    temp = dateArray ~= workDay(iWork);
    tf = tf & temp;
end

weekend = weekdayArray == 1 | weekdayArray == 7;

tf = tf & ~weekend;

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

% Find CS Quartiles
wrkCS = light.cs(wrkIdx & idx);
Q = quantile(wrkCS,3);
WrkAverage.csQ1 = Q(1);
WrkAverage.csQ2 = Q(2);
WrkAverage.csQ3 = Q(3);

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


function csHist(absTime,light,masks,workStart,workStop,building,location,subject,plotDir)
wrkIdx = iswork(absTime.localDateNum,workStart,workStop);
idx = masks.observation & masks.compliance & ~masks.bed;
wrkCS = light.cs(wrkIdx & idx);

figTitle = ['Building: ',building,', Location: ',location,', Subject: ',subject];
fileName = ['workCsHistogram_subjectID',subject,'_location',location,'_',datestr(now,'yyyy-mm-dd_HHMM'),'.jpg'];
if exist(fullfile(plotDir,'histograms'),'dir') ~= 7
    mkdir(fullfile(plotDir,'histograms'))
end

filePath = fullfile(plotDir,'histograms',fileName);


hFig = figure(3);
edges = 0:0.05:0.7;
hHist = histogram(wrkCS,edges);
hHist.Normalization = 'probability';
hAxes = gca;
hAxes.XLim = [0,0.7];
hAxes.YLim = [0,1.0];

ylabel('probability');
xlabel('circadian stimulus (CS)');
title(figTitle);
saveas(hFig,filePath);
close(hFig);
end