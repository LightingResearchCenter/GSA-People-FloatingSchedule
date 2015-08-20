function GSARepeatsGroupFigures

% Dependencies
[githubDir,~,~] = fileparts(pwd);
circadianDir = fullfile(githubDir,'circadian');
addpath(circadianDir);

% Map Paths
[~,summerParentDir,summerSessionTitle,winterParentDir,winterSessionTitle,~] = GSADirBuildingSelect;

dirObjSummer = LRCDirInit(summerParentDir);
dirObjWinter = LRCDirInit(winterParentDir);

phasorPathSummer = fullfile(summerParentDir,['phasor-repeatsONLY',summerSessionTitle,'.pdf']);
millerPathSummer = fullfile(summerParentDir,['miller-repeatsONLY',summerSessionTitle,'.pdf']);

phasorPathWinter = fullfile(winterParentDir,['phasor-repeatsONLY',winterSessionTitle,'.pdf']);
millerPathWinter = fullfile(winterParentDir,['miller-repeatsONLY',winterSessionTitle,'.pdf']);

% Find and Load Results
ResultsSummer = GSALoadResults(dirObjSummer);
ResultsWinter = GSALoadResults(dirObjWinter);

% Limit results to repeat subjects
[ResultsSummer,ResultsWinter] = GSAFindRepeats(ResultsSummer,ResultsWinter);

% Select the data to be plotted
[MillerSummer,PhasorSummer] = GSASelectData(ResultsSummer);
[MillerWinter,PhasorWinter] = GSASelectData(ResultsWinter);

% Phasor Plot
GSAPhasorPlot(PhasorSummer,phasorPathSummer);
GSAPhasorPlot(PhasorWinter,phasorPathWinter);

% Miller Plot
GSAMillerPlot(MillerSummer,millerPathSummer);
GSAMillerPlot(MillerWinter,millerPathWinter);

end


function Results = GSALoadResults(dirObj)
% Find the most recent results
lsResults = dir([dirObj.results,filesep,'results*.mat']);
[~,idxResults] = max([lsResults.datenum]);
lsResults = lsResults(idxResults);
resultsPath = fullfile(dirObj.results,lsResults.name);

S = load(resultsPath);
Results = S.output_args;
Results = [Results{:}];

sub = {Results.subjectID};
idxUnqSub = false(size(Results));
preSub = '';
for iSub = 1:numel(sub);
    thisSub = sub{iSub};
    idxUnqSub(iSub) = ~strcmp(preSub,thisSub);
    preSub = thisSub;
end
Results = Results(idxUnqSub);
end


function [ResultsSummer,ResultsWinter] = GSAFindRepeats(ResultsSummer,ResultsWinter)
subjectsSummer = {ResultsSummer.subjectID};
subjectsWinter = {ResultsWinter.subjectID};
[subjectsRepeat,idxSummer,idxWinter] = intersect(subjectsSummer,subjectsWinter);
ResultsSummer = ResultsSummer(idxSummer);
ResultsWinter = ResultsWinter(idxWinter);

end

function [Miller_3plus,Phasor_3plus] = GSASelectData(Results)
Phasor = [Results(:).Phasor];

nDaysPhasor = [Phasor(:).nDays]';
idx3DaysPlus = nDaysPhasor >= 3;

Results_3plus = Results(idx3DaysPlus);
Phasor_3plus = [Results_3plus(:).Phasor];
Miller_3plus = [Results_3plus(:).Miller];

idxEmpty = false(size(Miller_3plus));
for iM = 1:numel(Miller_3plus);
    idxEmpty(iM) = isempty(Miller_3plus(iM).cs);
end
Miller_3plus(idxEmpty) = [];
Phasor_3plus(idxEmpty) = [];
end

function GSAPhasorPlot(Phasor_3plus,phasorPath)

% Isolate the phasor vectors and average them
vector_3plus = [Phasor_3plus(:).vector];
mean_vector_3plus = mean(vector_3plus);

[hAxes,hGrid,hLabels] = plots.phasoraxes('rMax',0.6,'rTicks',3);

% Plot the individual phasor vectors
nVec = numel(vector_3plus);
black = [0, 0, 0];
gray = [0.5 0.5 0.5];
for iVec = 1:nVec
    thisVector = vector_3plus(iVec);
    hLine = line([0,real(thisVector)],[0,imag(thisVector)]);
    hLine.Color = gray;
    hLine.LineWidth = 0.5;
end

% Plot and format the average phasor vector
hLine = line([0,real(mean_vector_3plus)],[0,imag(mean_vector_3plus)]);
hLine.Color = black;
hLine.LineWidth = 2;

% Save the figure to disk
saveas(gcf,phasorPath);
close all;
end

function GSAMillerPlot(Miller_3plus,millerPath)
hFig = figure;
hAxes = axes;

time_3plus = vertcat(Miller_3plus(:).time);
minutes_3plus = vertcat(time_3plus(:).minutes);
unqMinutes_3plus = unique(minutes_3plus);
unqMinutes_3plus = sort(unqMinutes_3plus);
cs_3plus = vertcat(Miller_3plus(:).cs);
ai_3plus = vertcat(Miller_3plus(:).activity);

miller_time_3plus = relativetime(unqMinutes_3plus,'minutes');
miller_cs_3plus = zeros(size(miller_time_3plus.minutes));
miller_ai_3plus = zeros(size(miller_time_3plus.minutes));
for iT = 1:numel(miller_time_3plus.minutes)
    thisMinute = miller_time_3plus.minutes(iT);
    thisIdx = minutes_3plus == thisMinute;
    
    miller_cs_3plus(iT) = mean(cs_3plus(thisIdx));
    miller_ai_3plus(iT) = mean(ai_3plus(thisIdx));
end

plot(hAxes,miller_time_3plus.hours,miller_cs_3plus)
hold on;
plot(hAxes,miller_time_3plus.hours,miller_ai_3plus)
hLeg = legend('cs','ai');

hAxes.XLim = [0 24];
hAxes.YLim = [0 0.7];

% Save the figure to disk
saveas(gcf,millerPath);
close all
end