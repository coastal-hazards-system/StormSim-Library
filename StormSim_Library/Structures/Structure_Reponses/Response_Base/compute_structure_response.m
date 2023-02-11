function [Resp, project_forcing] = compute_structure_response(config, structure, project_forcing,  emp_coeff, storm_type)
%% GRAB DETAILS FROM "config"
% Define Tide File
tide_file = config.tide_file;
% Define Project SWL ADjustment
swl_slr = config.swl_slr;
% Depth Limitation Switch 
apply_DL = config.apply_depth_limitation;
% Strucutre Type 
struc_type = config.struc_type;
% Storm Duration [s]
Nz = config.storm_duration*3600; % Convert hr to s

%% GRAB DETAILS FROM "structure"
% Define Structure Crest Elevation
crest_elev = structure.crest_elevation;
% Define Structure Toe Elevation (<0 below datum zero)
toe_elev = structure.toe_elevation*-1; % Flip convention
% Berm Elevation (<0 Below Datum Zero)
berm_elev = structure.berm_elevation*-1; %
% Berm Width
berm_width = structure.berm_width;
% Seaside Slope (cot(alpha))
slope = structure.seaside_slope;
% Delta
delta = structure.armor_delta;
% Seaside Limit State
S = structure.seaside_limit_S;
% CEM P
P = structure.cem_P;
% Water Density kg/m^3
rho_w = structure.water_density; 

%% DEFINE CNOSTANTS
g = 9.81; % Gravity

%% FORCING DATA ADJUSTMENTS
%------ SWL ADJUSTMENTS -----
% Apply Random Tide To SWL
if exist(tide_file,'file') == 2
    project_forcing.(storm_type) = apply_random_tide(tide_file, project_forcing.(storm_type), 0);
end
% Apply SLR
if ~iscell(project_forcing.(storm_type).('SWL'))  % Peaks
    project_forcing.(storm_type).('SWL') = project_forcing.(storm_type).('SWL') + swl_slr;
else % Timeseries
    project_forcing.(storm_type).('SWL') = cellfun(@(x) x + swl_slr, project_forcing.(storm_type).('SWL'), 'un', false);
end
%------ Hm0 ADJUSTMENTS -----
if ~iscell(project_forcing.(storm_type).('SWL'))  % Peaks
    % Compute Water Depth @ Toe
    h = project_forcing.(storm_type).('SWL') + toe_elev;
    % Compute Freeboard
    Rc = crest_elev - project_forcing.(storm_type).('SWL');
    % Apply Depth Limitation
    if apply_DL == 1
        project_forcing.(storm_type).('Hm0') = apply_depth_limitation(project_forcing.(storm_type).('Hm0'), project_forcing.(storm_type).('Tp'), h);
    end
else % Timeseries
    % Compute Water Depth @ Toe
    h = cellfun(@(x) x + toe_elev,project_forcing.(storm_type).('SWL'), 'un', false);
    % Compute Freeboard
    Rc = cellfun(@(x) crest_elev - x, project_forcing.(storm_type).('SWL'), 'un', false);
    % Apply Depth Limitation
    if apply_DL == 1
        project_forcing.(storm_type).('Hm0') = cellfun(@(x, y, z) apply_depth_limitation(x, y, z), project_forcing.(storm_type).('Hm0'), project_forcing.(storm_type).('Tp'), h,'un',false);
    end
end
% Create Forcing Variables For Simplicity
SWL = project_forcing.(storm_type).SWL; % SWL
Hm0 = project_forcing.(storm_type).Hm0; % Hm0
Tp = project_forcing.(storm_type).Tp; % Tp

%% COMPUTE STRUCTURE RESPONSE
% Call Eurotop Influence Factors
gammas = call_eurotop_ifactors(config, structure, project_forcing.(storm_type).('SWL'), project_forcing.(storm_type).('Hm0'));
% Compute runup & Overtopping
[Resp.('R2p'),...
    Resp.('q')] = arrayfun(@(a, b, c, d, e, f, g) Eurotop_r2p_q_Final(a, b, c, d,...
    slope, e, gammas.gamma_beta_r2p, gammas.gamma_beta_q, f, g, toe_elev,...
    berm_width, struc_type),Hm0, Tp, SWL, Rc, gammas.gamma_f, gammas.gamma_star,...
    gammas.gamma_v);
% Compute R2p + SWL
Resp.('R2p_SWL') = Resp.('R2p') + SWL;
% Compute Structure Type Dependant Responses
switch struc_type
    case 2 % Floodwall
        % Compute Tm1_0
        Tm10 = Tp./1.1;
        % Compute Water Depth @ Berm
        hb = berm_elev + SWL;
        % Compute P1 Only
        Resp.('p1') = goda_forces_on_vertical_p1(Hm0, Tm10, 1.8,...
            0, h, hb, berm_width, slope, rho_w, [1, 1]);
    case 3 % Rubblemound - Stone Sizing
        % Compute Mean Period
        Tm = Tp./1.2; % This should be removed
        % Compute Stone SIze Using S Limit State
        [Resp.Dn50, Resp.Dn50_LCBW] = arrayfun(@(a, b, c, d) Seaside_stability_Melby_lowCrested(a, b, c,...
            Nz, slope, delta, P, S, g, emp_coeff.km1, emp_coeff.km2, d),...
            Hm0, Tm, h, Rc);
end
end