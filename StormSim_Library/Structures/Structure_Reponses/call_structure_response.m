function [Resp] = call_structure_response(config, project_forcing, structure, emp_coeff)
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

%% COMPUTE STRUCTURE RESPONSE BASED ON WORKFLOW
switch workflow
    case 1 %PROS
        % Compute Structure R2% , q and P1

        % Compute Dn50 (Rubblemound)

        % Compute P2 & P3 (Floodwalls)

        % Combine Hazards

        % Generate Plot Structure

    case 3 % CSR
        % Call StormSim; CSR Peaks Reliability
        [Resp.(storm_sampling).('Peaks').('Maxima').('PF_Summary'),...
            Resp.(storm_sampling).('Peaks').('Maxima').('Reliab_Summary')] = stormsim_csr_peaks(config,...
            structure.(storm_sampling).('Peaks').('Maxima'), emp_coeff.(storm_sampling).('Peaks').('Maxima'),...
            {project_forcing.(storm_sampling).('Peaks').('Maxima').LCNUM});
        % Wave Height Priority
        if use_whp == 1
            [Resp.(storm_sampling).('Peaks').('WHP').('PF_Summary'),...
                Resp.(storm_sampling).('Peaks').('WHP').('Reliab_Summary')] = stormsim_csr_peaks(config,...
                structure.(storm_sampling).('Peaks').('WHP'), emp_coeff.(storm_sampling).('Peaks').('WHP'),...
                {project_forcing.(storm_sampling).('Peaks').('WHP').LCNUM});
        end
        % Water Level Priority
        if use_wlp == 1
            [Resp.(storm_sampling).('Peaks').('WLP').('PF_Summary'),...
                Resp.(storm_sampling).('Peaks').('WLP').('Reliab_Summary')] =  stormsim_csr_peaks(config,...
                structure.(storm_sampling).('Peaks').('WLP'), emp_coeff.(storm_sampling).('Peaks').('WLP'),...
                {project_forcing.(storm_sampling).('Peaks').('WLP').LCNUM});
        end
        %
        % Timeseries
        if use_timeseries == 1
            % Replace Peak In Timeseries With Peak Reported In Peaks File
            [project_forcing.(storm_sampling).('Timeseries')] = time_series_peak_replacer(project_forcing.(storm_sampling).('Timeseries'),...
                project_forcing.(storm_sampling).('Peaks').('Maxima'),...
                project_forcing.(storm_sampling).('Peaks').sampled_storms_indx);
            % Call StormSim: CSR Damage Progression Analysis
            [Resp.(storm_sampling).('Timeseries')] = stormsim_csr_dpa(config, structure.(storm_sampling).('Timeseries'), emp_coeff.(storm_sampling).('Timeseries'), LC_SimOUT_hyd);
        end
        % Display Status
        disp('Saving structure responses....');
        % Save Outputs
        save([outDir '_Structure_Response.mat'],'Resp','-v7.3');
        % Generate Plot Structure
end


end