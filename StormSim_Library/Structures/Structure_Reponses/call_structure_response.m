function [Resp] = call_structure_response(config, project_forcing, structure)
%% GRAB INPUTS FROM "config"
% Define Workflow
workflow = config.cast_workflow;
% Define Storm Sampling
storm_sampling = config.storm_sampling;
% Define Wave Height Priority Switch
structure_type = config.struc_type;
%
use_timeseries = config.use_timeseries;
% Output Save Dir
outDir = [config.project_name, filesep, config.struc_id, filesep,...
    config.project_name,'_', config.struc_id];
% Use AEP Flag 
use_aep = config.pros_use_aep;
% Load Empirical Coefficients
[emp_coeff] = load_empirical_coefficients();

%% COMPUTE STRUCTURE RESPONSE BASED ON WORKFLOW
switch workflow
    case 1 % PROS
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
        disp(['Computing structure responses with peaks....']);
        % Loop Through All Peak Datasets & Storm Types
        for ii = 1:length(level_2)
            % Disp
            disp(['   Processing ' level_2{ii} ' dataset....']);
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
            % Define Subdir
            subDir = [config.project_name, filesep, config.struc_id, filesep];
            % Create Subdirectory
            if ~exist([subDir 'RB1_' level_2{ii}],'dir')
                mkdir([subDir 'RB1_' level_2{ii}]);
            else
                delete([subDir 'RB1_' level_2{ii} filesep '*.png']);
            end
            % Move SST/JPM Outputs Into Subdir
            if ~isempty(dir([subDir '*SST*']))
                movefile([subDir '*SST*'],[subDir 'RB1_' level_2{ii}]);
            end
            if ~isempty(dir([subDir '*JPM*']))
                movefile([subDir '*JPM*'],[subDir 'RB1_' level_2{ii}]);
            end
            if ~isempty(dir([subDir '*StormSim_CC*']))
                movefile([subDir '*StormSim_CC*'],[subDir 'RB1_' level_2{ii}]);
            end
        end
        level_a = fieldnames(Resp);
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
            % Define Subdir
            subDir = [config.project_name, filesep, config.struc_id, filesep];
            % Create Subdirectory
            mkdir([subDir 'RB3']);
            % Move SST/JPM Outputs Into Subdir
            % Move SST/JPM Outputs Into Subdir
            if ~isempty(dir([subDir '*SST*']))
                movefile([subDir '*SST*'],[subDir 'RB3']);
            end
            if ~isempty(dir([subDir '*JPM*']))
                movefile([subDir '*JPM*'],[subDir 'RB3']);
            end
            if ~isempty(dir([subDir '*StormSim_CC*']))
                movefile([subDir '*StormSim_CC*'],[subDir 'RB3']);
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
        S_damage_plotter(config, Resp.CC.Timeseries.S, 1, 0);
        % Define Subdir
        subDir = [config.project_name, filesep, config.struc_id, filesep];
        % Create Subdirectory
        mkdir([subDir 'LCS_DPA']);
        % Move SST/JPM Outputs Into Subdir
        movefile([subDir '*Seaside*'],[subDir 'LCS_DPA']);
        movefile([subDir '*Leeside*'],[subDir 'LCS_DPA']);
end

%% EXPORT OUTPUTS
% Display Status
disp('Saving project responses....');
% Save Outputs
save([outDir '_' wName '_project_responses.mat'],'Resp','-v7.3');
end