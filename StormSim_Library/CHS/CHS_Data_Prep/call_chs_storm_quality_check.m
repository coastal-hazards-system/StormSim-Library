function [config, storm, removed_storms, XC_Nyrs, XC_Nstm, prob_mass] = call_chs_storm_quality_check(config, CHS_Data, prob_mass, storm_type,...
    use_timeseries, WLP_switch, WHP_switch)
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
% CHS Region
chs_region = config.region;
% Save Point ID
spID = config.sp_ID;
% Define CHS Bias File 
chs_bias_file = config.chs_bias_file;

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
% Format storm Data
[storm.Maxima] = chs_peaks_formater(peaks_data(ad_indx==1).Table_StormData,...
    peaks_data(ad_indx==0).Table_StormData, STWAVE_headers_location);

% Convert From Tm to Tp (Special Case)
if Tp_special == 1
    % Convert Tm to Tp (Lake Ontario Case)
    storm.Maxima(:,3) = storm.Maxima(:,3)*1.2;
end
% Find NaN's In "Maxima" Dataset
storm2rm = unique([find(isnan(storm.Maxima(:,1)));find(isnan(storm.Maxima(:,2)));...
    find(isnan(storm.Maxima(:,3)));find(isnan(storm.Maxima(:,4)))]);
% Convert From Row Index To storm ID
storm2rm =  storm.Maxima(storm2rm,5);

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
    % Progress One Level
    timeseries_data = [timeseries_data(tc_indx).Conv_Data];
    % Run QA/QC Using TimeSeries
    [removed_storms.Maxima,...
        storm.WLP,storm.WHP,...
        removed_storms.WHP,...
        removed_storms.WLP] = chs_timeseries_qaqc(storm2rm,...
        peaks_data(ad_indx==1).Table_StormData, peaks_data(ad_indx==0).Table_StormData,...
        timeseries_data(ad_indx_timeseries==1).Table_StormData, timeseries_data(ad_indx_timeseries==0).Table_StormData,...
        has_WaterElevation, STWAVE_headers_location, WLP_switch, WHP_switch, Tp_special, storm_type);
    % Display Progress Step
    if strcmp(storm_type,'XC')
        disp('Matching CHS extratropical timeseries waves and water levels....');
    else
        disp('Matching CHS tropical timeseries waves and water levels....');
    end
    % Create ADCIRC-STWAVE TimeSeries Dataset
    [storm.Timeseries] = chs_timeseries_formater(timeseries_data(ad_indx_timeseries==1).Table_StormData,...
        timeseries_data(ad_indx_timeseries==0).Table_StormData,...
        removed_storms.Maxima, has_WaterElevation, STWAVE_headers_location, Tp_special);
end

%% REMOVE INVALID STORMS & ADJUST PARAMETERS ACCORDINGLY
% Maxima Dataset
% Grab Removed Storm Ids For Maxima Dataset
storm2rm = unique([storm2rm;removed_storms.Maxima];
% find(ismember(storm.Maxima(:,5), removed_storms.Maxima)==1);
% Remove Bad storms
storm.Maxima(ismember(storm.Maxima(:,5),...
    removed_storms.Maxima),:) = [];
% WLP
if WLP_switch
    % Grab Removed Storm Ids For WLP Dataset
    storm2rm_WLP = removed_storms.WLP;
    % Remove Bad storms
    storm.WLP(ismember(storm.WLP(:,5),...
        removed_storms.WLP),:) = [];
end
% WHP
if WHP_switch
    % Grab Removed Storm Ids For WHP Dataset
    storm2rm_WHP = removed_storms.WHP;
    % Add Structure Field To Prob Masses

    % Remove Bad storms
    storm.WHP(ismember(storm.WHP(:,5),...
        removed_storms.WHP),:) = [];
end
% Adjust storm Type Dependant Fields
switch storm_type
    case 'TC'% Tropical Cyclones
        % Remove storms From Frequency Vector
        prob_mass.TC_Freq(storm2rm,:)=[];
        % Redifine New Frequency Vector
        prob_mass.TC_Freq = prob_mass.TC_Freq*prob_mass.TotalFreq/sum(prob_mass.TC_Freq);
        % Remove storms From Other Vars
        prob_mass.Param(storm2rm,:)=[];
        prob_mass.dist(:,storm2rm)=[];
        %
        prob_mass.smpl1(ismember(prob_mass.smpl1,removed_storms.Maxima)) = [];
        prob_mass.smpl0(ismember(prob_mass.smpl0,removed_storms.Maxima)) = [];

        % Define EMpty Var For Outputs
        XC_Nyrs = [];XC_Nstm = [];
    case 'XC' % Extratropical storms
        % Get TimeStamp Vector
        tVector = cellstr(num2str(peaks_data(ad_indx==1).Table_StormData.('yyyymmddHHMM')));
        % Check For NaNs
        hIndx = sum(cell2mat(cellfun(@(x) ~strcmp(x,{'NaN','         NaN'}),tVector,'UniformOutput',false))==0,2)==0;
        % Get Most Recent storm Time Stamp
        [MaxYR,~,~,~,~,~] = datevec(max(datenum(tVector(hIndx),'yyyymmddHHMM')));
        % Get Oldest storm Time Stamp
        [MinYR,~,~,~,~,~] = datevec(min(datenum(tVector(hIndx),'yyyymmddHHMM')));
        % Compute Number Of Years
        XC_Nyrs=MaxYR-MinYR+1;
        % Number Of storms
        XC_Nstm = height(peaks_data(ad_indx==1).Table_StormData);
end

%% APPLY BIAS CORRECTION
% Initialize Bias Trigger
bias_tgr = 1;
% Load Bias Correction Data For CHS Region
switch chs_region
    case 'NACCS'
        % Load Bias Correction File
        load(chs_bias_file);
        % Comb.B_a, B_r, B_a_avg, B_r_avg, U_a, U_r, U_a_avg, U_r_avg
        B_a_SWL=Comb.B_a(spID); B_r_SWL=Comb.B_r(spID);
        % Overwrite Manual Value
        config.chs_swl_u_a = Comb.U_a(spID); % SWL absolute uncertainty
        config.chs_swl_u_r = Comb.U_r(spID); % SWL Proportional uncertainty
    otherwise
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
            eval(['storm.' sNames{ii} '(:,1) = f_u(storm.' sNames{ii} '(:,1));']);
        end
    end
end
end



