function masks = LRCRefactorMasks(masks, idx)
%LRCREFACTORMASKS Summary of this function goes here
%   Detailed explanation goes here

[githubDir,~,~] = fileparts(pwd);
circadianDir = fullfile(githubDir,'circadian');
addpath(circadianDir);

varnames = fieldnames(masks);
nVar = numel(varnames);
for iVar = 1:nVar
    thisVar = varnames{iVar};
    if islogical(masks.(thisVar))
        masks.(thisVar) = masks.(thisVar)(idx);
    end

end

end