function [config] = call_environment_setup(config, run_flag)
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
% OutDir
outDir = [project_name filesep struc_id filesep case_name];
% Project And Transect ID Folder And Subfolder
if ~exist(outDir,'dir')
    mkdir(outDir);
end
% Define Workflow
workflow = config.workflow;

%% DISPLAY WELCOME MESSAGE
% Determine What TO Print
if run_flag == 1
    switch workflow
        case 1 % StormSim: PROS
            welcome_message = ['************************************************************************' newline...
                '***            Coastal Analysis And Screening Tool (CAST)            ***' newline...
                '*** StormSim: Probabilistic Run-up, Overtopping, Stone Sizing (PROS) ***' newline...
                '***                          Version 1.0.0                           ***' newline...
                '***                        FOR  TESTING  ONLY                        ***' newline...
                '************************************************************************'];
        case 2 % StormSim: MCS
            welcome_message = ['************************************************************************' newline...
                '***            Coastal Analysis And Screening Tool (CAST)            ***' newline...
                '***             StormSim: Monte Carlo Storm Sampler (MCS)            ***' newline...
                '***                          Version 1.0.0                           ***' newline...
                '***                        FOR  TESTING  ONLY                        ***' newline...
                '************************************************************************'];
        case 3 % StormSim: MCS/CSR
            welcome_message = ['************************************************************************' newline...
                '***            Coastal Analysis And Screening Tool (CAST)            ***' newline...
                '***                        StormSim: MCS/CSR                         ***' newline...
                '***                          Version 1.0.0                           ***' newline...
                '***                        FOR  TESTING  ONLY                        ***' newline...
                '************************************************************************'];
        otherwise

    end

    % Display Welcome Banner
    disp(welcome_message);

    %% LOAD ENRINMENT ACCORDING TO WORKFLOW
    % Determine Environment To Load
    switch workflow
        case 4 % Any External Workflow
            % Do Nothing
        otherwise % StormSim Workflow
            % Check For Function Library
            chk1 = exist('StormSim_Library','dir')==7;
            % Verify Results
            if chk1 % Library Found
                % Add Library To Path
                addpath(genpath('StormSim_Library'));
                % Display Status
                disp('StormSim library found...');
            else % Library not Found
                % Throw Error Message
                error('Error ID: 001: | call_environment_setup.missing_dependency | StormSim library not found....');
            end
            % Check For TC Probabilities Dependencies
            chk2 = exist('MCSim_Inputs','dir')==7;
            % Verify Results
            if chk2
                disp('CHS tropical cylcones probability masses found...');
            else
                disp('CHS tropical cylcones probability masses not found...');
                % Throw Error Message
                warning('Warning ID: 001 | call_environment_setup.missing_dependency | CHS probability masses not found. Storm sampling limited to extratropical only (XC)....');
                % Update Config
                config.storm_sampling = 'XC';
            end
            % Check For norm_444.mat
            %     chk3 = exist(['MCSim_Inputs' filesep 'norm_444.mat'],'file')==2;
            % Verify Results
            %     if chk3
            %         disp('  Discretized normal curve found...');
            %     else
            %         disp('  Discretized normal curve not found...');
            %     end
    end
else
    % Create Strucutre Variable
    [structure] = create_structure_geometry(config, 0);% Second input argument: 1 - show plot 0 - hide plot
    assignin('base','structure',structure);
    % Save Out Configuration File
    save([outDir filesep project_name '_' struc_id '_' case_name '_config_file.mat'],...
        'config','structure');
end
end