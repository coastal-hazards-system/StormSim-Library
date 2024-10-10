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
% Get File Extension For "config.chs_zip"
[~,~,fext] = fileparts(config.chs_zip);
% Evaluate Case Based On File Type
switch find(cell2mat(cellfun(@(x) contains(fext,x),{'.zip','.mat'},'un',false)) == 1)
    case 1 % Zip Folder -> Native CHS Data
        if exist(config.chs_zip,'file')==2 % Valid Zip Folder Detected
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
            % Add h5 Files Path To Config
            config.chs_zip_path = 1;
            % ADCIRC Indx
            ad_indx = find(contains(config.chs_files_2_convert(:,2),'ADCIRC') == 1);
            % Grab CHS Identifiers
            chs_ident = strsplit(config.chs_files_2_convert{ad_indx(1),2},'_');% [Region Storm_Type Sim_Type Post_Type SP_ID Model File_Type]
            % Add CHS Region
            %             if contains(chs_ident{1},'CHS-NA')
            %                 config.region = 'NACCS';
            %             else
            config.region = chs_ident{1};
            %             end
            % Add CHS SP
            config.sp_ID = str2double(chs_ident{5}(3:end));
            % Grab ADCIRC Files
            CHS_file_ref = temp_dir(contains({temp_dir.name},{'ADCIRC'}));
            % Keep Only One File For Attributes
            CHS_file_ref = CHS_file_ref(1);
            try
                % Get H5 Info
                sp_depth = h5info([CHS_file_ref(1).folder filesep CHS_file_ref(1).name]);
                % Need To Access Attributes Of First Storm
                sp_depth = sp_depth.Groups.Attributes;
                % Grab Save Point Depth
                config.chs_sp_depth = str2double(sp_depth(strcmp({sp_depth.Name},{'Save Point Depth'})).Value);
            end
            % Grab ADCIRC Files
            CHS_file_ref = temp_dir(~contains({temp_dir.name},{'ADCIRC'}));
            % Keep Only One File For Attributes
            CHS_file_ref = CHS_file_ref(1);
            % Grab CHS Identifiers
            chs_ident = strsplit(CHS_file_ref(1).name,'_');% [Region Storm_Type Sim_Type Post_Type SP_ID Model File_Type]
            % Add CHS Wave SP
            config.sp_ID_wave = str2double(chs_ident{5}(3:end));
        else
            try
                config.region = evalin('base', 'h5_region');
            catch
                error('Error ID: 001 | call_input_parser.missing_dependency | CHS zip folder not found. Please verify file path...');
            end
        end
        % Create String Pattern For Naming Convention
        config.name_prefix = [project_name filesep struc_id filesep...
            project_name '_' struc_id '_' config.region];
        % Define Naming Convention
        file2look = [config.name_prefix '_SP*'];
    case 2 % .mat -> CSTORM or Other
        switch config.forcing_type % CHS/CSTORM Or External Models
            case 0 % CSTORM Or CHS Type Data (Has Unique Identifiers in Name)
                % Load In .mat With CHS_Data
                load(config.chs_zip,'CHS_Data');
                % Grab First File As Template
                [a,~,c] = fileparts(CHS_Data(1).Filename);
                % Create Path Vector
                sorted_list = repmat({a},length(CHS_Data),1);
                % Add File Names In Additional Column
                sorted_list(:,2) = cellfun(@(x) x(length(a)+2:end),{CHS_Data.Filename},'un',false)';
                % Sort File List Based On Filename
                sorted_list = sortrows(sorted_list,2,'ascend');
                % Add CHS Files 2 Convert In Cell Array
                config.chs_files_2_convert = sorted_list;
                % Find ADCIRC File
                adcirc_indx = find(contains(sorted_list(:,2),'ADCIRC'));
                % Find Wave File
                stwave_indx = find(~contains(sorted_list(:,2),'ADCIRC'));
                % Get File Extension Of Files
                [~,fname,~] = fileparts(CHS_Data(adcirc_indx(1)).Filename);
                % Grab CHS Identifiers
                chs_ident = strsplit(fname,'_');% [Region Storm_Type Sim_Type Post_Type SP_ID Model File_Type]
                % Add CHS Region
                %                 if contains(chs_ident{1},'CHS-NA')
                %                     config.region = 'NACCS';
                %                 else
                config.region = chs_ident{1};
                %                 end
                % Add CHS ADCIRC SP
                config.sp_ID = str2double(chs_ident{5}(3:end));
                % Get File Extension Of Files
                [~,fname,~] = fileparts(CHS_Data(stwave_indx(1)).Filename);
                % Grab CHS Identifiers
                chs_ident = strsplit(fname,'_');% [Region Storm_Type Sim_Type Post_Type SP_ID Model File_Type]
                % Add CHS ADCIRC SP
                config.sp_ID_wave = str2double(chs_ident{5}(3:end));
                if contains(config.region,'CHS')
                    % Create String Pattern For Naming Convention
                    config.name_prefix = [project_name filesep struc_id filesep...
                        project_name '_' struc_id '_' config.region];
                else
                    % Create String Pattern For Naming Convention
                    config.name_prefix = [project_name filesep struc_id filesep...
                        project_name '_' struc_id '_CHS_' config.region];
                end
                % Define Naming Convention
                file2look = [config.name_prefix '_SP*'];
            case 1 % Custom Modeling (External Model) (Lacking Identifiers)
                % Load In .mat With CHS_Data
                load(config.chs_zip,'CHS_Data');
                % Grab First File As Template
                [a,~,c] = fileparts(CHS_Data(1).Filename);
                % Create Path Vector
                sorted_list = repmat({a},length(CHS_Data),1);
                % Add File Names In Additional Column
                sorted_list(:,2) = cellfun(@(x) x(length(a)+2:end),{CHS_Data.Filename},'un',false)';
                % Sort File List Based On Filename
                sorted_list = sortrows(sorted_list,2,'ascend');
                % Add CHS Files 2 Convert In Cell Array
                config.chs_files_2_convert = sorted_list;
                % Define Save Point ID As Empty
                config.sp_ID = [];
                config.sp_ID_wave = [];
                % Define Region As Empty
                config.region = [];
                % Create String Pattern For Naming Convention
                config.name_prefix = [project_name filesep struc_id filesep...
                    project_name '_' struc_id '_Custom_Modeling'];
                % Define Naming Convention
                file2look = [config.name_prefix ''];
        end
end

%% CHECK IF STORMSIM PROCESSED SAVEPOINT DATA EXIST FOR CURRENT proj_name, struc_id, case_name
% Look For File
dummy = dir(file2look); % Search For Expected StormSim Naming Convention On Project Folder 
% Remove Raw Files Mat
dummy = dummy(~contains({dummy.name},{'raw_files'})); % Only Interested Processed Dataset
% If File Is Found Prompt User And Grab Needed Metadata
if ~isempty(dummy) % New Case Run
    % Build File Path
    file2look = fullfile(dummy.folder,dummy.name);
    % Prompt 
    disp(['Project forcing detected. Creating new case for ' project_name ': ' struc_id '....'])
    % Load Storm File
    load(file2look,'storm');
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
config.mcs_sampling_mode = 1; % Porbabilistic
config.pros_use_aep = 0; % AEF
config.use_waves_swl = 0; % Use ADCIRC SWL 
config.structure_dir = 0; % Assume Shore Normal Waves
config.chs_wDir_u_a = 0; % Assume Shore Normal Waves
config.tide_std = 0; % Tidal std , not implemented
% Check For Berm 
if config.add_berm == 0 % If No Berm Ensure Fields Are Set To 0
    config.berm_elevation = 0;
    config.berm_slope = 0;
    config.berm_width = 0;
end

%% LOAD COMPUTATIONAL ENVIRONMENT
% Set-up Computational Environment
[config, structure] = call_environment_setup(config, isempty(file2look));
end % End of Function
