function prob_mass_validation(config, prob_mass, storm)
% --------- prob_mass fields ------------
% 1. TC_SRR -> 1 x 4 double -> [low, mid, high, total]
%       Tropical Cyclone Recurrence Rates [storm/yr] per Intensity Bin
%       Intensities (center pressure deficit, dP) [hPa | mbar] -> dP<28 (low),
%       28 <= dP < 48 (mid), dP >= 48 (high)
% 2. TC_Freq -> number_of_tc_storms x 1 double -> [storm/yr]
%       Tropical Cyclone Discrete Storm Weights (DSW's) or Probability mass
% 3. TotalFreq -> 1 x 1 double -> sum(TC_Freq)
%       Total TC storm suite frequency
% 4. smpl1, smpl2, smpl3 -> N x 1 doubles
%       Each field contians storm IDs associated to each intensity bin.
%       Storm IDs must coincide with those listed on "storm" variable.
% ----------------------------------------
    % Define Intensity Bins
    intensity_bins = {'smpl1','smpl2','smpl3'}; % low, mid, high
% Scan Provided PM File Fields
pm_fields = fieldnames(prob_mass);
% Verify How Many Fields Are Found
if sum(contains(pm_fields, {'TC_SRR', 'TC_Freq', 'TotalFreq', 'smpl1', 'smpl2', 'smpl3'})) ~= 6
    error('Error: Provided "prob_mass" variable does not comply with the expected fields. Aborting...');
end
% Determine Number Of TC Storms In Storm Suite
% if config.use_peaks == 1
%     number_of_storms = length(storm.TC.Peaks.Default(:,1));
% else
%     number_of_storms = length(storm.TC.Timeseries.Default(:,1));
% end
% Ensure Each TC Storm Has An Associated Likelihood of Occurrence
% if number_of_storms~=length(prob_mass.('TC_Freq'))
%     error('Error: Provided "prob_mass.TC_Freq" field must match the number of TC storms on storm suite. Aborting...');
% else
if prob_mass.TotalFreq~=sum(prob_mass.TC_Freq) % Make Sure Total Frequency Matches
    % Throw Warning
    disp('Warning: Field "prob_mass.TotalFreq" field does not match sum(prob_mass.TC_Freq)...');
end
% Verify Storm Recurrence Rates
if size(prob_mass.TC_SRR, 1) ~= 1 && size(prob_mass.TC_SRR, 2) ~= 4
    error('Error: Field "prob_mass.TC_SRR" does not match expected dimensions 1 x 4 double. Each column represents yearly recurrance rate for each intensity bin [ low, mid, high, total ]...');
elseif sum(prob_mass.TC_SRR(1,1:end-1)) ~= prob_mass.TC_SRR(1, end)
    disp('Warning: Provided total SRR does not match sum(SRR_low, SRR_mid, SRR_high)....');
end
% Make Sure At Least 1 smpl Field Is Populated
if isempty(prob_mass.smpl1) && isempty(prob_mass.smpl2) && isempty(prob_mass.smpl3)
    error('Error: No storm IDs found assigned to intensity bins (smpl1, smpl2, smpl3)....');
elseif any(cell2mat(cellfun(@(x) strcmp(x, fieldnames(prob_mass)), intensity_bins, 'un', false)), 'all')
    % Check What Intensity Bins Exist
    found_bins = any(cell2mat(cellfun(@(x) strcmp(x, fieldnames(prob_mass)), intensity_bins, 'un', false)),1);
    % Populate Missing Intensity Bins With Empty Fields
    for ll = intensity_bins(~found_bins)
        prob_mass.({ll}) = [];
    end
end
end
