function [status, output_args] = LRCAnalysisController(cdfPath, hFig1, hFig2, dirObj)
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
    [absTime,relTime,epoch,light,activity,masks,subjectID,deviceSN] = convertcdf(cdfData);
else
    status = 'failure';
    return;
end

% Construct paths to logs
bedLog = fullfile(logDir,['bedLog_subject',subjectID,'.xlsx']);
workLog = fullfile(logDir,['workLog_subject',subjectID,'.xlsx']);

% Import logs
if exist(bedLog,'file') == 2 && exist(workLog,'file') == 2
    [bedTime, riseTime] = LRCImportBed(bedLog);
    [~, location, workStart, workStop] = LRCImportWork(workLog);
else
    status = 'failure';
    return;
end

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

% Daysigram
try
    sheetTitle = ['GSA - ',displayLocation,' - ',displaySession,' - Subject ',subjectID];
    daysigramFileID = ['subject',subjectID];
    reports.daysigram.daysigram(2,sheetTitle,absTime.localDateNum(idx),masks2,activity(idx),light.cs(idx),'cs',[0,1],8,dirObj.plots,[daysigramFileID,'_CS']);
catch err
    warning(err.message);
    status = 'failure';
    return;
end

% Light and Health Report/ Phasor Analysis
try
    figTitle = ['GSA - ',displayLocation,' - ',displaySession];
    Phasor = phasorprep(subjectID,figTitle,hFigure,units,Paths,...
        complianceArray,bedArray,timeArray,csArray,activityArray,...
        illuminanceArray);
catch err
    warning(err.message);
    status = 'failure';
    return;
end

% Averages
try
    [Average,WorkAverage,PostWorkAverage] = prepaverages(...
        timeArray,csArray,activityArray,illuminanceArray,...
        complianceArray,bedArray,bedTimeArray);
catch err
    warning(err.message);
    status = 'failure';
    return;
end

% Sleep Analysis
try
    [Sleep,nIntervalsAveraged] = sleepprep(timeArray,activityArray,...
        bedTimeArray,riseTimeArray,complianceArray);
catch err
    warning(err.message);
    status = 'failure';
    return;
end

% Assign output values upon successful completion
status = 'success';
output_args.Phasor = Phasor;
output_args.Average = Average;
output_args.WorkAverage = WorkAverage;
output_args.PostWorkAverage = PostWorkAverage;
output_args.Sleep = Sleep;


end



function Output = phasorprep(subject,figTitle,hFigure,units,Paths,complianceArray,bedArray,timeArray,csArray,activityArray,illuminanceArray)
clf;

wkendIdx = createweekend(timeArray);

% replace in bed time
csArray(bedArray) = 0;
activityArray(bedArray) = 0;
illuminanceArray(bedArray) = 0;

% remove only large noncompliance while awake
complianceArray = adjustcrop(timeArray,complianceArray,bedArray);
timeArray(~complianceArray | wkendIdx) = [];
csArray(~complianceArray | wkendIdx) = [];
activityArray(~complianceArray | wkendIdx) = [];
illuminanceArray(~complianceArray | wkendIdx) = [];

Output = generatereport(Paths.plots,timeArray,csArray,activityArray,...
    illuminanceArray,[subject,' sans-weekends'],hFigure,units,figTitle);
end


function wkendIdx = createweekend(timeArray)

dayArray        = floor(timeArray);
dayOfWeekArray	= weekday(dayArray); % Sunday = 1, Monday = 2, etc.
wkendIdx        = dayOfWeekArray == 1 | dayOfWeekArray == 7;

end

function [workIdx,postWorkIdx] = createworkday(timeArray,bedTimeArray)

workStart = 8/24;
workEnd   = 17/24;

dayArray       = unique(floor(timeArray));
dayOfWeekArray = weekday(dayArray); % Sunday = 1, Monday = 2, etc.
workDaysIdx    = dayOfWeekArray >= 2 & dayOfWeekArray <= 6;
workDayArray   = dayArray(workDaysIdx);

workStartArray = workDayArray + workStart;
workEndArray   = workDayArray + workEnd;

workIdx = false(size(timeArray));
postWorkIdx = false(size(timeArray));
for j1 = 1:numel(workStartArray)
    tempWorkIdx = timeArray > workStartArray(j1) & timeArray <= workEndArray(j1);
    workIdx = workIdx | tempWorkIdx;

    diffBedTime = bedTimeArray - workEndArray(j1);
    currentBedTime = bedTimeArray(diffBedTime<1 & diffBedTime>0);
    if numel(currentBedTime) == 1
        tempPostWorkIdx = timeArray > workEndArray(j1) & timeArray <=currentBedTime;
        postWorkIdx = postWorkIdx | tempPostWorkIdx;
    end
end

end


function [Average,WorkAverage,PostWorkAverage] = prepaverages(timeArray,csArray,activityArray,illuminanceArray,complianceArray,bedArray,bedTimeArray)

validIdx = complianceArray & ~bedArray;

timeArray(~validIdx) = [];
csArray(~validIdx) = [];
activityArray(~validIdx) = [];
illuminanceArray(~validIdx) = [];

[workIdx,postWorkIdx] = createworkday(timeArray,bedTimeArray);

Average = daysimeteraverages(csArray(csArray>0.01),illuminanceArray(illuminanceArray>0.01),activityArray(activityArray>0.01));
WorkAverage = daysimeteraverages(csArray(workIdx),...
    illuminanceArray(workIdx),activityArray(workIdx));
PostWorkAverage = daysimeteraverages(csArray(postWorkIdx),...
    illuminanceArray(postWorkIdx),activityArray(postWorkIdx));

end


function [Sleep,nIntervalsAveraged] = sleepprep(timeArray,activityArray,bedTimeArray,riseTimeArray,complianceArray)

timeArray(~complianceArray) = [];
activityArray(~complianceArray) = [];

analysisStartTimeArray = bedTimeArray  - 20/(60*24);
analysisEndTimeArray   = riseTimeArray + 20/(60*24);

startDayArray = floor(analysisStartTimeArray);
startDayOfWeekArray = weekday(startDayArray); % Sunday = 1, Monday = 2, etc.
wkendIdx = startDayOfWeekArray == 1 | startDayOfWeekArray == 7;

bedTimeArray(wkendIdx) = [];
riseTimeArray(wkendIdx) = [];
analysisStartTimeArray(wkendIdx) = [];
analysisEndTimeArray(wkendIdx) = [];

nIntervals = numel(bedTimeArray);
dailySleep = cell(nIntervals,1);
    
for i1 = 1:nIntervals
    % Perform analysis
    try
        dailySleep{i1} = sleepAnalysis(timeArray,activityArray,...
        analysisStartTimeArray(i1),analysisEndTimeArray(i1),...
        bedTimeArray(i1),riseTimeArray(i1),'auto');
    catch err
        continue
    end
end

% Average results
[Sleep,nIntervalsAveraged] = averageanalysis(dailySleep);

end