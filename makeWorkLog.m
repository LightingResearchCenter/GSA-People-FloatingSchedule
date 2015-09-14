function [interval, location, startTime, endTime] = makeWorkLog(absTime,location)
%MAKEWORKLOG Summary of this function goes here
%   Detailed explanation goes here

days_datenum = floor(absTime.localDateNum);
days_datevec = absTime.localDateVec;
days_datevec(:,4:6) = 0;

[~,ia,~] = unique(days_datenum);
uniqueDays_datevec = days_datevec(ia,:);
uniqueDays_datetime = datetime(uniqueDays_datevec);

TF = isweekend(uniqueDays_datetime);
weekDays_datevec = uniqueDays_datevec(~TF,:);

startTime_datevec = weekDays_datevec;
endTime_datevec = weekDays_datevec;

startTime_datevec(:,4) = 8; % 8 AM
endTime_datevec(:,4) = 17;  % 5 PM

startTime = datenum(startTime_datevec);
endTime = datenum(endTime_datevec);

interval = (1:numel(startTime))';
location = repmat({location},size(startTime));

end

