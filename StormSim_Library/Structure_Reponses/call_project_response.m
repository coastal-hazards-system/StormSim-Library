function [Resp] = call_project_response(config, project_forcing, structure, create_plots)
%% GRAB INPUTS FROM "config"
% Define Workflow
workflow = config.workflow;
% Define Storm Sampling
storm_sampling = config.storm_sampling;
%
use_peaks = config.use_peaks;
use_timeseries = config.use_timeseries;
% WLP & WHP Switches
use_whp = config.create_whp;
use_wlp = config.create_wlp;
% Project Name
project_name = config.project_name;
% Transect Id
struc_id = config.struc_id;
% Define Case  Name
case_name = config.case_name;
% Define
subDir = fullfile(config.outfolder, project_name, struc_id, case_name);
% Load Empirical Coefficients
[emp_coeff] = load_empirical_coefficients();
% Intialize Output Data Strucuture
Resp = struct();

%% COMPUTE STRUCTURE RESPONSE BASED ON WORKFLOW
switch workflow
    case {1,2,4} % PROS
        %% STORMSIM: PROS
        % Define Workflow ID String
        if workflow == 4
            % Define Workflow Name
            wName = 'FB';
            subDir = [fullfile(subDir, 'PROS'), filesep];
        else
            % Define Workflow Name
            wName = 'RB';
            subDir = [fullfile(subDir, 'PROS'), filesep];
        end
        % Make Dir
        if ~exist(subDir ,'dir')
            mkdir(subDir);
        end
        % Process Peaks Datasets: RB1
        if use_peaks == 1
            % Scan Peaks Datasets
            level_2 = fieldnames(project_forcing.('Peaks')); % Matching Type
            % Disp
            disp('Running StormSim: Probabilistic Response Of Structures (PROS) - Peaks....');
            % Loop Through All Peak Datasets & Storm Types
            for ii = 1:length(level_2)
                % Skip Based On Config File
                if (strcmp(level_2{ii},'WLP') && use_wlp == 0) || (strcmp(level_2{ii},'WHP') && use_whp == 0)
                    continue;
                else % Pass Peaks Dataset Through StormSim: PROS
                    % Disp
                    disp(['   Processing ' level_2{ii} ' dataset....']);
                    % Call StormSim: PROS RB1
                    Resp.('Peaks').(level_2{ii}) = stormsim_pros(config, project_forcing.('Peaks').(level_2{ii}),...
                        structure, emp_coeff, fullfile(subDir, [ wName '1_' level_2{ii} ]));
                end
            end
        end
        % RB3
        if use_timeseries == 1
            % Disp
            disp('Running StormSim: Probabilistic Response Of Structures (PROS) - Timeseries....');
            % Call StormSim: PROS RB3
            Resp.('Timeseries').('Default') = stormsim_pros(config, project_forcing.('Timeseries').('Default'),...
                structure, emp_coeff, fullfile(subDir, [ wName '3' ]));
        end
        % Plot Results
        if create_plots == 1
            disp('      Plotting StormSim: PROS Analysis outputs... ');
            call_pros_plots(config, structure, project_forcing, Resp);
        else
            if ~exist(subDir ,'dir')
                mkdir(subDir);
            end
        end
        % Update Naming Label 
        wName = ['PROS-' wName];
    case 3 % CSR
        %% STORMSIM: LCS-CSR
        % Define Workflow ID
        wName = 'LCS';
        % Define Workflow Subdirectory
        subDir = [subDir filesep 'Life_Cycle_Simulation' filesep];
        % Create Subdirectory
        if ~exist(subDir,'dir')
            mkdir(subDir);
        end
        % Scan Peaks Datasets
        if use_peaks == 1
            % Print Status
            disp('Running StormSim: Coastal Structure Reliability - Peaks....');
            %
            level_2 = fieldnames(project_forcing.Peaks);
            % Loop Through All Peak Datasets
            for ii = 1:length(level_2)
                disp(['   Processing ' level_2{ii} ' dataset....']);
                Resp.('Peaks').(level_2{ii}) = ...
                    stormsim_csr(config, project_forcing.('Peaks').(level_2{ii}),...
                    structure, emp_coeff, 'peaks', subDir);
            end
        end
        % Timeseries
        if use_timeseries == 1
            disp('Running StormSim: Coastal Structure Reliability - Timeseries....');
            Resp.('Timeseries').('Default') = ...
                stormsim_csr(config, project_forcing.('Timeseries').('Default'),...
                structure, emp_coeff, 'timeseries', subDir);
        end
end

%% EXPORT OUTPUTS
% Display Status
disp('Saving project responses....');
% Save Outputs
save([subDir project_name '_' struc_id '_' case_name '_' wName '_project_responses.mat'],'Resp','-v7.3');
end