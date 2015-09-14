function LRCBatchAnalysisController(pModeObj,dirObj,plotSwitch,sessionTitle,building)
%LRCBATCHANALYSISCONTROLLER Summary of this function goes here
%   Detailed explanation goes here


% Construct input index path string
timestamp = datestr(now,'yyyymmdd-HHMMSS-FFF');
inputIndexName = ['inputIndex-',timestamp,'.mat'];
inputIndexPath = fullfile(dirObj.results,inputIndexName);

% Construct results path
resultsName = ['results-',timestamp,'.mat'];
resultsPath = fullfile(dirObj.results,resultsName);

% Construct input file path strings and save index of input
switch pModeObj.mode
    case 'update'
        [inputPaths,lsInput,lsNewInput] = LRCCompareInput(dirObj.cropped,dirObj.results,'.cdf');
    case 'overwrite'
        lsInput = dir([dirObj.cropped,filesep,'*.cdf']);
        lsNewInput = lsInput;
        inputNames = {lsInput.name}';
        inputPaths = fullfile(dirObj.cropped,inputNames);
    otherwise
        error('Unrecognized process mode.')
end

nFile = numel(inputPaths);
output_args = cell(nFile,1);
for iFile = 1:nFile
    
    thisFile = inputPaths{iFile};
    
    [status, temp_output_args] = LRCAnalysisController(thisFile, dirObj, plotSwitch, sessionTitle, building);
    
%     switch status
%         case 'failure'
%             display('Warning failure detected');
%         case {'success','warning'}
            output_args{iFile} = temp_output_args;
%     end

    
end

close all;

save(inputIndexPath,'lsInput','lsNewInput');
save(resultsPath,'output_args');

end

