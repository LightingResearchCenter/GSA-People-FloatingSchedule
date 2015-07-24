function [parentDir,sessionTitle,building] = GSADirSelect
%GSADIRSELECT Summary of this function goes here
%   Detailed explanation goes here

GSADir = '\\ROOT\projects\GSA_Daysimeter';

city = {'DC-1800F','DC-ROB','Seattle-1201','Seattle-1202'};
choice = menu('Choose a city',city);
thisCity = city{choice};

switch thisCity
    case 'DC-1800F'
        cityDir = fullfile(GSADir,'WashingtonDC','Daysimeter_People_Data');
        thisSeason = seasonSelect;
        parentDir = fullfile(cityDir,lower(thisSeason));
        sessionTitle = ['GSA - Washington, D.C., 1800F - ',thisSeason];
        building = '1800F';
    case 'DC-ROB'
        cityDir = fullfile(GSADir,'WashingtonDC-RegionalOfficeBldg-7th&Dstreet','Daysimeter_People_Data');
        thisSeason = seasonSelect;
        parentDir = fullfile(cityDir,lower(thisSeason));
        sessionTitle = ['GSA - Washington, D.C., ROB - ',thisSeason];
        building = 'Regional Office Building';
    case 'Seattle-1201'
        cityDir = fullfile(GSADir,'Seattle_Washington\Daysimeter_People_Data\FCS_Building_1201');
        thisSeason = seasonSelect;
        parentDir = fullfile(cityDir,lower(thisSeason));
        sessionTitle = ['GSA - Seattle, WA FCS Building 1201 - ',thisSeason];
        building = 'FCS Building 1201';
    case 'Seattle-1202'
        cityDir = fullfile(GSADir,'Seattle_Washington\Daysimeter_People_Data\FCS_Building_1202');
        thisSeason = seasonSelect;
        parentDir = fullfile(cityDir,lower(thisSeason));
        sessionTitle = ['GSA - Seattle, WA FCS Building 1202 - ',thisSeason];
        building = 'FCS Building 1202';
    otherwise
        error('Unknown city');
end

end

function thisSeason = seasonSelect
season = {'Winter','Summer'};
choice = menu('Choose a season',season);
thisSeason = season{choice};


end
