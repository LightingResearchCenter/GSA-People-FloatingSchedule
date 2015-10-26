function GSACsFrequency
%GSACSFREQUENCY Summary of this function goes here
%   Detailed explanation goes here

% Map paths
[dataDir,logDir] = mapDirs;


end

function [dataDir,logDir] = mapDirs
GSADir = '\\ROOT\projects\GSA_Daysimeter';

buildingBase = {
    'WashingtonDC\Daysimeter_People_Data';...
    'WashingtonDC-RegionalOfficeBldg-7th&Dstreet\Daysimeter_People_Data';...
    'Seattle_Washington\Daysimeter_People_Data\FCS_Building_1201';...
    'Seattle_Washington\Daysimeter_People_Data\FCS_Building_1202';...
    'GrandJunction_Colorado_site_data\Daysimeter_People_Data';...
    'Portland_Oregon_site_data\Daysimeter_People_Data'
    };

buildingDir = fullfile(GSADir,buildingBase);

summerDir = fullfile(buildingDir,'summer');
winterDir = fullfile(buildingDir,'winter');
seasonDir = [summerDir;winterDir];

dataDir = fullfile(seasonDir,'croppedData');
logDir = fullfile(seasonDir,'logs');

TF = dirDoesExist(dataDir) & dirDoesExist(logDir);
if any(~TF)
    warning('Missing directories removed from list.');
    dataDir(~TF) = [];
    logDir(~TF) = [];
end

end

function TF = dirDoesExist(dirArray)

fun = @(x) exist(x,'dir');

TF = cellfun(fun,dirArray) == 7;

end

function TF = fileDoesExist(pathArray)

fun = @(x) exist(x,'file');

TF = cellfun(fun,dirArray) == 2;

end
