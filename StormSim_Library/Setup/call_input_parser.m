function [config, structure] = call_input_parser(input_filename)
%{
    %% DESCRIPTION
    This function parses StormSim's project input file and creates "config"
    data structure. Variable names are controlled by symbols in "str_ref"
    column.
    
    %% INPUTS
    fname: StormSim project input file name.
    
    %% OUTPUTS
    config: MATLAB data structure containing input file data parsed out as
    individual strucutre fields.
    
    %R DEV SIGNATURE
    Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}

%% GRAB AND DEFINE INPUTS
% Define Symbol Column Header (Serves As Anchor Points For Searches)
str_ref = 'Model Variable Symbol';
% Define Anchor Point Offset (Location Of First Data Point)
anchor_offset = 1;
next_tbl_offset = 3;
% Read StormSim Project Input File
input_file = readcell(input_filename);
% Add Filename To Config
config.stormsim_input_file = input_filename;
% Add Gravity Constant
config.gravity_constant = 9.80665; % m/s^2

%% PARSE INPUT FILE AND CREATE CONFIG STRUCTURE
% Find Row And Column Index For "str_ref" In "input_file"
[row_indx,col_indx] = find(cell2mat(cellfun(@(x) strcmp(x,str_ref),input_file,'un',false))==1);
[row_indx2,col_indx2] = find(cell2mat(cellfun(@(x) strcmp(x,'Value'),input_file,'un',false))==1);
% Loop Through Found Instances (Matched Cases Represent Input Tables)
for ii= 1:length(row_indx)
    % Extract Input Table
    if ii == length(row_indx2)
        helper_var = input_file(row_indx(ii)+anchor_offset:end,col_indx(ii):col_indx2(ii));
        helper_var = helper_var(sum(cellfun(@isempty,helper_var),2)<4, :);
    else
        if row_indx(ii+1) == row_indx(1)
            helper_var = input_file(row_indx(ii)+anchor_offset:end,col_indx(ii):col_indx2(ii));
        else
            helper_var = input_file(row_indx(ii)+anchor_offset:row_indx(ii+1)-next_tbl_offset,col_indx(ii):col_indx2(ii));
        end
    end
    % Remove Is Missing
    helper_var = helper_var(~cell2mat(cellfun(@(x) isa(x,'missing'),helper_var(:,1),'UniformOutput',false)),:);
    % Fill Others
    helper_var(cell2mat(cellfun(@(x) isa(x,'missing'),helper_var(:,end),'UniformOutput',false)),end) = {''};
    % Loop Through Input Table Items And Create Config
    for jj = 1:size(helper_var, 1)
        % Create "config" Structure Field
        config.(helper_var{jj,1}) = helper_var{jj,end};
    end
end
% Project Name
project_name = config.project_name;
% Transect Id
struc_id = config.struc_id;
% Case Name
case_name = config.case_name;
% Outfolder
out_folder = config.outfolder;
% Sim Directory
sim_dir = fullfile(out_folder, project_name, struc_id);
% Make Temp Path Empty
config.temp_path = '';
% OutDir
case_folder = fullfile(out_folder, project_name, struc_id, case_name);
% Project And Transect ID Folder And Subfolder
if ~exist(case_folder,'dir')
    mkdir(case_folder);
end
% Make Sure Specified File Exist
if ~exist(config.chs_zip, 'file') % Valid Zip Folder Detected
    error('Error: Provided file through config.chs_zip not found. Please verify path...');
end

%% VERIFY IF STORMSIM FILES ALREADY EXIST FOR CURRENT SIMULATION
% Check For StormSim Files On Transect Directory
ss_files_list = dir(fullfile(sim_dir, '*_SP*.mat')); % Search For Expected StormSim Naming Convention On Project Folder
% If Any File Is Found Try Loading To Save Processing Time
if ~isempty(ss_files_list)
    ss_storm = ss_files_list(~contains({ss_files_list.name},{'raw_files'})); % Existing storm .mat created by StormSim
    ss_raw = ss_files_list(contains({ss_files_list.name},{'raw_files'})); % Existing CHS_Data .mat created by StormSim
    % Check For StormSim Processed CHS_Data .mat
    if ~isempty(ss_raw)
        % Load CHS_Data
        load(fullfile(ss_raw.folder, ss_raw.name), 'CHS_Data');
        % Get File Names From Loaded Data Structure
        [file_list_paths, file_list, ~] = ...
            cellfun(@(x) fileparts(x), {CHS_Data.Filename}, 'un', false);
        % Append File Extension
        file_list = cellfun(@(x) [x '.h5'],...
            file_list, 'un', false);
        % Write Out Files On Loaded Data
        config.chs_files_2_convert = [file_list_paths(:), file_list(:)];
        % Grab CHS Study Details
        [config.region, config.sp_ID, config.sp_ID_wave] = get_study_details(file_list);
        % Create String Pattern For Naming Convention
        config.name_prefix = fullfile(sim_dir,...
            [project_name '_' struc_id '_' config.region]);
    end
    % Check For StormSim Processed storm .mat
    if ~isempty(ss_storm)
        % Load storm
        load(fullfile(ss_storm.folder, ss_storm.name), 'storm', 'prob_mass');
        % Grab Extratropical Storm Fields If Exist
        if isfield(storm,'XC')
            % Grab XC_Nyrs & XC_Nstm
            config.Nyrs_XC = storm.('XC').('Nyrs_XC');
            config.Nstm_XC = storm.('XC').('Nstm_XC');
        end
    end
else
    ss_storm = [];
    ss_raw = [];
end
% Get File Extension For "config.chs_zip"
[~,fname, fext] = fileparts(config.chs_zip);
% Get config.chs_zip Data Type
data_case = identify_storm_data_type(config.chs_zip);

%% GRAB CHS_DATA DETAILS
% This code section is executed if user provided a "CHS_Data" type dataset
% through config.chs_zip. This can be a .mat file or .zip folder (with HDF5 files).
if isempty(ss_raw) && strcmp(data_case, 'chs_data')
    switch fext
        case '.mat'
            % Load CHS_Data
            load(config.chs_zip, 'CHS_Data');
            % Get File Names From Loaded Data Structure
            [file_list_paths, file_list, ~] = ...
                cellfun(@(x) fileparts(x), {CHS_Data.Filename}, 'un', false);
            % Append File Extension
            file_list = cellfun(@(x) [x '.h5'],...
                file_list, 'un', false);
            % Write Out Files On Loaded Data
            config.chs_files_2_convert = [file_list_paths(:), file_list(:)];
            % Grab CHS Study Details
            [config.region, config.sp_ID, config.sp_ID_wave] = get_study_details(file_list);
            % Create String Pattern For Naming Convention
            config.name_prefix = fullfile(sim_dir,...
                [project_name '_' struc_id '_' config.region]);
            % Copy File To Add Naming Convention
            copyfile(config.chs_zip, [config.name_prefix '_SP' num2str(config.sp_ID) '_raw_files.mat']);
        case '.zip'
            % Create Temp Folder
            if exist('Temp','dir')==7
                % Determine How Many Temp Dirs Are Present
                temp_list = dir('Temp*');
                % Build Temp Folder Name
                config.temp_path = ['Temp_' num2str(length(temp_list) + 1)];
                % Assign Variable For Convenience
                temp_path = config.temp_path;
                % Create Temp Folder
                mkdir(temp_path);
            else % Temp Does Not Exist
                config.temp_path = 'Temp';
                temp_path = config.temp_path;
                mkdir('Temp');
            end
            % Decompress Zip Folder
            unzip(config.chs_zip,temp_path);
            % Scan Unzip Directory
            temp_dir = dir([temp_path filesep '**' filesep '*.h5']);
            % Add Field To config
            config.chs_files_2_convert = sortrows([{temp_dir.folder}', {temp_dir.name}'],2,'ascend');
            % Grab ADCIRC Reference File
            CHS_file_ref = config.chs_files_2_convert(contains(config.chs_files_2_convert(:,2), {'ADCIRC'}), :);
            % Try And Find SP Depth On HDF5 Attributes
            try
                % Get H5 Info
                sp_depth = h5info(fullfile(CHS_file_ref{1, 1}, CHS_file_ref{1, 2}));
                % Need To Access Attributes Of First Storm
                sp_depth = sp_depth.Groups.Attributes;
                % Grab Save Point Depth
                config.chs_sp_depth = str2double(sp_depth(strcmp({sp_depth.Name},{'Save Point Depth'})).Value);
            catch
                disp('Warning: could not find ADCIRC savepoint depth on h5 attributes. Using value on config file....');
            end
            % Grab File List To Extract Study Details From Naming
            file_list = config.chs_files_2_convert(:,2);
            % Grab CHS Study Details
            [config.region, config.sp_ID, config.sp_ID_wave] = get_study_details(file_list);
            % Create String Pattern For Naming Convention
            config.name_prefix = fullfile(sim_dir,...
                [project_name '_' struc_id '_' config.region]);
    end
end

%% GRAB STORM DETAILS
% This code section is executed if user provided a "storm" type dataset
% through config.chs_zip. "storm" meaning a dataset containing surge and
% wave data for each event matched in time.
if isempty(ss_storm) && strcmp(data_case, 'storm_data')
    % Add CHS Files 2 Convert In Cell Array
    config.chs_files_2_convert = [];
    % Try To Find Savepoint ID On Filename
    if contains(fname, {'SP'})
        sp_id = strsplit(fname, {'_', 'SP'});
        config.sp_ID = str2double(sp_id{end});
    else
        % Define Save Point ID As Empty
        config.sp_ID = [];
    end
    config.sp_ID_wave = []; % Not important
    % Try And Find CHS Region On File Name
    if contains(fname, {'CHS-'})
        chs_region = strsplit(fname, '_');
        chs_region = chs_region{contains(chs_region, {'CHS-'})};
        config.region = chs_region;
    else
        chs_region = 'Custom_Modeling';
        config.region = [];% User Needs To Provide Prob Mass
    end
    % Make Sure prob_mass Is .mat For Custom modeling
    if (isempty(config.sp_ID) || isempty(config.chs_region)) && exist(config.prob_mass_source, 'dir') == 7 % User Provided Path As prob_mass
        error('Error: Could not parse save point ID and/or CHS study from provided file (config.chs_zip). Please provided a corresponding .mat with prob_mass variable on config.prob_mass_source.');
    end
    % Load File
    load(config.chs_zip, 'storm');
    % Validate "storm" dataset
    storm_validation(config, storm);
    % Grab Extratropical Storm Fields If Exist
    if isfield(storm,'XC')
        % Grab XC_Nyrs & XC_Nstm
        config.Nyrs_XC = storm.('XC').('Nyrs_XC');
        config.Nstm_XC = storm.('XC').('Nstm_XC');
    end
    % Handle Prob Mass
    if strcmp(storm_sampling, 'XC')
        prob_mass = [];
    elseif isfolder(config.prob_mass_source)
        [prob_mass.Param, prob_mass.TC_SRR,...
            prob_mass.TC_Freq, prob_mass.TotalFreq,...
            prob_mass.smpl1, prob_mass.smpl2, prob_mass.smpl3] = chs_probability_mass_loader(config.prob_mass_source, config.grid_file, config.region, config.sp_ID);
    elseif isfile(config.prob_mass_source) % .mat
        % Load File
        load(config.prob_mass_source, 'prob_mass');
        % Validate Provided Custom Modeling prob_mass Variable
        prob_mass_validation(config, prob_mass, storm);
    end
    % Create String Pattern For Naming Convention
    config.name_prefix = fullfile(project_name, struc_id,...
        [project_name '_' struc_id '_' chs_region]);
    % Create StormSim storm file
    save([config.name_prefix '_SP' num2str(config.sp_ID) '.mat'], 'storm', 'prob_mass');
end

%% LOAD SIMULATION BIAS AND UNCERTAINTY VALUES
% Overwrite Bias & Uncertainty With Loaded Data
if exist(fullfile(sim_dir, case_name, [project_name '_' struc_id '_' case_name ,'_config_file.mat']), 'file')
    % Load Config
    config_load = load(fullfile(sim_dir, case_name, [project_name '_' struc_id '_' case_name '_config_file.mat']));
    config_load = config_load.config;
    % Pull Bias & Uncertainty Values If Same File For Convenience
    if strcmp(config.chs_ssl_bias_and_uncertainty_file, config_load.chs_ssl_bias_and_uncertainty_file) % Same Bias File
        try
            % SSL Proportional & Abolute Uncertainty
            config.chs_swl_u_a = config_load.chs_swl_u_a;
            config.chs_swl_u_r = config_load.chs_swl_u_r;
            config.chs_hm0_u_a = config_load.chs_hm0_u_a;
            config.chs_hm0_u_r = config_load.chs_hm0_u_r;
            % SSL Proportional And Absolute Bias
            config.chs_swl_b_a = config_load.chs_swl_b_a;
            config.chs_swl_b_r = config_load.chs_swl_b_r;
        end
    end
    % If SP ID Doesn't Match Wipe Transect Folder, New Forcing
    if config.sp_ID ~= config_load.sp_ID
        % Delete Files Because Bias Needs to Be Recomputed
        rmdir(sim_dir, 's');
    end
    % Grab Forcing Adjustment Flags
    config.u_engine = config_load.u_engine;
    config.f_adjust = config_load.f_adjust;
else
    % Uncertainty Engine Field Initialization
    config.u_engine = 0;
    % Forcing Adjustments Field Initialization
    config.f_adjust = 0;
end

%% APPEND ADDITIONAL SIMULATION DETAILS TO CONFIG

% Make Sure Confidence Limits Are In The Expected Format
try
    % Split Sring
    dummy = strsplit(config.project_CLs,{' ','[',']'});
    dummy = dummy(2:end-1);
    % Sort CLs
    dummy = sort(cellfun(@str2double, dummy), "ascend");
    % Store Back On Config
    config.project_CLs = ['[',strtrim(sprintf('%d ', dummy)),']'];
catch % In Case Of Unexpected Format , Default To
    config.project_CLs = '[16 84]';
end
% Deprecated Or Hidden Features
config.slope_type = 0; % Idealized Slope
config.structure_dir = 0; % Assume Shore Normal Waves
config.chs_wDir_u_a = 0; % Assume Shore Normal Waves
config.tide_std = 0; % Tidal std , not implemented

%% LOAD COMPUTATIONAL ENVIRONMENT
% isempty(ss_files_list) -> 1 (Print Welcome Message) , 0 (No Print)
% Set-up Computational Environment
[config, structure] = call_environment_setup(config, isempty(ss_files_list));

%% AUX FUNCTIONS
% Function 1: Extracts CHS study Details Needed For StormSim Simulation
    function [region, sp_ID, sp_ID_wave] = get_study_details(files_in)
        % ADCIRC Indx
        ad_indx = contains(files_in,'ADCIRC');
        % ADCIRC Reference File
        ad_ref = files_in(ad_indx); ad_ref = ad_ref(1); % Keep 1 File Only
        % Wave Reference File
        wave_ref = files_in(~ad_indx); wave_ref = wave_ref(1); % Keep 1 File Only
        % Split Into Identifiers
        chs_ident = cellfun(@(x) strsplit(x, '_'), [ad_ref;wave_ref], 'un', false);
        % Store CHS Region
        region = chs_ident{1}{1};
        % Store ADCIRC SP ID
        sp_ID = str2double(chs_ident{1}{5}(3:end));
        % Add CHS Wave SP ID
        sp_ID_wave = str2double(chs_ident{2}{5}(3:end));
    end
% Function 2: Identify What Type Of Modeling Data Is Provided By User
    function data_case = identify_storm_data_type(chs_zip)
        % Get File Extension
        [~, ~, file_extension] = fileparts(chs_zip);
        % Determine Modeling Data Provided Through config.chs_zip
        switch file_extension
            case '.mat' % Option 1: mat file with "storm" & "prob_mass" | Option 2: mat file with "CHS_Data"
                data_case = {'chs_data', 'storm_data'};
                % Verify Variable Inside .mat File
                mf = matfile(chs_zip);
                vars = who(mf);
                % Make Sure We Only Allow For Supported Vars
                var_pass = contains({'CHS_Data','storm'}, vars);
                %
                if sum(var_pass) == 0 || sum(var_pass) >1
                    error('Error: Provided .mat file under chs_zip must have "CHS_Data" or "storm" variables (not both).')
                else
                    data_case = data_case{var_pass};
                end
            case '.zip' % Zip Folder Downloaded From CHS
                data_case = 'chs_data';
            otherwise
                error('Error: Unsuported file type for config.chs_zip. Please provide valid .mat file or CHS .zip folder')
        end
    end
end % End of Function
