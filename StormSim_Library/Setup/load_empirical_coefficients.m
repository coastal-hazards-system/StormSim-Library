function [emp_coeff] = load_empirical_coefficients()

%% READ & FORMAT EMPIRICAL COEFFICIENTS FILE
% Import Empirical Coefficients Reference Document
emp_coeff2 = readcell('StormSim_empirical_coefficients.txt'); % [ variable_name, description, Units, Value, Std ]
% Remove Headers
emp_coeff2 = emp_coeff2(2:end,:);
% Grab Fieldnames
fields_2_read = emp_coeff2(:,1);
% % Create Fields
for ii = 1:length(fields_2_read)
    eval(['emp_coeff.',fields_2_read{ii},' = emp_coeff2{ii,4};']); % Mean Value
        eval(['emp_coeff.std.',fields_2_read{ii},' = emp_coeff2{ii,5};']); % Std
end

%{
% Reshape Fields According To Workflow
switch workflow
    case 1 %StormSim: PROS
% Do Nothing 

    otherwise % StormSim: MCS/CSR Life Cycle Base
        % Create Fields
        for ii = 1:length(fields_2_read)
            % For Each Life Cycle
            for lc = 1:length(project_forcing.(storm_sampling).Peaks.Maxima)
                % Determine Life Cycle Size
                sim_size = length(project_forcing.(storm_sampling).Peaks.Maxima(lc).LCNUM);
                % Reshape And Apply Uncertainty
                %eval(['emp_coeff2.Peaks(lc).',fields_2_read{ii},' = normrnd(emp_coeff{ii,4},emp_coeff{ii,5},[sim_size 1]);']);
                emp_coeff.Peaks(lc).(fields_2_read{ii}) = reshape(emp_coeff.(fields_2_read{ii}), sim_size, 1);
                % Reshape And Apply Uncertainty (Timeseries)
                if use_timeseries == 1
                    % Determine Life Cycle Size
                    sim_size_ts = length(project_forcing.(storm_sampling).Timeseries(lc).LCNUM);
                    % Timeseries
                    eval(['emp_coeff2.Timeseries(lc).',fields_2_read{ii},' = normrnd(emp_coeff{ii,4},emp_coeff{ii,5},[sim_size_ts 1]);']);
                end
            end
        end
end
%}

end