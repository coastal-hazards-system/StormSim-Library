function [project_forcing] = adjust_project_forcing(config, structure, project_forcing, storm_type, data_type)
%% GRAB DETAILS FROM "config"
% Define Tide File
tide_file = config.tide_file;
% Define Use Tide Switch 
use_tides = config.apply_random_tides;
% Define Project SWL ADjustment
swl_slr = config.swl_slr;
% Depth Limitation Switch
apply_DL = config.apply_depth_limitation;
% Storm

%% GRAB DETAILS FROM "structure"
% Define Structure Toe Elevation (<0 below datum zero)
toe_elev = structure.toe_elevation; % Flip convention

%% ADJUST PROJECT FORCING DATA - RESPONSE BASE
switch data_type
    case 'PROS'
        %------ SWL ADJUSTMENTS -----
        % Apply Random Tide To SWL
        if exist(tide_file,'file') == 2 && use_tides == 1
            project_forcing = apply_random_tide(tide_file, project_forcing, 0);
        end
        % Apply SLR
        if swl_slr~=0
            SWL_fnames = fieldnames(project_forcing);
            SWL_fnames = SWL_fnames(contains(SWL_fnames,{'SWL'}));
            for gg = 1:length(SWL_fnames)
                if ~iscell(project_forcing.(SWL_fnames{gg}))  % Peaks
                    project_forcing.(SWL_fnames{gg}) = project_forcing.(SWL_fnames{gg}) + swl_slr;
                else % Timeseries
                    project_forcing.(SWL_fnames{gg}) = cellfun(@(x) x + swl_slr, project_forcing.(SWL_fnames{gg}), 'un', false);
                end
            end
        end
        %------ Hm0 ADJUSTMENTS -----
        if ~iscell(project_forcing.('SWL'))  % Peaks
            % Compute Water Depth @ Toe
            h = project_forcing.('SWL') - toe_elev;
            % Apply Depth Limitation
            if apply_DL == 1
                project_forcing.('Hm0') = apply_depth_limitation(project_forcing.('Hm0'), project_forcing.('Tp'), h);
            end
        else % Timeseries
            % Compute Water Depth @ Toe
            h = cellfun(@(x) x - toe_elev,project_forcing.('SWL'), 'un', false);
            % Apply Depth Limitation
            if apply_DL == 1
                project_forcing.('Hm0') = cellfun(@(x, y, z) apply_depth_limitation(x, y, z), project_forcing.('Hm0'), project_forcing.('Tp'), h,'un',false);
            end
        end
    case 'LCS'
        %% ADJUST PROJECT FORCING DATA - LIFE CYCLE SIM
        %------ SWL ADJUSTMENTS -----
        % Apply Random Tide To SWL
        if exist(tide_file,'file') == 2 && use_tides == 1
            project_forcing = apply_random_tide(tide_file, project_forcing, 0);
        end
        % Apply SLR
        if swl_slr~=0
            if size(project_forcing(1).LCNUM,2)==8  % Peaks
                project_forcing = cell2struct(cellfun(@(x) x + [0 0 0 swl_slr 0 0 0 0], {project_forcing.LCNUM}, 'un', false), 'LCNUM');
            else % Timeseries
                project_forcing = cell2struct(cellfun(@(x) x + [0 0 0 0 swl_slr 0 0 0 0 0], {project_forcing.LCNUM}, 'un', false), 'LCNUM');
            end
        end
        %------ Hm0 ADJUSTMENTS -----
        if size(project_forcing(1).LCNUM,2)==8  % Peaks
            % Compute Water Depth @ Toe
            h = cellfun(@(x) x(:,4) - toe_elev,{project_forcing.LCNUM}, 'un', false);
            % Apply Depth Limitation
            if apply_DL == 1
                for kk = 1:length(h)
                    project_forcing(kk).LCNUM(:,5) = apply_depth_limitation(project_forcing(kk).LCNUM(:,5),...
                        project_forcing(kk).LCNUM(:,6), h{kk});
                end
            end
        else % Timeseries
            % Compute Water Depth @ Toe
            h = cellfun(@(x) x(:,5) - toe_elev,{project_forcing.LCNUM}, 'un', false);
            % Apply Depth Limitation
            if apply_DL == 1
                for kk = 1:length(h)
                    project_forcing(kk).LCNUM(:,6) = apply_depth_limitation(project_forcing(kk).LCNUM(:,6),...
                        project_forcing(kk).LCNUM(:,7), h{kk});
                end
            end
        end
end
end
