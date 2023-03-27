function storm = chs_timeseries_peak_replacer(storm)
% Get Fields Stored In "storm"
stypes = fieldnames(storm);
% For Each Storm Type
for ii = 1:length(stypes)
    % Grab Peaks Dataset
    dPeaks = storm.(stypes{ii}).('Peaks').('Maxima'); % [SWL Hm0 Tp wDir stmID timeStamp]
    % For Each Storm ID
    for kk = 1:length(dPeaks(:,1))
        % Find Storm ID Entry Row
        rowID = cell2mat(storm.(stypes{ii}).('Timeseries')(:,1)) == dPeaks(kk,5);
        % Extract Storm ID Hydrograph
        tsData = storm.(stypes{ii}).('Timeseries'){rowID, 2};
        % Verify That ADCIRC Peak Values Resides Inside Timeseries
        chk1 = dPeaks(kk,6) >= tsData(1,1) & dPeaks(kk,6) <= tsData(end,1);
        % If Peak Is Inside Timeseries Then Replace
        if chk1
            % Find Nearest Data Point To Peaks Timestamp
            [tsVal, tsIndx] = min(abs(tsData(:,1)-dPeaks(kk,6)));
            % Replace Timeseries Timestep If Within 1 hr
            if tsVal <= datenum(0,0,0,1,0,0)
                % Replace Timestep With Value In Peaks File
                tsData(tsIndx,2) = dPeaks(kk, 1);
                % Assign Back Adjusted Dataset
                storm.(stypes{ii}).('Timeseries')(rowID,2) = {tsData};
            end
        end
    end
end
end