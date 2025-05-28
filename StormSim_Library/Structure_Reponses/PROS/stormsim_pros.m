function HC_out = stormsim_pros(config, project_forcing, structure, emp_coeff, storm_type, outPath)
%% INITIALIZE FIELDS AND PROMT USER
% Turn Off Warnings
warning('off');
% Get AEP vs AEF Flag
use_aep = config.pros_use_aep;
% Display PROS Message
disp(['      Running StormSim: PROS....']);

%% STORMSIM: PROS - XC
if contains(config.storm_sampling, {'XC','CC'})
    % 1. Compute Structure Responses
    [Resp, project_forcing] = compute_structure_response(config, structure, project_forcing, emp_coeff, 'XC');
    % 2. Compute Extremal Distribution Curves
    HC_out.XC = call_hazard_curve_builder(config, structure, project_forcing.('XC'), Resp, 'XC', use_aep, outPath);
end

%% STORMSIM: PROS - TC
if contains(config.storm_sampling, {'TC','CC'})
    % 1. Compute Structure Responses
    [Resp, project_forcing] = compute_structure_response(config, structure, project_forcing, emp_coeff, 'TC');
    % 2. Compute Extremal Distribution Curves
    HC_out.TC = call_hazard_curve_builder(config, structure, project_forcing.('TC'), Resp, 'TC', use_aep, outPath);
end

%% STORMSIM: PROS - COMBINE HAZARDS
if contains(config.storm_sampling, {'CC'})
    if isfield(HC_out, 'TC') & isfield(HC_out, 'XC')
        disp('         Combining project primary responses hazard curves...');
        [HC_out.('CC')] = call_hazard_curve_combiner(config, structure, HC_out.('TC'), HC_out.('XC'), use_aep);
    end
end

%% REMOVE UNWANTED FIELDS FROM OUTPUT VAR
if ~isfield(HC_out, 'XC')
    HC_out = rmfield(HC_out.XC, {'tbl_rsp_x','tbl_rsp_y'});
end
if ~isfield(HC_out, 'TC')
    HC_out = rmfield(HC_out.TC, {'tbl_rsp_x','tbl_rsp_y'});
end
% Enable Warnings Again 
warning('on');
end