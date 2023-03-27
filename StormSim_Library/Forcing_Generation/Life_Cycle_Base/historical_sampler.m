function [Y, Y_WLP, Y_WHP] = historical_sampler(storm_peaks, storm_wlp_peaks, storm_whp_peaks, storm_indexes)
%% DEFINE INPUTS
WLP_switch = ~isempty(storm_wlp_peaks);
WHP_switch = ~isempty(storm_whp_peaks);
Y = zeros(length(storm_indexes),5);
if WLP_switch
    Y_WLP = zeros(length(storm_indexes),5);
else
    Y_WLP = [];
end
if WHP_switch
    Y_WHP = zeros(length(storm_indexes),5);
else
    Y_WHP = [];
end
%% PICK HISTORICAL STORMS
for kk = 1:length(storm_indexes)
    Y(kk,:) = storm_peaks(storm_peaks(:,end) == storm_indexes(kk),1:end);
    if WLP_switch
        Y_WLP(kk,:) = storm_wlp_peaks(storm_wlp_peaks(:,end) == storm_indexes(kk),1:end);
    end
    if WHP_switch
        Y_WHP(kk,:) = storm_whp_peaks(storm_whp_peaks(:,end) == storm_indexes(kk),1:end);
    end
end
end