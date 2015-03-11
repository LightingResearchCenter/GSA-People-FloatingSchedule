function [newPaths,lsInput,lsNewInput] = LRCCompareInput(inputDir,outputDir,ext)
%LRCCOMPAREINPUT Compares list of files previously used to content of
%inputDir
%   Detailed explanation goes here

% Find the most recent input index in the outputDir
lsIndex = dir([outputDir,filesep,'inputIndex*.mat']);
if ~isempty(lsIndex)
    [~,idxIndex] = max([lsIndex.datenum]);
    lsIndex = lsIndex(idxIndex);
    indexPath = fullfile(outputDir,lsIndex.name);
    
    S = load(indexPath);
    lsOldInput = S.lsInput;
else
    lsOldInput = struct('name','','date','','bytes',0,'isdir',false,'datenum',0);
end

lsInput = dir([inputDir,filesep,'*',ext]);

oldInputNames = {lsOldInput.name}';
inputNames = {lsInput.name}';
idxNew = ~ismember(inputNames,oldInputNames);
newInputNames = inputNames(idxNew(:));
lsNewInput = lsInput(idxNew(:));

newPaths = fullfile(inputDir,newInputNames);

end

