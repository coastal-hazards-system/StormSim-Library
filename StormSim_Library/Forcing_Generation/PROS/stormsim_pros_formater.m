function project_forcing = stormsim_pros_formater(storm_sampling, storm, prob_mass)
%% PREP INPUTS
% Execute Code Block According To Strom Type Being Calle
switch storm_sampling
    case 'CC'
        storm_types = {'TC','XC'};
    otherwise
        storm_types = {storm_sampling};
end

%% RESHAPE FORCING PARAMETERS FOR STORMSIM:PROS
% Loop Across Each Storm Type
for st = 1:length(storm_types)
    % Disp
    disp(['Reshaping ' storm_types{st} ' forcing data for response base analysis....']);
    % Get Data Types (Peaks/Timeseries)
    data_type = fieldnames(storm.(storm_types{st}));
    data_type(~contains(data_type, {'Peaks', 'Timeseries'})) = [];
    % Loop Across Each Data Type
    for kk = 1:length(data_type)
        % Determine Match Types
        match_types = fieldnames(storm.(storm_types{st}).(data_type{kk}));
        % Loop Across Each Match Type
        for ii = 1:length(match_types)
            % Define Normal Discretization To Use
            switch storm_types{st}
                case 'XC'
                    RandNorm = 20; % 20 values for XC because there is 1000 bootstrap samples in SST code
                case 'TC'
                    RandNorm = 444; % 444 values covering the (-3,3) z-score range
            end
            % Create Replicates
            project_forcing.(data_type{kk}).(match_types{ii}).(storm_types{st}) = create_reps(storm.(storm_types{st}).(data_type{kk}).(match_types{ii})(:, 2), RandNorm, [1 2 3]);
            % Reshape Storm Probability Masses To Be nStorms * normal_discretization
            if strcmp(storm_types{st}, 'TC')
                project_forcing.(data_type{kk}).(match_types{ii}).(storm_types{st}).TC_Prob = prob_mass.TC_Freq;%./RandNorm;
            end
        end
    end
end

%% AUX FUNCTIONS
    function data_out = create_reps(storm_data, n_reps, col_indx)
        % Reshape Peaks Data To Be nStorms * normal_discretization
        data_out.SWL = cellfun(@(x) repmat(x(:,col_indx(1)),1,n_reps),storm_data,'un',false); % SWL
        data_out.Hm0 = cellfun(@(x) repmat(x(:,col_indx(2)),1,n_reps),storm_data,'un',false); % Hm0
        data_out.Tp = cellfun(@(x) repmat(x(:,col_indx(3)),1,n_reps),storm_data,'un',false); %  Tp

        %
        data_out.SWL_no_rep = cellfun(@(x) x(:,col_indx(1)),storm_data,'un',false); % SWL
        data_out.Hm0_no_rep = cellfun(@(x) x(:,col_indx(2)),storm_data,'un',false); % Hm0
        data_out.Tp_no_rep = cellfun(@(x) x(:,col_indx(3)),storm_data,'un',false); % Tp
    end
end

