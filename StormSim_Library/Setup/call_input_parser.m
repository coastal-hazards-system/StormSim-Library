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
% Make Temp Path Empty
config.temp_path = '';
% Overwrite Bias & Uncertainty With Loaded Data
if exist(fullfile(pwd, project_name, struc_id, case_name, [project_name '_' struc_id '_' case_name ,'_config_file.mat']), 'file')
    % Load Config
    config_load = load([pwd filesep project_name filesep struc_id filesep case_name filesep project_name '_' struc_id '_' case_name '_config_file.mat']);config_load = config_load.config;
    % Add Values
    if strcmp(config.chs_ssl_bias_and_uncertainty_file,config_load.chs_ssl_bias_and_uncertainty_file) % Same Bias File
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
    else
        % Delete Files Because Bias Needs to Be Recomputed
        delete([pwd filesep project_name filesep struc_id filesep '*.mat']);
    end
end

%% DETERMINE FORCING DATA SOURCE CASE
% Make Sure Specified File Exist
if exist(config.chs_zip,'file')~=2 % Valid Zip Folder Detected
    error('Error ID: 001 | call_input_parser.missing_dependency | CHS zip folder not found. Please verify file path...');
end
% Get File Extension For "config.chs_zip"
[~,fname,fext] = fileparts(config.chs_zip);
% Build File Listing According To File Extension
switch fext
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
        % Try And Find SP Depth On HDF% Attributes
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
        % ADCIRC Indx
        ad_indx = contains(config.chs_files_2_convert(:,2),'ADCIRC');
        % ADCIRC Reference File
        ad_ref = config.chs_files_2_convert(ad_indx, 2); ad_ref = ad_ref(1); % Keep 1 File Only
        % Wave Reference File
        wave_ref = config.chs_files_2_convert(~ad_indx, 2); wave_ref = wave_ref(1); % Keep 1 File Only
        % Split Into Identifiers
        chs_ident = cellfun(@(x) strsplit(x, '_'), [ad_ref;wave_ref], 'un', false);
        % Store CHS Region
        config.region = chs_ident{1}{1};
        % Store ADCIRC SP ID
        config.sp_ID = str2double(chs_ident{1}{5}(3:end));
        % Add CHS Wave SP ID
        config.sp_ID_wave = str2double(chs_ident{2}{5}(3:end));
        % Create String Pattern For Naming Convention
        config.name_prefix = [project_name filesep struc_id filesep...
            project_name '_' struc_id '_' config.region];
        % Define Naming Convention
        file2look = [config.name_prefix '_SP*'];
        % Look For File
        dummy = dir(fullfile(config.outfolder, file2look)); % Search For Expected StormSim Naming Convention On Project Folder
        % Remove Raw Files Mat
        dummy = dummy(~contains({dummy.name},{'raw_files'})); % Only Interested Processed Dataset
        % Check If .mat is storm or CHS_Data
        if isempty(dummy)
            vars = 'none';
        else
            mf = matfile(fullfile(dummy.folder,dummy.name));
            vars = who(mf);
        end
    case '.mat'
        % Add CHS Files 2 Convert In Cell Array
        config.chs_files_2_convert = [];
        % Try To Find Savepoint ID From Loaded File
        if contains(fname, {'SP'})
            sp_id = strsplit(fname, {'_', 'SP'});
            config.sp_ID = str2double(sp_id{end});
        else
            % Define Save Point ID As Empty
            config.sp_ID = [];
        end
        config.sp_ID_wave = [];
        % Define Region As Empty
        config.region = [];
        % Create String Pattern For Naming Convention
        if contains(fname, {'CHS-'})
            chs_region = strsplit(fname, '_');
            chs_region = chs_region{contains(chs_region, {'CHS-'})};
        else
            chs_region = 'Custom_Modeling';
        end
        % Create String Pattern For Naming Convention
        config.name_prefix = [project_name filesep struc_id filesep...
            project_name '_' struc_id '_' chs_region];
        % Define Naming Convention
        file2look = config.chs_zip;
        % Look For File
        dummy = dir(file2look); % Search For Expected StormSim Naming Convention On Project Folder
        % Check If .mat is storm or CHS_Data
        mf = matfile(fullfile(dummy.folder,dummy.name));
        vars = who(mf);
        if strcmp(vars, 'CHS_Data')
            % Load
            load(fullfile(dummy.folder,dummy.name), 'CHS_Data');
            % Get File Names From Loaded Data Structure
            [chs_files_2_convert_paths, chs_files_2_convert, ~] = ...
                cellfun(@(x) fileparts(x), {CHS_Data.Filename}, 'un', false);
            % Append File Extension
            chs_files_2_convert = cellfun(@(x) [x '.h5'],...
                chs_files_2_convert, 'un', false);
            %
            config.chs_files_2_convert = [chs_files_2_convert_paths', chs_files_2_convert'];
            % Asign CHS Region
            config.region = strsplit(chs_files_2_convert{1}, '_');
            config.region = config.region{1};
        end
end

%% CHECK IF STORMSIM PROCESSED SAVEPOINT DATA EXIST FOR CURRENT proj_name, struc_id, case_name
% If File Is Found Prompt User And Grab Needed Metadata
if ~isempty(dummy) & ~strcmp(vars, 'CHS_Data')% New Case Run
    % Build File Path
    file2look = fullfile(dummy.folder,dummy.name);
    %
    disp('Project storm suite detected. Verifying data compliance....');
    % Load Provided Storm Suite File (storm)
    try
        load(file2look, 'storm');
    catch
        error('Provided .mat must include StormSim "storm" variable when using .mat....');
    end
    % Validate Loaded Storm Data
    storm_validation(config, storm);
    % Load Provided Probability Mass File (prob_mass)
    if strcmp(config.storm_sampling, {'XC'})
        prob_mass = [];
    else
        try
            load(config.prob_mass_source, 'prob_mass');
        catch
            error('Provided .mat must include StormSim "prob_mass" variable when .mat....');
        end
        % Validate Provided Custom Modeling prob_mass Variable
        prob_mass_validation(config, prob_mass, storm);
    end
    % Prompt
    disp(['Data inspection passed. Loading data and creating new case for ' project_name ': ' struc_id '....']);
    % Grab Extratropical Storm Fields If Exist
    if isfield(storm,'XC')
        % Grab XC_Nyrs & XC_Nstm
        config.Nyrs_XC = storm.('XC').('Nyrs_XC');
        config.Nstm_XC = storm.('XC').('Nstm_XC');
    end
else
    file2look = []; % This is used to determine if welcome message should be printed
end

%% FAILSAFES
% WLP, WHP Require Peaks & Timeseries Files
if sum([config.use_peaks,config.use_timeseries])~=2
    % Set WLP, WHP To Off
    config.create_wlp = 0;
    config.create_whp = 0;
end
% Uncertainty Engine Field Initialization
config.u_engine = 0;
% Forcing Adjustments Field Initialization
config.f_adjust = 0;
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
% Check For Berm
if config.add_berm == 0 % If No Berm Ensure Fields Are Set To 0
    switch config.struc_type
        case 2
            config.berm_elevation = config.wall_bottom_elevation;
            config.toe_elevation = config.wall_bottom_elevation;
        case {1, 3}
            config.berm_elevation = config.toe_elevation;
    end
    config.berm_slope = 0;
    config.berm_width = 0;
end
% P2, P3 Are Secondary Responses. Need to process FB
if config.compute_p2_p3 == 1 || config.compute_nappe == 1
    % Ensure P1 Hazard Curve Is Computed
    config.compute_p1 = 1;
    % Ensure Surge & Waves Hazards Are Computed
    config.pros_compute_forcing_HC = 1;
end
% P2, P3, Nappe Are Secondary Responses. Need to process FB
if config.compute_nappe == 1
    % Ensure q Hazard Curve Is Computed
    config.compute_q = 1;
    % Ensure Surge & Waves Hazards Are Computed
    config.pros_compute_forcing_HC = 1;
end

%% LOAD COMPUTATIONAL ENVIRONMENT
% Set-up Computational Environment
[config, structure] = call_environment_setup(config, isempty(file2look));
end % End of Function
