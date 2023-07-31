function [aep_out] = combine_hazard_curves(tc_prob, xc_prob, xc_resp_vector, aep_list)
% Initialize Out Var
aep_out = NaN(length(aep_list), size(xc_prob, 2));
% Loop Through Each CL
for ii = 1:size(xc_prob, 2) % Each CL
    % Define Probability Vectors
    FREQ_mean_1 = xc_prob(:,ii);
    FREQ_mean_2 = tc_prob(:,ii);
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
    x1(rIndx) = [];
    y1(rIndx) = [];
    % Compute Log
    x1 = log(x1);
    % Do Unique, Keep Order
    [C, ia, ~] = unique(x1,'stable');
    x1 = C;y1 = y1(ia,1);

    %% Interpolate to compute ARI for each y-value
    try
        % Interpolate Response For Specified ARI's
        dummy = interp1(x1,y1,log(aep_list),'linear','extrap');
        % Set Negative Interp Values To NaN
        dummy(dummy<0) = NaN;
        % Store Results
        aep_out(:,ii) = dummy;
    catch
        %            dummy = [];
        %                    aep_out(:,ii) = dummy;
    end
end
end