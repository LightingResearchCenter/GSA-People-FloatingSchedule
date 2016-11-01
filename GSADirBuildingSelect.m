function [buildingDir,summerParentDir,summerSessionTitle,winterParentDir,winterSessionTitle,building] = GSADirBuildingSelect(varargin)
%GSADIRBUILDINGSELECT Summary of this function goes here
%   Detailed explanation goes here

GSADir = '\\ROOT\projects\GSA_Daysimeter';

if nargin < 1
    city = {'DC-1800F','DC-ROB','Seattle-1201','Seattle-1202','Grand Junction','Portland'};
    choice = menu('Choose a city',city);
    thisCity = city{choice};
else
    thisCity = varargin{1};
end

switch thisCity
    case 'DC-1800F'
        buildingDir = fullfile(GSADir,'WashingtonDC','Daysimeter_People_Data');
        [summerParentDir,winterParentDir] = constructPaths(buildingDir);
        titleRoot = 'GSA - Washington, D.C., 1800F';
        [summerSessionTitle,winterSessionTitle] = constructTitles(titleRoot);
        building = '1800F';
    case 'DC-ROB'
        buildingDir = fullfile(GSADir,'WashingtonDC-RegionalOfficeBldg-7th&Dstreet','Daysimeter_People_Data');
        [summerParentDir,winterParentDir] = constructPaths(buildingDir);
        titleRoot = 'GSA - Washington, D.C., ROB';
        [summerSessionTitle,winterSessionTitle] = constructTitles(titleRoot);
        building = 'Regional Office Building';
    case 'Seattle-1201'
        buildingDir = fullfile(GSADir,'Seattle_Washington\Daysimeter_People_Data\FCS_Building_1201');
        [summerParentDir,winterParentDir] = constructPaths(buildingDir);
        titleRoot = 'GSA - Seattle, WA FCS Building 1201';
        [summerSessionTitle,winterSessionTitle] = constructTitles(titleRoot);
        building = 'FCS Building 1201';
    case 'Seattle-1202'
        buildingDir = fullfile(GSADir,'Seattle_Washington\Daysimeter_People_Data\FCS_Building_1202');
        [summerParentDir,winterParentDir] = constructPaths(buildingDir);
        titleRoot = 'GSA - Seattle, WA FCS Building 1202';
        [summerSessionTitle,winterSessionTitle] = constructTitles(titleRoot);
        building = 'FCS Building 1202';
    case 'Grand Junction'
        buildingDir = fullfile(GSADir,'GrandJunction_Colorado_site_data','Daysimeter_People_Data');
        [summerParentDir,winterParentDir] = constructPaths(buildingDir);
        titleRoot = 'GSA - Grand Junction, CO';
        [summerSessionTitle,winterSessionTitle] = constructTitles(titleRoot);
        building = 'Grand Junction';
    case 'Portland'
        buildingDir = fullfile(GSADir,'Portland_Oregon_site_data','Daysimeter_People_Data');
        [summerParentDir,winterParentDir] = constructPaths(buildingDir);
        titleRoot = 'GSA - Portland, OR';
        [summerSessionTitle,winterSessionTitle] = constructTitles(titleRoot);
        building = 'Portland';
    otherwise
        error('Unknown city');
end

end


function [summerParentDir,winterParentDir] = constructPaths(cityDir)

summerParentDir = fullfile(cityDir,'summer');
winterParentDir = fullfile(cityDir,'winter');

end

function [summerSessionTitle,winterSessionTitle] = constructTitles(titleRoot)

summerSessionTitle = [titleRoot,' - Summer'];
winterSessionTitle = [titleRoot,' - Winter'];

end

