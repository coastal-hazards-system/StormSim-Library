function [storm, proxy_data]= chs_timeseries_peak_replacer(storm)
% Get Fields Stored In "storm"
stypes = fieldnames(storm);
% For Each Storm Type
for ii = 1:length(stypes)
    % Grab Peaks Dataset
    dPeaks = storm.(stypes{ii}).('Peaks').('Default'); % [SWL Hm0 Tp wDir stmID timeStamp]
    proxy_data.(stypes{ii}) = zeros(length(dPeaks), 6);
    proxy_data.(stypes{ii})(:,5:6) = cell2mat(cellfun(@(x) x(5:6), dPeaks(:, 2), 'un', false));
    % For Each Storm ID
    for kk = 1:length(dPeaks(:,1))
        for jj = 1:4 % For Each Column SWL, Hm0, Tp, wDir
            % Find Storm ID Entry Row
            rowID = cell2mat(storm.(stypes{ii}).('Timeseries').('Default')(:,1)) == storm.(stypes{ii}).('Peaks').('Default'){kk,1};
            % SKip Storm If Not Found
            if ~any(rowID)
                continue; % Skip
            else
                % Find Max On Hydrograph
                [~, tsIndx] = max(storm.(stypes{ii}).('Timeseries').('Default'){rowID, 2}(:, jj));
                % Replace Timestep With Value In Peaks File
                storm.(stypes{ii}).('Timeseries').('Default'){rowID, 2}(tsIndx, jj) = dPeaks{kk, 2}(1, jj);
                % Proxy Data is For Debbuging Purposes
                proxy_data.(stypes{ii})(kk, jj) = storm.(stypes{ii}).('Timeseries').('Default'){rowID, 2}(tsIndx, jj);
            end
        end
    end
end
end