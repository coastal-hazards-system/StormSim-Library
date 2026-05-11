function [project_forcing, config]  = call_project_forcing_formater(config, storm, prob_mass)
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
    has_peaks = contains('Peaks', fieldnames(project_forcing));
    if ~has_peaks
        has_wlp = false;
        has_whp = false;
    else
        has_wlp = contains('WLP', fieldnames(project_forcing.Peaks));
        has_whp = contains('WHP', fieldnames(project_forcing.Peaks));
    end
    has_timeseries = contains('Timeseries', fieldnames(project_forcing));
    if ~has_peaks
        has_xc = contains('XC', fieldnames(project_forcing.Timeseries.Default));
        has_tc = contains('TC', fieldnames(project_forcing.Timeseries.Default));
    else
        has_xc = contains('XC', fieldnames(project_forcing.Peaks.Default));
        has_tc = contains('TC', fieldnames(project_forcing.Peaks.Default));
    end
    % Define Storm Type Needs
    switch lower(config.storm_sampling)
        case 'xc'
            tc_conf = false;
            xc_conf = true;
        case 'tc'
            tc_conf = true;
            xc_conf = false;
        case 'cc'
            tc_conf = true;
            xc_conf = true;
    end
    % Build Boolean Table
    have = [has_peaks;has_wlp;has_whp;has_timeseries;has_tc;has_xc];
    need = [cellfun(@(x) logical(config.(x)), {'use_peaks','create_wlp','create_whp','use_timeseries'}, 'un', true)';tc_conf;xc_conf];
    % Check If Loaded Project Forcing Meets The Requirements
    if any(~have(need)) % Requested Data Is Not Present
        delete(config.out_files.project_forcing);
        load_pass = false;
        config.u_engine = 0;
        config.f_adjust = 0;
    else
        disp('A project_forcing already exist for this alternative. Trying to load....');
        disp(['Successfully loaded:' existing_file]);
        load_pass = true;
    end
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
    % RESET DATA MOD FLAGS
    config.u_engine = 0;
    config.f_adjust = 0;
end
end