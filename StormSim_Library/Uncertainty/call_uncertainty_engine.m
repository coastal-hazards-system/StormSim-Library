function [project_forcing, config] = call_uncertainty_engine(config, project_forcing)
%% APPLY FORCING AND STRCUCTURAL UNCERTAINTY
if config.u_engine == 0 % Uncertainty Has Not Been Applied To Project Forcing Replicates
    % Display Status Message
    disp('Applying uncertainty to project forcing....');
    %% STORMSIM: PROS (STRUCTURE DESIGN)
    % Scan For Data Types
    data_types = fieldnames(project_forcing);
    % Loop Across Each Data Type
    for dt = 1:length(data_types) % Peaks , Timeseries
        % Scan For Matching Types
        match_types = fieldnames(project_forcing.(data_types{dt}));
        % Keep Relevant Fields
        match_types = match_types(contains(match_types, {'Default','WLP','WHP'}));
        % Loop Across Each Matching Type
        for mt = 1:length(match_types) % Default, WLP, WHP
            % Scan For Storm Types
            storm_types = fieldnames(project_forcing.(data_types{dt}).(match_types{mt}));
            % Loop Across Each Storm Type
            for st = 1:length(storm_types) % XC, TC, CC
                % Data
                data = project_forcing.(data_types{dt}).(match_types{mt}).(storm_types{st});
                % Load RandNorm
                switch config.workflow % PROS - 1, 2, 4 | LCS - 3
                    case {1,2,4} % Use Pre-computed Discrete Normal Distribution
                        switch storm_types{st}
                            case 'TC'
                                RandNorm = readmatrix('discrete_norm_444.txt')'; % z-scores
                            case 'XC'
                                RandNorm = readmatrix('discrete_norm_20.txt')';
                        end
                    case {3}
                        RandNorm = []; % Create Random Normal Distribution for Each Event (randn(size(Resp))
                end
                % Apply Uncertainty
                project_forcing.(data_types{dt}).(match_types{mt}).(storm_types{st}) = apply_uncertainty(config, data, RandNorm);
            end
        end
    end
    % Add Uncertainty Application Flag To Config
    config.u_engine = 1;
    %% SAVE OUT ADJUSTED & WITH UNCERTAINTY PROJECT_FROCING & CONFIG
    save(config.out_files.project_forcing, 'project_forcing','-v7.3');
    save(config.out_files.config, 'config', '-append');
else % Project Forcing Replicates Already Have Uncertainty Applied
    % Display Status Message
    disp('Project forcing already has uncertainty, skipping....');
end
end


