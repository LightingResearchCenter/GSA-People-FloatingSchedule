function [parentDir,sessionTitle,building] = GSADirSelect
%GSADIRSELECT Summary of this function goes here
%   Detailed explanation goes here

GSADir = '\\ROOT\projects\GSA_Daysimeter';

city = {'DC','Seattle'};
choice = menu('Choose a city',city);
thisCity = city{choice};

switch thisCity
    case 'DC'
        cityDir = fullfile(GSADir,'WashingtonDC\Daysimeter_People_Data');
        thisSeason = seasonSelect;
        switch thisSeason
            case 'Winter'
                parentDir = fullfile(cityDir,'winter');
                sessionTitle = 'GSA - Washington, D.C. - Winter';
                building = '';
            case 'Summer'
                parentDir = fullfile(cityDir,'summer');
                sessionTitle = 'GSA - Washington, D.C. - Summer';
                building = '';
            otherwise
                error('Unknown season');
        end
    case 'Seattle'
        cityDir = fullfile(GSADir,'Seattle_Washington\Daysimeter_People_Data\FCS_Building_1202');
        thisSeason = seasonSelect;
        switch thisSeason
            case 'Winter'
                parentDir = fullfile(cityDir,'winter');
                sessionTitle = 'GSA - Seattle, WA FCS Building 1202 - Winter';
                building = 'FCS Building 1202';
            case 'Summer'
                parentDir = fullfile(cityDir,'summer');
                sessionTitle = 'GSA - Seattle, WA FCS Building 1202 - Summer';
                building = 'FCS Building 1202';
            otherwise
                error('Unknown season');
        end
    otherwise
        error('Unknown city');
end

end

function thisSeason = seasonSelect
season = {'Winter','Summer'};
choice = menu('Choose a season',season);
thisSeason = season{choice};


end
