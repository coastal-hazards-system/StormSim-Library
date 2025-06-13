function [SWL, tide_indx] = apply_random_tide(tide_file, SWL, t_size, tide_indx)
%% IMPORT TIDAL DATA
warning('off');
% Import Tidal Data Provided
tidal_data = readcell(tide_file,'NumHeaderLines',1);
% Keep Only Final Column
tidal_data = cell2mat(tidal_data(:,end));
warning('on');

%% ADD RANDOM TIDE ACCORDINGLY
% Create Random Tide Indexes
rand_tide = {};
if isempty(tide_indx)
    tide_indx = cellfun(@(x) randi([1 length(tidal_data)], length(x), 1), t_size, 'un', false);
end
% For Each Event
for stm = 1:length(tide_indx)
    % Verify If Tidal Indexes Are Good For Timeseries
    pass_indx = tide_indx{stm} + t_size{stm}> length(tidal_data);
    % Keep Sampling For Valid Index
    while any(pass_indx)
        % Correct Any That Did Not Pass
        tide_indx{stm}(pass_indx) = randi([1 length(tidal_data)], sum(pass_indx), 1);
        % Check All Storm Hydrographs In LC
        pass_indx = tide_indx{stm} + t_size{stm}> length(tidal_data);
    end
    % Add Tide To Storm Data
    rand_tide{stm, 1} = cell2mat(arrayfun(@(x, y) tidal_data(x:x+y-1), tide_indx{stm}, t_size{stm},'un',false));
end
% Add To Surge
for gg = 1:size(SWL, 2)
    % Add Tidal Signal To Storm Data
    SWL(:, gg) = cellfun(@(x,y) x + y, SWL(:, gg), rand_tide, 'un', false);
end
end