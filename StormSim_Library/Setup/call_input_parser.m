function config = call_input_parser(input_filename)
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
% Read StormSim Project Input File
input_file = readcell(input_filename);
% Add Filename To Config
config.stormsim_input_file = input_filename;

%% PARSE INPUT FILE AND CREATE CONFIG STRUCTURE
% Find Row And Column Index For "str_ref" In "input_file"
[row_indx,col_indx] = find(cell2mat(cellfun(@(x) strcmp(x,str_ref),input_file,'un',false))==1);
% Loop Through Found Instances (Matched Cases Represent Input Tables)
for ii= 1:length(row_indx)
    % Grab Dummy Section To Determine Current Table Size
    helper_var = input_file(row_indx(ii)+anchor_offset:end,:);
    % Determine "helper_var" Cells With Data Size
    helper_var_indx = cellfun(@ismissing,helper_var(:,col_indx(ii)),'UniformOutput',false); % Returns arrays in cells with chars, interested in 1x1 entries {1x1 missing}
    % Determine 1x1 Entries Locations In "helper_var"
    helper_var_indx = find(cellfun(@length,helper_var_indx)==1)-1; % -1 is to get last valid data point in col
    if ~isempty(helper_var_indx)
        % Grab Input Table Rows
        table_rows = helper_var_indx(1); % Always want to use 1st index of "helper_var_indx"
    else
        table_rows = length(helper_var(:,1));
    end
    % Grab All Cols In Table Header Row
    table_width = input_file(row_indx(ii),:);
    % Find "ismissing" Cols
    table_width = cellfun(@ismissing,table_width,'un',false);
    % Determine 1x1 Entries Locations In "table_width"
    table_width = cellfun(@length,table_width)==1;
    %
    if col_indx(ii) > 1
        % Get Col Index Of Empty Cells
        if isempty(find(table_width(col_indx(ii):end) == 1))
            table_width = length(table_width(col_indx(ii):end));
        else
            table_width = find(table_width(col_indx(ii):end) == 1)-1+col_indx(ii);
            table_width = table_width(1) - col_indx(ii);
        end
    else % First Col
        % Get Col Index Of Empty Cells
        table_width = find(table_width == 1);
        % Get Table Width
        table_width = table_width(1)-1;
    end
    % Initialize "helper_var2"
    helper_var2 = [];
    % Loop Through Input Table Items And Create Config
    for jj = 1:table_rows
        if contains(helper_var{jj,col_indx(ii)},{'chs_tc_swl','chs_xc_swl','chs_tc_hm0','chs_xc_hm0'})
            helper_var2 = [helper_var2;helper_var(jj,col_indx(ii)+3)];
        end
        % Handle According To Table Size
        switch table_width
            case 4 % Only Has Mean Values
                % Create "config" Structure Field
                config.(helper_var{jj,col_indx(ii)}) = helper_var{jj,col_indx(ii)+3};
            case 5 % Has Mean Value + Std
                % Store Mean Value
                config.(helper_var{jj,col_indx(ii)}).mean = helper_var{jj,col_indx(ii)+3};
                % Store Std Value
                config.(helper_var{jj,col_indx(ii)}).std = helper_var{jj,col_indx(ii)+4};
        end
    end
end
% Project Name
project_name = config.project_name;
% Transect Id
struc_id = config.struc_id;
% Case Name
case_name = config.case_name;
% Workflow
workflow = config.workflow;
%
if ismissing(config.chs_bias_file)
    config.chs_bias_file = 'none';
end
%
if exist([pwd filesep project_name filesep struc_id filesep case_name filesep project_name '_' struc_id '_' case_name '_config_file.mat'], 'file')
    % Load Config
    config_load = load([pwd filesep project_name filesep struc_id filesep case_name filesep project_name '_' struc_id '_' case_name '_config_file.mat'],'config');
    config_load = config_load.config;
    % Add Values
    if strcmp(config.chs_bias_file,config_load.chs_bias_file) % Same Bias File
        config.chs_swl_u_a = config_load.chs_swl_u_a;
        config.chs_swl_u_r = config_load.chs_swl_u_r;
        config.chs_hm0_u_a = config_load.chs_hm0_u_a;
        config.chs_hm0_u_r = config_load.chs_hm0_u_r;
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
            if exist('Temp','dir')~=7
                mkdir('Temp');
            else
                rmdir('Temp','s');
                mkdir('Temp');
            end
            % Decompress Zip Folder
            unzip(config.chs_zip,'Temp');
            % Scan Unzip Directory
            temp_dir = dir(['Temp' filesep '**' filesep '*.h5']);
            % Add Field To config
            config.chs_files_2_convert = sortrows([{temp_dir.folder}', {temp_dir.name}'],2,'ascend');
            % Add h5 Files Path To Config
            config.chs_zip_path = 1;
            % Grab CHS Identifiers
            chs_ident = strsplit(config.chs_files_2_convert{1,2},'_');% [Region Storm_Type Sim_Type Post_Type SP_ID Model File_Type]
            % Add CHS Region
            if contains(chs_ident{1},'CHS-NA')
                config.region = 'NACCS';
            else
                config.region = chs_ident{1};
            end
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
            error('Error ID: 001 | call_input_parser.missing_dependency | CHS zip folder not found. Please verify file path...');
        end
        % Create String Pattern For Naming Convention
        config.name_prefix = [project_name filesep struc_id filesep...
            project_name '_' struc_id '_CHS_' config.region];
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
                if contains(chs_ident{1},'CHS-NA')
                    config.region = 'NACCS';
                else
                    config.region = chs_ident{1};
                end
                % Add CHS ADCIRC SP
                config.sp_ID = str2double(chs_ident{5}(3:end));
                % Get File Extension Of Files
                [~,fname,~] = fileparts(CHS_Data(stwave_indx(1)).Filename);
                % Grab CHS Identifiers
                chs_ident = strsplit(fname,'_');% [Region Storm_Type Sim_Type Post_Type SP_ID Model File_Type]
                % Add CHS ADCIRC SP
                config.sp_ID_wave = str2double(chs_ident{5}(3:end));
                % Create String Pattern For Naming Convention
                config.name_prefix = [project_name filesep struc_id filesep...
                    project_name '_' struc_id '_CHS_' config.region];
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

%% Check If This Is Fresh Run Or New Case
% Look For File
dummy = dir(file2look);
% Remove Raw Files Mat
dummy = dummy(~contains({dummy.name},{'raw_files'}));
if ~isempty(dummy) % New Case Run
    % Build File Path
    file2look = fullfile(dummy.folder,dummy.name);
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
    file2look = [];
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

%% LOAD COMPUTATIONAL ENVIRONMENT
% Set-up Computational Environment
config = call_environment_setup(config, isempty(file2look));
end % End of Function
