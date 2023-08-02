function [Resp] = call_project_response(config, project_forcing, structure)
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
    case {1,2,4} % PROS
        %% STORMSIM: PROS
        % Define Workflow ID String
        if workflow == 4
            % Define Workflow Name
            wName = 'FB';
        else
            % Define Workflow Name
            wName = 'RB';
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
                    % Create Subdirectory
                    if ~exist([subDir wName '1_' level_2{ii}],'dir')
                        mkdir([subDir wName '1_' level_2{ii}]);
                    else % Directory Exist
                        % Delete Existing Files
                        delete([subDir wName '1_' level_2{ii} filesep '*.png']);
                    end
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
                        aux_var, structure, emp_coeff, [subDir wName '1_' level_2{ii}]);
                    % Check If XC & TC Exist
                    level_a = fieldnames(helper_var);
                    % Create Subdirectory
                    if ~exist([subDir wName '1_' level_2{ii} '_Hazards_Cross-Sections'],'dir')
                        mkdir([subDir wName '1_' level_2{ii} '_Hazards_Cross-Sections']);
                    else % Directory Exist
                        % Delete Existing Files
                        delete([subDir wName '1_' level_2{ii} '_Hazards_Cross-Sections' filesep '*.png']);
                    end
                    % Add Additional Layer To Data Structure For Peaks Alt Datasets
                    for jj = 1:length(level_a)
                        Resp.(level_a{jj}).('Peaks').(level_2{ii}) = helper_var.(level_a{jj}).('Peaks');
                        % Plot Cross-section For Each Storm Type
                        plot_structure_and_forcing(config, Resp.(level_a{jj}).('Peaks').(level_2{ii}),...
                            structure, level_a{jj},[subDir wName '1_' level_2{ii} '_Hazards_Cross-Sections']);
                    end
                    % Clear Aux Var
                    clearvars('aux_var');
                end
            end

            % Only If there Is 2 Or More Peaks Datasets
            if length(fieldnames(Resp.(level_a{1}).('Peaks')))>=2
                % Make Dir
                if ~exist([subDir wName '1_Comparison'],'dir')
                    mkdir([subDir wName '1_Comparison']);
                else
                    delete([subDir wName '1_Comparison' filesep '*.png']);
                end
                % Create RB1 Peak Dataset HC Comparison Figures
                for ii = 1:length(level_a)
                    % Create Comparison Figure
                    peaks_hc_stack_plot(Resp, level_a{ii}, use_aep, 'h', [subDir wName '1_Comparison']);
                end
            end
            % Create Project Forcing + HC Comparison Figure
            if compute_forcing_hc == 1 || workflow == 2
                % Create Figures
                peaks_hc_and_storms_stack_plot(config, Resp, project_forcing, 0, [subDir wName '1_Project_Forcing_Comparison']);
            end
        end
        % RB3
        if use_timeseries == 1
            % Disp
            disp('Computing structure responses using timeseries....');
            % Create Subdirectory
            if ~exist([subDir wName '3'],'dir')
                mkdir([subDir wName '3']);
            else % Directory Exist
                % Delete Existing Files
                delete([subDir wName '3' filesep '*.png']);
            end
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
            % Create Subdirectory
            if ~exist([subDir wName '3_Hazards_Cross-Sections'],'dir')
                mkdir([subDir wName '3_Hazards_Cross-Sections']);
            else % Directory Exist
                % Delete Existing Files
                delete([subDir wName '3_Hazards_Cross-Sections' filesep '*.png']);
            end
            % Call StormSim: PROS RB3
            if use_peaks == 1 % Append To Existing
                aux_var = stormsim_pros(config,...
                    aux_var, structure, emp_coeff, [subDir wName '3']);
                % Assign Results
                for ii = 1:length(level_a)
                    Resp.(level_a{ii}).Timeseries = aux_var.(level_a{ii}).Timeseries;
                    % Plot Cross-section For Each Storm Type
                    plot_structure_and_forcing(config, Resp.(level_a{ii}).('Timeseries'),...
                        structure, level_a{ii},[subDir wName '3_Hazards_Cross-Sections']);
                end
            else % Create Resp Variable
                Resp = stormsim_pros(config,...
                    aux_var, structure, emp_coeff, [subDir wName '3']);
                % Add Additional Layer To Data Structure For Peaks Alt Datasets
                for jj = 1:length(level_1)
                    % Plot Cross-section For Each Storm Type
                    plot_structure_and_forcing(config, Resp.(level_1{jj}).('Timeseries'),...
                        structure, level_1{jj},[subDir wName '3_Hazards_Cross-Sections']);
                end
            end
            % Create Project Forcing + HC Comparison Figure
            if compute_forcing_hc == 1 || workflow == 2
                % Create Figures
                peaks_hc_and_storms_stack_plot(config, Resp, project_forcing, 1, [subDir wName '3_Project_Forcing_Comparison']);
            end
        end

        % RB1 vs RB3
        if use_peaks == 1 && use_timeseries == 1
            % Only If there Is 2 Or More Peaks Datasets
            % Create RB1 Peak Dataset HC Comparison Figures
            for jj = 1:length(level_2)
                % Make Dir
                if ~exist([subDir wName '1_' level_2{jj} '_' wName '3_Comparison'],'dir')
                    mkdir([subDir wName '1_' level_2{jj} '_' wName '3_Comparison']);
                else
                    delete([subDir wName '1_' level_2{jj} '_' wName '3_Comparison' filesep '*.png']);
                end
                for ii = 1:length(level_a)
                    % Create Comparison Figure
                    response_base_comparison(Resp.(level_a{ii}).('Peaks').(level_2{jj}), Resp.(level_a{ii}).('Timeseries'), level_a{ii}, use_aep, 'h', [subDir wName '1_' level_2{jj} '_' wName '3_Comparison']);
                end
            end
        end
    case 3 % CSR
        %% STORMSIM: MCS-CSR
        disp('Computing structure responses with peaks....');
        wName = 'LCS';
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