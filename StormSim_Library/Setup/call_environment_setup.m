function [config, structure] = call_environment_setup(config, run_flag)
%{
%% DESCRIPTION
This function initializes the StormSim library.


%% INPUTS
config: Parsed StormSim project input file. MATLAB structure.

%% OUTPUTS
config: MATLAB data structure containing input file data parsed out as
individual strucutre fields.

%R DEV SIGNATURE
Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}
%% CREATE DIRECTORIES
% Define Workflow
workflow = config.workflow;
% Get Structure Type
struc_type = config.struc_type;
%
switch workflow
    case {1,2}
        wflow = 'PROS-RB';
        wflow2 = 'PROS';
    case 3
        wflow = 'LCS';
        wflow2 = 'LCS';
    case 4
        wflow = 'PROS-FB';
        wflow2 = 'PROS';
end
chs_region = config.region;
spID = config.sp_ID;

%% VOID SWITCHES WHEN NEEDED
% Safeguard For Unssuported Responses For Each Structure Type
switch struc_type
    case 1 % Levee
        % Goda Pressures
        config.compute_p1 = 0;
        config.compute_p2_p3 = 0;
        % Nappe
        config.compute_nappe = 0;
    case 2 % floodwall
        % Dn50 - Momentum Flux
        config.compute_dn50_seaside = 0;
        % Dn50 - Van Gent
        config.compute_dn50_leeside = 0;
        % Dn50 - LCBW
        config.compute_dn50_lcbw = 0;
        % Eurotop
        config.compute_r2p = 0;
    case 3 % Rubblemound
        % Goda Pressures
        config.compute_p1 = 0;
        config.compute_p2_p3 = 0;
        % Nappe
        config.compute_nappe = 0;
end
% Workflow Restrictions
switch workflow
    case 2
        config.workflow = 1;
    case 4
        config.pros_compute_forcing_HC = 1;
end
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
% WLP, WHP Require Peaks & Timeseries Files
if sum([config.use_peaks,config.use_timeseries])~=2
    % Set WLP, WHP To Off
    config.create_wlp = 0;
    config.create_whp = 0;
end

%% DISPLAY WELCOME MESSAGE
% Determine What TO Print
if run_flag == 1
    switch workflow
        case {1,4} % StormSim: PROS
            welcome_message = ['************************************************************************' newline...
                '***           Stochastic Storm Simulation System (StormSim)          ***' newline...
                '***        StormSim: Probabilistic Responses of Structures (PROS)    ***' newline...
                '***                          Version 1.0.0                           ***' newline...
                '***                        FOR  TESTING  ONLY                        ***' newline...
                '************************************************************************'];
        case 2 % StormSim: EVA
            welcome_message = ['************************************************************************' newline...
                '***           Stochastic Storm Simulation System (StormSim)          ***' newline...
                '***              StormSim: Extreme Value Analysis (EVA)              ***' newline...
                '***                          Version 1.0.0                           ***' newline...
                '***                        FOR  TESTING  ONLY                        ***' newline...
                '************************************************************************'];
        case 3 % StormSim: MCS/CSR
            welcome_message = ['************************************************************************' newline...
                '***           Stochastic Storm Simulation System (StormSim)          ***' newline...
                '***               StormSim: Life Cycle Simulation (LCS)              ***' newline...
                '***                          Version 1.0.0                           ***' newline...
                '***                        FOR  TESTING  ONLY                        ***' newline...
                '************************************************************************'];
    end
    % Display Welcome Banner
    disp(welcome_message);
end

%% CHECK FOR CHS DEPENDENCIES FOLDER
if ~exist(config.chs_dependencies,'dir')
    % Prompt User
    error(['Error: Missing CHS_Dependencies folder.', newline,...
        'Download from: https://chs.erdc.dren.mil/Home/Library']);
else
    disp('External CHS_Dependencies folder found...');
    % Revised function: Returns a cell array of full paths for 0, 1, or N matches
    f_x = @(x, y) fullfile({y(contains({y.name}, x)).folder}, {y(contains({y.name}, x)).name});

    % 1. Get ADCIRC & Wave Model Bias And Uncertainty
    dummy = dir(fullfile(config.chs_dependencies, 'Probability_Masses', config.region, '*.mat'));
    config.in_files.tc_dsw = cell2mat(f_x('DSW', dummy));
    config.in_files.tc_master_table = cell2mat(f_x('Param', dummy));

    % 2. Atlantic Basin TC Statistics
    dummy = dir(fullfile(config.chs_dependencies, 'Probability_Masses', '*.mat'));
    config.in_files.crl = cell2mat(f_x('CRLs', dummy)); % Coastal Reference Locations 
    config.in_files.tc_srr = f_x('SRR', dummy); % Storm Recurrance Rates [stm/yr*Km] at CRLs

    % 3. Study Grid
    dummy = dir(fullfile(config.chs_dependencies, 'Grid_Files', config.region, '*.mat'));
    config.in_files.grid = cell2mat(f_x(config.region, dummy));

    % 4. Model Bias & Epistemic Uncertainty 
    dummy = dir(fullfile(config.chs_dependencies, 'Bias_and_Uncertainty', config.region, '*.mat'));
    config.in_files.BnU_circulation = cell2mat(f_x({'Comb','WL'}, dummy));
    config.in_files.BnU_waves = cell2mat(f_x('STWAVE', dummy));
end

%% CHECK FOR STORM TYPE COMPLIANCE
% Only Applicable When CHS HDF5 Files Are Present (Not storm_data Path)
if ~isempty(config.chs_files_2_convert)
    % Grab Storm Types On chs_zip
    st_types = cellfun(@(x) strsplit(x, '_'), config.chs_files_2_convert(:, 2), 'un', false);
    st_types = unique(cellfun(@(x) x(2), st_types, 'un', true));
    % Make Bool Check For Storm Type Request
    switch config.storm_sampling
        case 'XC'
            stm_pass = any(contains(st_types, {'XC','XH'}));
        case 'TC'
            stm_pass = any(contains(st_types, {'TS','TC'}));
        case 'CC'
            stm_pass = any(contains(st_types, {'TS','TC'})) &  any(contains(st_types, {'XC','XH'}));
    end
    % Stop Execution If Fail
    if ~stm_pass
        error('Error: Provided CHS savepoint data does not meet storm type requirements');
    end
end

%% BUILD FILENAMES FOR SIMULATION 
% Transect Level Files (Applies To All Alternatives)
config.out_files.storm_and_prob_mass = [config.name_prefix '_SP' num2str(config.sp_ID) '.mat'];
config.out_files.chs_data = [config.name_prefix '_SP' num2str(config.sp_ID) '_raw_files.mat'];
% ALternative Specific Files
prefix = fullfile(config.outfolder, config.project_name,...
    config.struc_id, config.case_name, wflow2, [config.project_name '_' config.struc_id '_' config.case_name '_' wflow]);
config.out_files.config = [prefix '_config_file.mat'];
config.out_files.resp_data = [prefix '_config_file.mat'];
config.out_files.project_forcing = [prefix '_project_forcing.mat'];

 %% GRAB CSTORM MODELING BIAS & EPISTEMIC UNCERTAINTY  
    % Load Bias Correction Data For CHS Region
    switch chs_region
        case 'CHS-LA'
            % Load Grid Files
            load(config.in_files.grid{contains(config.in_files.grid, 'SPs')}, 'SPs');  % SPs
            load(config.in_files.grid{contains(config.in_files.grid, 'staID')}, 'staID'); % staID -> [SP_ID Node_ID Lon Lat Depth]
            % Get Row
            adcirc_node_id = SPs(SPs(:,1) == spID, 2);
            % Find Correct Row ID For Bias & Uncertainty
            bias_indx = find(staID(:,2) == adcirc_node_id); % Row INdex For Bias And Uncertainty
        otherwise
            % Define Load Cases
            load_cases = {'nodeID','staID'};
            % Grab File Names
            [~, grid_files, ~] = fileparts(config.in_files.grid);
            % Identify Case
            load_bool = cell2mat(cellfun(@(x)contains(grid_files, x), {'nodeID','staID'}, 'un', false));
            % Load Grid Files
            switch load_cases{load_bool}
                case 'nodeID'
                    % Load Grid Files
                    staID = load(config.in_files.grid, 'nodeID');staID = staID.nodeID;  % SPs
                case 'staID'
                    % Load Grid Files
                    load(config.in_files.grid,'staID'); % staID -> [SP_ID Node_ID Lon Lat Depth]
            end
            % Find Correct Row ID For DSWs
            bias_indx = find(staID(:,1) == spID); % Row INdex For Bias And Uncertainty
    end
    % Load Bias Correction File
    warning('off');
    try
        u_data = load(config.in_files.BnU_circulation, 'Comb'); % PBL + ADCIRC
        u_data = u_data.Comb;
    catch
        u_data = load(config.in_files.BnU_circulation, 'WL'); % ADCIRC Only
        u_data = u_data.WL;
    end
    % Load Wave Model Bias & Uncertainty
    u_hm0 = load(config.in_files.BnU_waves, 'Hm0');u_hm0 = u_hm0.Hm0;
    % Determine Fields
    if length(u_hm0.U_a)~=1
        config.chs_hm0_u_a = u_hm0.U_a_avg;
        config.chs_hm0_u_r = u_hm0.U_r_avg;
    else
        config.chs_hm0_u_a = u_hm0.U_a;
        config.chs_hm0_u_r = u_hm0.U_r;
    end
    warning('on');
    % Comb.B_a, B_r, B_a_avg, B_r_avg, U_a, U_r, U_a_avg, U_r_avg
    B_a_SWL=u_data.B_a(bias_indx); B_r_SWL=u_data.B_r(bias_indx);
    config.chs_swl_b_a = B_a_SWL;
    config.chs_swl_b_r = B_r_SWL;
    % Overwrite Manual Value
    config.chs_swl_u_a = u_data.U_a(bias_indx); % SWL absolute uncertainty
    config.chs_swl_u_r = u_data.U_r(bias_indx); % SWL Proportional uncertainty

%% LOAD SIMULATION BIAS AND UNCERTAINTY VALUES
% Overwrite Bias & Uncertainty With Loaded Data
if exist(config.out_files.config, 'file')
    % Load Config
    config_load = load(config.out_files.config, 'config');
    config_load = config_load.config;
    % Pull Bias & Uncertainty Values If Same File For Convenience
    if strcmp(config.out_files.config, config_load.out_files.config) % Same Bias File
        try
            % SSL Proportional & Abolute Uncertainty
            config.chs_swl_u_a = config_load.chs_swl_u_a;
            config.chs_swl_u_r = config_load.chs_swl_u_r;
            config.chs_hm0_u_a = config_load.chs_hm0_u_a;
            config.chs_hm0_u_r = config_load.chs_hm0_u_r;
            % SSL Proportional And Absolute Bias
            config.chs_swl_b_a = config_load.chs_swl_b_a;
            config.chs_swl_b_r = config_load.chs_swl_b_r;
            % If SP ID Doesn't Match Wipe Transect Folder, New Forcing
            if config.sp_ID ~= config_load.sp_ID
                % Delete Files Because Bias Needs to Be Recomputed
                sim_dir = fullfile(config.outfolder, config.project_name, config.struc_id, config.case_name);
                rmdir(sim_dir, 's');
                mkdir(sim_dir);
                mkdir(fullfile(sim_dir, wflow2));
                % Grab Forcing Adjustment Flags
                config.u_engine = 0;
                config.f_adjust = 0;
            else
                % Grab Forcing Adjustment Flags
                config.u_engine = config_load.u_engine;
                config.f_adjust = config_load.f_adjust;
            end
        catch
            % Delete Files Because Bias Needs to Be Recomputed
            sim_dir = fullfile(config.outfolder, config.project_name, config.struc_id, config.case_name, wflow2);
            rmdir(sim_dir, 's');
            mkdir(sim_dir);
            % Uncertainty Engine Field Initialization
            config.u_engine = 0;
            % Forcing Adjustments Field Initialization
            config.f_adjust = 0;
        end
    end
else
    % Uncertainty Engine Field Initialization
    config.u_engine = 0;
    % Forcing Adjustments Field Initialization
    config.f_adjust = 0;
end

%% INITIALIZE GEOMETRY
    % Create Structure Variable
    [structure] = create_structure_geometry(config, 0);% Second input argument: 1 - show plot 0 - hide plot
    % Save Out Configuration & Structure File
    save(config.out_files.config, 'config','structure');
end