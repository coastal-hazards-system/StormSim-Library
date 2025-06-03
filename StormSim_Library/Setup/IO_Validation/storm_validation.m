function storm_validation(config, storm)
%{
% ------- Expected "storm" Variable Format -------
Data Structure Fields -> storm.(st_type).(data_type).(match_type)
    - st_type: Storm Types -> 'XC' and/or 'TC'
    - data_type: Modeling data type -> 'Peaks' and/or 'Timeseries'
    - match_type: Storm modeling matching type (Circulation + Wave model) ->
        Peaks: Alows for additional alternate datasets.
            -> 'Default': Normal matching method.storm data includes peak responses from circulation
                          (surge) & wave models (wave height, peak period, wave direction)
                          regardlesss of the phases.
            -> 'WLP': Makes use of both Peaks & Timeseries data types to create new
                      alternate Peaks dataset. For WLP matching is done as a function of the
                      peak circulation model response. Corresponding wave model responses is
                      matched from timeseries data type while searching for nearest data
                      point to circulation model peak response phase.
            -> 'WHP': Makes use of both Peaks & Timeseries data types to create new
                      alternate Peaks dataset. For WHP matching is done as a function of the
                      peak wave model responses. Corresponding circulation model response is
                      matched from timeseries data type while searching for nearest data
                      point to wave model peak responses phase.
        Timeseries: Only supports 'Default'.
        
Storm Type Specific Fields -> storm.XC.XX
    For XC storms there are two additional fields that are needed in order
    to run StormSim workflows. XX represents the folowing:
        -> Nyrs_XC: Record length in extra-tropical storm suite (years)
        -> Nstm_XC: Number of extra-tropical storms in storm suite.
% ---------------------------------------------
%}
% Define Data Type Pass Flag
pass_cnt = config.use_peaks + config.use_timeseries;
% Get Storm Types On Storm Suite
st_types = fieldnames(storm); % XC, TC
% Check For storm variable contents compliance
if ~any(contains(st_types, {'XC','TC'}))
    error('Error: StormSim only supports "XC" and/or "TC" storm types. Rename fields as such....');
else % Fields Exist
    % Remove Unsupported Fields
    storm = rmfield(storm, st_types(~contains(st_types, {'XC','TC'})));
    % Define Storm Types Again
    st_types = st_types(contains(st_types, {'XC','TC'}));
end
% Loop Across Each Storm Type
for kk = 1:length(st_types)
    % Scan Data Type Fieldnames
    data_types = fieldnames(storm.(st_types{kk})); % Peaks and/or Timeseries
    % Check For Data Type Compliance
    chk = sum(contains(data_types, {'Peaks','Timeseries'})) == pass_cnt;
    % throw Error If Not Met
    if ~chk
        error('Error: Could not find expected data types "Peaks" and/or "Timeseries per user request on config...')
    end
    % Evaluate Storm Type Special Cases
    switch st_types{kk}
        case 'XC'
            % Check For XC Specific Fields
            if ~all(contains({'Nyrs_XC','Nstm_XC'}, data_types))
                error('Error: Could not find expected XC storm additional fields. Make sure to include the record length (Nyrs_XC) and number of XC storms (Nstm_XC) on provided storm suite...');
            end
    end
    % Get Row Indexes
    sindx = find(contains(data_types, {'Peaks','Timeseries'}) == 1);
    % Check For Data Type Content Shapes Compliance
    for ii = min(sindx):max(sindx)
        % Scan Matching Type
        match_types = fieldnames(storm.(st_types{kk}).(data_types{ii}));
        % Loop Across Match Types
        for jj = 1:length(match_types)
            % Make Sure Cell Array Has 2 Colums
            data_shape = size(storm.(st_types{kk}).(data_types{ii}).(match_types{jj}), 2); % N x 2 | col 1: storm ID, col 2: storm data cell
            % Check For Compliance
            if data_shape ~= 2
                error(['Error: Detected wrong data shape for storm.', st_types{kk},...
                    '.', data_types{ii}, '.', match_types{jj},...
                    '. Please ensure data shape is a N x 2 cell array where col 1: storm ID, col 2: storm data cell...']);
            end
            % Verify Shape Of Storm Suite Data
            [stm_row, stm_col] = size(storm.(st_types{kk}).(data_types{ii}).(match_types{jj}){1, 2});% Storm Data Cell -> { M x 6 } -> [ SWL Hm0 Tp wDir datenum storm_duration ] (storm duration in days)
            % Ensure Storm Suite Data Complies With Expected Number Of Columns
            if stm_col ~= 6 % [ SSL Hm0 Tp wDir date event_duration ]
                error('Error: Storm suite modeling data must comply with expected data shape ( M x 6 ). ');
            end
            % Ensure Storm Suite Data Complies With Expected Number Of Rows (Peaks Only)
            if stm_row ~= 1 && strcmp(data_types{ii}, 'Peaks')
                error('Error: Storm suite modeling data must comply with expected data shape ( 1 x 6 ) for "Peaks". ');
            end
        end
    end
end
end