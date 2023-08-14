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
name_prefix = config.name_prefix;
% Define CHS_Data file (.zip, .mat)
chs_zip = config.chs_zip;
% Define CHS_Data Fiel Extension
[~,~,fext] = fileparts(config.chs_zip);
% Determine Storm Data Source
chs_type_case = find(cell2mat(cellfun(@(x) contains(fext,x),{'.zip','.mat'},'un',false)) == 1);
% Define Probability Masses Source
pm_file = config.prob_mass_source;
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

%% Check If This Is Fresh Run Or New Case
% Define Filename Prefix Based On Data Source
if ~isempty(sp_ID)
    file2look = [name_prefix '_SP*']; % CHS/CSTORM Related Data
else
    file2look = [name_prefix '*']; % External Model
end
% Scan Project Directory For Checkpoints
h5_list = dir(file2look);
% Grab "storm" Filename
storm_data_filename = h5_list(~contains({h5_list.name},{'raw_files'}));
% Grab "CHS_Data" Filename
chs_data_filename = h5_list(contains({h5_list.name},{'raw_files'}));
% Create New Case For Current Transect
if ~isempty(storm_data_filename) % New Case Run
    % Build File Path
    file2look = fullfile(storm_data_filename.folder,storm_data_filename.name); % storm, prob_mass
    file2look_2 = fullfile(chs_data_filename.folder,chs_data_filename.name); % CHS_Data
    % Load Storm File
    load(file2look, 'storm', 'prob_mass');
    load(file2look_2, 'CHS_Data');
    % Verify Contents And Requested Config (chk needs to be 1 after all checks)
    % Check Storm Sampling
    storm_level_1 = fieldnames(storm);
    % Check Timeseries & Peaks
    storm_level_2 = fieldnames(storm.(storm_level_1{1}));
    storm_level_2 = storm_level_2(contains(storm_level_2,{'Peaks','Timeseries'}));
    % Verify Storm Sampling
    switch storm_sampling
        case 'CC'
            chk1 = contains('TC',storm_level_1) && contains('XC',storm_level_1);
        case 'XC'
            chk1 = contains('XC',storm_level_1);
        case 'TC'
            chk1 = contains('TC',storm_level_1);
    end
    % Verify Peaks
    if use_peaks == 1
        % Check If Peaks Exist In storm
        chk2 = contains('Peaks',storm_level_2);
        % If Peaks Exist Then Verify Datasets
        if chk2
            % Grab Field names For Peaks
            storm_level_3 = fieldnames(storm.(storm_level_1{1}).('Peaks'));
            % Verify WLP
            if create_wlp == 1
                chk4 = contains('WLP',storm_level_3);
                % If WLP dDoes Not Exist
                if ~chk4
                    % Check Failed
                    chk2 = false;
                end
            end
            % Verify WHP
            if create_whp == 1
                chk5 = contains('WHP',storm_level_3);
                % If WHP dDoes Not Exist
                if ~chk5
                    % Check Failed
                    chk2 = false;
                end
            end
        end
    else
        chk2 = false;
    end
    % Verify Timeseries
    if use_timeseries == 1
        % Check If Timeseries Exist In storm
        chk3 = contains('Timeseries',storm_level_2);
    end
    % Determine If Pre-Processing Needs To Be Run
    if sum([chk1, chk2, chk3]) == 1 + sum([use_timeseries, use_peaks])
        % .mats Have The Necessary information For Requested Config. Do Nothing.
        disp(['Project forcing detected. Loading processed SP data....']);
    else % .mats Do Not Have Required Data For Requested Config
        % Delete Loaded Vars
        clearvars('storm','prob_mass','CHS_Data');
        % Set file2look To Empty
        file2look = [];
    end
    % Verify Minimum File Requirement For CHS_Data
    if exist('CHS_Data','var')
        [min_file_req, ~, ~] = minimum_file_requirement_check(chs_files_2_convert_paths, chs_files_2_convert,....
            storm_sampling, use_peaks, use_timeseries);
        % Compare With Loaded Dataset
        if length(CHS_Data) < min_file_req
            file2look = [];
        end
    end
    if isempty(file2look)
        % Display MEssage To User
        disp(['Project forcing does not have neccesary dependencies. Restarting import process....']);
    else
        % Clean-up Fields If Needed
        % Storm Type
        switch storm_sampling
            case 'TC'
                if isfield(storm,'XC')
                    storm = rmfield(storm,'XC');
                end
            case 'XC'
                if isfield(storm,'TC')
                    storm = rmfield(storm,'TC');
                end
        end
        % Get Latest Storm Sampling Type
        storm_level_1 = fieldnames(storm);
        % For Each Storm Type
        for kk = 1:length(storm_level_1)
            % Timeseries
            if use_timeseries == 0 &&  isfield(storm.(storm_level_1{kk}),'Timeseries')
                storm.(storm_level_1{kk}) = rmfield(storm.(storm_level_1{kk}),'Timeseries');
            end
            % Peaks
            if use_peaks == 0 && isfield(storm.(storm_level_1{kk}),'Peaks')
                storm.(storm_level_1{kk}) = rmfield(storm.(storm_level_1{kk}),'Peaks');
            end
            if use_peaks == 1 && isfield(storm.(storm_level_1{kk}),'Peaks')
                % WLP
                if create_wlp == 0 && isfield(storm.(storm_level_1{kk}).('Peaks'),'WLP')
                    storm.(storm_level_1{kk}).('Peaks') = rmfield(storm.(storm_level_1{kk}).('Peaks'),'WLP');
                end
                % WHP
                if create_whp == 0 && isfield(storm.(storm_level_1{kk}).('Peaks'),'WHP')
                    storm.(storm_level_1{kk}).('Peaks') = rmfield(storm.(storm_level_1{kk}).('Peaks'),'WHP');
                end
            end
        end
    end
else
    file2look = [];
end

%% CONVERT AND PROCESS CHS_Data
% Execute Pre-Processing If Needed
if isempty(file2look) % Process SP Data
    % Determine Minimum File Requirement For config
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
    switch chs_type_case
        case 1 % Zip Folder -> Native CHS Data
            % Remove Unwanted Storm Types
            if strcmp(storm_sampling,'XC')
                chs_files_2_convert_paths = chs_files_2_convert_paths(~contains(chs_files_2_convert,'TC'));
                chs_files_2_convert = chs_files_2_convert(~contains(chs_files_2_convert,'TC'));
            end
            if strcmp(storm_sampling,'TC')
                chs_files_2_convert_paths = chs_files_2_convert_paths(~contains(chs_files_2_convert,'XC'));
                chs_files_2_convert = chs_files_2_convert(~contains(chs_files_2_convert,'XC'));
            end
            % Append Filenames With Paths
            full_file_path = cellfun(@(x,y) [x filesep y],chs_files_2_convert_paths,chs_files_2_convert,'un',false);
            % Print Status
            disp('Begin CHS h5 file conversion....');
            % Convert CHS Data
            CHS_Data = call_chs_h5_converter(full_file_path);
            % Export Data
            save([name_prefix '_SP' num2str(config.sp_ID) '_raw_files.mat'],'CHS_Data');
        case 2
            % Try to load CHS_Data From Provided File
            try
                % Load CHS_Data
                load(chs_zip,'CHS_Data');
            catch
                % CHS_Data Was Not Found
                error(['Error ID: 002 | call_chs_data_formater.naming_mismatch | Failed to load variable ''CHS_Data'' from ' chs_zip]);
            end
            % Export Data Based On Case
            if ~isempty(sp_ID)
                % Export Data
                save([name_prefix '_SP' num2str(config.sp_ID) '_raw_files.mat'],'CHS_Data');
            else % External Model (No SP Associated)
                % Export Data
                save([name_prefix '_raw_files.mat'],'CHS_Data');
            end
    end


    %% FORMAT AND INSPECT CHS TROPICALS CYCLONES PEAKS DATA
    %{
    Extracts SWL, Hm0, Tp And wave direction from CHS "Peaks" storm files.
    %}
    if contains(storm_sampling,{'TC','CC','TS'})
        switch chs_type_case
            case 1
                % Load Storm Probability Massess
                [prob_mass.Param, prob_mass.TC_SRR,...
                    prob_mass.TC_Freq, prob_mass.dist, prob_mass.TotalFreq,...
                    prob_mass.smpl0, prob_mass.smpl1] = csh_probability_mass_loader(pm_path, region,sp_ID);
            case 2
                try
                    % Load CHS_Data
                    load(pm_file,'prob_mass');
                catch
                    % prob_mass Was Not Found
                    error(['Error ID: 002 | call_chs_data_formater.naming_mismatch | Failed to load variable ''prob_mass'' from ' pm_file]);
                end
        end
        % Format And Inspect Storm Peaks Files
        [config, storm.('TC'), storm.('TC').removed_storms, ~, ~, prob_mass] = call_chs_storm_quality_check(config, CHS_Data, prob_mass, 'TC');
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
        storm = chs_timeseries_peak_replacer(storm);
    end

    %% EXPORT PROJECT CONFIGURATION FILE & FORMATTED CHS DATA
    if ~isempty(sp_ID)
        % Export Project Forcing
        save([name_prefix '_SP' num2str(config.sp_ID) '.mat'], 'storm', 'prob_mass');
    else
        % Export Project Forcing
        save([name_prefix '.mat'], 'storm', 'prob_mass');
    end
    save([project_name filesep struc_id filesep case_name filesep project_name '_' struc_id '_' config.case_name '_config_file.mat'],...
        'config');
end
end