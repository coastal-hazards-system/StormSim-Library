function project_forcing = call_project_forcing_formater(config, storm, prob_mass)
%% GRAB INPUT FROM "config"
% Define Requested Workflow (1 -> RB1 Approach, other-> Life-Cycle Base)
workflow = config.workflow;
% Define Storm Type ('XC' or 'TC')
storm_sampling = config.storm_sampling;
% Define Save Name
save_name = fullfile(config.outfolder, config.project_name, config.struc_id,...
    config.case_name , [config.project_name,'_', config.struc_id]);
% Define MCS Project Forcing Mode
load_project_forcing = config.load_project_forcing;
% Define Reference Case_name
ref_case_name = config.ref_case_name;
% Define Workflow Key Phrase
switch workflow
    case 1 % PROS - RB
        wName = 'PROS';
    case 3 % PROS - EVA
        wName = 'LCS';
    case 4 % PROS - FB
        wName = 'PROS-FB';
end
% Initialize Load Flag As False
load_pass = false;

%% FORMAT FORCING DATA ACCORDING TO WORKFLOW
% Build Ref Case Path
mcs_ref_pth = fullfile(config.outfolder, config.project_name, config.struc_id,...
    ref_case_name, [config.project_name,'_', config.struc_id, '_' wName '_project_forcing.mat']);
% Evaluate According To User Selection
if load_project_forcing == 1 && exist(mcs_ref_pth,'file')
    try
        % Load Project Forcing
        load(mcs_ref_pth,'project_forcing');
        % Copy To Current Case
        if ~exist([save_name '_' wName '_project_forcing.mat'], 'file')
            copyfile(mcs_ref_pth, [save_name '_' wName '_project_forcing.mat']);
        end
        % Project Forcing Was Succesfully Loaded, Skip Next Step
        load_pass = true;
        % Prompt User Of Loading
        dips(['Successfully loaded project_forcing from simulation case'  ref_case_name]);
    catch
        % Prompt User Of Loading Fail
        dips(['Loading of project_forcing from simulation case'  ref_case_name 'failed. Initializing new run....']);
        % Set Load Flag To False
        load_pass = false; % Will create new "project_forcing" according to requested workflow.
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
            project_forcing = stormsim_pros_formater(storm_sampling, storm, prob_mass);
            % Save Peaks Life Cycle Structures
            save([save_name '_' wName '_project_forcing.mat'],'project_forcing','-v7.3');
        case 3 % StormSim: LCS
            % Call StormSim: Monte Carlo Storm Sampler
            [project_forcing] = stormsim_lcs(config, storm, prob_mass);
            % Save Peaks Life Cycle Structures
            save([save_name '_' wName '_project_forcing.mat'],'project_forcing','-v7.3');
    end
end
end