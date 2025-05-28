function [storm, CHS_Data, prob_mass, config] = call_chs_data_formater(config)
%{
    %% DESCRIPTION
        This function is responsible for reading, formatting and screening
        Coastal Hazards System (CHS) .h5 storm "Peaks" & "Timeseries"
        files. Additionally, it loads and formats TC's probability masses
        if supported by library. 
    
    %% INPUTS
        config.
            chs_files_2_convert: CHS files to convert. | cell | 1 x number_of_files (max 8)
            chs_files_2_convert_path: CHS files to convert path. | cell | 1 x number_of_files (max 8)
            use_timeseries: Enables the use of timeseries files. (0/1) | double | 1 x 1 
            storm_sampling: Storm sampling type.('TC','XC' or 'CC') | char | 1 x 2 
            wlp_switch: Enables the creation of Water Level Priority | double | 1 x 1
                        (WLP) dataset. Reuqires timeseries files. (0/1)
            whp_switch: Enables the creation of Wave Height Priority | double | 1 x 1
                        (WHP) dataset. Reuqires timeseries files. (0/1)
            project_name: CAST project name.(No spaces) | char | 1 x any_length 
            struc_id: CAST project structure/transect ID.(No spaces) | char | 1 x any_length 
        
    %% OUTPUTS
        Additional to data outputs 2 files are exported from this function.
        *_CHS_raw_files.mat: MAT-file containing converted CHS files 
                             with no screening applied to them.
        *_CHS_"region"_SP####.mat: MAT-file containing formated and  
                                   screened CHS peaks data.
        
        config.      
            sp_depth: CHS savepoint depth extracted from .h5 attributes. | double | 1 x 1
            sp_ID: CHS ADCIRC savepoint ID. | double | 1 x 1
            region: CHS file region. | char | 1 x 1
    
        storm: Data structure containing formated and screened CHS storm  | struc | size_varies
               peaks data. First level of data structure can have 'XC'
               and/or 'TC'. This depends on user provided CHS data files.
               Storm peaks datasets provided (Maxima, WLP, WHP) have the
               same format 4x1 matrix with cols: SWL,Hm0,Tp, wave dir. 
               Additional field labeled "removed_storms" is a structure
               containing removed storm IDs fore ach dataset. WHP and WLP
               datasets are optional and require the use_timeseries switch
               to be enabled in conjunction with WLP_switch/WHP_switch.
    
        "storm" Fields:
            storm.(storm_type).
                Maxima: Dataset is built using only CHS "Peaks"files.    | double | 1 x 4
                         ADCIRC (SWL) peak and STWAVE (Hm0,TP,wave dir)   
                         are matched together for each storm ID.  
 
                WLP: Dataset is built using ADCIRC "Peaks" file and 
                      STWAVE timeseries file to match peak water level
                      with its corresponding wave. A time window of +/- 3
                      hours is used to find nearest STWAVE data point. In
                      the case that ADCIRC peak resides outside the
                      temporal range of STWAVE timeseries output then a
                      "new" peak water level is computed from ADCIRC's
                      timeseries output by matching timesteps with STWAVE
                      and finding the maximum of the resulting water level
                      timeseries.
    
                WHP: Dataset is built using STWAVE "Peaks" file and 
                      ADCIRC timeseries file to match peak wave height
                      with its corresponding water level. A time window of +/- 3
                      hours is used to find nearest ADCIRC data point. In
                      the case that STWAVE model output offers water level
                      output, then that will be used instead.
 
                removed_storms - Structure containing removed storm IDs for | struc | size_varies
                                 each dataset in "storm". 
      
    %% DEV SIGNATURE
    Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}
%% GRAB INPUT FROM "config"
%{
        This section meant to provide an easy way to make changes to config
        variable calls without having to alter core code.
%}
% Define CHS Files
chs_files_2_convert = config.chs_files_2_convert(:,2);
% Define CHS Paths
chs_files_2_convert_paths = config.chs_files_2_convert(:,1);
% Use Peaks Switch
use_peaks = config.use_peaks;
% Use Timeseries Switch
use_timeseries = config.use_timeseries;
% Storm Sampling
storm_sampling = config.storm_sampling;
% Define File Name Prefix
name_prefix = fullfile(config.outfolder, config.name_prefix);
% Define CHS_Data file (.zip, .mat)
chs_zip = config.chs_zip;
% Define CHS_Data Fiel Extension
[~,~,fext] = fileparts(config.chs_zip);
% Deifne Save Point ID
sp_ID = config.sp_ID;
% Define Region
region = config.region;
% Deifne WLP & WHP Switches
create_wlp = config.create_wlp;
create_whp = config.create_whp;
% Project Name
project_name = config.project_name;
% Transect Id
struc_id = config.struc_id;
% Define Case  Name
case_name = config.case_name;
% Probability Masses
pm_path = config.prob_mass_source;
% Grab Temp Folder For Simulation
temp_path = config.temp_path;
% Grid File
grid_file = config.chs_grid_file_source;

%% CHECK IF PROCESSED SAVEPOINT DATA EXIST FOR TRANSECT (struc_id)
% Build File Listing According To File Extension
switch fext
    case '.zip'
        % --------- Search and Load For Expected StormSim Simulation Files In  ------------
        % Define Filename Prefix Based On Data Source
        file_search = [name_prefix '_SP*']; % CHS/CSTORM Related Data
        % Scan Project Transect Directory For Processing Checkpoints
        h5_list = dir(file_search);
        % Evaluate File Existance
        if isempty(h5_list)
            hotstart_fail = true;
            chs_data_filename = [];
        else
            % Grab "storm" Filename
            if any(~contains({h5_list.name},{'raw_files'}))
                storm_data_filename = fullfile(h5_list(~contains({h5_list.name},{'raw_files'})).folder,...
                    h5_list(~contains({h5_list.name},{'raw_files'})).name);
                % Files Detected
                hotstart_fail = false;
                % Load Data
                load(storm_data_filename, 'storm', 'prob_mass');
            else
                % Files Not Detected
                hotstart_fail = true;
            end
            % Grab CHS_Data Filename
            if any(contains({h5_list.name},{'raw_files'}))
                chs_data_filename =  fullfile(h5_list(contains({h5_list.name},{'raw_files'})).folder,...
                    h5_list(contains({h5_list.name},{'raw_files'})).name);
                % Load Data
                load(chs_data_filename, 'CHS_Data');
            else
                CHS_Data = [];
            end
        end
    case '.mat'
        storm_data_filename = chs_zip; % mat file with "storm" variable
        load(storm_data_filename,'storm');
        load(pm_path, 'prob_mass');
        CHS_Data = [];
        % Files Detected
        hotstart_fail = false;
end

%% EVALUATE DATASET FOR "HOTSTART"
% Create New Case For Current Transect
if ~hotstart_fail % New Case Run
    % --------- Verify If "storm" Contents Meet "config" Request ----------
    % Check Storm Sampling
    storm_level_1 = fieldnames(storm);
    % Check Timeseries & Peaks
    storm_level_2 = fieldnames(storm.(storm_level_1{1}));
    storm_level_2 = storm_level_2(contains(storm_level_2,{'Peaks','Timeseries'}));
    % Verify Storm Sampling
    switch storm_sampling
        case 'CC'
            % Verify Dataset Complies With User Specifications
            stm_type_chk = contains('TC',storm_level_1) && contains('XC',storm_level_1);
        case 'TC'
            % Verify Dataset Complies With User Specifications
            stm_type_chk = contains(storm_sampling, storm_level_1);
            % Remove Additional Field If Needed
            if isfield(storm, 'XC')
                storm = rmfield(storm,'XC');
            end
        case 'XC'
            % Verify Dataset Complies With User Specifications
            stm_type_chk = contains(storm_sampling, storm_level_1);
            % Remove Additional Field If Needed
            if isfield(storm, 'TC')
                storm = rmfield(storm,'TC');
            end
    end
    % Verify Peaks
    if contains( {'Peaks'}, storm_level_2)
        % Verify WLP
        [wlp_chk, storm] = alternate_dataset_check(storm, storm_level_1,...
            'WLP', create_wlp);
        % Verify WHP
        [whp_chk, storm] = alternate_dataset_check(storm, storm_level_1,...
            'WHP', create_whp);
        % Define Loading Flag
        peaks_chk = wlp_chk & whp_chk;
    else % if use_peaks == 0 && ~contains('Peaks') || use_peaks == 1 && ~contains('Peaks')
        if use_peaks == 0
            peaks_chk = true;
        else
            peaks_chk = false;
        end
    end
    % Verify Timeseries
    if contains({'Timeseries'}, storm_level_2)
        % Define Timeseries Loading Flag
        timeseries_chk = true;
        % Remove Timeseries From Loaded Data If User Specified
        if use_timeseries == 0
            for ii = storm_types % Loop Across Storm Types
                storm.(ii{:}).Timeseries = rmfield(storm.(ii{:}), 'Timeseries');
            end
        end
    else % Define Flag According To Case
        if use_timeseries == 0
            timeseries_chk = true;
        else
            timeseries_chk = false;
        end
    end
    % Determine If Pre-Processing Needs To Be Run
    if stm_type_chk && peaks_chk && timeseries_chk
        % .mats Have The Necessary information For Requested Config. Do Nothing.
        disp('Project forcing detected. Loading processed SP data....');
        % hotstrat Conditions Have Been Met
        hotstart_fail = false;
    else % .mats Do Not Have Required Data For Requested Config
        % Delete Loaded Vars
        clearvars('storm','prob_mass');
        % Set file2look To Empty
        hotstart_fail = true;
        % Display Message To User
        disp('Project forcing does not have neccesary dependencies. Restarting import process....');
    end
else % StormSim Processing Checkpoint Files Not Found
    % Set Processing Flag to Empty.
    hotstart_fail = true;% Empty -> Triggers h5 conversion and QA/QC Process
end

%% STORMSIM COLDSTART - STORM SUITE QA/QC AND FORMATTING
% Execute Pre-Processing If Needed
if hotstart_fail && strcmp(fext,'.zip')% StormSim needs to create and process storm datasets.
    % Determine Minimum File Requirement For config
    % Total Files Needed = storm_types * Data_type * 2 (comes from models (ADCIRC + Wave))
    % Storm_types: XC and/or TC | Data_type: Peaks and/or Timeseries
    % Min/Max files: 2 (1 storm_type & 1 data_type) / 8 ( 2 storm_types & 2 Data_types)
    [min_file_req, chs_files_2_convert,...
        chs_files_2_convert_paths] = minimum_file_requirement_check(chs_files_2_convert_paths, chs_files_2_convert,....
        storm_sampling, use_peaks, use_timeseries);
    % Throw Error If Minimum Is Not Met
    if length(chs_files_2_convert)~=min_file_req
        error('Error ID: 001 | call_chs_data_formater.missing_dependency | Minimum CHS storm data requirements not met for specified inputs.');
    end

    %% CONVERT CHS DATA
    %{
        Run provided CHS h5 files through h5 to MATLAB converter.
        Additionally, extract ADCIRC save point: depth, region, ID.
        Converted CHS data gets exported as .mats in CHS_Data folder.
        Exported .mat file naming convetion is tied to ADCIRC file region
        and save point ID. 
    %}
    % Evaluate Case Based On File Type
    if isempty(chs_data_filename)
        % Remove Unwanted Storm Types
        switch storm_sampling
            case 'XC'
                chs_files_2_convert_paths = chs_files_2_convert_paths(contains(chs_files_2_convert, {'XC', 'XH'}));
                chs_files_2_convert = chs_files_2_convert(contains(chs_files_2_convert, {'XC', 'XH'}));
            case 'TC'
                chs_files_2_convert_paths = chs_files_2_convert_paths(contains(chs_files_2_convert, {'TC', 'TS'}));
                chs_files_2_convert = chs_files_2_convert(contains(chs_files_2_convert, {'TC', 'TS'}));
        end
        % Append Filenames With Paths
        full_file_path = cellfun(@(x,y) [x filesep y],chs_files_2_convert_paths,chs_files_2_convert,'un',false);
        % Print Status
        disp('Begin CHS h5 file conversion....');
        % Convert CHS Data
        CHS_Data = call_chs_h5_converter(full_file_path);
        % Export Data
        save([name_prefix '_SP' num2str(config.sp_ID) '_raw_files.mat'],'CHS_Data');
        % Remove Temp Dir
        if ~isempty(temp_path)
            rmdir(temp_path,'s');
        end
    else  % chs_data_filename already exists
        % Load CHS_Data From Provided File
        load(chs_data_filename,'CHS_Data');
    end

    %% FORMAT AND INSPECT CHS TROPICALS CYCLONES PEAKS DATA
    %{
    Extracts SWL, Hm0, Tp And wave direction from CHS "Peaks" storm files.
    %}
    if contains(storm_sampling,{'TC','CC','TS'})
        % Load Storm Probability Massess
        [prob_mass.Param, prob_mass.TC_SRR,...
            prob_mass.TC_Freq, prob_mass.TotalFreq,...
            prob_mass.smpl1, prob_mass.smpl2, prob_mass.smpl3] = chs_probability_mass_loader(pm_path, grid_file, region,sp_ID);
        % Format And Inspect Storm Peaks Files
        [config, storm.('TC'), storm.('TC').removed_storms, ~, ~, prob_mass] = call_chs_storm_quality_check(config, CHS_Data, prob_mass, 'TC');
        % Check For Missing PM's (Something wrong in PM's)
        if isempty(prob_mass.TC_Freq) && strcmp(storm_sampling, 'TC')
            error('Probability masses came out empty. Please verify path on input file.');
        end
    else
        prob_mass = [];
    end

    %% FORMAT CHS EXRTATROPICALS CYCLONES DATA
    %{
    Extracts SWL, Hm0, Tp And wave direction from CHS "Peaks" storm files.
    %}
    if contains(storm_sampling,{'XC','CC'})
        % Format And Inspect Storm Peaks Files
        [config, storm.('XC'), storm.('XC').removed_storms, config.Nyrs_XC, config.Nstm_XC, ~] = call_chs_storm_quality_check(config, CHS_Data, [], 'XC');
        % Add Fields To Storm
        storm.('XC').Nyrs_XC = config.Nyrs_XC;
        storm.('XC').Nstm_XC = config.Nstm_XC;
    end

    %% TIMESERIES SWL PEAK REPLACER
    if use_timeseries == 1 && use_peaks == 1
        [storm, proxy] = chs_timeseries_peak_replacer(storm);
    end

    %% EXPORT PROJECT CONFIGURATION FILE & FORMATTED CHS DATA
    % Export Project Forcing
    save([name_prefix '_SP' num2str(config.sp_ID) '.mat'], 'storm', 'prob_mass');
    % Append Storm Data Dependent Fields To Configuration File
    save(fullfile(config.outfolder, project_name, struc_id, case_name,[ project_name '_' struc_id '_' config.case_name '_config_file.mat']),...
        'config', '-append');
elseif hotstart_fail && strcmp(fext,'.mat')
    % Initialize Error Message
    error_msg = "Error: Provided storm data failed to meet user request on configuration file. inspection failed on:";
    % Add Storm Type Error Message
    if ~stm_type_chk
        error_msg = error_msg + newline + "Missing storm data per requested storm sampling.";
    end
    % Add Peaks Dataset Error Message
    if ~peaks_chk
        error_msg = error_msg + newline + "Missing peaks data, make sure you have the requested datasets (Default, WLP, WHP).";
    end
    % Add Timeseries Dataset Error Message
    if ~timeseries_chk
        error_msg = error_msg + newline + "Missing timeseries data.";
    end
    % Display error Message
    error(error_msg);
else % StormSim Processing Checkpoint Met Requirements. Use Loaded Data
    % Remove Temp Folder
    if exist(temp_path,'dir')
        rmdir(temp_path,'s');
    end
end

%% AUX FUNCTIONS
    function [chk_flag, storm] = alternate_dataset_check(storm, storm_types,...
            dataset_name, dataset_switch)
        % Grab Field names For Peaks
        storm_level_3 = fieldnames(storm.(storm_types{1}).('Peaks'));
        %
        if contains(dataset_name, storm_level_3)
            % Set Flag To True
            chk_flag = true;
            % Remove Field If Requested
            if dataset_switch == 0
                for jj = storm_types % Loop Across Storm Types
                    storm.(jj{:}).Peaks = rmfield(storm.(jj{:}).Peaks, 'WLP');
                end
            end
        else % WLP Does Not Exist In Peaks
            if dataset_switch == 0 % User Did Not Request WLP
                chk_flag = true; % Pass
            else % User Requested WLP
                chk_flag = false; % Fail, Need to create WLP
            end
        end
    end
end