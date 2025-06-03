function HC_out = stormsim_pros(config, project_forcing, structure, emp_coeff, outPath)
%% INITIALIZE FIELDS AND PROMT USER
% Turn Off Warnings
warning('off');
% Get AEP vs AEF Flag
use_aep = config.pros_use_aep;
% Display PROS Message
disp(['      Running StormSim: PROS....']);
% Get Secondary Responses Switch
varnames = fieldnames(config);
varnames = varnames(contains(varnames, {'compute_p2_p3', 'compute_nappe'}));
% Get Responses To Compute Usign PROS-FB
fb_responses = cellfun(@(x) config.(x), varnames, 'un', true);
% Turn Off Responses For RB Section
config = config_editor(config, varnames, 0);
% PROS-FB For All Responses
if config.workflow == 4 % PROS-FB
    % Force Forcing Hazard Curve Creation
    config.pros_compute_forcing_HC = 1;
    % Force Overtopping Dischar Volume To Off
    config.compute_q_vol = 0; % Can't Integrate q Hazard Curve
    % Get Responses To Compute
    varnames = fieldnames(config);
    varnames = varnames(contains(varnames, {'compute_'}));  % Keep compute_*
    varnames = varnames(~contains(varnames, {'pros_', '_Ks','_slope'})); % Remove unwanted
    % Get Responses To Compute Usign PROS-FB
    fb_responses = cellfun(@(x) config.(x), varnames, 'un', true);
    % Turn Off Responses For RB Section
    config = config_editor(config, varnames, 0);
end

%% STORMSIM: PROS - XC
if contains(config.storm_sampling, {'XC','CC'})
    % 1. Compute Structure Responses
    [Resp, ~] = compute_structure_response(config, structure, project_forcing.('XC'), emp_coeff, 1);
    % 2. Compute Extremal Distribution Curves
    HC_out.XC = call_hazard_curve_builder(config, [], Resp, 'XC', use_aep, outPath);
end

%% STORMSIM: PROS - TC
if contains(config.storm_sampling, {'TC','CC'})
    % 1. Compute Structure Responses
    [Resp, project_forcing] = compute_structure_response(config, structure, project_forcing.('TC'), emp_coeff, 1);
    % 2. Compute Extremal Distribution Curves
    HC_out.TC = call_hazard_curve_builder(config, project_forcing.TC_Prob, Resp, 'TC', use_aep, outPath);
end

%% STORMSIM: PROS - COMBINE HAZARDS
if contains(config.storm_sampling, {'CC'})
    if isfield(HC_out, 'TC') & isfield(HC_out, 'XC')
        disp('         Combining project primary responses hazard curves...');
        [HC_out.('CC')] = call_hazard_curve_combiner(config, HC_out.('TC'), HC_out.('XC'), use_aep);
    end
end

%% REMOVE UNWANTED FIELDS FROM OUTPUT VAR
if isfield(HC_out, 'XC')
    HC_out.XC = rmfield(HC_out.XC, {'tbl_rsp_x','tbl_rsp_y'});
end
if isfield(HC_out, 'TC')
    HC_out.TC = rmfield(HC_out.TC, {'tbl_rsp_x','tbl_rsp_y'});
end

%% COMPUTE SECONDARY RESPONSES
% Compute Secondary Response Hazard Curves Using PROS-FB
if any(fb_responses) || config.workflow == 4
    %
    disp('         Computing Frequency Base Responses Hazard Curves...');
    % Turn On Responses For FB Section
    config = config_editor(config, varnames, 1);
    % Run StormSim PROS-FB
    HC_out = stormsim_pros_frequency_base(config, structure, HC_out, outPath);
end

% Enable Warnings Again
warning('on');

%% AUX FUNCTION
    function config_out = config_editor(config_out, var_to_look, value)
        % Turn Off Responses For RB Section
        for ii = 1:length(var_to_look)
            config_out.(var_to_look{ii}) = value;
        end
    end
end