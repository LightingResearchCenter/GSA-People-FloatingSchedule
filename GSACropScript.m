%% Reset
close all
clear
clc

%% Folder Paths
parentDir = GSADirSelect;
dirObj = LRCDirInit(parentDir);

%% Set Update/Replace Mode
pModeObj = LRCProcessMode;

%% Execute Cropping
LRCCropController(pModeObj,dirObj);