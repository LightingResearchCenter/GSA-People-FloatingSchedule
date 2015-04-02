%% Reset
close all
clear
clc

%% Dependencies
[githubDir,~,~] = fileparts(pwd);
circadianDir = fullfile(githubDir,'circadian');
addpath(circadianDir);

%% Folder Paths
parentDir = '\\ROOT\projects\GSA_Daysimeter\WashingtonDC\Daysimeter_People_Data\winter';
dirObj = LRCDirInit(parentDir);

p1 = fullfile(parentDir,'phasor-1800F-winter.pdf');
p2 = fullfile(parentDir,'miller-1800F-winter.pdf');

p3 = fullfile(parentDir,'phasor-ROB-winter.pdf');
p4 = fullfile(parentDir,'miller-ROB-winter.pdf');

%% Find and Load Results
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

%% Select the data to be plotted

Phasor = [Results(:).Phasor];

nDaysPhasor = [Phasor(:).nDays]';
idx3DaysPlus = nDaysPhasor >= 3;

idx1800F = strcmpi({Results.building}','1800F');
idx1800F_3Plus = idx1800F & idx3DaysPlus;

Results_1800F = Results(idx1800F_3Plus);
Phasor_1800F = [Results_1800F(:).Phasor];
Miller_1800F = [Results_1800F(:).WorkMiller];

idxEmpty = false(size(Miller_1800F));
for iM = 1:numel(Miller_1800F);
    idxEmpty(iM) = isempty(Miller_1800F(iM).cs);
end
Miller_1800F(idxEmpty) = [];
Phasor_1800F(idxEmpty) = [];

idxROB = strcmpi({Results.building}','ROB');
idxROB_3Plus = idxROB & idx3DaysPlus;

Results_ROB = Results(idxROB_3Plus);
Phasor_ROB = [Results_ROB(:).Phasor];
Miller_ROB = [Results_ROB(:).WorkMiller];

idxEmpty = false(size(Miller_ROB));
for iM = 1:numel(Miller_ROB);
    idxEmpty(iM) = isempty(Miller_ROB(iM).cs);
end
Miller_ROB(idxEmpty) = [];
Phasor_ROB(idxEmpty) = [];

%% Isolated the phasor vectors and average them
vector_1800F = [Phasor_1800F(:).vector];
mean_vector_1800F = mean(vector_1800F);

vector_ROB = [Phasor_ROB(:).vector];
mean_vector_ROB = mean(vector_ROB);

%% Phasor Plot 1800F
[hAxes,hGrid,hLabels] = plots.phasoraxes('rMax',0.6,'rTicks',3);

% Plot the individual phasor vectors
nVec = numel(vector_1800F);
black = [0, 0, 0];
gray = [0.5 0.5 0.5];
for iVec = 1:nVec
    thisVector = vector_1800F(iVec);
    hLine = line([0,real(thisVector)],[0,imag(thisVector)]);
    hLine.Color = gray;
    hLine.LineWidth = 0.5;
end

% Plot and format the average phasor vector
hLine = line([0,real(mean_vector_1800F)],[0,imag(mean_vector_1800F)]);
hLine.Color = black;
hLine.LineWidth = 2;

% Save the figure to disk
saveas(gcf,p1);
close all;

%% Miller Plot 1800F
hFig = figure;
hAxes = axes;

time_1800F = vertcat(Miller_1800F(:).time);
minutes_1800F = vertcat(time_1800F(:).minutes);
unqMinutes_1800F = unique(minutes_1800F);
unqMinutes_1800F = sort(unqMinutes_1800F);
cs_1800F = vertcat(Miller_1800F(:).cs);
ai_1800F = vertcat(Miller_1800F(:).activity);

miller_time_1800F = relativetime(unqMinutes_1800F,'minutes');
miller_cs_1800F = zeros(size(miller_time_1800F.minutes));
miller_ai_1800F = zeros(size(miller_time_1800F.minutes));
for iT = 1:numel(miller_time_1800F.minutes)
    thisMinute = miller_time_1800F.minutes(iT);
    thisIdx = minutes_1800F == thisMinute;
    
    miller_cs_1800F(iT) = mean(cs_1800F(thisIdx));
    miller_ai_1800F(iT) = mean(ai_1800F(thisIdx));
end

plot(hAxes,miller_time_1800F.hours,miller_cs_1800F)
hold on;
plot(hAxes,miller_time_1800F.hours,miller_ai_1800F)
hLeg = legend('cs','ai');

hAxes.XLim = [0 24];
hAxes.YLim = [0 0.7];

% Save the figure to disk
saveas(gcf,p2);
close all

%% Phasor Plot ROB
[hAxes,hGrid,hLabels] = plots.phasoraxes('rMax',0.6,'rTicks',3);

% Plot the individual phasor vectors
nVec = numel(vector_ROB);
black = [0, 0, 0];
gray = [0.5 0.5 0.5];
for iVec = 1:nVec
    thisVector = vector_ROB(iVec);
    hLine = line([0,real(thisVector)],[0,imag(thisVector)]);
    hLine.Color = gray;
    hLine.LineWidth = 0.5;
end

% Plot and format the average phasor vector
hLine = line([0,real(mean_vector_ROB)],[0,imag(mean_vector_ROB)]);
hLine.Color = black;
hLine.LineWidth = 2;

% Save the figure to disk
saveas(gcf,p3);
close all;

%% Miller Plot ROB
hFig = figure;
hAxes = axes;


time_ROB = vertcat(Miller_ROB(:).time);
minutes_ROB = vertcat(time_ROB(:).minutes);
minutes_ROB = unique(minutes_ROB);
minutes_ROB = sort(minutes_ROB);
cs_ROB = vertcat(Miller_ROB(:).cs);
ai_ROB = vertcat(Miller_ROB(:).activity);

miller_time_ROB = relativetime(minutes_ROB,'minutes');
miller_cs_ROB = zeros(size(miller_time_ROB.minutes));
miller_ai_ROB = zeros(size(miller_time_ROB.minutes));
for iT = 1:numel(miller_time_ROB.minutes)
    thisMinute = miller_time_ROB.minutes(iT);
    thisIdx = minutes_ROB == thisMinute;
    
    miller_cs_ROB(iT) = mean(cs_ROB(thisIdx));
    miller_ai_ROB(iT) = mean(ai_ROB(thisIdx));
end

plot(hAxes,miller_time_ROB.hours,miller_cs_ROB)
hold on;
plot(hAxes,miller_time_ROB.hours,miller_ai_ROB)
hLeg = legend('cs','ai');

hAxes.XLim = [0 24];
hAxes.YLim = [0 0.7];

% Save the figure to disk
saveas(gcf,p4);
close all
