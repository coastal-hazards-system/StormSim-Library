function [storm_data, ts_storm2rm] = create_priority_dataset(peaks_table, timeseries_table_surge, timeseries_table_wave, storms2rm, wave_headers, storm_duration, Tp_special, priority_type, print_progress)
%% DEFINE INPUTS
ts_storm2rm = storms2rm;
% Define Time Window Around Peak To Pull Response From Timeseries
tdelta = datenum(0, 0, 0, 3, 0, 0); %  +/- 3 hours
% Get Storm Data Table
peaks_table = sortrows(peaks_table,'Storm ID','ascend');
% Sort Data Table
timeseries_table_surge = sortrows(timeseries_table_surge,'Storm ID','ascend');
timeseries_table_wave = sortrows(timeseries_table_wave,'Storm ID','ascend');
% Grab Storm IDs
stmID = num2cell(str2double(peaks_table.("Storm ID")));
% Initialize Storage Matrix
storm_data = [stmID ,cell(length(stmID(:,1)),1)];

%% PROMT USER
% Display Progress Step
switch priority_type
    case 'wlp'
        disp_toggle(print_progress,'Building water level priority (WLP) dataset....');
        timeseries_table = timeseries_table_wave;
        chk_field = wave_headers.Hm0;
    case 'whp'
        disp_toggle(print_progress,'Building wave height priority (WHP) dataset....');
        timeseries_table = timeseries_table_surge;
        chk_field = "Water Elevation";
end
% Display Completion Progress Initial Print
if print_progress
    fprintf(1,'   Completion Progress: %3d%%\n',0);
end
%%
% Find Table Row To Extract
for stm = 1:length(stmID)
    % Print Status
    if print_progress
        fprintf(1,'\b\b\b\b%3.0f%%',(100*(stm/length(stmID))));
    end
    % Skip Bad Storm
    if ismember(stmID{stm}, storms2rm) || length(timeseries_table.(chk_field){stm,1}) == 1
        % Assign NaN
        storm_data(stm, 2) = {nan(1,1)};
        % Store Bad Storm ID
        ts_storm2rm = [ts_storm2rm;stmID{stm}];
        % Move To Next Storm
        continue;
    end
    % Get Storm Timeseries Timestamp
    ts_date =  datenum(timeseries_table.('yyyymmddHHMM'){stm,1});
    % Get Priority Response Peak Timestamp
    peak_date = datenum(peaks_table.('yyyymmddHHMM')(stm,1));
    % Find Timeseries Data Points Withing The +/- Time Window (tdelta)
    wIndx = find(abs(ts_date-peak_date)<=tdelta);
    % Remove Storm For Failed Peak Match
    if isempty(wIndx)
        % Water Level Priority Failsafe
        if strcmp(priority_type, 'wlp') % Find Surge Timeseries Within Wave Timeseries
            % Get Wave Timestamp
            ts_date_surge = datenum(timeseries_table_surge.('yyyymmddHHMM'){stm,1});
            % Find Surge Timseries Rows Within Wave Timeseries
            wl_indx = ts_date_surge >= min(ts_date) & ts_date_surge <= max(ts_date);
            % Execute Data Assignment
            if ~any(wl_indx) % Bad Storm
                % Assign NaN
                storm_data(stm, 2) = {nan(1,1)};
                % Store Bad Storm ID
                ts_storm2rm = [ts_storm2rm;stmID{stm}];
                % Move To Next Storm
                continue;
            else % Find Corresponding Peak Wave Response
                % Find New Peak Surge
                [~, peak_indx] = max(timeseries_table_surge.('Water Elevation'){stm,1}(wl_indx, 1));
                % Grab Surge Timeseries Timestamp Within Wave Temporal Range
                ts_date_surge = ts_date_surge(wl_indx);
                % Find Peak Response Date
                peak_date = ts_date_surge(peak_indx);
                % Find Timeseries Data Points Withing The +/- Time Window (tdelta)
                wIndx = find(abs(ts_date-peak_date)<=tdelta);
            end
        else
            % Assign NaN
            storm_data(stm, 2) = {nan(1,1)};
            % Store Bad Storm ID
            ts_storm2rm = [ts_storm2rm;stmID{stm}];
            % Move To Next Storm
            continue;
        end
    end
    % Determine The CLoses Timestamp
    [~, wIndx2] = min(abs(ts_date(wIndx)-peak_date));
    % Redefine Index To Final Selection
    wIndx = wIndx(wIndx2);
    % Assign Storm Data
    switch priority_type
        case 'wlp'
            storm_data{stm, 2} = [peaks_table.('Water Elevation')(stm,1),...
                timeseries_table.(wave_headers.Hm0){stm,1}(wIndx),...
                timeseries_table.(wave_headers.Tp){stm,1}(wIndx),...
                timeseries_table.(wave_headers.wDir){stm,1}(wIndx),...
                peak_date, storm_duration];
        case 'whp'
            storm_data{stm, 2} = [timeseries_table.('Water Elevation'){stm,1}(wIndx),...
                peaks_table.(wave_headers.Hm0)(stm,1),...
                peaks_table.(wave_headers.Tp)(stm,1),...
                peaks_table.(wave_headers.wDir)(stm,1),...
                peak_date, storm_duration];
    end
    % Check For Special Tp Case
    if Tp_special == 1
        storm_data{stm, 2}(:, 3) = storm_data{stm, 2}(:, 3).*1.2;
    end
end
% Do Unique
ts_storm2rm = unique(ts_storm2rm);
% Print Status
if print_progress
    fprintf(1,['\b\b\b\b%3.0f%%' newline],(100*(stm/length(stmID))));
end
end
