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
% Compute Forcing HC
compute_HC = config.pros_compute_forcing_HC;

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
if ~iscell(project_forcing.(storm_type).SWL)
    SWL = {project_forcing.(storm_type).SWL}; % SWL
    Hm0 = {project_forcing.(storm_type).Hm0}; % Hm0
    Tp = {project_forcing.(storm_type).Tp}; % Tp
    h = {h};
    Rc = {Rc};
else
    SWL = project_forcing.(storm_type).SWL; % SWL
    Hm0 = project_forcing.(storm_type).Hm0; % Hm0
    Tp = project_forcing.(storm_type).Tp; % Tp
end

%% COMPUTE STRUCTURE RESPONSE
% Call Eurotop Influence Factors
gammas = cellfun(@(x,y) call_eurotop_ifactors(config, structure, x, y),SWL,Hm0,'un',false);
% Compute runup & Overtopping
[R2p,R2p_SWL,q]=cellfun(@(a, b, c, d, e) Eurotop_r2p_q_Final(a, b, c, d,...
    slope, e.gamma_f, e.gamma_beta_r2p, e.gamma_beta_q, e.gamma_star, e.gamma_v, e.gamma_b,...
    toe_elev,berm_width, struc_type),...
    Hm0, Tp, SWL, Rc, gammas,'un',false);
% Compute Structure Type Dependant Responses
switch struc_type
    case 2 % Floodwall
        % Compute Tm1_0
        Tm10 = cellfun(@(x) x./1.1,Tp,'un',false);
        % Compute Water Depth @ Berm
        hb = cellfun(@(x) berm_elev + x, SWL,'un',false);
        % Compute P1 Only
        p1 = cellfun(@(a, b, c, d) goda_forces_on_vertical_p1(a, b, 1.8,...
            zeros(size(a)), c, d, berm_width, slope, rho_w, [1, 1]),Hm0,Tm10,h,hb,'un',false);
    case {1,3} % Levees & Rubblemound
        % Compute Mean Period
        Tm = cellfun(@(x) x./1.2,Tp,'un',false); % This should be removed
        % Compute Stone SIze Using S Limit State
        if struc_type == 3
            [Dn50] = cellfun(@(a, b, c, d) Seaside_stability_Melby_lowCrested(a, b, c,...
                Nz, slope, delta, P, S, g, emp_coeff.km1, emp_coeff.km2, d),...
                Hm0, Tm, h, Rc,'un',false);
        end
end
if length(R2p)==1 % Peaks Case
    if exist('R2p','var') && struc_type~=2
        Resp.('R2p') = R2p{:};
        Resp.('R2p_SWL') = R2p_SWL{:};
    end
    Resp.('q') = q{:};
    if exist('p1','var')
        Resp.('p1') = p1{:};
    end
    if exist('Dn50','var')
        Resp.('Dn50') = Dn50{:};
        %Resp.('Dn50_LCBW') = Dn50_LCBW{:};
    end
else % Timeseries
    if exist('R2p','var') && struc_type~=2
        Resp.('R2p') = cell2mat(cellfun(@(x) max(x,[],1),R2p,'un',false));
        Resp.('R2p_SWL') = cell2mat(cellfun(@(x) max(x,[],1),R2p_SWL,'un',false));
    end
    Resp.('q') = cell2mat(cellfun(@(x) max(x,[],1),q,'un',false));
    if exist('p1','var')
        Resp.('p1') = cell2mat(cellfun(@(x) max(x,[],1),p1,'un',false));
    end
    if exist('Dn50','var')
        Resp.('Dn50') = cell2mat(cellfun(@(x) max(x,[],1),Dn50,'un',false));
        %Resp.('Dn50_LCBW') = cell2mat(cellfun(@(x) max(x,[],1),Dn50_LCBW,'un',false));
    end
    if compute_HC == 1
        % Find SWL Max For Each Storm
        project_forcing.(storm_type).('SWL') = cell2mat(cellfun(@(x) max(x,[],1),SWL,'un',false));
        % Find Hm0 Max For Each Storm
        [Hm0_2,Hm0_indx] = cellfun(@(x) max(x,[],1),Hm0,'un',false);
        % Create Col index For Max
        cc = repmat({1:length(Hm0_2{1})},length(Hm0_2),1);
        % Store Back Into Project Forcing
        project_forcing.(storm_type).('Hm0') = cell2mat(Hm0_2);
        % Initialize Tp Var
        dummy = zeros(size(project_forcing.(storm_type).('Hm0')));
        % Tp as a f(Hm0)
        for ll = 1:length(Hm0)
            dummy(ll,:) = cell2mat(arrayfun(@(x,y) Tp{ll}(x,y),Hm0_indx{ll},cc{ll},'un',false));
        end
        % Assign Back To Project Forcing
        project_forcing.(storm_type).('Tp') = dummy;
    end
end
end