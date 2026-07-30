function [project_forcing] = stormsim_lcs(config, storm, prob_mass)
%{
INPUTS:
     config.StormSamplingDropDown.Value; -> 'Extratropical Only' , 'Tropical Only' , 'Combined Sampling'
     config.nLifeCycles.Value -> Number of life cycles
     config.SimLength.Value -> Simulation Length
     config.SPID; -> Savepoint ID
     config.UseTimeseriesCheckBox.Value; -> True or False
     config.Data; -> CHS Data from matlab CHS Data Converter
     config.WaterLevelPriorityCheckBox.Value; -> True or False
     config.WaveHeightPriorityCheckBox.Value; -> True or False
     config.SaveNameEditField.Value; -> Output Dir Save Name

OUTPUTS HEADERS:
    LC_MCSimOUT:
        Size (# of LC's, 8) -> (Rows,Col)
            (01) Storm ID                       [-]
            (02) Storm type                     [0 = extratropical]
            (03) Storm Year                     [-]
            (04) Number of storm in storm year  [-]
            (05) Water Level                    [meters, MSL]
            (06) Wave Height                    [meters]
            (07) Peak Wave Period               [seconds]
            (08) Wave Direction                 [degrees; N=0, E=+90, S=+/-180, W=-90]
    LC_SimOUT_hyd:
        First Level:
            Size (# of LC's, 1) -> (Rows,Col)
            Each row contains a matrix which size depends on the ammount of
            storms sampled for that specific life cyccle.
        Second Level:
            (01) Storm ID                       [-]
            (02) Storm type                     [0 = extratropical]
            (03) Storm Year                     [-]
            (04) Number of storm in storm year  [-]
            (05) Water Level                    [meters, MSL]
            (06) Wave Height                    [meters]
            (07) Peak Wave Period               [seconds]
            (08) Wave Direction                 [degrees; N=0, E=+90, S=+/-180, W=-90]
            (09) Storm Duration           [days]
            (10) Timestep Counter         [0:storm_tstp-1]
    MC_indx:
        First Level:
            Size (# of LC's, 1) -> (Rows,Col)
            Each row contains a vector which size depends on the ammount of
            storms sampled for that specific life cyccle.
        Second Level:
            (01) Storm Year               [-]
            (02) Storm Type               [-]
            (03) Same Year Counter        [-]
            (04) Storm ID                 [-]

%}
warning('off','all');

%% GRAB INPUT FROM "config"
% Storm Sampling Scheme
storm_sampling = config.storm_sampling;
% Number Of Life Cycles
number_of_life_cyles = config.mcs_nLC;
% Simulation Length
simulation_years = config.mcs_nYears;
% Create Water Level Priority Switch
wlp_switch = config.create_wlp;
% Create Wave Height Priority Switch
whp_switch = config.create_whp;
switch storm_sampling
    case 'TC'
        XC_Nstm = [];
        XC_Nyrs = [];
    otherwise
        % Define Number Of Extratropical Storms In Data
        XC_Nstm = config.Nstm_XC;
        % Define Number of Years In Extratropical Data
        XC_Nyrs = config.Nyrs_XC;
end
mcs_ref_pth = fullfile(config.outfolder, config.project_name, config.struc_id,...
    config.ref_case_name, 'LCS', [config.project_name,'_', config.struc_id, '_', config.ref_case_name, '_LCS_project_forcing.mat']);

%% CREATE DUMMY PEAKS DATASET IF NEEDED
if config.use_peaks == 0
    % Define Storm Types
    switch config.storm_sampling
        case 'CC'
            stm_list = {'TC','XC'};
        otherwise
            stm_list = {config.storm_sampling};
    end
    % Create Dummy Peak Dataset
    for kk = 1:length(stm_list)
        % Get Max Responses [ ]
        dummy_data = cell2mat(cellfun(@(x) max(x,[],1),...
            storm.(stm_list{kk}).('Timeseries').Default(:,2), 'un', false));
        % Replace Storm Duration For Peak Response
        dummy_data(:, end) = config.storm_duration/24;
        % Create Dummy Dataset
        storm.(stm_list{kk}).('Peaks').('Default') = [ storm.(stm_list{kk}).('Timeseries').Default(:,1),...
            num2cell(dummy_data, 2)];
    end
end

%% DEFINE ADDITIONAL VARIABLES
% Initialize Life Cycle Storage Vars
if contains(storm_sampling,{'XC','CC'})
    % Initialize Default Dataset MC Storage Variable
    project_forcing.Peaks.Default.('XC') = repmat({},number_of_life_cyles,1);
    % Initialize WLP Dataset MC Storage Variable
    project_forcing.Peaks.WLP.('XC') = repmat({},number_of_life_cyles,1);
    % Initialize WHP Dataset MC Storage Variable
    project_forcing.Peaks.WHP.('XC') = repmat({},number_of_life_cyles,1);
end
if contains(storm_sampling,{'TC','CC'})
    % Initialize Default Dataset MC Storage Variable
    project_forcing.Peaks.Default.('TC') = repmat({},number_of_life_cyles,1);
    % Initialize WLP Dataset MC Storage Variable
    project_forcing.Peaks.WLP.('TC') = repmat({},number_of_life_cyles,1);
    % Initialize WHP Dataset MC Storage Variable
    project_forcing.Peaks.WHP.('TC') = repmat({},number_of_life_cyles,1);
end

%% CYCLE THROUGH LIFE CYCLES
% Command Prompts
disp('   Running StormSim: Monte Carlo Simulation (Storm Sampling)....');


    %% SAMPLE EXTRATROPICAL STORMS
    if strcmp(storm_sampling,'CC')==1 || strcmp(storm_sampling,'XC')==1
        % Sample XC Storms According To Peak Responses
        if config.load_project_forcing == 1 && exist(mcs_ref_pth, 'file')
            % Prevent Multiple Loads
            ref_pf = load(mcs_ref_pth, 'project_forcing');
            ref_pf = ref_pf.project_forcing;
            % Check What Sampling Seed The Reference Case Actually Has
            has_ref_peaks = isfield(ref_pf,'Peaks') && isfield(ref_pf.Peaks,'Default') && isfield(ref_pf.Peaks.Default,'XC');
            has_ref_ts = isfield(ref_pf,'Timeseries') && isfield(ref_pf.Timeseries,'Default') && isfield(ref_pf.Timeseries.Default,'XC');
            if has_ref_peaks || has_ref_ts
                hot_start = true;
                if has_ref_peaks
                    disp(['     Loading XC sampling seed from case_name: '  config.ref_case_name]);
                    % Pull Sampling Seed
                    sampled_xc = cellfun(@(x) x(:, 1:4), ref_pf.Peaks.Default.('XC'), 'un', false);
                else
                    disp(['     Loading XC sampling seed from case_name (derived from Timeseries, reference has no Peaks): '  config.ref_case_name]);
                    % Pull Sampling Seed (Identity Columns Repeat Per Timestep, Same As Peaks Would Provide)
                    sampled_xc = cellfun(@(x) unique(x(:, 1:4), 'rows', 'stable'), ref_pf.Timeseries.Default.('XC'), 'un', false);
                end
                fprintf(1,'      Completion Progress: %3d%%\n',0);
                storm_data = storm.XC.Peaks.Default;
                % Populate Storm Data
                for lc=1:number_of_life_cyles
                    % Find Sampled Event On Storm Suite
                    stm_indx = arrayfun(@(x) find(cell2mat(storm_data(:, 1)) == x), sampled_xc{lc}(:, 1), 'un', true);
                    % Pull Storm Data
                    peaks_data = cellfun(@(x) [x(:, 1:4) config.storm_duration/24], storm_data(stm_indx, 2), 'un', false);
                    % Create LCs
                    project_forcing.Peaks.Default.('XC'){lc, 1} = [sampled_xc{lc}, cell2mat(peaks_data)]; % Headers: [ storm_IDs, intensity_bin, Sim_Year, yearly_ocurrance_order, SSL, Hm0, Tp, wDir, storm_duration ]
                    fprintf(1,'\b\b\b\b%3.0f%%',(100*(lc/number_of_life_cyles)));
                end
            else
                disp(['     Warning: ref_case_name ('  config.ref_case_name ') does not have XC sampling information...']);
                hot_start = false;
            end
        else
            hot_start = false;
        end
        if ~hot_start
            disp('     Sampling Extratropical Events .....');
            fprintf(1,'      Completion Progress: %3d%%\n',0);
            for lc=1:number_of_life_cyles
                %
                [sampled_xc{lc, 1},...
                    project_forcing.Peaks.Default.('XC'){lc, 1}] = ...
                    sample_xc_storm(cell2mat(storm.XC.Peaks.Default), simulation_years, XC_Nstm/XC_Nyrs);
                %
                fprintf(1,'\b\b\b\b%3.0f%%',(100*(lc/number_of_life_cyles)));
            end
        end
        % Replicate Storm Sampling With Storm Timeseries
        for lc=1:number_of_life_cyles
            if config.use_timeseries == 1
                % Build LCS Timeseries Dataset
                project_forcing.Timeseries.Default.('XC'){lc, 1} = timeseries_lc_creation(sampled_xc{lc, 1},...
                    storm.('XC').('Timeseries').('Default'));
            end
            % Create Alternate Datasets
            if config.create_wlp == 1
                project_forcing.Peaks.WLP.('XC'){lc, 1} = ...
                    sample_alternate_dataset(cell2mat(storm.XC.Peaks.WLP),...
                    sampled_xc{lc, 1}, 'XC', project_forcing.Peaks.Default.('XC'){lc, 1});
            end
            if config.create_whp == 1
                project_forcing.Peaks.WHP.('XC'){lc, 1} = ...
                    sample_alternate_dataset(cell2mat(storm.XC.Peaks.WHP),...
                    sampled_xc{lc, 1}, 'XC', project_forcing.Peaks.Default.('XC'){lc, 1});
            end
        end
    end

    %% SAMPLE TROPICAL CYCLONES
    if strcmp(storm_sampling,'CC')==1 || strcmp(storm_sampling,'TC')==1
        % Sample XC Storms According To Peak Responses
        if config.load_project_forcing == 1 && exist(mcs_ref_pth, 'file')
            % Prevent Multiple Loads
            ref_pf = load(mcs_ref_pth, 'project_forcing');
            ref_pf = ref_pf.project_forcing;
            % Check What Sampling Seed The Reference Case Actually Has
            has_ref_peaks = isfield(ref_pf,'Peaks') && isfield(ref_pf.Peaks,'Default') && isfield(ref_pf.Peaks.Default,'TC');
            has_ref_ts = isfield(ref_pf,'Timeseries') && isfield(ref_pf.Timeseries,'Default') && isfield(ref_pf.Timeseries.Default,'TC');
            if has_ref_peaks || has_ref_ts
                hot_start = true;
                if has_ref_peaks
                    disp(['     Loading TC sampling seed from case_name: '  config.ref_case_name]);
                    % Pull Sampling Seed
                    sampled_tc = cellfun(@(x) x(:, 1:4), ref_pf.Peaks.Default.('TC'), 'un', false);
                else
                    disp(['     Loading TC sampling seed from case_name (derived from Timeseries, reference has no Peaks): '  config.ref_case_name]);
                    % Pull Sampling Seed (Identity Columns Repeat Per Timestep, Same As Peaks Would Provide)
                    sampled_tc = cellfun(@(x) unique(x(:, 1:4), 'rows', 'stable'), ref_pf.Timeseries.Default.('TC'), 'un', false);
                end
                fprintf(1,'      Completion Progress: %3d%%\n',0);
                storm_data = storm.TC.Peaks.Default;
                % Populate Storm Data
                for lc=1:number_of_life_cyles
                    % Find Sampled Event On Storm Suite
                    stm_indx = arrayfun(@(x) find(cell2mat(storm_data(:, 1)) == x), sampled_tc{lc}(:, 1), 'un', true);
                    % Pull Storm Data
                    peaks_data = cellfun(@(x) [x(:, 1:4) config.storm_duration/24], storm_data(stm_indx, 2), 'un', false);
                    % Create LCs
                    project_forcing.Peaks.Default.('TC'){lc, 1} = [sampled_tc{lc}, cell2mat(peaks_data)]; % Headers: [ storm_IDs, intensity_bin, Sim_Year, yearly_ocurrance_order, SSL, Hm0, Tp, wDir, storm_duration ]
                    fprintf(1,'\b\b\b\b%3.0f%%',(100*(lc/number_of_life_cyles)));
                end
            else
                disp(['     Warning: ref_case_name ('  config.ref_case_name ') does not have TC sampling information...']);
                hot_start = false;
            end
        else
            hot_start = false;
        end
        if ~hot_start
            disp('     Sampling Tropical Events .....');
            fprintf(1,'      Completion Progress: %3d%%\n',0);
            for lc=1:number_of_life_cyles
            [sampled_tc{lc, 1},...
                project_forcing.Peaks.Default.('TC'){lc, 1}] = ...
                sample_tc_storm(cell2mat(storm.TC.Peaks.Default), simulation_years, prob_mass);
            %
            fprintf(1,'\b\b\b\b%3.0f%%',(100*(lc/number_of_life_cyles)));
            end
        end
        % Replicate Storm Sampling With Storm Timeseries
        for lc=1:number_of_life_cyles
            if config.use_timeseries == 1
                % Build LCS Timeseries Dataset
                project_forcing.Timeseries.Default.('TC'){lc, 1} = timeseries_lc_creation(sampled_tc{lc, 1},...
                    storm.('TC').('Timeseries').('Default'));
            end
            % Create Alternate Datasets
            if config.create_wlp == 1
                project_forcing.Peaks.WLP.('TC'){lc, 1} = ...
                    sample_alternate_dataset(cell2mat(storm.TC.Peaks.WLP),...
                    sampled_tc{lc, 1}, 'TC', project_forcing.Peaks.Default.('TC'){lc, 1});
            end
            if config.create_whp == 1
                project_forcing.Peaks.WHP.('TC'){lc, 1} = ...
                    sample_alternate_dataset(cell2mat(storm.TC.Peaks.WHP),...
                    sampled_tc{lc, 1}, 'TC', project_forcing.Peaks.Default.('TC'){lc, 1});
            end
        end
    end

    %% COMBINE TROPICAL AND EXTRATROPICAL SAMPLED STORMS
    if strcmp(storm_sampling,'CC')==1
        for lc=1:number_of_life_cyles
            % Combined Suite Of XC and TC for Simulation Period Per Each Modeled Life-Cycle
            project_forcing.Peaks.Default.('CC'){lc, 1} = sortrows([project_forcing.Peaks.Default.('TC'){lc, 1};...
                project_forcing.Peaks.Default.('XC'){lc, 1}],[3, 4, 2]);

            if whp_switch
                % Combined Suite Of XC and TC for Simulation Period Per Each Modeled Life-Cycle
                project_forcing.Peaks.WHP.('CC'){lc, 1} = sortrows([project_forcing.Peaks.WHP.('TC'){lc, 1};...
                    project_forcing.Peaks.WHP.('XC'){lc, 1}],[3, 4, 2]);
            end
            if wlp_switch
                % Combined Suite Of XC and TC for Simulation Period Per Each Modeled Life-Cycle
                project_forcing.Peaks.WLP.('CC'){lc, 1} = sortrows([project_forcing.Peaks.WLP.('TC'){lc, 1};...
                    project_forcing.Peaks.WLP.('XC'){lc, 1}],[3, 4, 2]);
            end
            % Combine Timseries Data
            if config.use_timeseries == 1
                project_forcing.Timeseries.Default.('CC'){lc, 1} = sortrows([project_forcing.Timeseries.Default.('TC'){lc, 1};...
                    project_forcing.Timeseries.Default.('XC'){lc, 1}],[3, 4, 2]);
            end
        end
    end
    disp(newline);

%% REMOVE ADDITIONAL FIELDS (IF NEEDED)
% Wave Height Priority
if whp_switch == 0
    % Remove Empty Field (Tropicals)
    project_forcing.Peaks = rmfield(project_forcing.Peaks,'WHP');
end
% Water Level Priority
if wlp_switch == 0
    % Remove Empty Field (Tropicals)
    project_forcing.Peaks = rmfield(project_forcing.Peaks,'WLP');
end

warning('on','all');
%% AUX FUNCTION: TIMESERIES LC CREATOR
    function lc_out = timeseries_lc_creation(sample_indx, storm)
        % Compute Stride To Make Data Hourly 
        hourly_stride = num2cell(1./(cellfun(@(x) x(1, 6), storm(:,2), 'un', true).*24));
        % Make storm data hourly 
        storm(:, 2) = cellfun(@(x, y) y(1:x:end,:), hourly_stride, storm(:, 2), 'un', false);
        % Indentify Storm IDs To Pull Hydrographs For
        [~, pull_indx] = arrayfun(@(x) ismember(x,...
            cell2mat(storm(:, 1))),...
            sample_indx(:, 1), 'un', true);
        % Pull Hydrographs
        stm_mat = cell2mat(storm(pull_indx, 2));
        % Pull And Reshape Sampling Index Information
        sample_indx_hyd = cell2mat(arrayfun(@(y, z) repmat(sample_indx(z, :), y, 1),...
            cellfun(@length, storm(pull_indx, 2)),...
            [1:length(sample_indx)]', 'un', false));
        % Create Timestep Arrays To Append
        stm_tstp = arrayfun(@(x) [0:x-1]',...
            cellfun(@length, storm(pull_indx, 2)),'un', false);
        % Build LCS Timeseries Dataset
        lc_out = [sample_indx_hyd, stm_mat(:, [1:4, 6]), cell2mat(stm_tstp)];
    end
%% AUX FUNCTION: SAMPLE ALTERNATE DATASETS
    function lcs_default = sample_alternate_dataset(storm_data, sampled_indx, storm_type, lcs_default)
        switch storm_type
            case 'XC'
                % Call Copula Sampler [ SSL, Hm0, Tp, wDir, storm_IDs ]
                [Y_WLP] = copula_sampler(storm_data(:,2:5), sampled_indx);
                % Store Results
                lcs_default(:, 5:8) = Y_WLP;
            case 'TC'
                % Get Row Index
                [~, bi] = ismember(sampled_indx(:, 1), storm_data(:, 1));
                % Pull WHP Dataset For Sampled Storms
                lcs_default(bi, 5:end) = storm_data(bi, [2:5,7]);
        end
    end
end