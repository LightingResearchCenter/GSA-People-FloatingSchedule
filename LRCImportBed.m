function [bedTimeArray, riseTimeArray] = LRCImportBed(file)
% imports the bed log given by file.
[~, ~, ext] = fileparts(file);
switch ext
    case '.m'
        load(file);
    case {'.xls','.xlsx'}
        % Import bed log as a table
        [~,~,bedLogCell] = xlsread(file,'A1:C101');
        
        % Find rows with NaN and delete them
        nanIdxCell = cellfun(@isnan,bedLogCell,'UniformOutput',false);
        nanIdxMat = cellfun(@any,nanIdxCell);
        nanIdxVec = any(nanIdxMat,2);
        bedLogCell = bedLogCell(~nanIdxVec,:);
        
        % Initialize the arrays
        nIntervals = size(bedLogCell,1)-1;
        bedTimeArray = zeros(nIntervals,1);
        riseTimeArray = zeros(nIntervals,1);
        
        % Load the data from the cell
        for i1 = 1:nIntervals
            try
                bedTimeArray(i1) = datenum(bedLogCell{i1 + 1,2});
                riseTimeArray(i1) = datenum(bedLogCell{i1 + 1,3});
            catch err
                % Skip lines that cannot be converted
            end
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
            try
                bedTimeArray(i1) = datenum([bedd{i1} ' ' bedt{i1}]);
                riseTimeArray(i1) = datenum([rised{i1} ' ' riset{i1}]);
            catch err
                % Skip lines that cannot be converted
            end
        end
        fclose(fileID);
    otherwise
        return
end

% Delete skipped entries
skippedIdx = bedTimeArray == 0;
bedTimeArray(skippedIdx) = [];
riseTimeArray(skippedIdx) = [];

end