%% Reset
close all
clear
clc

%% Folder Paths
[parentDir,sessionTitle,building] = GSADirSelect;
dirObj = LRCDirInit(parentDir);

%% Ask if plots are desired
plainPlotMode   = {'on','off'};
displayPlotMode = {'On (generate plots and reports)',...
                   'Off (numeric analysis only)'};
choice = menu('Choose a process mode',displayPlotMode);
plotSwitch = plainPlotMode{choice};

%% Set Update/Replace Mode
pModeObj = LRCProcessMode;
switch pModeObj.mode
    case 'update'
        
    case 'overwrite'
        switch plotSwitch
            case 'on'
                lsPlots = dir(dirObj.plots);
                fileIdx = ~[lsPlots.isdir]';
                if any(fileIdx)
                    plotNames = {lsPlots(~[lsPlots.isdir]').name}';
                    plotPaths = fullfile(dirObj.plots,plotNames);
                    delete(plotPaths{:});
                end
        end
    otherwise

end

%%
LRCBatchAnalysisController(pModeObj,dirObj,plotSwitch,sessionTitle,building);

