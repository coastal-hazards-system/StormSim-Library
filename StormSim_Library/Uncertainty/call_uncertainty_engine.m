function project_forcing = call_uncertainty_engine(config, project_forcing)
%% GRAB INFORMATION FROM "config"
% Workflow Called
wFlow = config.cast_workflow;

%% APPLY FORCING AND STRCUCTURAL UNCERTAINTY
% Display Status Message
disp('Applying uncertainty to project forcing....');
% Execute Code Block By Workflow Type
switch wFlow
    case 1 % RB
        %% RESPONSE BASE
        % Define Workflow Key Phrase
        wName = 'RB';
        % Scan For Storm Types In "project_forcing"
        level_1 = fieldnames(project_forcing);
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
            level_2 = fieldnames(project_forcing.(level_1{ii}));
            level_2 = level_2(contains(level_2, {'Peaks','Timeseries'}));
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
                        % Data
                        data = project_forcing.(level_1{ii}).(level_2{jj}).(level_3{kk});
                        % Apply Uncertainty
                        if strcmp(level_1{ii},'TC')
                            [project_forcing.(level_1{ii}).(level_2{jj}).(level_3{kk}),...
                                project_forcing.(level_1{ii}).TC_Prob] = apply_rb_uncertainty(config, data,...
                                project_forcing.(level_1{ii}).TC_Freq, 'Peaks', RandNorm);
                        else
                            [project_forcing.(level_1{ii}).(level_2{jj}).(level_3{kk}), ~] = apply_rb_uncertainty(config, data, [], 'Peaks', RandNorm);
                        end
                    end
                else % Timeseries
                    % Data
                    data = project_forcing.(level_1{ii}).(level_2{jj});
                    % Apply Uncertainty
                    if strcmp(level_1{ii},'TC')
                        [project_forcing.(level_1{ii}).(level_2{jj}),...
                            project_forcing.(level_1{ii}).TC_Prob] = apply_rb_uncertainty(config, data,...
                            project_forcing.(level_1{ii}).TC_Freq, 'Timeseries', RandNorm);
                    else
                        [project_forcing.(level_1{ii}).(level_2{jj}), ~] = apply_rb_uncertainty(config, data, [], 'Timeseries', RandNorm);
                    end
                end
            end
        end
    case {2,3} % LCS
        %% LIFE CYCLE BASE
        % Define Workflow Key Phrase
        wName = 'LCS';
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
                        project_forcing.(level_1{ii}).(level_2{jj}).(level_3{kk}) = apply_lcs_uncertainty(config, lc_data, level_2{jj});
                    end
                else % Timeseries
                    % Extract LC Data
                    lc_data = project_forcing.(level_1{ii}).(level_2{jj});
                    % Apply Uncertainty
                    project_forcing.(level_1{ii}).(level_2{jj})= apply_lcs_uncertainty(config, lc_data, level_2{jj});
                end
            end
        end
end
end


