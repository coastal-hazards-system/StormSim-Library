function project_forcing = call_project_forcing_adjuster(config, project_forcing, structure)
%% GRAB INPUTS FROM "config"
% Define Workflow
workflow = config.cast_workflow;
%% COMPUTE STRUCTURE RESPONSE BASED ON WORKFLOW
disp('Adjusting project forcing datasets....')
% Determine Data Type
switch workflow
    case 1
        wName = 'RB';
    case {2,3}
        wName = 'LCS';
end
% Grab "project_forcing" Structure Fields
level_1 = fieldnames(project_forcing);
% Scan Peaks Datasets
level_2 = fieldnames(project_forcing.(level_1{1}).('Peaks'));
level_2 = level_2(contains(level_2,{'Maxima','WLP','WHP'}));
% Scan Peaks And Timeseries Field
level_3 = fieldnames(project_forcing.(level_1{1}));
% Loop Through All Peak Datasets & Storm Types
for jj = 1:length(level_1)
    % Get Prob Mass
    if isfield(project_forcing.(level_1{jj}),'TC_Prob')
        continue;
        %aux_var.(level_1{jj}).('TC_Prob') = project_forcing.(level_1{jj}).('TC_Prob');
    end
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
end



