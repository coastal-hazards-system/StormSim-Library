function Resp = stormsim_pros(config, project_forcing, structure, emp_coeff)
% Project_forcing input is project_forcing.XC.Peaks.Maxima ->
toe_elev = structure.toe_elevation*-1;
if isnan(config.sp_depth)
    sp_depth = toe_elev;
else
    sp_depth = config.sp_depth;
end
struc_type = config.struc_type;

%% EXTRATROPICAL STORMS
% Prompt Status
disp('Processing extratropical storm data....');
% Apply Workflow
if any(contains(fieldnames(project_forcing),{'XC'}))
    % 1. Compute Structure Responses
    disp('Computing structure responses....');
    [Resp.('XC'), project_forcing] = compute_structure_response(config, structure, project_forcing, emp_coeff, 'XC');
    % 2. Compute Project Forcing & Structure Responses Hazard Curves
    disp('Building hazard curves....');
    HC_out.('XC') = call_hazard_curve_builder(config, project_forcing.('XC'), Resp.('XC'), 'XC');
end
%% TROPICAL STORMS
% Prompt Status
disp('Processing tropical storm data....');
% Apply Workflow
if any(contains(fieldnames(project_forcing),{'TC'}))
    % Compute Structure Responses
    disp('Computing structure responses....');
    [Resp.('TC'), project_forcing] = compute_structure_response(config, structure, project_forcing, emp_coeff, 'TC');
    % 2. Compute Project Forcing & Structure Responses Hazard Curves
    disp('Building hazard curves....');
    HC_out.('TC') = call_hazard_curve_builder(config, project_forcing.('TC'), Resp.('TC'), 'TC');
end
end