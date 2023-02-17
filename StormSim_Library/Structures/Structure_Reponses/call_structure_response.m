function [Resp] = call_structure_response(config, project_forcing, structure)
%% GRAB INPUTS FROM "config"
% Define Workflow
workflow = config.cast_workflow;
% Define Storm Sampling
storm_sampling = config.storm_sampling;
% Define Wave Height Priority Switch
use_whp = config.mcs_create_whp;
% Define Water Level Priority Switch
use_wlp = config.mcs_create_wlp;
%
use_timeseries = config.use_timeseries;
% Output Save Dir
outDir = [config.project_name, filesep, config.struc_id, filesep,...
    config.project_name,'_', config.struc_id];
% Load Empirical Coefficients
[emp_coeff] = load_empirical_coefficients();

%% COMPUTE STRUCTURE RESPONSE BASED ON WORKFLOW
switch workflow
    case 1 % PROS
        % Grab "project_forcing" Structure Fields
        level_1 = fieldnames(project_forcing);
        % Scan Peaks Datasets
        level_2 = fieldnames(project_forcing.(level_1{1}).('Peaks'));
        % Loop Through All Peak Datasets & Storm Types
        for ii = 1:length(level_2)
            for jj = 1:length(level_1)
                % Create Aux Var
                aux_var.(level_1{jj}) = project_forcing.(level_1{jj}).('Peaks').(level_2{ii});
                %
                if any(contains(fieldnames(project_forcing.(level_1{jj})),{'TC_Prob'}))
                    aux_var.(level_1{jj}).('TC_Prob') = project_forcing.(level_1{jj}).('TC_Prob');
                end
            end
            % Call StormSim; CSR Peaks Reliability
            helper_var = stormsim_pros(config,...
                aux_var, structure, emp_coeff);
            % Add Additional Layer To Data Structure For Peaks Alt Datasets
            if isfield(helper_var,'XC')
                Resp.('XC').('Peaks').(level_2{ii}) = helper_var.('XC').('Peaks');
            end
            if isfield(helper_var,'TC')
                Resp.('TC').('Peaks').(level_2{ii}) = helper_var.('TC').('Peaks');
            end
            clearvars('aux_var');
        end
        % RB3 
        if use_timeseries == 1
            for jj = 1:length(level_1)
                aux_var.(level_1{jj}) = project_forcing.(level_1{jj}).('Timeseries');
                if any(contains(fieldnames(project_forcing.(level_1{jj})),{'TC_Prob'}))
                    aux_var.(level_1{jj}).('TC_Prob') = project_forcing.(level_1{jj}).('TC_Prob');
                end
            end
              % Call StormSim; CSR Peaks Reliability - Need to debug , got
              % error in SST
            helper_var = stormsim_pros(config,...
                aux_var, structure, emp_coeff);  
            if isfield(helper_var,'XC')
                Resp.('XC').('Timeseries') = helper_var.('XC').('Timeseries');
            end
            if isfield(helper_var,'TC')
                Resp.('TC').('Timeseries') = helper_var.('TC').('Timeseries');
            end
        end
    case 3 % CSR

        % Call StormSim; CSR Peaks Reliability
        [Resp.(storm_sampling).('Peaks').('Maxima').('PF_Summary'),...
            Resp.(storm_sampling).('Peaks').('Maxima').('Reliab_Summary')] = stormsim_csr_peaks(config,...
            structure, emp_coeff,...
            {project_forcing.(storm_sampling).('Peaks').('Maxima').LCNUM});
        % Wave Height Priority
        if use_whp == 1
            [Resp.(storm_sampling).('Peaks').('WHP').('PF_Summary'),...
                Resp.(storm_sampling).('Peaks').('WHP').('Reliab_Summary')] = stormsim_csr_peaks(config,...
                structure, emp_coeff,...
                {project_forcing.(storm_sampling).('Peaks').('WHP').LCNUM});
        end
        % Water Level Priority
        if use_wlp == 1
            [Resp.(storm_sampling).('Peaks').('WLP').('PF_Summary'),...
                Resp.(storm_sampling).('Peaks').('WLP').('Reliab_Summary')] =  stormsim_csr_peaks(config,...
                structure, emp_coeff,...
                {project_forcing.(storm_sampling).('Peaks').('WLP').LCNUM});
        end
        % Timeseries
        if use_timeseries == 1
            % Call StormSim: CSR Damage Progression Analysis
            [Resp.(storm_sampling).('Timeseries')] = stormsim_csr_dpa(config, structure, emp_coeff, {project_forcing.(storm_sampling).('Timeseries').LCNUM});
        end
        % Display Status
        disp('Saving structure responses....');
        % Save Outputs
        save([outDir '_Structure_Response.mat'],'Resp','-v7.3');
        % Generate Plot Structure
end


end