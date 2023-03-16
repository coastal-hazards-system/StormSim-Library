function [Resp] = call_project_response(config, project_forcing, structure)
%% GRAB INPUTS FROM "config"
% Define Workflow
workflow = config.workflow;
% Define Storm Sampling
storm_sampling = config.storm_sampling;
% Define Wave Height Priority Switch
structure_type = config.struc_type;
%
use_timeseries = config.use_timeseries;
% WLP & WHP Switches
use_whp = config.mcs_create_whp;
use_wlp = config.mcs_create_wlp;
% Compute Forcing HC
compute_forcing_hc = config.pros_compute_forcing_HC;
% Project Name
project_name = config.project_name;
% Transect Id
struc_id = config.struc_id;
% Define Case  Name
case_name = config.case_name;
% Define
subDir = [project_name filesep struc_id filesep case_name filesep];
% Output Save Dir
outDir = [project_name, filesep, struc_id, filesep,...
    project_name,'_', struc_id];
% Use AEP Flag
use_aep = config.pros_use_aep;
% Load Empirical Coefficients
[emp_coeff] = load_empirical_coefficients();

%% COMPUTE STRUCTURE RESPONSE BASED ON WORKFLOW
switch workflow
    case {1,2} % PROS
        %% STORMSIM: PROS
        % Grab "project_forcing" Structure Fields
        switch storm_sampling
            case 'XC'
                level_1 = {'XC'};
            case 'TC'
                level_1 = {'TC'};
            case 'CC'
                level_1 = {'TC','XC'};
        end
        wName = 'RB';
        % Scan Peaks Datasets
        level_2 = fieldnames(project_forcing.(level_1{1}).('Peaks'));
        % Disp
        disp(['Computing project responses with peaks....']);
        % Loop Through All Peak Datasets & Storm Types
        for ii = 1:length(level_2)
            % Skip Based On Config File
            if (strcmp(level_2{ii},'WLP') && use_wlp == 0) || (strcmp(level_2{ii},'WHP') && use_whp == 0)
                continue;
            else
                % Disp
                disp(['   Processing ' level_2{ii} ' dataset....']);
                % Create Helper Var (Removes One Layer Of Classification)
                for jj = 1:length(level_1)
                    % Create Aux Var
                    aux_var.(level_1{jj}) = project_forcing.(level_1{jj}).('Peaks').(level_2{ii});
                    %
                    if any(contains(fieldnames(project_forcing.(level_1{jj})),{'TC_Prob'}))
                        aux_var.(level_1{jj}).('TC_Prob') = project_forcing.(level_1{jj}).('TC_Prob');
                    end
                end
                % Call StormSim: PROS RB1
                helper_var = stormsim_pros(config,...
                    aux_var, structure, emp_coeff);
                % Add Additional Layer To Data Structure For Peaks Alt Datasets
                if isfield(helper_var,'XC')
                    Resp.('XC').('Peaks').(level_2{ii}) = helper_var.('XC').('Peaks');
                end
                if isfield(helper_var,'TC')
                    Resp.('TC').('Peaks').(level_2{ii}) = helper_var.('TC').('Peaks');
                end
                if isfield(helper_var,'CC')
                    Resp.('CC').('Peaks').(level_2{ii}) = helper_var.('CC').('Peaks');
                end
                clearvars('aux_var');
                % Create Subdirectory
                if ~exist([subDir 'RB1_' level_2{ii}],'dir')
                    mkdir([subDir 'RB1_' level_2{ii}]);
                else
                    delete([subDir 'RB1_' level_2{ii} filesep '*.png']);
                end
                % Move SST/JPM Outputs Into Subdir
                if ~isempty(dir([outDir '*SST*']))
                    movefile([outDir '*SST*'],[subDir 'RB1_' level_2{ii}]);
                end
                if ~isempty(dir([outDir '*JPM*']))
                    movefile([outDir '*JPM*'],[subDir 'RB1_' level_2{ii}]);
                end
                if ~isempty(dir([outDir '*StormSim_CC*']))
                    movefile([outDir '*StormSim_CC*'],[subDir 'RB1_' level_2{ii}]);
                end
            end
        end
        % Check If XC & TC Exist
        level_a = fieldnames(Resp);
            % Only If there Is 2 Or More Peaks Datasets
            if length(fieldnames(Resp.(level_a{1}).('Peaks')))>=2
                % Create RB1 Peak Dataset HC Comparison Figures
                for ii = 1:length(level_a)
                    % Create Comparison Figure
                    peaks_hc_stack_plot(Resp, level_a{ii}, use_aep, 'h', outDir);
                end
                % Make Dir
                if ~exist([subDir 'RB1_Comparison'],'dir')
                    mkdir([subDir 'RB1_Comparison']);
                end
                % Move Files
                movefile([outDir '_StormSim_Peaks_*'],[subDir 'RB1_Comparison']);
            end
         % Create Project Forcing + HC Comparison Figure
            if compute_forcing_hc == 1
                % Create Figures
                peaks_hc_and_storms_stack_plot(config, Resp, project_forcing, outDir);
                % Make Dir
                if ~exist([subDir 'RB1_Project_Forcing_Comparison'],'dir')
                    mkdir([subDir 'RB1_Project_Forcing_Comparison']);
                end
                % Move Files
                movefile([outDir '*Project_Forcing_and_Hazard_Curve_Comparison*'],[subDir 'RB1_Project_Forcing_Comparison']);
            end

        % RB3
        if use_timeseries == 1
            % Disp
            disp('Computing structure responses using timeseries....');
            for jj = 1:length(level_1)
                aux_var.(level_1{jj}) = project_forcing.(level_1{jj}).('Timeseries');
                if any(contains(fieldnames(project_forcing.(level_1{jj})),{'TC_Prob'}))
                    aux_var.(level_1{jj}).('TC_Prob') = project_forcing.(level_1{jj}).('TC_Prob');
                end
            end
            % Call StormSim: PROS RB3
            helper_var = stormsim_pros(config,...
                aux_var, structure, emp_coeff);
            if isfield(helper_var,'XC')
                Resp.('XC').('Timeseries') = helper_var.('XC').('Timeseries');
            end
            if isfield(helper_var,'TC')
                Resp.('TC').('Timeseries') = helper_var.('TC').('Timeseries');
            end
            if isfield(helper_var,'CC')
                Resp.('CC').('Timeseries') = helper_var.('CC').('Timeseries');
            end
            % Create Subdirectory
            if ~exist([subDir 'RB3'],'dir')
                mkdir([subDir 'RB3']);
            end
            % Move SST/JPM Outputs Into Subdir
            % Move SST/JPM Outputs Into Subdir
            if ~isempty(dir([outDir '*SST*']))
                movefile([outDir '*SST*'],[subDir 'RB3']);
            end
            if ~isempty(dir([outDir '*JPM*']))
                movefile([outDir '*JPM*'],[subDir 'RB3']);
            end
            if ~isempty(dir([outDir '*StormSim_CC*']))
                movefile([outDir '*StormSim_CC*'],[subDir 'RB3']);
            end
        end
    case 3 % CSR
        %% STORMSIM: MCS-CSR
        disp('Computing structure responses with peaks....');
        wName = 'LCS';
        % Scan Peaks Datasets
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
        % Timeseries
        if use_timeseries == 1
            disp('Computing structure responses using timeseries....');
            % Compute Structure Respose: q, R2%, Dn50, Dn50 LCBW, P1
            [Resp.(storm_sampling).('Timeseries'), ~] = compute_structure_response(config, structure, project_forcing.(storm_sampling).('Timeseries'), emp_coeff, storm_sampling);
            if structure_type == 3 % Rubblemound Only
                % Call StormSim: CSR Damage Progression Analysis
                [Resp.(storm_sampling).('Timeseries').S] = stormsim_csr_dpa(config, structure, emp_coeff, {project_forcing.(storm_sampling).('Timeseries').LCNUM});
            end
        end
        % Generate Plot Structure
        S_damage_plotter(config, Resp.(storm_sampling).Timeseries.S, 1, 0);
        % Create Subdirectory
        if ~exist([subDir 'LCS_DPA'],'dir')
            mkdir([subDir 'LCS_DPA']);
        end
        % Move SST/JPM Outputs Into Subdir
        movefile([outDir '*Seaside*'],[subDir 'LCS_DPA']);
        movefile([outDir '*Leeside*'],[subDir 'LCS_DPA']);
end

%% EXPORT OUTPUTS
% Display Status
disp('Saving project responses....');
% Save Outputs
save([subDir project_name '_' struc_id '_' case_name '_' wName '_project_responses.mat'],'Resp','-v7.3');
end