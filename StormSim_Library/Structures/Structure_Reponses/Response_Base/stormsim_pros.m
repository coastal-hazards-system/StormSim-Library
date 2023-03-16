function HC_out = stormsim_pros(config, project_forcing, structure, emp_coeff)
disp(['      Running StormSim: PROS....']);
warning('off');
storm_sampling = config.storm_sampling;
try
    use_aep = config.pros_use_aep;
catch
    use_aep = 1;
end
workflow = config.workflow;

%% DETERMINE DATA TYPE
% Find Field Dimensions
if isfield(project_forcing,'XC')
    if iscell(project_forcing.('XC').('SWL')) % Timeseries Dataset
        f_str = 'Timeseries';
    else % Peaks
        f_str = 'Peaks';
    end
elseif isfield(project_forcing,'TC')
    if iscell(project_forcing.('TC').('SWL')) % Timeseries Dataset
        f_str = 'Timeseries';
    else % Peaks
        f_str = 'Peaks';
    end
end


%% EXTRATROPICAL STORMS
% Apply Workflow
if any(contains(fieldnames(project_forcing),{'XC'}))
    % Prompt Status
    disp('         Processing extratropical storm data....');
    % 1. Compute Structure Responses
    [Resp.('XC').(f_str), project_forcing] = compute_structure_response(config, structure, project_forcing, emp_coeff, 'XC');
    % 2. Compute Project Forcing & Structure Responses Hazard Curves
    HC_out.('XC').(f_str) = call_hazard_curve_builder(config, structure, project_forcing.('XC'), Resp.('XC').(f_str), 'XC', use_aep);
    % 3. Plot Outputs
    disp('            Plotting hazard curves....');
    plot_hazard_curves(HC_out.('XC').(f_str), use_aep);
end
%% TROPICAL STORMS
% Apply Workflow
if any(contains(fieldnames(project_forcing),{'TC'}))
    % Prompt Status
    disp('         Processing tropical storm data....');
    % 1. Compute Structure Responses
    [Resp.('TC').(f_str), project_forcing] = compute_structure_response(config, structure, project_forcing, emp_coeff, 'TC');
    % 2. Compute Project Forcing & Structure Responses Hazard Curves
    HC_out.('TC').(f_str) = call_hazard_curve_builder(config, structure, project_forcing.('TC'), Resp.('TC').(f_str), 'TC', use_aep);
    % 3. Plot Outputs
    disp('            Plotting hazard curves....');
    plot_hazard_curves(HC_out.('TC').(f_str), use_aep);
end

%% COMBINE HAZARD CURVES
if strcmp(storm_sampling,'CC')
    disp('         Combining project forcing tropical and extratropical hazard curves...')
    HC_out.('CC').(f_str) = call_hazard_curve_combiner(HC_out.('TC').(f_str), HC_out.('XC').(f_str), use_aep);
    % 3. Plot Outputs
    disp('            Plotting hazard curves....');
    plot_hazard_curves(HC_out.('CC').(f_str), use_aep);
end

%% REMOVE UNWANTED FIELDS FROM OUTPUT VAR
if any(contains(fieldnames(project_forcing),{'TC'}))
    HC_out.('TC').(f_str) = rmfield(HC_out.('TC').(f_str), {'tbl_rsp_x','tbl_rsp_y'});
end
if any(contains(fieldnames(project_forcing),{'XC'}))
    HC_out.('XC').(f_str) = rmfield(HC_out.('XC').(f_str), {'tbl_rsp_x','tbl_rsp_y'});
end

warning('on');
end