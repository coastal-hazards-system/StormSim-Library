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
        if iscell(project_forcing.(SWL_fnames{1})) % Timeseries
            % Get Size Vector
            t_size = cell2mat(cellfun(@(x) size(x,1),project_forcing.(SWL_fnames{1}),'un',false));
            % Create Random Tide Indexes
            tide_indx = randi([1 length(tidal_data)], length(t_size), 1);
            % Grab Pull Indexes
            pass_indx = tide_indx + t_size - 1 > length(tidal_data);
            % Make Sure Tide Index Is Enough To Capture Hydrograph
            if sum(pass_indx) > 0
                chk = 0;
                while chk == 0
                    % Correct Any That Did Not Pass
                    tide_indx(pass_indx) = randi([1 length(tidal_data)],sum(pass_indx),1);
                    % Check All Storm Hydrographs In LC
                    pass_indx = tide_indx + t_size > length(tidal_data);
                    % Try To Exit
                    if sum(pass_indx) == 0 % All good
                        chk = 1; % Exit Flag
                    end
                end
            end
            % Add Tide To Storm Data
            rand_tide = arrayfun(@(x, y) tidal_data(x:x+y-1), tide_indx, t_size,'un',false);
            for gg = 1:length(SWL_fnames)
                % Add Tidal Signal To Storm Data
                project_forcing.(SWL_fnames{gg}) = cellfun(@(x,y) x + y, project_forcing.(SWL_fnames{gg}), rand_tide, 'un', false);
            end
        else % Peaks
            % Get Size Vector
            t_size = size(project_forcing.(SWL_fnames{1}), 1);
            % Create Random Tide Indexes
            tide_indx = randi([1 length(tidal_data)], t_size, 1);
            for gg = 1:length(SWL_fnames)
                % Add Tide To SWL
                project_forcing.(SWL_fnames{gg}) = project_forcing.(SWL_fnames{gg}) + tidal_data(tide_indx);
            end
        end
    case 2 % LC
        % Define SWL Column ON LCS Data
        if size(project_forcing(1).LCNUM,2) == 8 || size(project_forcing(1).LCNUM,2) == 9 % Peaks
            swl_indx = 4;
        elseif size(project_forcing(1).LCNUM,2) == 10 % Timeseries
            swl_indx = 5;
        end
        % Add Random Tides According To Data Type
        switch swl_indx
            case 4 % Peaks
                % Get Size Vector
                t_size = cellfun(@(x) length(x(:,1)),{project_forcing.LCNUM},'un',false);
                % Create Random Tide Indexes
                tide_indx = cellfun(@(x) randi([1 length(tidal_data)],x,1),t_size,'un',false);
                % Add Tide To SWL
                for ii = 1:length(t_size)
                    project_forcing(ii).LCNUM(:, swl_indx) = project_forcing(ii).LCNUM(:, swl_indx) + tidal_data(tide_indx{ii},end);
                end
            case 5 % Timeseries
                % Determine How Long & How Many Storm Hydrographs Are In Data
                stm_indx = cellfun(@(x) x(x(:,3) == 0, 1:2), {project_forcing.LCNUM}, 'un', false);
                % Create Random Tide Indexes
                tide_indx = cellfun(@(x) randi([1 length(tidal_data)],size(x,1),1),stm_indx,'un',false);
                % Process Each Life Cycle
                for ii = 1:length({project_forcing.LCNUM})
                    % Grab Pull Indexes
                    pull_indx = stm_indx{ii};
                    % Grab Tide Indexes For Storms
                    t_indx = tide_indx{ii};
                    % Make Sure Tide Index Is Enough To Capture Hydrograph
                    chk = 0;
                    while chk == 0
                        % Check All Storm Hydrographs In LC
                        pass_indx = t_indx + pull_indx(:,2) - 1 > length(tidal_data);
                        % Correct Any That Did Not Pass
                        t_indx(pass_indx) = randi([1 length(tidal_data)],sum(pass_indx),1);
                        % Check Again
                        pass_indx = t_indx + pull_indx(:,2) - 1> length(tidal_data);
                        % Try To Exit
                        if sum(pass_indx) == 0 % All good
                            chk = 1; % Exit Flag
                        end
                    end
                    % Pull Data Segments From Tidal File And Add To Hydrograph SWL
                    project_forcing(ii).LCNUM(:, swl_indx) =  project_forcing(ii).LCNUM(:, swl_indx) + cell2mat(arrayfun(@(x,y) tidal_data(x:x+y-1), t_indx, pull_indx(:,2),'un', false));
                end
        end
    case 3
        % tbd
end

end