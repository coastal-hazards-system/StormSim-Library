function [project_forcing, config] = call_project_forcing_adjuster(config, project_forcing, structure)
%% GRAB INPUTS FROM "config"
% Grab Forcing Adjsutment Flag
f_adjust = config.f_adjust;
save_name = fullfile(config.outfolder, config.project_name, config.struc_id,...
    config.case_name , [config.project_name,'_', config.struc_id]);
% Define Workflow Key Phrase
switch config.workflow
    case 1
        wName = 'PROS-RB';
    case 4 % PROS
        wName = 'PROS-FB';
    case 3 % LCS
        wName = 'LCS';
end

%% ADJUST PROJECT FORCING ACCORDING TO WORKFLOW
% Adjust Forcing If Needed
if f_adjust == 0
    % Print Status
    disp('Adjusting project forcing datasets....');
    % Scan For Data Types
    data_types = fieldnames(project_forcing);
    % Loop Across Each Data Type
    for dt = 1:length(data_types)
        % Scan For Matching Types
        match_types = fieldnames(project_forcing.(data_types{dt}));
        % Loop Across Each Matching Type
        for mt = 1:length(match_types)
            % Scan For Storm Types
            storm_types = fieldnames(project_forcing.(data_types{dt}).(match_types{mt}));
            % Loop Across Each Storm Type
            for st = 1:length(storm_types)
                % Data
                data = project_forcing.(data_types{dt}).(match_types{mt}).(storm_types{st});
                % Adjust Project Forcing Fields
                [project_forcing.(data_types{dt}).(match_types{mt}).(storm_types{st}), config] = adjust_project_forcing(config, structure, data, storm_types{st});
            end
        end
    end
    % Raise Flag In Case Function Is Executed Again
    config.f_adjust = 1;
    %% SAVE OUT ADJUSTED & WITH UNCERTAINTY PROJECT_FROCING & CONFIG
    save([save_name '_' wName '_project_forcing.mat'], 'project_forcing','-v7.3');
    save([save_name '_' config.case_name '_config_file.mat'], 'config', '-append');
else
    % Display Status Message
    disp('Project forcing has already been adjusted, skipping....');
end
end



