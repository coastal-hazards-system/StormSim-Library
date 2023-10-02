function [aep_out] = combine_hazard_curves(tc_prob, xc_prob, xc_resp_vector, aep_list, log_scale)
% Initialize Out Var
aep_out = NaN(length(aep_list), size(xc_prob, 2));
% Loop Through Each CL

% JAM mod 8/23/23 as per NNC
% combine for mean curves but only use tropical curves for CL
% first column is BE, second is lower CL, third is upper
% Define BE Probability Vectors
FREQ_mean_1 = xc_prob(:,1);
FREQ_mean_2 = tc_prob(:,1);
% Make Zero Entries NaN's
FREQ_mean_1(FREQ_mean_1 == 0) = NaN;
FREQ_mean_2(FREQ_mean_2 == 0) = NaN;
FREQ_mean_1(isnan(FREQ_mean_1)) = 0;
FREQ_mean_2(isnan(FREQ_mean_2)) = 0;
% Add Probabilities
% screen for cases when there are few or no values.  This happens with,
% for example, the crest elevation is high enough to prevent OT.
% Often, XC storms will produce no OT.
FREQ_mean_3 = (FREQ_mean_1 + FREQ_mean_2);
FREQ_mean_3(FREQ_mean_3==0) = NaN;

%% Process data for interpolation (remove NaN, inf, and repeats)
x1 = FREQ_mean_3;
y1 = xc_resp_vector;

% Remove NaN & Inf Values
rIndx = isnan(x1) | isinf(x1);
x1(rIndx) = []; y1(rIndx) = [];
% Compute Log
x1 = log(x1);
% Do Unique, Keep Order
[C, ia, ~] = unique(x1,'stable');
x1 = C;y1 = y1(ia,1);

try
    % Interpolate Response For Specified ARI's
    dummy = interp1(x1,y1,log(aep_list),'linear','extrap');
    % Set Negative Interp Values To NaN
    dummy(dummy<=0) = NaN;
    % Store Results
    aep_out(:,1) = dummy;
catch
    % dummy = [];
    %  aep_out(:,ii) = dummy;
end

% At this point we have a final combined BE HC

%% Interpolate to compute ARI for each y-value for tropical storms
for ii=1:size(tc_prob,2)
    x1 = tc_prob(:,ii); % CLs use tropical only
    y1 = xc_resp_vector;

    % Remove NaN & Inf Values
    rIndx = isnan(x1) | isinf(x1);
    x1(rIndx) = []; y1(rIndx) = [];
    % Compute Log
    x1 = log(x1);
    rIndx = isnan(x1) | isinf(x1);
    x1(rIndx) = []; y1(rIndx) = [];
    % Do Unique, Keep Order
    [C, ia, ~] = unique(x1,'stable');
    x1 = C;y1 = y1(ia,1);
    try
        % Interpolate Response For Specified ARI's
        dummy = interp1(x1,y1,log(aep_list),'linear','extrap');
        % Set Negative Interp Values To NaN
        dummy(dummy<=0) = NaN;
        % Store Results
        TC_aep(:,ii) = dummy;
    catch
    end
end
for ii=2:size(TC_aep,2)
    %    CL_BE_TC_ratio = TC_aep(:,1)./TC_aep(:,ii); % TC BE/CL
    CL_BE_TC_diff = TC_aep(:,1) - TC_aep(:,ii); % TC BE - CL
    %     aep_out(:,ii) = aep_out(:,1) ./ CL_BE_TC_ratio; % CC BE/(TC BE/CL)
    aep_out(:,ii) = aep_out(:,1) - CL_BE_TC_diff; % CC BE/(TC BE + CL)
    if size(aep_out,1)>100
        nan_index = find(isnan(aep_out(:,ii)),1,'first');
        aep_out(nan_index-1,ii)=nan;
        aep_out(nan_index-2,ii)=nan;
    end
end
end