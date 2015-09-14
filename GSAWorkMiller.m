function GSAWorkMiller

% Dependencies
[githubDir,~,~] = fileparts(pwd);
circadianDir = fullfile(githubDir,'circadian');
addpath(circadianDir);

% Map Paths
[~,summerParentDir,summerSessionTitle,winterParentDir,winterSessionTitle,~] = GSADirBuildingSelect;

dirObjSummer = LRCDirInit(summerParentDir);
dirObjWinter = LRCDirInit(winterParentDir);

summerSavePath = fullfile(dirObjSummer.plots,'workMiller');
winterSavePath = fullfile(dirObjWinter.plots,'workMiller');

if exist(summerSavePath,'dir') == 7
    rmdir(summerSavePath,'s');
end
mkdir(summerSavePath);

if exist(winterSavePath,'dir') == 7
    rmdir(winterSavePath,'s');
end
mkdir(winterSavePath);

% Find and Load Results
ResultsSummer = GSALoadResults(dirObjSummer);
ResultsWinter = GSALoadResults(dirObjWinter);

% Create Miller Plots
plotMillers(ResultsSummer,summerSavePath,summerSessionTitle)
plotMillers(ResultsWinter,winterSavePath,winterSessionTitle)

end


function Results = GSALoadResults(dirObj)
% Find the most recent results
lsResults = dir([dirObj.results,filesep,'results*.mat']);
[~,idxResults] = max([lsResults.datenum]);
lsResults = lsResults(idxResults);
resultsPath = fullfile(dirObj.results,lsResults.name);

S = load(resultsPath);
Results = S.output_args;
fun = @(c) isfield(c,'subjectID');
idxValid = cellfun(fun,Results);
% idxEmpty = cellfun(@isempty,Results);
Results(~idxValid) = [];
Results = [Results{:}];

end


function plotMillers(results,savePath,sessionTitle)

oldState = recycle('on');

hFig = figure;
hFig.Units = 'inches';
hFig.PaperOrientation = 'landscape';
hFig.PaperPosition = [0, 0, 11, 8.5];
hFig.Position = [0, 0, 11, 8.5];
hFig.Renderer = 'painters';

n = numel(results);

for i1 = 1:n
    % Clear figure window
    clf(hFig);
    
    % Isolate data for this iteration
    thisSubject = results(i1).subjectID;
    thisLocation = results(i1).location;
    thisMiller = results(i1).WorkMiller;
    
    % Create axes to plot on
    hMiller = axes;
    hMiller.Units = 'inches';
    hMiller.Position = [1, 1.5, 9, 5.5]; 
    
    if isempty(thisMiller.cs)
        continue;
    end
    
    % Create the Miller plot
    try
        plots.miller(thisMiller.time,'Circadian Stimulus (CS)',thisMiller.cs,'Activity Index (AI)',thisMiller.activity,hMiller);
    catch err
        warning(err);
    end
    % Create title
    thisTitle = {'Average Workday';...
                  sessionTitle;...
                ['Subject: ',thisSubject,'  Location: ',thisLocation]};
    hMillerTitle = title(thisTitle);
    
    thisPath = fullfile(savePath,['workMiller_',sessionTitle,'_subject_',thisSubject,'_location_',thisLocation,'.pdf']);
    
    saveas(hFig,thisPath);
end

close(hFig);

recycle(oldState);

end

