function [structure, project_forcing, emp_coeff] = call_uncertainty_engine(config, structure, project_forcing)
%% GRAB INFORMATION FROM "config"
% Workflow Called
wFlow = config.cast_workflow;
% Load Empirical Coeffients
[emp_coeff] = load_empirical_coefficients();

%% APPLY FORCING AND STRCUCTURAL UNCERTAINTY
% Display Status Message
disp('Applying uncertainty to project forcing and structural parameters....');
% Execute Code Block By Workflow Type
switch wFlow
    case 1 % RB
        %% RESPONSE BASE
        % Scan For Storm Types In "project_forcing"
        level_1 = fieldnames(project_forcing);
        % For Each Storm Type
        for ii = 1:length(level_1)
            % Load Corresponding Normal Discretization File
            switch level_1{ii}
                case 'TC'
                    RandNorm = readmatrix('discrete_norm_444.txt')';
                    % Apply Forcing Uncertainty
                    [project_forcing] = apply_rb_uncertainty(config, project_forcing, 'TC', RandNorm);
                case 'XC'
                    RandNorm = readmatrix('discrete_norm_20.txt')';
                    % Apply Forcing Uncertainty
                    [project_forcing] = apply_rb_uncertainty(config, project_forcing, 'XC', RandNorm);
            end
            % Add Structural Parameter Uncertainty
            % None for PROS , Why ?
        end
    case {2,3} % LCS
        %% LIFE CYCLE BASE
        % Scan For Storm Types In "project_forcing"
        level_1 = fieldnames(project_forcing);
        % For Each Storm Sampling Scheme Available
        for ii = 1:length(level_1)
            % Scan Contents Of 2nd Structure Level
            level_2 = fieldnames(project_forcing.(level_1{ii}));
            % For Peaks And/Or Timeseries
            for jj = 1:length(level_2)
                % Search For Alternater DAtasets In Case Of Peaks
                if strcmp(level_2{jj},'Peaks')
                    % Scan Contents Of 3rd Structure Level
                    level_3 = fieldnames(project_forcing.(level_1{ii}).(level_2{jj}));
                    % Remove Sample Index Field
                    level_3 = level_3(contains(level_3,{'Maxima','WHP','WLP'}));
                    % For Each Dataset Found
                    for kk = 1:length(level_3)
                        % Extract LC Data
                        lc_data = project_forcing.(level_1{ii}).(level_2{jj}).(level_3{kk});
                        % Compute Structural Parameter UNcertainty Only Once
                        % Apply Uncertainty
                        [project_forcing.(level_1{ii}).(level_2{jj}).(level_3{kk}),...
                            structure.(level_1{ii}).(level_2{jj}).(level_3{kk}),...
                            emp_coeff.(level_1{ii}).(level_2{jj}).(level_3{kk})] = apply_lcs_uncertainty(config, lc_data, structure, emp_coeff, level_2{jj},1,1);
                    end
                else % Timeseries
                    % Extract LC Data
                    lc_data = project_forcing.(level_1{ii}).(level_2{jj});
                    % Apply Uncertainty
                    [project_forcing.(level_1{ii}).(level_2{jj}),...
                        structure.(level_1{ii}).(level_2{jj}),...
                        emp_coeff.(level_1{ii}).(level_2{jj})] = apply_lcs_uncertainty(config, lc_data, structure, emp_coeff, level_2{jj},1,1);
                end
            end
        end
end
end


