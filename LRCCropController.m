function LRCCropController(pModeObj,dirObj)
%LRCCROPCONTROLLER Controls the batch cropping of CDF files
%   Detailed explanation goes here

% Enable dependencies
[githubDir,~,~] = fileparts(pwd);
circadianDir = fullfile(githubDir,'circadian');
addpath(circadianDir);

% Check input arguments
if ~isa(pModeObj,'LRCProcessMode')
    error('pModeObj must be an object of class LRCProcessMode');
end
if ~isa(dirObj,'LRCDirInit')
    error('dirObj must be an object of class LRCDirInit.');
end

inputDir = dirObj.original;
outputDir = dirObj.cropped;
logDir = dirObj.logs;

% Check if directories exist. Create directories if they do not.
if ~isdir(inputDir)
    mkdir(inputDir)
end
if ~isdir(outputDir)
    mkdir(outputDir)
end
if ~isdir(logDir)
    error(['Cannot find: ',logDir]);
end

% Construct input index path string
timestamp = datestr(now,'yyyymmdd-HHMMSS-FFF');
inputIndexName = ['inputIndex-',timestamp,'.mat'];
inputIndexPath = fullfile(outputDir,inputIndexName);

% Construct input file path strings and save index of input
switch pModeObj.mode
    case 'update'
        [inputPaths,lsInput,lsNewInput] = LRCCompareInput(inputDir,outputDir,'.cdf');
        save(inputIndexPath,'lsInput','lsNewInput');
    case 'overwrite'
        delete([outputDir,filesep,'*.cdf']);
        
        lsInput = dir([inputDir,filesep,'*.cdf']);
        lsNewInput = lsInput;
        inputNames = {lsInput.name}';
        inputPaths = fullfile(inputDir,inputNames);
        save(inputIndexPath,'lsInput','lsNewInput');
    otherwise
        error('Unrecognized process mode.')
end

% Construct output file path strings
outputNames = {lsNewInput.name}';
outputPaths = fullfile(outputDir,outputNames);

% Prepare figure for cropping interface
hFig = figure;
hFig.Units = 'normalized';
hFig.Position = [0.01,0.05,.98,.87];
% Iterate through files
nFiles = numel(inputPaths);
for iFile = 1:nFiles
    % Select original and cropped file paths
    thisOrigFile = inputPaths{iFile};
    thisCropFile = outputPaths{iFile};
    % Load original data
    origData = daysimeter12.readcdf(thisOrigFile);
    % Determine bed log based on subject
    thisSubject = origData.GlobalAttributes.subjectID;
    thisBedLog = fullfile(logDir,['bedLog_subject',thisSubject,'.xlsx']);
    % Crop original data
    cropData = LRCSingleCDFcrop(origData,thisBedLog,hFig);
    % Save cropped data
    if exist(thisCropFile,'file') == 2
        delete(thisCropFile)
    end
    daysimeter12.writecdf(cropData,thisCropFile);
end
% Close the figure from cropping
close(hFig);


end

