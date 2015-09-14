function workDay = makeWorkLog2(absTime)
%MAKEWORKLOG2 Summary of this function goes here
%   Detailed explanation goes here

days_datenum = floor(absTime.localDateNum);
days_datevec = absTime.localDateVec;
days_datevec(:,4:6) = 0;

[uniqueDays_datenum,ia,~] = unique(days_datenum);
uniqueDays_datevec = days_datevec(ia,:);
uniqueDays_datetime = datetime(uniqueDays_datevec);

TF = isweekend(uniqueDays_datetime);
workDay = uniqueDays_datenum(~TF);

end

