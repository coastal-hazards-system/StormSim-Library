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

%% CHS ZIP OR MANUAL FILES
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
    % Sort File List
    sorted_list = sortrows([{temp_dir.folder}', {temp_dir.name}'],2,'ascend');
    % Add CHS Files 2 Convert In Cell Array
    config.chs_files_2_convert = sorted_list(:,2);
    % Add CHS Files Path
    config.chs_files_2_convert_path = sorted_list(:,1);
    % Grab Peaks Files
    peaks_files = {temp_dir(contains({temp_dir.name},{'Peaks'})).name};
    % Grab Timeseries files
    timeseries_files = {temp_dir(contains({temp_dir.name},{'Timeseries'})).name};
    % Grab Files According To "storm_sampling"
    if contains(config.storm_sampling,{'TC','CC'})
        % Grab TC Peaks Files
        peaks_files_tc = peaks_files(contains(peaks_files,{'TC','TS'}));
        % Grab TC Timeseries Files
        timeseries_files_tc = timeseries_files(contains(timeseries_files,{'TC','TS'}));
        % Assign ADCIRC TC Peaks File To Config
        config.('chs_tc_swl_peaks') = peaks_files_tc(contains(peaks_files_tc,{'ADCIRC'}));
        % Assign ADCIRC TC Timeseries File To Config
        config.('chs_tc_swl_timeseries') = timeseries_files_tc(contains(timeseries_files_tc,{'ADCIRC'}));
        % Assign Waves TC Peaks File To Config
        config.('chs_tc_hm0_peaks') = peaks_files_tc(contains(peaks_files_tc,{'STWAVE','SWAN','WAM'}));
        % Assign Waves TC Timeseries File To Config
        config.('chs_tc_hm0_timeseries') = timeseries_files_tc(contains(timeseries_files_tc,{'STWAVE','SWAN','WAM'}));
    end

    if contains(config.storm_sampling,{'XC','CC'})
        % Grab TC Peaks Files
        peaks_files_xc = peaks_files(contains(peaks_files,{'XC','XH'}));
        % Grab TC Timeseries Files
        timeseries_files_xc = timeseries_files(contains(timeseries_files,{'XC','XH'}));
        % Assign ADCIRC TC Peaks File To Config
        config.('chs_xc_swl_peaks') = peaks_files_xc(contains(peaks_files_xc,{'ADCIRC'}));
        % Assign ADCIRC TC Timeseries File To Config
        config.('chs_xc_swl_timeseries') = timeseries_files_xc(contains(timeseries_files_xc,{'ADCIRC'}));
        % Assign Waves TC Peaks File To Config
        config.('chs_xc_hm0_peaks') = peaks_files_xc(contains(peaks_files_xc,{'STWAVE','SWAN','WAM'}));
        % Assign Waves TC Timeseries File To Config
        config.('chs_xc_hm0_timeseries') = timeseries_files_xc(contains(timeseries_files_xc,{'STWAVE','SWAN','WAM'}));
    end
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

else % Manual Files
    % Need to implement checks to make sure files are h5s and CHS
    % native.
end

%% Check If This Is Fresh Run Or New Case
% Project Name
project_name = config.project_name;
% Transect Id
struc_id = config.struc_id;
% Define Case  Name
case_name = config.case_name;
% Define
file2look = [project_name filesep struc_id filesep...
    project_name '_' struc_id '_CHS_' config.region '_SP*'];
% Look For File
dummy = dir(file2look);
% Remove Raw Files Mat
dummy = dummy(~contains({dummy.name},{'raw_files',num2str(config.sp_ID)}));
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
end
