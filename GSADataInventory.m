%% Reset
close all
clear
clc

%% Dependencies
[githubDir,~,~] = fileparts(pwd);
circadianDir = fullfile(githubDir,'circadian');
addpath(circadianDir);

%% Folder Paths
[parentDir,sessionTitle,building] = GSADirSelect;
dirObj = LRCDirInit(parentDir);

%% Perform Inventory
LRCDataInventory(dirObj.parent);