function [project_forcing, config] = adjust_project_forcing(config, structure, project_forcing, st_type)
%% GRAB DETAILS FROM "config"
% Define Tide File
tide_file = config.tide_file;
% Define Use Tide Switch
use_tides = config.apply_random_tides;
% Define Project SWL ADjustment
swl_slr = config.swl_slr;
% Depth Limitation Switch
apply_DL = config.apply_depth_limitation;
% gravity constant 
g = config.gravity_constant;

%% GRAB DETAILS FROM "structure"
% Define Structure Toe Elevation (<0 below datum zero)
toe_elev = structure.toe_elevation; % Flip convention

%% GRAB PROJECT FORCING DATA
switch config.workflow
    case  {1, 2, 4}
        SWL = [project_forcing.('SWL'), project_forcing.('SWL_no_rep')];% Water Level
        Hm0 = project_forcing.('Hm0');% Wave Height
        Tp = project_forcing.('Tp'); % Wave Period
        % Get Size Vector
        t_size = cellfun(@(x) size(x,1), SWL(:, 1), 'un', false);
    case {3} % LCS
        SWL = cellfun(@(x) x(:, 5), project_forcing, 'un', false); % Get SWL From LC
        Hm0 = cellfun(@(x) x(:, 6), project_forcing, 'un', false); % Get Hm0 From LC
        Tp = cellfun(@(x) x(:, 7), project_forcing, 'un', false); % Get Tp From LC
        % Get Size Vector
        if size(project_forcing{1}, 2) == 10 % 10 Cols Is Indicator Of Timeseries
            t_size = cellfun(@(x) x(find([nan;x(2:end, 10);0]== 0)-1, 10)+1 , project_forcing, 'un', false);
        else
            t_size = cellfun(@(x) ones(length(x), 1), SWL, 'un', false);
        end
        % Logic Behind Previous Line
        % Add nan on top -> Keep Dimensions Consistent But Remove 0 of first Storm
        % Add Zero To End -> Want to flag final timestep of final storm
        % - 1 -> Gives the end row index of each storm
        % + 1 -> x(:, 10) goes from 0:n_stsp-1 hence need to add 1 to get proper length
end

%% SWL ADJUSTMENTS
% Apply Random Tide To SWL
if exist(tide_file,'file') == 2 && use_tides == 1
    if ~isfield(config, ['tide_indx_' lower(st_type)])
        config.(['tide_indx_' lower(st_type)]) = [];
    end
    [SWL, config.(['tide_indx_' lower(st_type)])] = apply_random_tide(tide_file, SWL, t_size, config.(['tide_indx_' lower(st_type)]));
end
% Apply SLR
if swl_slr~=0
    for kk = 1:size(SWL, 2)
        SWL(:, kk) = cellfun(@(x) x + swl_slr, SWL(:, kk), 'un', false);
    end
end

%% Hm0 ADJUSTMENTS
% Compute Water Depth @ Toe
h = cellfun(@(x) x - toe_elev, SWL(:, 1), 'un', false);
% Apply Depth Limitation
if apply_DL == 1
    Hm0 = cellfun(@(x, y, z) apply_depth_limitation(x, y, z, g), Hm0, Tp, h,'un',false);
end

%% STORE ADJUSTED DATA
% Store Modifications
switch config.workflow
    case  {1, 2, 4}
        project_forcing.SWL = SWL(:, 1); % Get SWL From LC
        project_forcing.SWL_no_rep = SWL(:,2);
        project_forcing.Hm0 = Hm0; % Get SWL From LC
    case {3}
        for jj = 1:length(SWL)
            project_forcing{jj}(:,5) = SWL{jj}; % Get SWL From LC
            project_forcing{jj}(:,6) = Hm0{jj}; % Get SWL From LC
        end
end
end
