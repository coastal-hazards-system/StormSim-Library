function [project_forcing, config] = call_project_forcing_adjuster(config, project_forcing, structure)
%% GRAB INPUTS FROM "config"
% Define Workflow
workflow = config.workflow;
use_peaks = config.use_peaks;
f_adjust = config.f_adjust;

%% COMPUTE STRUCTURE RESPONSE BASED ON WORKFLOW
if f_adjust == 0
disp('Adjusting project forcing datasets....')
% Determine Data Type
switch workflow
    case {1,2,4}
        wName = 'RB';
    case 3
        wName = 'LCS';
end
% Grab "project_forcing" Structure Fields
level_1 = fieldnames(project_forcing);
% Scan Peaks Datasets
if use_peaks == 1
    level_2 = fieldnames(project_forcing.(level_1{1}).('Peaks'));
    level_2 = level_2(contains(level_2,{'Maxima','WLP','WHP'}));
end
% Scan Peaks And Timeseries Field
level_3 = fieldnames(project_forcing.(level_1{1}));
level_3 = level_3(contains(level_3,{'Peaks','Timeseries'}));
% Loop Through All Peak Datasets & Storm Types
for jj = 1:length(level_1)
    % Loop Through Peaks/Timeseries
    for kk = 1:length(level_3)
        if strcmp(level_3{kk},{'Peaks'})
            for ii = 1:length(level_2)
                % Create Aux Var
                aux_var = project_forcing.(level_1{jj}).('Peaks').(level_2{ii});
                %
                project_forcing.(level_1{jj}).('Peaks').(level_2{ii}) = adjust_project_forcing(config, structure, aux_var, level_1{jj}, wName);
                %
            end
        else
            % Create Aux Var
            aux_var = project_forcing.(level_1{jj}).('Timeseries');
            %
            project_forcing.(level_1{jj}).('Timeseries') = adjust_project_forcing(config, structure, aux_var, level_1{jj}, wName);
        end
    end
end
config.f_adjust = 1;
else
    % Display Status Message
    disp('Project forcing has already been adjusted, skipping....');
end
end



