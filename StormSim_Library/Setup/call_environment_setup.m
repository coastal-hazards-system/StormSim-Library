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
% Project Name
project_name = config.project_name;
% Transect Id
struc_id = config.struc_id;
% Define Case  Name
case_name = config.case_name;
% Probability Masses
PM_path = config.prob_mass_source;
% outfolkder
outfolder = config.outfolder;
% OutDir
outDir = fullfile(outfolder, project_name, struc_id, case_name);
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

    %% LOAD ENVRONMENT ACCORDING TO WORKFLOW
    % Determine Environment To Load
    switch workflow
        case 2
            config.workflow = 1;
        case 4
            config.pros_compute_forcing_HC = 1;
    end
    % Check For TC Probabilities Dependencies
    if contains(config.storm_sampling, {'TC', 'CC'})
        chk2 = exist(PM_path,'dir') | exist(PM_path,'file');
        % Verify Results
        if chk2 ~= 0
            disp('CHS tropical cylcones probability masses found...');
        else
            disp('CHS tropical cyclones probability masses not found...');
            % Throw Error Message
            warning('Warning ID: 001 | call_environment_setup.missing_dependency | CHS probability masses not found. Storm sampling limited to extratropical only (XC)....');
            % Update Config
            config.storm_sampling = 'XC';
        end
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

%% INITIALIZE GEOMETRY
    % Create Structure Variable
    [structure] = create_structure_geometry(config, 0);% Second input argument: 1 - show plot 0 - hide plot
    % Save Out Configuration & Structure File
    save(config.out_files.config, 'config','structure');
end