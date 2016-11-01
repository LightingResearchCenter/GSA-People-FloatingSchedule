close all
clear
clc


s = load('dataStore.mat');
data = s.data;
output = data(:,1:3);

nSub = numel(data.subjectId);

for iSub = 1:nSub
    thisTime = data.time{iSub};
    thisCs = data.cs{iSub};
    thisWork = data.work{iSub};
    
    t = thisTime(thisWork);
    h = hour(t);
    cs = thisCs(thisWork);
    
    for iHour = 0:23
        h1 = sprintf('%02i',iHour);
        h2 = sprintf('%02i',iHour+1);
        thisLabel = ['from',h1,'00_to_',h2,'00'];
        idx = h == iHour;
        thisHoursCs = cs(idx);
%         if numel(thisHoursCs) < 59
%             thisHoursCs = NaN;
%         end
        output.(thisLabel)(iSub) = mean(thisHoursCs);
    end
end

timestamp = datestr(now,'yyyy-mm-dd_HHMM');
filename = ['GSA-hourlyCS_',timestamp,'.xlsx'];
writetable(output,filename);
winopen(filename);