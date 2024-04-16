function HC_out = stormsim_pros(config, project_forcing, structure, emp_coeff, outPath)
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
    HC_out.('XC').(f_str) = call_hazard_curve_builder(config, structure, project_forcing.('XC'), Resp.('XC').(f_str), 'XC', use_aep, outPath);
end

%% TROPICAL STORMS
% Apply Workflow
if any(contains(fieldnames(project_forcing),{'TC'}))
    % Prompt Status
    disp('         Processing tropical storm data....');
    % 1. Compute Structure Responses
    [Resp.('TC').(f_str), project_forcing] = compute_structure_response(config, structure, project_forcing, emp_coeff, 'TC');
    % 2. Compute Project Forcing & Structure Responses Hazard Curves
    HC_out.('TC').(f_str) = call_hazard_curve_builder(config, structure, project_forcing.('TC'), Resp.('TC').(f_str), 'TC', use_aep, outPath);
end

%% COMBINE HAZARD CURVES
if strcmp(storm_sampling,'CC')
    if ~isempty(HC_out.('TC').(f_str)) & ~isempty(HC_out.('XC').(f_str))
        disp('         Combining project primary responses hazard curves...');
        [HC_out.('CC').(f_str)] = call_hazard_curve_combiner(config, structure, HC_out.('TC').(f_str), HC_out.('XC').(f_str), use_aep);
    end
end

%% COMPUTE FREQUENCY BASED RESPONSES (IF NEEDED)
if workflow == 4
    disp('         Computing & Plotting frequency base responses...');
    HC_out = compute_frequency_base_responses(config, structure, emp_coeff, HC_out, f_str, use_aep);
end
%% REMOVE UNWANTED FIELDS FROM OUTPUT VAR
if any(contains(fieldnames(project_forcing),{'TC'}))
    if ~isempty(HC_out.('TC').(f_str))
        HC_out.('TC').(f_str) = rmfield(HC_out.('TC').(f_str), {'tbl_rsp_x','tbl_rsp_y'});
    end
end
if any(contains(fieldnames(project_forcing),{'XC'}))
    if ~isempty(HC_out.('XC').(f_str))
        HC_out.('XC').(f_str) = rmfield(HC_out.('XC').(f_str), {'tbl_rsp_x','tbl_rsp_y'});
    end
end

warning('on');


end