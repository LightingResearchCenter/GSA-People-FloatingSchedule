%% Reset
close all
clear
clc

%% Folder Paths
parentDir = '\\ROOT\projects\GSA_Daysimeter\WashingtonDC\Daysimeter_People_Data\winter';
dirObj = LRCDirInit(parentDir);

%% Set Update/Replace Mode
pModeObj = LRCProcessMode;

%% Execute Cropping
LRCCropController(pModeObj,dirObj);