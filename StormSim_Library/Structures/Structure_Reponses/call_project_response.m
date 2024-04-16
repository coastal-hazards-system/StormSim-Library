function [Resp] = call_project_response(config, project_forcing, structure, prob_mass, create_plots)
%% GRAB INPUTS FROM "config"
% Define Workflow
workflow = config.workflow;
% Define Storm Sampling
storm_sampling = config.storm_sampling;
% Define Wave Height Priority Switch
structure_type = config.struc_type;
%
use_peaks = config.use_peaks;
use_timeseries = config.use_timeseries;
% WLP & WHP Switches
use_whp = config.create_whp;
use_wlp = config.create_wlp;
% Compute Forcing HC
compute_forcing_hc = config.pros_compute_forcing_HC;
% Project Name
project_name = config.project_name;
% Transect Id
struc_id = config.struc_id;
% Define Case  Name
case_name = config.case_name;
% Define
subDir = fullfile(config.outfolder, project_name, struc_id, case_name);
% Output Save Dir
outDir = fullfile(config.outfolder, project_name, struc_id, [project_name,'_', struc_id]);
% Load Empirical Coefficients
[emp_coeff] = load_empirical_coefficients();

%% COMPUTE STRUCTURE RESPONSE BASED ON WORKFLOW
switch workflow
    case {1,2,4} % PROS
        %% STORMSIM: PROS
        % Define Workflow ID String
        if workflow == 4
            % Define Workflow Name
            wName = 'PROS-FB';
            subDir = [fullfile(subDir, 'PROS-FB'), filesep];
        else
            % Define Workflow Name
            wName = 'PROS';
            subDir = [fullfile(subDir, 'PROS'), filesep];
        end
        % Grab "project_forcing" Structure Fields
        switch storm_sampling
            case 'CC' % Combined Storm Sampling
                % Define First Structure Level
                level_1 = {'TC','XC'};
            otherwise % TC or XC
                % Define First Structure Level
                level_1 = {storm_sampling};
        end
        % Process Peaks Datasets: RB1
        if use_peaks == 1
            % Scan Peaks Datasets
            level_2 = fieldnames(project_forcing.(level_1{1}).('Peaks'));
            % Disp
            disp('Computing project responses with peaks....');
            % Loop Through All Peak Datasets & Storm Types
            for ii = 1:length(level_2)
                % Skip Based On Config File
                if (strcmp(level_2{ii},'WLP') && use_wlp == 0) || (strcmp(level_2{ii},'WHP') && use_whp == 0)
                    continue;
                else % Pass Peaks Dataset Through StormSim: PROS
                    % Disp
                    disp(['   Processing ' level_2{ii} ' dataset....']);
                    % Create Helper Var (Removes One Layer Of Classification)
                    for jj = 1:length(level_1)
                        % Create Aux Var
                        aux_var.(level_1{jj}) = project_forcing.(level_1{jj}).('Peaks').(level_2{ii});
                        % Grab TC Probabilities (If Needed)
                        if any(contains(fieldnames(project_forcing.(level_1{jj})),{'TC_Prob'}))
                            % Add TC_Prob To Aux Var
                            aux_var.(level_1{jj}).('TC_Prob') = project_forcing.(level_1{jj}).('TC_Prob');
                        end
                    end
                    % Call StormSim: PROS RB1
                    helper_var = stormsim_pros(config,...
                        aux_var, structure, emp_coeff, fullfile(subDir, [ wName '_RB1_' level_2{ii} ]));
                    % Get Available Storm Types
                    level_a = fieldnames(helper_var);
                    %
                    for jj = 1:length(level_a)
                        Resp.(level_a{jj}).('Peaks').(level_2{ii}) = helper_var.(level_a{jj}).('Peaks');
                    end
                    % Clear Aux Var
                    clearvars('aux_var');
                end
            end
        end
        % RB3
        if use_timeseries == 1
            % Disp
            disp('Computing structure responses using timeseries....');
            % Create Helper Var (Removes One Layer Of Classification)
            for jj = 1:length(level_1)
                % Create Aux Var
                aux_var.(level_1{jj}) = project_forcing.(level_1{jj}).('Timeseries');
                % Grab TC Probabilities (If Needed)
                if any(contains(fieldnames(project_forcing.(level_1{jj})),{'TC_Prob'}))
                    % Add TC_Prob To Aux Var
                    aux_var.(level_1{jj}).('TC_Prob') = project_forcing.(level_1{jj}).('TC_Prob');
                end
            end
            % Call StormSim: PROS RB3
            if use_peaks == 1 % Append To Existing
                aux_var = stormsim_pros(config,...
                    aux_var, structure, emp_coeff, fullfile(subDir, [ wName '_RB3' ]));
                % Check If XC & TC Exist
                level_a = fieldnames(helper_var);
                % Assign Results
                for ii = 1:length(level_a)
                    Resp.(level_a{ii}).Timeseries = aux_var.(level_a{ii}).Timeseries;
                end
            else % Create Resp Variable
                Resp = stormsim_pros(config,...
                    aux_var, structure, emp_coeff, fullfile(subDir, [ wName '_RB3' ]));
            end
        end
        % Plot Results
        if create_plots == 1
            call_pros_plots(config, structure, project_forcing, prob_mass, Resp);
        else
            if ~exist(subDir ,'dir')
                mkdir(subDir);
            end
        end
    case 3 % CSR
        %% STORMSIM: MCS-CSR
        % Print Status
        disp('Computing structure responses with peaks....');
        % Define Workflow ID
        wName = 'LCS';
        % Define Workflow Subdirectory
        subDir = [subDir filesep 'Life_Cycle_Simulation' filesep];
        % Scan Peaks Datasets
        if use_peaks == 1
            level_2 = fieldnames(project_forcing.(storm_sampling).('Peaks'));
            level_2 = level_2(contains(level_2,{'Maxima','WLP','WHP'}));
            % Loop Through All Peak Datasets & Storm Types
            for ii = 1:length(level_2)
                disp(['   Processing ' level_2{ii} ' dataset....']);
                % Compute Structure Respose: q, R2%, Dn50, Dn50 LCBW, P1
                [Resp.(storm_sampling).('Peaks').(level_2{ii}), ~] = compute_structure_response(config, structure, project_forcing.(storm_sampling).('Peaks').(level_2{ii}), emp_coeff, storm_sampling);
                % Rubblemound Only
                if structure_type == 3
                    % Compute Structure Response: Peaks Reliability
                    [Resp.(storm_sampling).('Peaks').(level_2{ii}).('PF_Summary'),...
                        Resp.(storm_sampling).('Peaks').(level_2{ii}).('Reliab_Summary')] = stormsim_csr_peaks(config,...
                        structure, emp_coeff,...
                        {project_forcing.(storm_sampling).('Peaks').(level_2{ii}).LCNUM});
                end
            end
        end
        % Timeseries
        if use_timeseries == 1
            disp('Computing structure responses using timeseries....');
            % Compute Structure Respose: q, R2%, Dn50, Dn50 LCBW, P1
            [Resp.(storm_sampling).('Timeseries'), ~] = compute_structure_response(config, structure, project_forcing.(storm_sampling).('Timeseries'), emp_coeff, storm_sampling);
            if structure_type == 3 % Rubblemound Only
                % Call StormSim: CSR Damage Progression Analysis
                [Resp.(storm_sampling).('Timeseries').S] = stormsim_csr_dpa(config, structure, emp_coeff, {project_forcing.(storm_sampling).('Timeseries').LCNUM});
                % Generate Plot Structure
                S_damage_plotter(config, Resp.(storm_sampling).Timeseries.S, 0, 0);
                % Create Subdirectory
                if ~exist([subDir 'LCS_DPA'],'dir')
                    mkdir([subDir 'LCS_DPA']);
                end
                % Move SST/JPM Outputs Into Subdir
                movefile([outDir '*Seaside*'],[subDir 'LCS_DPA']);
                movefile([outDir '*Leeside*'],[subDir 'LCS_DPA']);
            end
        end
end

%% EXPORT OUTPUTS
% Display Status
disp('Saving project responses....');
% Save Outputs
save([subDir project_name '_' struc_id '_' case_name '_' wName '_project_responses.mat'],'Resp','-v7.3');
end