%% Reset
close all
clear
clc

%% Folder Paths
[parentDir,sessionTitle,building] = GSADirSelect;
dirObj = LRCDirInit(parentDir);

%% Find and Load Results
% Find the most recent results
lsResults = dir([dirObj.results,filesep,'results*.mat']);
[~,idxResults] = max([lsResults.datenum]);
lsResults = lsResults(idxResults);
resultsPath = fullfile(dirObj.results,lsResults.name);

S = load(resultsPath);
Results = S.output_args;
idxEmpty = cellfun(@isempty,Results);
Results(idxEmpty) = [];
Results = [Results{:}];

%% Convert Structure to Cell matrix
nResults = numel(Results);

varCell = {'1', ' ','subject ID';...
           '2', ' ','building';...
           '3', ' ','location';...
           
           '4', 'overall phasor','# days used';...
           '5', 'overall phasor','magnitude';...
           '6', 'overall phasor','angle (hours)';...
           
           '7', 'overall is & iv','# days used';...
           '8', 'overall is & iv','interdaily stability';...
           '9', 'overall is & iv','intradaily variability';...
           
           '10','overall sleep','# days used';...
           '11','overall sleep','actual sleep time (mins.)';...
           '12','overall sleep','actual sleep (%)';...
           '13','overall sleep','actual wake time (mins.)';...
           '14','overall sleep','actual wake (%)';...
           '15','overall sleep','sleep efficiency (%)';...
           '16','overall sleep','sleep onset latency (mins.)';...
           
           '17','overall waking average','# days used';...
           '18','overall waking average','cs ari-mean';...
           '19','overall waking average','illuminance ari-mean';...
           '20','overall waking average','illuminance geo-mean';...
           '21','overall waking average','activity ari-mean';...
           
           '22','pre-work average','# days used';...
           '23' 'pre-work average','cs ari-mean';...
           '24','pre-work average','illuminance ari-mean';...
           '25','pre-work average','illuminance geo-mean';...
           '26','pre-work average','activity ari-mean';...
           
           '27','work average','# days used';...
           '28' 'work average','cs ari-mean';...
           '29','work average','illuminance ari-mean';...
           '30','work average','illuminance geo-mean';...
           '31','work average','activity ari-mean';...
           
           '32','post-work average','# days used';...
           '33' 'post-work average','cs ari-mean';...
           '34','post-work average','illuminance ari-mean';...
           '35','post-work average','illuminance geo-mean';...
           '36','post-work average','activity ari-mean'
           
           '37','post-work sleep','# days used';...
           '38','post-work sleep','actual sleep time (mins.)';...
           '39','post-work sleep','actual sleep (%)';...
           '40','post-work sleep','actual wake time (mins.)';...
           '41','post-work sleep','actual wake (%)';...
           '42','post-work sleep','sleep efficiency (%)';...
           '43','post-work sleep','sleep onset latency (mins.)'}';

[~,nVar] = size(varCell);

rCell = cell(nResults+3,nVar);

rCell(1:3,:) = varCell;

for iR = 1:nResults
    thisResult = Results(iR);
    row = iR+3;
    
    if isfield(thisResult,'subjectID')
        rCell{row,1}  = thisResult.subjectID;
        rCell{row,2}  = thisResult.building;
        rCell{row,3}  = thisResult.location;
    end
    
    if isfield(thisResult.Phasor,'nDays')
        rCell{row,4}  = thisResult.Phasor.nDays;
        rCell{row,5}  = thisResult.Phasor.magnitude;
        rCell{row,6}  = thisResult.Phasor.angle.hours;
    end
    
    if isfield(thisResult.Actigraphy,'nDays')
        rCell{row,7}  = thisResult.Actigraphy.nDays;
        rCell{row,8}  = thisResult.Actigraphy.interdailyStability;
        rCell{row,9}  = thisResult.Actigraphy.intradailyVariability;
    end
    
    if isfield(thisResult.Sleep,'nIntervalsAveraged')
        rCell{row,10} = thisResult.Sleep.nIntervalsAveraged;
        rCell{row,11} = thisResult.Sleep.actualSleepTime;
        rCell{row,12} = thisResult.Sleep.actualSleepPercent;
        rCell{row,13} = thisResult.Sleep.actualWakeTime;
        rCell{row,14} = thisResult.Sleep.actualWakePercent;
        rCell{row,15} = thisResult.Sleep.sleepEfficiency;
        rCell{row,16} = thisResult.Sleep.sleepLatency;
    end
    
    if isfield(thisResult.Average,'nDays')
        rCell{row,17} = thisResult.Average.nDays;
        rCell{row,18} = thisResult.Average.cs.arithmeticMean;
        rCell{row,19} = thisResult.Average.illuminance.arithmeticMean;
        rCell{row,20} = thisResult.Average.illuminance.geometricMean;
        rCell{row,21} = thisResult.Average.activity.arithmeticMean;
    end
    
    if isfield(thisResult.PreWorkAverage,'nDays')
        rCell{row,22} = thisResult.PreWorkAverage.nDays;
        rCell{row,23} = thisResult.PreWorkAverage.cs.arithmeticMean;
        rCell{row,24} = thisResult.PreWorkAverage.illuminance.arithmeticMean;
        rCell{row,25} = thisResult.PreWorkAverage.illuminance.geometricMean;
        rCell{row,26} = thisResult.PreWorkAverage.activity.arithmeticMean;
    end
    
    if isfield(thisResult.WorkAverage,'nDays')
        rCell{row,27} = thisResult.WorkAverage.nDays;
        rCell{row,28} = thisResult.WorkAverage.cs.arithmeticMean;
        rCell{row,29} = thisResult.WorkAverage.illuminance.arithmeticMean;
        rCell{row,30} = thisResult.WorkAverage.illuminance.geometricMean;
        rCell{row,31} = thisResult.WorkAverage.activity.arithmeticMean;
    end
    
    if isfield(thisResult.PostWorkAverage,'nDays')
        rCell{row,32} = thisResult.PostWorkAverage.nDays;
        rCell{row,33} = thisResult.PostWorkAverage.cs.arithmeticMean;
        rCell{row,34} = thisResult.PostWorkAverage.illuminance.arithmeticMean;
        rCell{row,35} = thisResult.PostWorkAverage.illuminance.geometricMean;
        rCell{row,36} = thisResult.PostWorkAverage.activity.arithmeticMean;
    end
    
    if isfield(thisResult.PostWorkSleep,'nIntervalsAveraged')
        rCell{row,37} = thisResult.PostWorkSleep.nIntervalsAveraged;
        rCell{row,38} = thisResult.PostWorkSleep.actualSleepTime;
        rCell{row,39} = thisResult.PostWorkSleep.actualSleepPercent;
        rCell{row,40} = thisResult.PostWorkSleep.actualWakeTime;
        rCell{row,41} = thisResult.PostWorkSleep.actualWakePercent;
        rCell{row,42} = thisResult.PostWorkSleep.sleepEfficiency;
        rCell{row,43} = thisResult.PostWorkSleep.sleepLatency;
    end
end

%% Write cell matrix to file
[folder,name,~] = fileparts(resultsPath);
excelPath = [folder,filesep,name,'.xlsx'];
if exist(excelPath,'file') == 2
    delete(excelPath);
end
xlswrite(excelPath,rCell);