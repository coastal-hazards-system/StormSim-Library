function HC_out = stormsim_pros(config, project_forcing, structure, emp_coeff)
warning('off');
% Project_forcing input is project_forcing.XC.Peaks.Maxima ->
toe_elev = structure.toe_elevation*-1;
if isnan(config.sp_depth)
    sp_depth = toe_elev;
else
    sp_depth = config.sp_depth;
end
struc_type = config.struc_type;
storm_sampling = config.storm_sampling;
%% DETERMINE DATA TYPE
% Find Field Dimensions
if isfield(project_forcing,'XC')
    if iscell(project_forcing.('XC').('SWL')) % Timeseries Dataset
        f_str = 'Timeseries';
    else % Peaks
        f_str = 'Peaks';
    end
elseif isfield(project_forcing,'TC')
    if iscell(project_forcing.('TC').('SWL'))
        if iscell(project_forcing.('TC').('SWL')) % Timeseries Dataset
            f_str = 'Timeseries';
        else % Peaks
            f_str = 'Peaks';
        end
    end
end

%% EXTRATROPICAL STORMS
% Prompt Status
disp('Processing extratropical storm data....');
% Apply Workflow
if any(contains(fieldnames(project_forcing),{'XC'}))
    % 1. Compute Structure Responses
    disp('Computing structure responses....');
    [Resp.('XC').(f_str), project_forcing] = compute_structure_response(config, structure, project_forcing, emp_coeff, 'XC');
    % 2. Compute Project Forcing & Structure Responses Hazard Curves
    disp('Building hazard curves....');
    HC_out.('XC').(f_str) = call_hazard_curve_builder(config, structure, project_forcing.('XC'), Resp.('XC').(f_str), 'XC');
    % 3. Combine Hazard Curves If Requested 
    if strcmp(storm_sampling,'CC')


    end
end
%% TROPICAL STORMS
% Prompt Status
disp('Processing tropical storm data....');
% Apply Workflow
if any(contains(fieldnames(project_forcing),{'TC'}))
    % Compute Structure Responses
    disp('Computing structure responses....');
    [Resp.('TC').(f_str), project_forcing] = compute_structure_response(config, structure, project_forcing, emp_coeff, 'TC');
    % 2. Compute Project Forcing & Structure Responses Hazard Curves
    disp('Building hazard curves....');
    HC_out.('TC').(f_str) = call_hazard_curve_builder(config, structure, project_forcing.('TC'), Resp.('TC').(f_str), 'TC');
end
warning('on');
end