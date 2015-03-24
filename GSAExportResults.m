%% Reset
close all
clear
clc

%% Folder Paths
parentDir = '\\ROOT\projects\GSA_Daysimeter\WashingtonDC\Daysimeter_People_Data\winter';
dirObj = LRCDirInit(parentDir);

%% Find and Load Results
% Find the most recent results
lsResults = dir([dirObj.results,filesep,'results*.mat']);
[~,idxResults] = max([lsResults.datenum]);
lsResults = lsResults(idxResults);
resultsPath = fullfile(dirObj.results,lsResults.name);

S = load(resultsPath);
Results = S.output_args;
Results = cat(1,Results{:});

%% Convert Structure to Cell matrix
nResults = numel(Results);

varCell = {'1', ' ','subject ID';...
           '2', ' ','building';...
           '3', ' ','locations';...
           
           '4', 'phasor','# days used';...
           '5', 'phasor','magnitude';...
           '6', 'phasor','angle (hours)';...
           
           '7', 'is & iv','# days used';...
           '8', 'is & iv','interdaily stability';...
           '9', 'is & iv','intradaily variability';...
           
           '10','sleep','# days used';...
           '11','sleep','actual sleep time (mins.)';...
           '12','sleep','actual sleep (%)';...
           '13','sleep','actual wake time (mins.)';...
           '14','sleep','actual wake (%)';...
           '15','sleep','sleep efficiency (%)';...
           '16','sleep','sleep onset latency (mins.)';...
           
           '17','waking average','# days used';...
           '18','waking average','cs ari-mean';...
           '19','waking average','illuminance ari-mean';...
           '20','waking average','illuminance geo-mean';...
           '21','waking average','activity ari-mean';...
           
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
           '36','post-work average','activity ari-mean'}';

[~,nVar] = size(varCell);

rCell = cell(nResults+3,nVar);

rCell(1:3,:) = varCell;

for iR = 1:nResults
    thisResult = Results(iR);
    row = iR+3;
    
    rCell{row,1}  = thisResult.subjectID;
    rCell{row,2}  = thisResult.building;
    rCell{row,3}  = thisResult.locations;
    
    rCell{row,4}  = thisResult.Phasor.nDays;
    rCell{row,5}  = thisResult.Phasor.magnitude;
    rCell{row,6}  = thisResult.Phasor.angle.hours;
    
    rCell{row,7}  = thisResult.Actigraphy.nDays;
    rCell{row,8}  = thisResult.Actigraphy.interdailyStability;
    rCell{row,9}  = thisResult.Actigraphy.intradailyVariability;
    
    rCell{row,10} = thisResult.Sleep.nIntervalsAveraged;
    rCell{row,11} = thisResult.Sleep.actualSleepTime;
    rCell{row,12} = thisResult.Sleep.actualSleepPercent;
    rCell{row,13} = thisResult.Sleep.actualWakeTime;
    rCell{row,14} = thisResult.Sleep.actualWakePercent;
    rCell{row,15} = thisResult.Sleep.sleepEfficiency;
    rCell{row,16} = thisResult.Sleep.sleepLatency;
    
    rCell{row,17} = thisResult.Average.nDays;
    rCell{row,18} = thisResult.Average.cs.arithmeticMean;
    rCell{row,19} = thisResult.Average.illuminance.arithmeticMean;
    rCell{row,20} = thisResult.Average.illuminance.geometricMean;
    rCell{row,21} = thisResult.Average.activity.arithmeticMean;
    
    rCell{row,22} = thisResult.PreWorkAverage.nDays;
    rCell{row,23} = thisResult.PreWorkAverage.cs.arithmeticMean;
    rCell{row,24} = thisResult.PreWorkAverage.illuminance.arithmeticMean;
    rCell{row,25} = thisResult.PreWorkAverage.illuminance.geometricMean;
    rCell{row,26} = thisResult.PreWorkAverage.activity.arithmeticMean;
    
    rCell{row,27} = thisResult.WorkAverage.nDays;
    rCell{row,28} = thisResult.WorkAverage.cs.arithmeticMean;
    rCell{row,29} = thisResult.WorkAverage.illuminance.arithmeticMean;
    rCell{row,30} = thisResult.WorkAverage.illuminance.geometricMean;
    rCell{row,31} = thisResult.WorkAverage.activity.arithmeticMean;
    
    rCell{row,32} = thisResult.PostWorkAverage.nDays;
    rCell{row,33} = thisResult.PostWorkAverage.cs.arithmeticMean;
    rCell{row,34} = thisResult.PostWorkAverage.illuminance.arithmeticMean;
    rCell{row,35} = thisResult.PostWorkAverage.illuminance.geometricMean;
    rCell{row,36} = thisResult.PostWorkAverage.activity.arithmeticMean;
end

%% Write cell matrix to file
[folder,name,~] = fileparts(resultsPath);
excelPath = [folder,filesep,name,'.xlsx'];
if exist(excelPath,'file') == 2
    delete(excelPath);
end
xlswrite(excelPath,rCell);