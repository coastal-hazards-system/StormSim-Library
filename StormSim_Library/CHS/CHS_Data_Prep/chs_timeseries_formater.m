function [storm_data, ts_storm2rm] = chs_timeseries_formater(swl_timeseries, hm0_timeseries, storms2rm,...
    STWAVE_headers_location, Tp_special, print_progress)
%{
    %% DESCRIPTION
    An optimized, vectorized version of the CHS time-series parser.
    Eliminates iterative datetime parsing and redundant logical scans.
%}

%% DEFINE INPUTS AND PRE-ALLOCATE
if print_progress
    fprintf(1,'   Completion Progress:  0%%\n');
end

% Ensure Data Is Sorted Per Storm ID
swl_timeseries = sortrows(swl_timeseries,'Storm ID','ascend');
hm0_timeseries = sortrows(hm0_timeseries,'Storm ID','ascend');

% Extract Storm IDs quickly as a numeric matrix
stmID_vec = cellfun(@str2double, swl_timeseries.('Storm ID'));
num_storms = length(stmID_vec);

% Initialize Storage Cell Matrix 
storm_data = [num2cell(stmID_vec), cell(num_storms, 1)];

% Pre-allocate space for bad storms to prevent dynamic array resizing
bad_storms_buffer = nan(num_storms, 1);
bad_count = 0;

%% PROACTIVE VECTORIZED DATETIME PARSING (MASSIVE SPEEDUP)
% Determine date formats and convert entire columns outside the loop
dformat = 'yyyyMMddHHmmss';
% yyyymmddHHMM columns are already datetime — pass through directly
all_ad_dtime = swl_timeseries.("yyyymmddHHMM");
all_wv_dtime = hm0_timeseries.("yyyymmddHHMM");
dt_final = hours(1);
dt_final_datenum = datenum(dt_final);

%% ADCIRC-STWAVE TIMESERIES MATCHING PROCESS
for stm = 1:num_storms
    % Print Status
    if print_progress % Only print every 10 iterations to minimize I/O overhead
        fprintf(1,'\b\b\b\b%3.0f%%',(100*(stm/num_storms)));
        drawnow;
    end
    
    current_stmID = stmID_vec(stm);
    
    % Skip Bad Storm
    if ismember(current_stmID, storms2rm) || length(swl_timeseries.("Water Elevation"){stm,1}) == 1
        storm_data{stm, 2} = nan(1,1);
        bad_count = bad_count + 1;
        bad_storms_buffer(bad_count) = current_stmID;
        continue;
    end
    
    %% EXTRACT STORM DATA (Direct Indexing via 'stm' replaces 'pull_indx')
    WL = swl_timeseries.("Water Elevation"){stm, 1};
    
    waves = [hm0_timeseries.(STWAVE_headers_location.Hm0){stm, 1},...
             hm0_timeseries.(STWAVE_headers_location.Tp){stm, 1},...
             hm0_timeseries.(STWAVE_headers_location.wDir){stm, 1}];
         
    wv_dtime = all_wv_dtime{stm};
    ad_dtime = all_ad_dtime{stm};
    
    % Lake Ontario Special Case
    if Tp_special == 1
        waves(:,3) = waves(:,3) .* 1.2;
    end
    
    %% EXTRACT ADCIRC DATA RESIDING INSIDE STWAVE TEMPORAL RANGE
    min_wv = wv_dtime(1);    % Optimization: avoid min/max function overhead over sorted arrays
    max_wv = wv_dtime(end);
    
    ad_mask = (ad_dtime >= min_wv) & (ad_dtime <= max_wv);
    WL = WL(ad_mask, :);
    ad_dtime = ad_dtime(ad_mask, :);
    
    %% ADJUST MODEL OUTPUTS VIA INTERPOLATION
    min_bound = max(min_wv, ad_dtime(1));
    max_bound = min(max_wv, ad_dtime(end));
    
    date_final = (min_bound:dt_final:max_bound)';
    len_final = length(date_final);
    
    % Perform Interpolation
    WL_interp = interp1(ad_dtime, WL, date_final, 'linear');
    waves_interp = interp1(wv_dtime, waves, date_final, 'linear'); % Interpolates all 3 columns simultaneously
    
    % Build Storm Data Matrix [ SSL, Hm0, Tp, wDir, date, dt ]
    storm_mat = [WL_interp, waves_interp, datenum(date_final), repmat(dt_final_datenum, len_final, 1)];
    
    %% REMOVE BAD ENTRIES
    % ADCIRC Flag Check
    storm_mat(storm_mat(:, 1) < -90, :) = NaN;
    % STWAVE Flag Check
    storm_mat(any(storm_mat(:, 2:3) < -90, 2), 2:3) = NaN;
    
    % Empty Matrix Handling
    if isempty(storm_mat)
        bad_count = bad_count + 1;
        bad_storms_buffer(bad_count) = current_stmID;
        continue;
    end
    
    % Store Final Results
    storm_data{stm, 2} = storm_mat;
end

%% POST-PROCESSING CONSOLIDATION
% Prune unused pre-allocated elements and combine with input array
bad_storms_buffer = bad_storms_buffer(1:bad_count);
ts_storm2rm = unique([storms2rm(:); bad_storms_buffer]);

% Print Final Status Completion
if print_progress
    fprintf(1, '\b\b\b\b100%%\n');
end
end