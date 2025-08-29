function [config, storm, removed_storms, XC_Nyrs, XC_Nstm, prob_mass] = call_chs_storm_quality_check(config, CHS_Data, prob_mass, storm_type)

%{
    %% DESCRIPTION
        This function is responsible for grabbing and applying QA/QC
        process to the provbided CHS files. QA/QC revolves around:
        searching for NaN's/flagged values and making sure storm wave model
        output is contained within ADCIRC simulation outputs.
        
    %% INPUTS
        CHS_Data: Converted CHS data. | struc | 1 x size_varies
        ProbMass: Associated savepoint TC storm porbability | struc | 1 x 5
                  masses.
        storm_type: storm type being processed. ('TC' or 'XC') | char | 1 x 2
        use_timeseries: Switch for using CHS timeseries for
                        QA/QC process. Also, enables the use
                        of WLP & WHP switches.
        WLP_switch: Switch for creating Water Level Priority   | double | 1 x 1
                    dataset.
        WHP_switch: Switch for creating Wave Height Priority   | double | 1 x 1
                    dataset.
        
    %% OUTPUTS
        storm
        removed_storms
        XC_Nyrs
      
    %% DEV SIGNATURE
    Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}

%% GRAB INFORMATION FROM "config"
use_timeseries = config.use_timeseries;
use_peaks = config.use_peaks;
WLP_switch = config.create_wlp;
WHP_switch = config.create_whp;
% CHS Region
chs_region = config.region;
% Save Point ID
spID = config.sp_ID;
% Define Storm Surge Level CHS Bias File
chs_ssl_bias_file = config.chs_ssl_bias_and_uncertainty_file;
% Define CHS REgional Study Grid File
grid_path = config.chs_grid_file_source;
% Storm Duration
storm_duration = config.storm_duration;
%
disp_on = config.print_progress;

%% DEFINE AUX VARIABLES
% storm Type Flag To Search For
switch storm_type
    case 'TC'
        storm_if = {'TS','TC'};
    case 'XC'
        storm_if = {'XC','XH'};
        prob_mass = [];
end

%% PROCESS CHS PEAKS DATASET TO CREATE "storm.Peaks"
if use_peaks == 1
    % Display Progress Step
    if strcmp(storm_type,'XC')
        disp_toggle(disp_on,['Matching CHS extratropical peak waves and water levels....']);
    else
        disp_toggle(disp_on,['Matching CHS tropical peak waves and water levels....']);
    end
    % Pull Storm Data From Parsed H5 Files
    [peaks_data, adcirc_bool,  STWAVE_headers_location, Tp_special] = chs_file_selection(CHS_Data, 'Peaks', storm_if);
    % Format storm Data
    [storm.('Peaks').Default, storm2rm] = chs_peaks_formater(peaks_data{adcirc_bool},...
        peaks_data{~adcirc_bool}, STWAVE_headers_location, storm_duration, Tp_special); % storm2rm is a storm ID
else
    storm2rm = [];
end

%% PROCESS CHS TIMESERIES DATASET TO CREATE "storm.Timeseries" & PRIORITY DATASETS ("storm.Peaks.WLP" and/or "storm.Peaks.WHP")
if use_timeseries == 1
    % Display Progress Step
    if strcmp(storm_type,'XC')
        disp_toggle(disp_on,['Matching CHS extratropical timeseries waves and water levels....']);
    else
        disp_toggle(disp_on,['Matching CHS tropical timeseries waves and water levels....']);
    end
    % Pull Storm Data From Parsed H5 Files
    [timeseries_data, adcirc_bool_ts,  STWAVE_headers_location_ts, Tp_special_ts] = chs_file_selection(CHS_Data, 'Timeseries', storm_if);
    % Create ADCIRC-STWAVE TimeSeries Dataset
    [storm.Timeseries.Default, storm2rm] = chs_timeseries_formater(timeseries_data{adcirc_bool_ts},...
        timeseries_data{~adcirc_bool_ts},...
        storm2rm, STWAVE_headers_location_ts, Tp_special_ts, disp_on);
    % Create Alternate Datasets
    if use_peaks == 1
        % Create Water Level Priority
        if WLP_switch == 1
            [storm.('Peaks').WLP, ~] = create_priority_dataset(peaks_data{adcirc_bool},...
                timeseries_data{adcirc_bool_ts}, timeseries_data{~adcirc_bool_ts},...
                storm2rm, STWAVE_headers_location_ts, storm_duration, Tp_special_ts, 'wlp', disp_on);
        end
        % Create Wave Height Priority
        if WHP_switch == 1
            [storm.('Peaks').WHP, ~] = create_priority_dataset(peaks_data{~adcirc_bool}, ...
                timeseries_data{adcirc_bool_ts}, timeseries_data{~adcirc_bool_ts},...
                storm2rm, STWAVE_headers_location, storm_duration, Tp_special, 'whp', disp_on);
        end
    end
end
% Store Invalid Storms
removed_storms.Default = storm2rm;

%% REMOVE FLAGED STORMS
% Remove Storms From "Default" Peaks Dataset
if use_peaks == 1
    % Identify Rows To Remove
    rm_bool = ismember(cell2mat(storm.('Peaks').Default(:, 1)), removed_storms.Default);
    % Remove Storms
    storm.('Peaks').Default(rm_bool, :) = [];
end
% Remove Storms From "Default" Timeseries Dataset
if use_timeseries == 1
    % Identify Rows To Remove
    rm_bool = ismember(cell2mat(storm.('Timeseries').Default(:, 1)), removed_storms.Default);
    % Remove Storms
    storm.('Timeseries').Default(rm_bool, :) = [];
end
% Remove Storms From Alternate Water Level Priority (WLP) Dataset
if WLP_switch == 1 & use_peaks == 1
    % Identify Rows To Remove
    %         rm_bool_wlp = ismember(cell2mat(storm.('Peaks').WLP(:, 1)), removed_storms.WLP);
    % Remove Storms
    storm.('Peaks').WLP(rm_bool, :) = [];
end
% Remove Storms From Alternate Wave Height Priority (WLP) Dataset
if WHP_switch == 1 & use_peaks == 1
    % Identify Rows To Remove
    %         rm_bool_whp = ismember(cell2mat(storm.('Peaks').WHP(:, 1)), removed_storms.WHP);
    % Remove Storms
    storm.('Peaks').WHP(rm_bool, :) = [];
end

%% ADJUST STORM DEPENDANT PARAMETERS
% Adjust storm Type Dependant Fields
switch storm_type
    case 'TC'% Tropical Cyclones
        if isempty(prob_mass.TC_Freq)
            % Something Went Wrong In PM Load
            warning('Something went wrong loading probability masses..');
        else
            % Remove storms From Frequency Vector
            prob_mass.TC_Freq(rm_bool,:)=[];
            % Redifine New Frequency Vector
            if ~isempty(storm2rm)
                prob_mass.TC_Freq = prob_mass.TC_Freq*prob_mass.TotalFreq/sum(prob_mass.TC_Freq);
            end
            % Remove storms From Other Vars
            prob_mass.Param(rm_bool,:)=[];
            %
            prob_mass.smpl1(ismember(prob_mass.smpl1,removed_storms.Default)) = [];
            prob_mass.smpl2(ismember(prob_mass.smpl2,removed_storms.Default)) = [];
            prob_mass.smpl3(ismember(prob_mass.smpl3,removed_storms.Default)) = [];
        end
        % Define Empty Var For Outputs
        XC_Nyrs = [];XC_Nstm = [];
    case 'XC' % Extratropical storms
        if use_peaks == 1
            % Determine Number Of Events
            XC_Nstm = height(peaks_data{adcirc_bool==1});
            % Get Timestamp Vector
            tVector = peaks_data{adcirc_bool==1}.yyyymmddHHMM;
            % Check For NaNs
            hIndx = sum(cell2mat(cellfun(@(x) ~strcmp(x,{'NaN','         NaN'}),tVector,'UniformOutput',false))==0,2)==0;
            % Get Event Record Years
            [record_years,~,~,~,~,~] = datevec(cell2mat(tVector(hIndx)), 'yyyymmddHHMM');
            % Compute Number Of Years
            XC_Nyrs=max(record_years)-min(record_years)+1;
        else
            % Determine Number Of Events
            XC_Nstm = height(timeseries_data{adcirc_bool_ts==1});
            % Get Timestamp Vector
            tVector = timeseries_data{adcirc_bool_ts==1}.yyyymmddHHMM;
            % Check For NaNs
            hIndx = cellfun(@(x) ~contains(cellstr(x),{'NaN','         NaN'}),tVector,'un',false);
            % Get Event Record Years
            for kk = 1:length(hIndx)
                if any(hIndx{kk})
                    [record_years{kk},~,~,~,~,~] = datevec(tVector{kk}(hIndx{kk}, :), 'yyyymmddHHMM');
                else
                    record_years{kk} = NaN;
                end
            end
            % Compute Number Of Years
            XC_Nyrs = max(cellfun(@max, record_years), [], "omitnan") - min(cellfun(@min, record_years), [], "omitnan")+1;
        end
end

%% APPLY BIAS CORRECTION
% Initialize Bias Trigger
bias_tgr = 1;
% Load Bias Correction Data For CHS Region
if ~exist(chs_ssl_bias_file,'file') | contains(chs_region, {'Lake'}) | isempty(spID) | strcmp(storm_type, 'XC')
    % Check for Non Zero Bias Values
    bias_tgr = 0;
else
    switch chs_region
        case 'CHS-LA'
            % Load Grid Files
            load(fullfile(grid_path, 'CHS-LA_ADCIRC_SPs.mat'), 'SPs');  % SPs
            load(fullfile(grid_path, 'CHS-LA_staID.mat'), 'staID');  % staID -> [SP_ID Node_ID Lon Lat Depth]
            % Get Row
            adcirc_node_id = SPs(SPs(:,1) == spID, 2);
            % Find Correct Row ID For Bias & Uncertainty
            bias_indx = find(staID(:,2) == adcirc_node_id); % Row INdex For Bias And Uncertainty
        otherwise
            % Get File Dir
            dummy = dir(fullfile(grid_path,'*.mat'));
            % Define Load Cases
            load_cases = {'nodeID','staID'};
            % Pull Grid File
            dummy = dummy(contains({dummy.name},{'nodeID','staID'}));
            % Identify Case
            load_bool = cell2mat(cellfun(@(x)contains(dummy.name, x), {'nodeID','staID'}, 'un', false));
            % Load Grid Files
            switch load_cases{load_bool}
                case 'nodeID'
                    % Load Grid Files
                    staID = load(fullfile(grid_path, dummy.name), 'nodeID');staID = staID.nodeID;  % SPs
                case 'staID'
                    % Load Grid Files
                    load(fullfile(grid_path, dummy.name) ,'staID'); % staID -> [SP_ID Node_ID Lon Lat Depth]
            end
            % Find Correct Row ID For DSWs
            bias_indx = find(staID(:,1) == spID); % Row INdex For Bias And Uncertainty
    end
    % Load Bias Correction File
    warning('off');
    try
        u_data = load(chs_ssl_bias_file, 'Comb'); % PBL + ADCIRC
        u_data = u_data.Comb;
    catch
        u_data = load(chs_ssl_bias_file, 'WL'); % ADCIRC Only
        u_data = u_data.WL;
    end
    warning('on');
    % Comb.B_a, B_r, B_a_avg, B_r_avg, U_a, U_r, U_a_avg, U_r_avg
    B_a_SWL=u_data.B_a(bias_indx); B_r_SWL=u_data.B_r(bias_indx);
    config.chs_swl_b_a = B_a_SWL;
    config.chs_swl_b_r = B_r_SWL;
    % Overwrite Manual Value
    config.chs_swl_u_a = u_data.U_a(bias_indx); % SWL absolute uncertainty
    config.chs_swl_u_r = u_data.U_r(bias_indx); % SWL Proportional uncertainty
end

% Apply Bias Correction (If Applicable)
if bias_tgr == 1
    % Determine Structure Fields
    sNames = fieldnames(storm);
    % Define Function
    f_u = @(x) x - B_a_SWL./abs(B_a_SWL)./sqrt(1./B_a_SWL.^2 + 1./(B_r_SWL .* x).^2); % Bias Correction Formula
    % Adjust SWL Bias
    for ii = 1:length(sNames) % Data Types: Peaks, Timeseries
        % Get Level_2 Fieldnames
        level_2 = fieldnames(storm.(sNames{ii}));
        % Apply Bias Correction
        for kk = 1:length(level_2) % Match Type: Default, WLP, WHP
            for ss = 1:length(storm.(sNames{ii}).(level_2{kk})) % Number Of Storms
                storm.(sNames{ii}).(level_2{kk}){ss, 2}(:, 1) = f_u(storm.(sNames{ii}).(level_2{kk}){ss, 2}(:, 1)); % Apply Bias Correction To SSL (Surge)
            end
        end
    end
end

%% AUX FUNCTION
    function [storm_data, ad_indx, STWAVE_headers_location, Tp_special] = chs_file_selection(CHS_Data, data_type, storm_type)
        % Pull CHS Parsed H5 Files Accordin To Data Type & Storm Type
        file_indx = contains({CHS_Data.Filename},{data_type}) &...
            contains({CHS_Data.Filename}, storm_type);
        % Extract Peaks Files
        storm_data = CHS_Data(file_indx);
        % Find ADCIRC Filename
        ad_indx = contains({storm_data.Filename},{'ADCIRC'});
        % Get Headers For Hm0,Tp,wDir
        [STWAVE_headers_location, Tp_special] = chs_wave_model_header_locator(storm_data(~ad_indx));
        % Extract "Strom_Table" Field
        storm_data = cellfun(@(x) x.Table_StormData, {CHS_Data(file_indx).Conv_Data}, 'un', false)';
    end
end



