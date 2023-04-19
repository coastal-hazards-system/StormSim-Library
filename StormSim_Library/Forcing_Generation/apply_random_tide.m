function project_forcing = apply_random_tide(tide_file, project_forcing, unique_rep)
%% IMPORT TIDAL DATA
warning('off');
% Import Tidal Data Provided
tidal_data = readcell(tide_file,'NumHeaderLines',1);
% Keep Only Final Column
tidal_data = cell2mat(tidal_data(:,end));
warning('on');

%% DETERMINE "project_forcing" DATA CONTEXT
% Verify Data Context
if any(contains(fieldnames(project_forcing),{'SWL'})) % Response Base
    dType = 1;
elseif contains(fieldnames(project_forcing),{'LCNUM'}) % LC Base
    dType = 2;
else
    dType = 3; % SWL Col Vector
end

%% ADD RANDOM TIDE ACCORDINGLY
switch dType
    case 1 % Response Base
        % Get Fieldnames
        SWL_fnames = fieldnames(project_forcing);
        SWL_fnames = SWL_fnames(contains(SWL_fnames, {'SWL'}));
        % Loop Through Fieldnames
        for gg = 1:length(SWL_fnames)
            if iscell(project_forcing.(SWL_fnames{gg})) % Timeseries
                % Get Size Vector
                t_size = cellfun(@(x) size(x,1),project_forcing.(SWL_fnames{gg}),'un',false);
                % Compute Padding Failsafe
                tpad = max(cell2mat(t_size))*2; % Ensure Tidal Signal Does Not Exceed Record Length
                if unique_rep == 1
                    reps = size(project_forcing.(SWL_fnames{gg}){1},2); % TO Create Tide Signal For Each replicate
                else
                    reps = 1;
                end
                % Create Random Tide Indexes
                tide_indx = randi([1 length(tidal_data)-tpad],length(t_size),reps);
                % Add Tide To Storm Data
                for ii = 1:length(t_size)
                    % Build Index List For Replicates
                    rep_indx = cellfun(@(x) [tide_indx(ii,x):tide_indx(ii,x)+t_size{ii}-1]',num2cell(1:reps),'un',false);
                    % Extract Random Tidal Signal(s) for Replicates
                    rep_tide = cell2mat(cellfun(@(x) tidal_data(x),rep_indx,'un',false));
                    % Add Tidal Signal To Storm Data
                    project_forcing.(SWL_fnames{gg}){ii} = project_forcing.(SWL_fnames{gg}){ii} + rep_tide;
                end
            else % Peaks
                % Get Size Vector
                t_size = size(project_forcing.(SWL_fnames{gg}));
                % Create Random Tide Indexes
                tide_indx = randi([1 length(tidal_data)],t_size);
                % Add Tide To SWL
                project_forcing.(SWL_fnames{gg}) = project_forcing.(SWL_fnames{gg}) + tidal_data(tide_indx);
                for ii = 1:t_size(2)
                    project_forcing.(SWL_fnames{gg})(:,ii) = project_forcing.(SWL_fnames{gg})(:,ii) + tidal_data(tide_indx(:,ii));
                end
            end
        end
    case 2 % LC
        if size(project_forcing(1).LCNUM,2) == 8 || size(project_forcing(1).LCNUM,2) == 9 % Peaks
            swl_indx = 4;
        elseif size(project_forcing(1).LCNUM,2) == 10 % Timeseries
            swl_indx = 5;
        end
        % Get Size Vector
        t_size = cellfun(@(x) length(x(:,1)),{project_forcing.LCNUM},'un',false);
        % Create Random Tide Indexes
        tide_indx = cellfun(@(x) randi([1 length(tidal_data)],x,1),t_size,'un',false);
        % Add Tide To SWL
        for ii = 1:length(t_size)
            project_forcing(ii).LCNUM(:,swl_indx) = project_forcing(ii).LCNUM(:,swl_indx) + tidal_data(tide_indx{ii},end);
        end
    case 3
        % tbd
end

end