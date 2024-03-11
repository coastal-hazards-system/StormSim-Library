function storm = chs_timeseries_peak_replacer(storm)
% Get Fields Stored In "storm"
stypes = fieldnames(storm);
% For Each Storm Type
for ii = 1:length(stypes)
    for jj = 2:4
        % Grab Peaks Dataset
        dPeaks = storm.(stypes{ii}).('Peaks').('Maxima'); % [SWL Hm0 Tp wDir stmID timeStamp]
        % For Each Storm ID
        for kk = 1:length(dPeaks(:,1))
            % Find Storm ID Entry Row
            rowID = cell2mat(storm.(stypes{ii}).('Timeseries')(:,1)) == dPeaks(kk,5);
            % SKip Storm If Not Found
            if sum(rowID) == 0
                continue; % Skip
            else
                % Extract Storm ID Hydrograph
                tsData = storm.(stypes{ii}).('Timeseries'){rowID, 2};
                % Find Nearest Data Point To Peaks Timestamp
                [~, tsIndx] = max(tsData(:,jj));
                % Replace Timeseries Timestep If Within 1 hr
                % Replace Timestep With Value In Peaks File
                tsData(tsIndx,jj) = dPeaks(kk, jj-1);
                % Assign Back Adjusted Dataset
                storm.(stypes{ii}).('Timeseries')(rowID,2) = {tsData};
            end
        end
    end
end
end