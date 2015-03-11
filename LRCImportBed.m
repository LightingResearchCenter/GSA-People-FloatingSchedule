function [bedTimeArray, riseTimeArray] = LRCImportBed(file)
% imports the bed log given by file.
[~, ~, ext] = fileparts(file);
switch ext
    case '.m'
        load(file);
    case {'.xls','.xlsx'}
        % Import bed log as a table
        [~,~,bedLogCell] = xlsread(file);
        
        % Initialize the arrays
        nIntervals = size(bedLogCell,1)-1;
        bedTimeArray = zeros(nIntervals,1);
        riseTimeArray = zeros(nIntervals,1);
        
        % Load the data from the cell
        for i1 = 1:nIntervals
            bedTimeArray(i1) = datenum(bedLogCell{i1 + 1,2});
            riseTimeArray(i1) = datenum(bedLogCell{i1 + 1,3});
        end
    case '.txt'
        fileID = fopen(file);
        [bedCell] = textscan(fileID,'%f%s%s%s%s','headerlines',1);
        bedd = bedCell{2};
        bedt = bedCell{3};
        rised = bedCell{4};
        riset = bedCell{5};
        bedTimeArray = zeros(size(bedd));
        riseTimeArray = zeros(size(bedd));
        % this can probably be vectorized
        for i1 = 1:length(bedd)
            bedTimeArray(i1) = datenum([bedd{i1} ' ' bedt{i1}]);
            riseTimeArray(i1) = datenum([rised{i1} ' ' riset{i1}]);
        end
        fclose(fileID);
    otherwise
        return
end

end