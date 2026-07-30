function [project_forcing, config]  = call_project_forcing_formater(config, storm, prob_mass)
%CALL_PROJECT_FORCING_FORMATER Loads/builds project_forcing, applying hotstart coverage checks.
% IMPORTANT: Callers MUST capture BOTH outputs:
%   [project_forcing, config] = call_project_forcing_formater(config, storm, prob_mass);
% The coverage check below can reset config.u_engine/config.f_adjust to 0
% when a cached project_forcing.mat does not cover the current request --
% later pipeline stages only see that reset if the second output is
% captured. No caller inside StormSim_Library currently enforces this.
%% GRAB INPUT FROM "config"
% Define Requested Workflow (1 -> RB1 Approach, other-> Life-Cycle Base)
workflow = config.workflow;
% Define Storm Type ('XC' or 'TC')
storm_sampling = config.storm_sampling;
% Initialize Load Flag As False
load_pass = false;
% Grab Sim File Paths
existing_file = config.out_files.project_forcing;

%% FORMAT FORCING DATA ACCORDING TO WORKFLOW
% Check If Project Forcing Exist
if exist(existing_file, 'file') == 2
    % Load Project Forcing
    load(existing_file,'project_forcing');
    % Check If Existing Data Complies With Request
    [covers, missing_desc] = project_forcing_coverage(config, project_forcing);
    if ~covers % Requested Data Is Not Present
        disp_toggle(config.print_progress, sprintf('Hotstart: cached project forcing does not cover requested permutation (missing: %s) -- deleting, will be regenerated....', missing_desc));
        delete(config.out_files.project_forcing);
        load_pass = false;
        config.u_engine = 0;
        config.f_adjust = 0;
    else
        disp('A project_forcing already exist for this alternative. Trying to load....');
        disp(['Successfully loaded:' existing_file]);
        load_pass = true;
    end
else
    % RESET DATA MOD FLAGS
    config.u_engine = 0;
    config.f_adjust = 0;
end

%% FORMAT STORM SUITE ACCORDING TO WORKFLOW
if ~load_pass
    % Prompt User
    disp('Preping project forcing data....');
    % Define Events Per Case
    switch workflow
        case {1,4} % StormSim: PROS (RB1, RB3, FB)
            % Reshape Forcing Parameters For RB Analysis (nStorms * normal_discretizations)
            project_forcing = stormsim_pros_formater(storm_sampling, storm, prob_mass, config.print_progress);
            % Save Peaks Life Cycle Structures
            save(existing_file,'project_forcing','-v7.3');
        case 3 % StormSim: LCS
            % Call StormSim: Monte Carlo Storm Sampler
            [project_forcing] = stormsim_lcs(config, storm, prob_mass);
            % Save Peaks Life Cycle Structures
            save(existing_file,'project_forcing','-v7.3');
    end
    % Save Config
    save(config.out_files.config, 'config', '-append');
end
end