function combined = GSACombine(summerResultsStruct,winterResultsStruct)
%GSACOMBINE Summary of this function goes here
%   Detailed explanation goes here

% Prepare tables from structures
sumTable = prepSeason(summerResultsStruct,'summer');
winTable = prepSeason(winterResultsStruct,'winter');

% Join the two tables
combined1 = outerjoin(sumTable,winTable,'MergeKeys',true);

% Rearrange columns
combined = combined1(:,1);
combined.Properties.VariableNames{1} = combined1.Properties.VariableNames{1};
combined.Properties.VariableDescriptions{1} = combined1.Properties.VariableDescriptions{1};

for a = 2:52
    b = 51 + a;
    c1 = (a - 1)*2;
    c2 = c1 + 1;
    
    combined(:,c1) = combined1(:,a);
    combined.Properties.VariableNames{c1} = combined1.Properties.VariableNames{a};
    combined.Properties.VariableDescriptions{c1} = combined1.Properties.VariableDescriptions{a};
    
    combined(:,c2) = combined1(:,b);
    combined.Properties.VariableNames{c2} = combined1.Properties.VariableNames{b};
    combined.Properties.VariableDescriptions{c2} = combined1.Properties.VariableDescriptions{b};
end

combined.Properties.RowNames = combined.subjectId;

end


function T = prepSeason(S,season)

% Convert structs to tables
T = struct2table(S);

% Rename subject ID
T.Properties.VariableNames{'subjectID'} = 'subjectId';

% Add descriptions
T.Properties.VariableDescriptions{'subjectId'} = 'subject id';
T.Properties.VariableDescriptions{'building'} = 'building';
T.Properties.VariableDescriptions{'location'} = 'location';

% Remove uneeded variables
T.Miller = [];
T.WorkMiller = [];
T.NonWorkMiller = [];

% Expand nested structs
T = expandPhasor(T);
T = expandActigraphy(T);
T = expandSleep(T,'Sleep','overallSleep');
T = expandAverage(T,'Average','overalWakingAverage');
T = expandAverage(T,'PreWorkAverage','preworkAverage');
T = expandWorkAverage(T);
T = expandAverage(T,'PostWorkAverage','postworkAverage');
T = expandSleep(T,'PostWorkSleep','postworkSleep');
T = expandAverage(T,'NonWorkAverage','nonworkWeekdayWakingAverage');

% Append variable names with season
T = appendVarNames(T,['_',season]);

end


function T = expandPhasor(T)

S = T.Phasor;

newVarName = 'overallPhasor';

T.([newVarName,'_nDaysUsed']) = {S.nDays}';
T.Properties.VariableDescriptions{[newVarName,'_nDaysUsed']} = '# of days used';

T.([newVarName,'_magnitude']) = {S.magnitude}';
T.Properties.VariableDescriptions{[newVarName,'_magnitude']} = 'magnitude';

S2 = [S.angle]';
T.([newVarName,'_angleHours']) = {S2.hours}';
T.Properties.VariableDescriptions{[newVarName,'_angleHours']} = 'angle (hours)';

T.Phasor = [];

end


function T = expandActigraphy(T)

S = T.Actigraphy;

newVarName = 'overallIsAndIv';

T.([newVarName,'_nDaysUsed']) = {S.nDays}';
T.Properties.VariableDescriptions{[newVarName,'_nDaysUsed']} = '# of days used';

T.([newVarName,'_interdailyStability']) = {S.interdailyStability}';
T.Properties.VariableDescriptions{[newVarName,'_interdailyStability']} = 'interdaily stability';

T.([newVarName,'_intradailyVariability']) = {S.intradailyVariability}';
T.Properties.VariableDescriptions{[newVarName,'_intradailyVariability']} = 'intradaily variability';

T.Actigraphy = [];

end


function T = expandSleep(T,varName,newVarName)

S = T.(varName);

if iscell(S)
    template = struct('nIntervalsAveraged',0,...
    'actualSleepTime',0,...
    'actualSleepPercent',0,...
    'actualWakeTime',0,...
    'actualWakePercent',0,...
    'sleepEfficiency',0,...
    'sleepLatency',0);

end


T.([newVarName,'_nDaysUsed']) = {S.nIntervalsAveraged}';
T.Properties.VariableDescriptions{[newVarName,'_nDaysUsed']} = '# of days used';

T.([newVarName,'_actualSleepTime']) = {S.actualSleepTime}';
T.Properties.VariableDescriptions{[newVarName,'_actualSleepTime']} = 'actual sleep time (mins.)';

T.([newVarName,'_actualSleepPercent']) = {S.actualSleepPercent}';
T.Properties.VariableDescriptions{[newVarName,'_actualSleepPercent']} = 'actual sleep (%)';

T.([newVarName,'_actualWakeTime']) = {S.actualWakeTime}';
T.Properties.VariableDescriptions{[newVarName,'_actualWakeTime']} = 'actual wake time (mins.)';

T.([newVarName,'_actualWakePercent']) = {S.actualWakePercent}';
T.Properties.VariableDescriptions{[newVarName,'_actualWakePercent']} = 'actual wake (%)';

T.([newVarName,'_sleepEfficiency']) = {S.sleepEfficiency}';
T.Properties.VariableDescriptions{[newVarName,'_sleepEfficiency']} = 'sleep efficiency (%)';

T.([newVarName,'_sleepLatency']) = {S.sleepLatency}';
T.Properties.VariableDescriptions{[newVarName,'_sleepLatency']} = 'sleep onset latency (mins.)';

T.(varName) = [];

end


function T = expandAverage(T,varName,newVarName)

S = T.(varName);

T.([newVarName,'_nDaysUsed']) = {S.nDays}';
T.Properties.VariableDescriptions{[newVarName,'_nDaysUsed']} = '# of days used';

Scs = [S.cs]';
T.([newVarName,'_CsArithmeticMean']) = {Scs.arithmeticMean}';
T.Properties.VariableDescriptions{[newVarName,'_CsArithmeticMean']} = 'cs arithmetic mean';

Silluminance = [S.illuminance]';
T.([newVarName,'_IlluminanceArithmeticMean']) = {Silluminance.arithmeticMean}';
T.Properties.VariableDescriptions{[newVarName,'_IlluminanceArithmeticMean']} = 'illuminance arithmetic mean';

T.([newVarName,'_IlluminanceGeometricMean']) = {Silluminance.geometricMean}';
T.Properties.VariableDescriptions{[newVarName,'_IlluminanceGeometricMean']} = 'illuminance geometric mean';

Sactivity = [S.activity]';
T.([newVarName,'_actualWakePercent']) = {Sactivity.arithmeticMean}';
T.Properties.VariableDescriptions{[newVarName,'_actualWakePercent']} = 'activity arithmetic mean';

T.(varName) = [];

end

function T = expandWorkAverage(T)

S = T.WorkAverage;

newVarName1 = 'workAverage';
newVarName2 = 'workCsQuartiles';

T.([newVarName1,'_nDaysUsed']) = {S.nDays}';
T.Properties.VariableDescriptions{[newVarName1,'_nDaysUsed']} = '# of days used';

Scs = [S.cs]';
T.([newVarName1,'_CsArithmeticMean']) = {Scs.arithmeticMean}';
T.Properties.VariableDescriptions{[newVarName1,'_CsArithmeticMean']} = 'cs arithmetic mean';

Silluminance = [S.illuminance]';
T.([newVarName1,'_IlluminanceArithmeticMean']) = {Silluminance.arithmeticMean}';
T.Properties.VariableDescriptions{[newVarName1,'_IlluminanceArithmeticMean']} = 'illuminance arithmetic mean';

T.([newVarName1,'_IlluminanceGeometricMean']) = {Silluminance.geometricMean}';
T.Properties.VariableDescriptions{[newVarName1,'_IlluminanceGeometricMean']} = 'illuminance geometric mean';

Sactivity = [S.activity]';
T.([newVarName1,'_actualWakePercent']) = {Sactivity.arithmeticMean}';
T.Properties.VariableDescriptions{[newVarName1,'_actualWakePercent']} = 'activity arithmetic mean';

T.([newVarName2,'_nDaysUsed']) = {S.nDays}';
T.Properties.VariableDescriptions{[newVarName2,'_nDaysUsed']} = '# of days used';

T.([newVarName2,'_csQ1']) = {S.csQ1}';
T.Properties.VariableDescriptions{[newVarName2,'_csQ1']} = '1st quartile';

T.([newVarName2,'_csQ2']) = {S.csQ2}';
T.Properties.VariableDescriptions{[newVarName2,'_csQ2']} = '2nd quartile';

T.([newVarName2,'_csQ3']) = {S.csQ3}';
T.Properties.VariableDescriptions{[newVarName2,'_csQ3']} = '3rd quartile';

T.WorkAverage = [];

end


function T = appendVarNames(T,suffix)

varNames = T.Properties.VariableNames;
nVar = numel(varNames);

for iVar = 2:nVar
    varNames{iVar} = [varNames{iVar},suffix];
end

T.Properties.VariableNames = varNames;

end