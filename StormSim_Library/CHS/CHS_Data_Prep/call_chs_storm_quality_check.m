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
% Define CHS Bias File
chs_bias_file = config.chs_bias_file;
% Define SWL Hydrograph Switch
use_waves_swl = config.use_waves_swl;
pm_path = config.prob_mass_source;

%% DEFINE AUX VARIABLES
% storm Type Flag To Search For
switch storm_type
    case 'TC'
        storm_if = {'TS','TC'};
    case 'XC'
        storm_if = {'XC','XH'};
        prob_mass = [];
end

%% FORMAT CHS STORM DATA AND CREATE MAXIMA DATASET
if use_peaks == 1
    % Peaks Data
    peaks_indx = contains({CHS_Data.Filename},{'Peaks'});
    % Ectract Peaks Files
    peaks_data = CHS_Data(peaks_indx);
    % Find TC Filenames
    tc_indx = contains({peaks_data.Filename},storm_if);
    % Convert CHS Data Files
    peaks_data = peaks_data(tc_indx);
    % Find ADCIRC Filename
    ad_indx = contains({peaks_data.Filename},{'ADCIRC'});
    % Get Headers For Hm0,Tp,wDir
    [STWAVE_headers_location,Tp_special] = chs_wave_model_header_locator(peaks_data(ad_indx==0));
    % Determine If Wave Model Provides Water Elevation
    has_WaterElevation = sum(contains(peaks_data(ad_indx==0).Conv_Data.headers,{'Water Elevation','WaterElevation'}));
    % Extract "Strom_Table" Field
    peaks_data = [peaks_data.Conv_Data];
    % Number Of TC's
    nTC_storms = height(peaks_data(ad_indx==1).Table_StormData);
    % Format storm Data
    [storm.('Peaks').Maxima] = chs_peaks_formater(peaks_data(ad_indx==1).Table_StormData,...
        peaks_data(ad_indx==0).Table_StormData, STWAVE_headers_location);
    % Convert From Tm to Tp (Special Case)
    if Tp_special == 1
        % Convert Tm to Tp (Lake Ontario Case)
        storm.('Peaks').Maxima(:,3) = storm.('Peaks').Maxima(:,3)*1.2;  % Remove This For Release, Need to inform user
    end
    % Find NaN's In "Maxima" Dataset
    storm2rm = unique([find(isnan(storm.('Peaks').Maxima(:,1)));find(isnan(storm.('Peaks').Maxima(:,2)));...
        find(isnan(storm.('Peaks').Maxima(:,3)));find(isnan(storm.('Peaks').Maxima(:,4)))]);
    % Convert From Row Index To storm ID
    storm2rm =  storm.('Peaks').Maxima(storm2rm,5);
else
    % Peaks Data
    peaks_indx = contains({CHS_Data.Filename},{'Timeseries'});
    % Ectract Peaks Files
    peaks_data = CHS_Data(peaks_indx);
    % Find TC Filenames
    tc_indx = contains({peaks_data.Filename},storm_if);
    % Convert CHS Data Files
    peaks_data = peaks_data(tc_indx);
    % Find ADCIRC Filename
    ad_indx = contains({peaks_data.Filename},{'ADCIRC'});
    % Get Headers For Hm0,Tp,wDir
    [STWAVE_headers_location,Tp_special] = chs_wave_model_header_locator(peaks_data(ad_indx==0));
    % Determine If Wave Model Provides Water Elevation
    has_WaterElevation = sum(contains(peaks_data(ad_indx==0).Conv_Data.headers,{'Water Elevation','WaterElevation'}));
    % Extract "Strom_Table" Field
    peaks_data = [peaks_data.Conv_Data];
    % Number Of TC's
    nTC_storms = height(peaks_data(ad_indx==1).Table_StormData);
    % Initialize Storms To Remove
    storm2rm = [];
    % Find NaN Entries
    for ll = 1:length(peaks_data)
        % Check For Bad Hydrohgraphs
        dummy = cellfun(@length,peaks_data(ll).StormData(:,9));
        % Grab Storm IDs
        dummy2 = str2double(peaks_data(ll).Table_StormData.('Storm ID'));
        % Add Bad Storm IDs TO Storms To Remove
        storm2rm = [storm2rm; dummy2(dummy==1)];
    end
    removed_storms.Maxima = storm2rm;
end

%% APPLY TIMESERIES QA/QC AND GENERATE ALTERNATE DATASETS
if use_timeseries == 1
    % Timeseries Data
    timeseries_indx = contains({CHS_Data.Filename},{'Timeseries'});
    % Ectract Peaks Files
    timeseries_data = CHS_Data(timeseries_indx);
    % Find TC Filenames
    tc_indx = contains({timeseries_data.Filename},storm_if);
    % Find ADCIRC Filename
    ad_indx_timeseries = contains({timeseries_data(tc_indx).Filename},{'ADCIRC'});
    % Mismatch ing Headers Failsafe
    timeseries_data_temp = timeseries_data(tc_indx);
    % Progress One Level
    timeseries_data = [timeseries_data(tc_indx).Conv_Data];
    % Get Headers For Hm0,Tp,wDir
    [STWAVE_headers_location_ts,Tp_special_ts] = chs_wave_model_header_locator(timeseries_data_temp(ad_indx_timeseries==0));
    % Create Alternate Datastes (WHP,WLP)
    if use_peaks == 1
        % Run QA/QC Using TimeSeries
        [removed_storms.Maxima,...
            storm.('Peaks').WLP, storm.('Peaks').WHP,...
            removed_storms.WHP,...
            removed_storms.WLP] = chs_timeseries_qaqc(storm2rm,...
            peaks_data(ad_indx==1).Table_StormData, peaks_data(ad_indx==0).Table_StormData,...
            timeseries_data(ad_indx_timeseries==1).Table_StormData, timeseries_data(ad_indx_timeseries==0).Table_StormData,...
            has_WaterElevation, STWAVE_headers_location, STWAVE_headers_location_ts, WLP_switch, WHP_switch, Tp_special, Tp_special_ts, storm_type);
        % Remove Alternate Datasets If Empty
        if WLP_switch == 0
            storm.('Peaks') = rmfield(storm.('Peaks'),'WLP');
            removed_storms =  rmfield(removed_storms,'WLP');
        end
        if WHP_switch == 0
            storm.('Peaks') = rmfield(storm.('Peaks'),'WHP');
            removed_storms =  rmfield(removed_storms,'WHP');
        end
    end
    % Display Progress Step
    if strcmp(storm_type,'XC')
        disp([newline 'Matching CHS extratropical timeseries waves and water levels....']);
    else
        disp([newline 'Matching CHS tropical timeseries waves and water levels....']);
    end
    % Make Sure To Grab Request SWL Hydrograph
    if use_waves_swl == 0
        has_WaterElevation = 0;
    end
    % Create ADCIRC-STWAVE TimeSeries Dataset
    [storm.Timeseries, ts_storm2rm] = chs_timeseries_formater(timeseries_data(ad_indx_timeseries==1).Table_StormData,...
        timeseries_data(ad_indx_timeseries==0).Table_StormData,...
        removed_storms.Maxima, has_WaterElevation, STWAVE_headers_location_ts, Tp_special_ts);
    % Use Timeseries Indes If Peaks Are Missing
    if use_peaks == 0
        % Remove Bad Storms
        storm.Timeseries(ismember(cell2mat(storm.Timeseries(:,1)), ts_storm2rm),:) = [];
        removed_storms.Maxima = ts_storm2rm;
    end
end

%% REMOVE INVALID STORMS & ADJUST PARAMETERS ACCORDINGLY
if use_timeseries == 1 && use_peaks == 1
    removed_storms.Maxima = unique([storm2rm;removed_storms.Maxima;ts_storm2rm]);
    % Grab Removed Storm Ids For Maxima Dataset
    storm2rm =  removed_storms.Maxima;
    % find(ismember(storm.Maxima(:,5), removed_storms.Maxima)==1);
    % Remove Bad storms
    storm.('Peaks').Maxima(ismember(storm.('Peaks').Maxima(:,5),...
        removed_storms.Maxima),:) = [];
    storm.('Timeseries')(ismember(cell2mat(storm.('Timeseries')(:,1)),...
        storm2rm),:) = [];
    % WLP
    if WLP_switch
        % Grab Removed Storm Ids For WLP Dataset
        storm2rm_WLP = removed_storms.WLP;
        % Remove Bad storms
        storm.('Peaks').WLP(ismember(storm.('Peaks').WLP(:,5),...
            removed_storms.WLP),:) = [];
    end
    % WHP
    if WHP_switch
        % Grab Removed Storm Ids For WHP Dataset
        storm2rm_WHP = removed_storms.WHP;
        % Remove Bad storms
        storm.('Peaks').WHP(ismember(storm.('Peaks').WHP(:,5),...
            removed_storms.WHP),:) = [];
    end
    % Compute Logical Vector Of Bad Storms
    storm2rm = ismember(1:nTC_storms,...
        storm2rm);
elseif use_timeseries == 1 && use_peaks == 0
    % Compute Logical Vector Of Bad Storms
    storm2rm = ismember(1:nTC_storms,...
        removed_storms.Maxima);
elseif use_peaks == 1 && use_timeseries == 0
    % Grab Removed Storm Ids For Maxima Dataset
    removed_storms.Maxima = storm2rm;
    % find(ismember(storm.Maxima(:,5), removed_storms.Maxima)==1);
    % Remove Bad storms
    storm.('Peaks').Maxima(ismember(storm.('Peaks').Maxima(:,5),...
        removed_storms.Maxima),:) = [];
end
% Adjust storm Type Dependant Fields
switch storm_type
    case 'TC'% Tropical Cyclones
        if isempty(prob_mass.TC_Freq)
            % Something Went Wrong In PM Load
            warning(['Something went wrong loading probability masses..']);
        else
            % Remove storms From Frequency Vector
            prob_mass.TC_Freq(storm2rm,:)=[];
            % Redifine New Frequency Vector
            if ~isempty(storm2rm)
                prob_mass.TC_Freq = prob_mass.TC_Freq*prob_mass.TotalFreq/sum(prob_mass.TC_Freq);
            end
            % Remove storms From Other Vars
            prob_mass.Param(storm2rm,:)=[];
            %
            prob_mass.smpl1(ismember(prob_mass.smpl1,removed_storms.Maxima)) = [];
            prob_mass.smpl2(ismember(prob_mass.smpl2,removed_storms.Maxima)) = [];
            prob_mass.smpl3(ismember(prob_mass.smpl3,removed_storms.Maxima)) = [];
        end
        % Define EMpty Var For Outputs
        XC_Nyrs = [];XC_Nstm = [];
    case 'XC' % Extratropical storms
        % Determine Number Of XCs & Years
        if use_peaks == 1
            % Get TimeStamp Vector
            tVector = peaks_data(ad_indx==1).Table_StormData.('yyyymmddHHMM');
            % Check For NaNs
            hIndx = sum(cell2mat(cellfun(@(x) ~strcmp(x,{'NaN','         NaN'}),tVector,'UniformOutput',false))==0,2)==0;
            % Get Most Recent storm Time Stamp
            [MaxYR,~,~,~,~,~] = datevec(max(datenum(tVector(hIndx),'yyyymmddHHMM')));
            % Get Oldest storm Time Stamp
            [MinYR,~,~,~,~,~] = datevec(min(datenum(tVector(hIndx),'yyyymmddHHMM')));
        else
            % Get TimeStamp Vector
            tVector = peaks_data(ad_indx==1).Table_StormData.('yyyymmddHHMM');
            % Check For NaNs
            hIndx = cellfun(@(x) ~contains(cellstr(x),{'NaN','         NaN'}),tVector,'un',false);
            % Get Min/Max Of Hydrographs
            for kk = 1:length(tVector)
                [MinYR(kk),~,~,~,~,~] = datevec(min(datenum(tVector{kk}(hIndx{kk},:),'yyyymmddHHMM')));
                [MaxYR(kk),~,~,~,~,~] = datevec(max(datenum(tVector{kk}(hIndx{kk},:),'yyyymmddHHMM')));
            end
            % Get Most Recent storm Time Stamp
            MaxYR = max(MaxYR);
            % Get Oldest storm Time Stamp
            MinYR = min(MinYR);
        end
        % Compute Number Of Years
        XC_Nyrs=MaxYR-MinYR+1;
        % Number Of storms
        XC_Nstm = height(peaks_data(ad_indx==1).Table_StormData);
end

%% APPLY BIAS CORRECTION
% Initialize Bias Trigger
bias_tgr = 1;
% Load Bias Correction Data For CHS Region
if ~exist(chs_bias_file,'file')
    bias_tgr = 0;
else
    switch chs_region
        case 'CHS-LA'
            % Load Grid Files 
            load(fullfile(pm_path, 'CHS-LA_ADCIRC_SPs.mat'), 'SPs');  % SPs
            load(fullfile(pm_path, 'CHS-LA_staID.mat'), 'staID');  % staID -> [SP_ID Node_ID Lon Lat Depth]
            % Get Row
            adcirc_node_id = SPs(SPs(:,1) == spID, 2);
            % Find Correct Row ID For Bias & Uncertainty
            bias_indx = find(staID(:,2) == adcirc_node_id); % Row INdex For Bias And Uncertainty
        otherwise
            bias_indx = spID;
    end
    % Load Bias Correction File
    load(chs_bias_file, 'Comb');
    % Comb.B_a, B_r, B_a_avg, B_r_avg, U_a, U_r, U_a_avg, U_r_avg
    B_a_SWL=Comb.B_a(bias_indx); B_r_SWL=Comb.B_r(bias_indx);
    config.chs_swl_b_a = B_a_SWL; 
    config.chs_swl_b_r = B_r_SWL;
    % Overwrite Manual Value
    config.chs_swl_u_a = Comb.U_a(bias_indx); % SWL absolute uncertainty
    config.chs_swl_u_r = Comb.U_r(bias_indx); % SWL Proportional uncertainty
end
%
if strcmp(storm_type, 'XC') && config.apply_xc_bias == 0
    bias_tgr = 0;
end
% Apply Bias Correction (If Applicable)
if bias_tgr == 1
    % Determine Structure Fields
    sNames = fieldnames(storm);
    % Define Function
    f_u = @(x) x - B_a_SWL./abs(B_a_SWL)./sqrt(1./B_a_SWL.^2 + 1./(B_r_SWL .* x).^2);
    % Adjust SWL Bias
    for ii = 1:length(sNames)
        if strcmp(sNames{ii},'Timeseries')
            % Correct All Timeseries
            for kk = 1:length(storm.('Timeseries')(:,2))
                % Rewrite SWL Data
                storm.('Timeseries'){kk,2}(:,2) = f_u(storm.('Timeseries'){kk,2}(:,2));
            end
        else
            % Get Level_2 Fieldnames
            level_2 = fieldnames(storm.(sNames{ii}));
            % Apply Bias Correction
            for kk = 1:length(level_2)
                storm.(sNames{ii}).(level_2{kk})(:,1) = f_u(storm.(sNames{ii}).(level_2{kk})(:,1));
            end
        end
    end
end
end



