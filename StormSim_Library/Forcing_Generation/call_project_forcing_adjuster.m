function [project_forcing, config] = call_project_forcing_adjuster(config, project_forcing, structure)
%% GRAB INPUTS FROM "config"
% Define Workflow
workflow = config.workflow;
% Define If Peaks Are Being Used 
use_peaks = config.use_peaks;
% Grab Forcing Adjsutment Flag 
f_adjust = config.f_adjust;

%% ADJUST PROJECT FORCING ACCORDING TO WORKFLOW
% Adjust Forcing If Needed
if f_adjust == 0
    % Print Status
    disp('Adjusting project forcing datasets....');
    % Determine Data Type
    switch workflow
        case {1,2,4} % StormSim: PROS
            wName = 'PROS';
        case 3 % StormSim: LCS
            wName = 'LCS';
    end
    % Grab "project_forcing" Structure Fields
    level_1 = fieldnames(project_forcing);
    % Scan Peaks Datasets
    if use_peaks == 1
        level_2 = fieldnames(project_forcing.(level_1{1}).('Peaks'));
        level_2 = level_2(contains(level_2,{'Maxima','WLP','WHP'}));
    end
    % Loop Through All Peak Datasets & Storm Types
    for jj = 1:length(level_1)
        % Scan Peaks And Timeseries Field
        level_3 = fieldnames(project_forcing.(level_1{jj}));
        level_3 = level_3(contains(level_3,{'Peaks','Timeseries'}));
        % Loop Through Peaks/Timeseries
        for kk = 1:length(level_3)
            if strcmp(level_3{kk},{'Peaks'})
                for ii = 1:length(level_2)
                    % Create Aux Var
                    aux_var = project_forcing.(level_1{jj}).('Peaks').(level_2{ii});
                    % Assign To Output Variable
                    project_forcing.(level_1{jj}).('Peaks').(level_2{ii}) = adjust_project_forcing(config, structure, aux_var, level_1{jj}, wName);
                end
            else % Timeseries
                % Create Aux Var
                aux_var = project_forcing.(level_1{jj}).('Timeseries');
                % Assign To Output Variable
                project_forcing.(level_1{jj}).('Timeseries') = adjust_project_forcing(config, structure, aux_var, level_1{jj}, wName);
            end
        end
    end
    % Raise Flag In Case Function Is Executed Again
    config.f_adjust = 1;
else
    % Display Status Message
    disp('Project forcing has already been adjusted, skipping....');
end
end



