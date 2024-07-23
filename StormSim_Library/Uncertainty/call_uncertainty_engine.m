function [project_forcing, config] = call_uncertainty_engine(config, project_forcing)
%% GRAB INFORMATION FROM "config"
% Workflow Called
wFlow = config.workflow;
% Grab Uncertainty Application Flag
u_engine = config.u_engine; % Check if user has already applied uncertainty with this function

%% APPLY FORCING AND STRCUCTURAL UNCERTAINTY
if u_engine == 0 % Uncertainty Has Not Been Applied To Project Forcing Replicates
    % Display Status Message
    disp('Applying uncertainty to project forcing....');
    % Execute Code Block By Workflow Type
    switch wFlow
        case 1 % StormSim: PROS
            %% STORMSIM: PROS (STRUCTURE DESIGN)
            % Scan For Storm Types In "project_forcing"
            level_1 = fieldnames(project_forcing); % XC and/or TC
            % For Each Storm Sampling Scheme Available
            for ii = 1:length(level_1)
                % Load RandNorm
                switch level_1{ii}
                    case 'TC'
                        RandNorm = readmatrix('discrete_norm_444.txt')';
                    case 'XC'
                        RandNorm = readmatrix('discrete_norm_20.txt')';
                end
                % Scan Contents Of 2nd Structure Level
                level_2 = fieldnames(project_forcing.(level_1{ii})); % Peaks and/or Timeseries
                level_2 = level_2(contains(level_2, {'Peaks','Timeseries'}));
                % For Peaks And/Or Timeseries
                for jj = 1:length(level_2)
                    % Search For Alternater DAtasets In Case Of Peaks
                    if strcmp(level_2{jj},'Peaks')
                        % Scan Contents Of 3rd Structure Level
                        level_3 = fieldnames(project_forcing.(level_1{ii}).(level_2{jj}));
                        % Remove Sample Index Field
                        level_3 = level_3(contains(level_3,{'Maxima','WHP','WLP'})); % Maxima, Wave Height Priority, Water Level Priority
                        % For Each Dataset Found
                        for kk = 1:length(level_3)
                            % Data
                            data = project_forcing.(level_1{ii}).(level_2{jj}).(level_3{kk});
                            % Apply Uncertainty
                            [project_forcing.(level_1{ii}).(level_2{jj}).(level_3{kk})] = apply_pros_uncertainty(config, data, 'Peaks', RandNorm);
                        end
                    else % Timeseries
                        % Data
                        data = project_forcing.(level_1{ii}).(level_2{jj}); % Timeseries Are Restricted To Maxima Data Matching Only
                        % Apply Uncertainty
                        [project_forcing.(level_1{ii}).(level_2{jj})] = apply_pros_uncertainty(config, data, 'Timeseries', RandNorm);
                    end
                end
            end
        case {2,4} % SST/JPM for Forcing Only Using RB1 & RB3 Approach
            % Do nothing, Uncertainty is incorporated inside SST/JPM
            % StormSim: EVA, StormSim: PROS-FB
        case 3 % LCS
            %% LIFE CYCLE BASE
            % Scan For Storm Types In "project_forcing"
            level_1 = fieldnames(project_forcing); % XC and/or TC
            % For Each Storm Sampling Scheme Available
            for ii = 1:length(level_1)
                % Scan Contents Of 2nd Structure Level
                level_2 = fieldnames(project_forcing.(level_1{ii})); % Peaks and/or Timeseries
                % For Peaks And/Or Timeseries
                for jj = 1:length(level_2)
                    % Search For Alternater DAtasets In Case Of Peaks
                    if strcmp(level_2{jj},'Peaks')
                        % Scan Contents Of 3rd Structure Level
                        level_3 = fieldnames(project_forcing.(level_1{ii}).(level_2{jj})); % Maxima, Wave Height Priority, Water Level Priority
                        % Remove Sample Index Field
                        level_3 = level_3(contains(level_3,{'Maxima','WHP','WLP'}));
                        % For Each Dataset Found
                        for kk = 1:length(level_3)
                            % Extract LC Data
                            lc_data = project_forcing.(level_1{ii}).(level_2{jj}).(level_3{kk});
                            % Compute Structural Parameter UNcertainty Only Once
                            % Apply Uncertainty
                            project_forcing.(level_1{ii}).(level_2{jj}).(level_3{kk}) = apply_lcs_uncertainty(config, lc_data, level_2{jj});
                        end
                    else % Timeseries
                        % Extract LC Data
                        lc_data = project_forcing.(level_1{ii}).(level_2{jj}); % Timeseries Are Restricted To Maxima Data Matching Only
                        % Apply Uncertainty
                        project_forcing.(level_1{ii}).(level_2{jj})= apply_lcs_uncertainty(config, lc_data, level_2{jj});
                    end
                end
            end
    end
    % Add Uncertainty Application Flag To Config
    config.u_engine = 1;
else % Project Forcing Replicates Already Have Uncertainty Applied
    % Display Status Message
    disp('Project forcing already has uncertainty, skipping....');
end
end


