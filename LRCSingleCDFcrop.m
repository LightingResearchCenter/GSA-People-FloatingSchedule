function cropData = LRCSingleCDFcrop(origData,bedLog,hFig)
% CROPCDF finds and crops a projects data individually for each CDF file
% This will locate a directory that contains any number of CDF files and
% will load them one at a time, in file order and give the user three
% options, a start and end date option, non-compliance, and bed will
% apear in that order.
% 
% bed dates can be stored in either .m, .xls, .xlsx, or .txt files.
% for .m files the dates must be saved as bedTimes, riseTimes.
% for .xls and .xlsx the format muse be |day|bedTimes|riseTimes|
% for .txt files the same format must be kept as above but they must be
% seperated by tabs.
% 
% For the first two types of cropping you will be asked to select a start
% and end date. To do this you will be given the option to first zoom in to
% the area of the of the graph you want. Then you need to hit any key on
% the keay board and you will be given the option to select the date and 
% you want. 
%
% After each data set is finished being cropped, it will call RewriteCDF
% and will save the files to the directory the user selects

hFig.Units = 'normalized';
    
%% Load the data
[absTime,~,~,light,activityArray,~,subjectID,deviceSN] = daysimeter12.convertcdf(origData);
timeArray = absTime.localDateNum;
csArray = light.cs;

%% Provide GUI for cropping of the data
logicalArray = true(size(timeArray));
complianceArray = true(size(timeArray));
bedArray = false(size(timeArray));

%% bed Cropping
display = true(size(timeArray));
plotcrop(hFig,timeArray,csArray,activityArray,display)
plotcroptitle(subjectID,'');

temp = false(size(timeArray));

[bedTimes, riseTimes] = importbedlog(bedLog);
for i2 = 1:length(bedTimes)
    temp2 = timeArray>bedTimes(i2) & timeArray<riseTimes(i2);
    temp = temp | temp2;
end

plotcrop(hFig,timeArray,csArray,activityArray,~temp)
plotcroptitle(subjectID,'');

bedArray = temp;
    
%% Start and Stop end points cropping
needsCropping = true;
while needsCropping
    logicalArray = true(size(timeArray));
    display = ~bedArray & logicalArray;
    plotcrop(hFig,timeArray,csArray,activityArray,display)
    plotcroptitle(subjectID,'Select Start of Data');
    zoom(hFig,'on');
    pause
    [cropStart,~] = ginput(1);
    zoom(hFig,'out');
    zoom(hFig,'on');
    plotcroptitle(subjectID,'Select End of Data');
    pause
    [cropStop,~] = ginput(1);
    logicalArray = (timeArray >= cropStart) & (timeArray <= cropStop);
    display = ~bedArray & logicalArray;
    plotcrop(hFig,timeArray,csArray,activityArray,display)
    plotcroptitle(subjectID,'');
    needsCropping = ~cropdialog('Is this data cropped correctly?','Crop Data');
end
%% Compliance Cropping
needsCropping = cropdialog('Is there non-compliance in the data?','Compliance');
while needsCropping
    display = ~bedArray & logicalArray & complianceArray;
    plotcrop(hFig,timeArray,csArray,activityArray,display)
    plotcroptitle(subjectID,'Select Start of Data');
    zoom(hFig,'on');
    pause
    [cropStart,~] = ginput(1);
    zoom(hFig,'out');
    zoom(hFig,'on');
    plotcroptitle(subjectID,'Select End of Data');
    pause
    [cropStop,~] = ginput(1);
    temp  = not((timeArray >= cropStart) & (timeArray <= cropStop));
    display = ~bedArray & logicalArray & complianceArray & temp;
    plotcrop(hFig,timeArray,csArray,activityArray,display)
    plotcroptitle(subjectID,'');
    needsCropping = ~cropdialog('Is this data cropped correctly?','Crop Data');
    if needsCropping == false
        needsCropping = cropdialog('Is there more non-compliance in the data?','Compliance');
        complianceArray = complianceArray & temp;
    end
end

clf(hFig);

%% Assign the modified variables
cropData = origData;

cropData.Variables.logicalArray = logicalArray;
cropData.Variables.complianceArray = complianceArray;
cropData.Variables.bedArray = bedArray;

%% Compliance array properties
cropData.VariableAttributes.complianceArray.description = 'compliance array, true = subject appears to be using the device';
cropData.VariableAttributes.complianceArray.unitPrefix = '';
cropData.VariableAttributes.complianceArray.baseUnit = '1';
cropData.VariableAttributes.complianceArray.unitType = 'logical';
cropData.VariableAttributes.complianceArray.otherAttributes = '';

%% Bed array properties
cropData.VariableAttributes.bedArray.description = 'bed array, true = subject reported being in bed';
cropData.VariableAttributes.bedArray.unitPrefix = '';
cropData.VariableAttributes.bedArray.baseUnit = '1';
cropData.VariableAttributes.bedArray.unitType = 'logical';
cropData.VariableAttributes.bedArray.otherAttributes = '';

end

function needsCropping = cropdialog(string, title)
% gives the user a choice if the data is cropped correctly, or not.
button = questdlg(string, title,'Yes','No','Yes');
switch button
    case 'Yes'
        needsCropping = true;
    case 'No'
        needsCropping = false;
    otherwise
        needsCropping = false;
end
end

function plotcrop(hCrop,timeArray,csArray,activityArray,logicalArray2)
% adds the plot to the figure, while taking out the values corrosponding to
% logicalArray2 
figure(hCrop)
clf(hCrop)

hArea = area(timeArray,~logicalArray2);
set(hArea,'FaceColor',[.6,.6,.6],'EdgeColor','none');
hold on
plot(timeArray,[csArray, activityArray])
datetick2('x');
hold off
legend('Crop','Circadian Stimulus','Activity');
end

function plotcroptitle(subjectName,subTitle)
% adds a title to the active matlab figure
hTitle = title({subjectName;subTitle});
set(hTitle,'FontSize',16);

end

