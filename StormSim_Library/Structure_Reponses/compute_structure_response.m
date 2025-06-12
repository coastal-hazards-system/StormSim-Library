function [Resp] = compute_structure_response(config, structure, project_forcing,  emp_coeff, get_max)
%% GRAB DETAILS FROM "config"
% Strucutre Type
struc_type = config.struc_type;
% Storm Duration [s]
duration = config.storm_duration*3600; % Convert hr to s
% Compute Forcing HC
compute_HC = config.pros_compute_forcing_HC;
% Define Requested Workflow
workflow = config.workflow;
% Gravity
g = config.gravity_constant;
% Grab Structure Response Switches
calc_dn50_ss = config.compute_dn50_seaside;
calc_dn50_ls = config.compute_dn50_leeside;
calc_dn50_lcbw = config.compute_dn50_lcbw;
calc_r2p = config.compute_r2p;
calc_q = config.compute_q;
calc_q_vol = config.compute_q_vol; % Permanently set to 0 for FB
calc_dd = config.compute_damaging_depth;
calc_dd_ks = config.compute_damaging_depth_Ks;
calc_dd_slope = config.compute_damaging_depth_slope;
calc_p1 = config.compute_p1;
calc_p2_p3 = config.compute_p2_p3;
calc_nappe = config.compute_nappe;

% Get Save Point Depth
SPdepth = config.chs_sp_depth;
% Remove Responses Based On Structure Type
switch struc_type
    case 1 % Levee (R2p & OT)
        calc_p1 = 0;
        calc_dn50_ss = 0;
        calc_dn50_ls = 0;
        calc_dn50_lcbw = 0;
    case 2 % Floodwall (q, P1, P2, P3, Nappe)
        calc_dn50_ss = 0;
        calc_dn50_ls = 0;
        calc_dn50_lcbw = 0;
        calc_r2p = 0;
        if calc_p2_p3 == 1
            calc_p1 = 1;
            compute_HC = 1;
        end
        if calc_nappe == 1
            calc_q = 1;
            compute_HC = 1;
        end
    case 3 % Rubblemound (R2p, q, Dn50)
        calc_p1 = 0;
end
% Remove Responses Based On Workflow
if workflow == 3
    % Set Stone Size To Zero
    calc_dn50_ss = 0;
    calc_dn50_ls = 0;
    calc_q_vol = 0;
else
    calc_FS_lcbw = 0; % This is only meant for LCS
end
% No Structural Response Computed
no_resp = sum([calc_dn50_ss,calc_dn50_ls,calc_dn50_lcbw,calc_r2p,calc_q,calc_q_vol,calc_p1,calc_dd]);

%% GRAB DETAILS FROM "structure"
% Define Structure Crest Elevation
crest_elev = structure.crest_elevation;
% Define Structure Crest Width
crest_width = structure.crest_width;
% Define Structure Toe Elevation (<0 below datum zero)
toe_elev = structure.toe_elevation; % Flip convention
% Berm Elevation (<0 Below Datum Zero)
berm_elev = structure.berm_elevation; %
% Berm Width
berm_width = structure.berm_width;
% Berm Slope
berm_slope = structure.berm_slope;
% Seaside Slope (cot(alpha))
if config.slope_type == 1 % This flag will be harcoded for distirbutable version
    slope = structure.seaward_slope; % []
else % Idealized Slope
    slope = structure.seaside_slope;
end
% Leeside Slope
slope_lee = structure.leeside_slope;
% Rubblemound Fields
switch struc_type
    case 3
        % Delta
        delta = structure.armor_delta;
        % Seaside Limit State
        S = structure.seaside_design_S;
        S_ls = structure.leeside_design_S;
        % CEM P
        P = structure.cem_P;
    case  2
        wall_bottom_elev = structure.wall_bottom_elevation;
        hw = wall_bottom_elev + crest_elev;
        toe_elev = wall_bottom_elev;
end
% Water Density kg/m^3
rho_w = structure.water_density;

%% GET FORCING FIELDS
% Grab Workflow Specific Fields
switch workflow
    case {1,2,4} % RB
        % Create Forcing Variables For Simplicity
        SWL = project_forcing.SWL; % SWL
        Hm0 = project_forcing.Hm0; % Hm0
        Tp = project_forcing.Tp; % Tp
        h = cellfun(@(x) x - toe_elev, SWL, 'un', false);
        Rc = cellfun(@(x) crest_elev - x, SWL, 'un', false);
    case 3 % LCS
        SWL = cellfun(@(x) x(:,5),project_forcing,'un',false); % SWL
        Hm0 = cellfun(@(x) x(:,6),project_forcing,'un',false); % Hm0
        Tp = cellfun(@(x) x(:,7),project_forcing,'un',false); % Tp
        h = cellfun(@(x) x - toe_elev, SWL, 'un', false);
        Rc = cellfun(@(x) crest_elev - x, SWL, 'un', false);
end

%% GET LCBW SPECIFIC FIELDS
if struc_type == 3
    crest_elev_lcbw = structure.crest_elevation_lcbw; % Crest Elevation
    Rc_lcbw = cellfun(@(x) crest_elev_lcbw - x, SWL, 'un', false); % Freeboard
    SG = 1 + config.armor_delta;% Armor Stone Specific Gravity
    dr = SG*rho_w;% Armor Stone Density [kg/m^3]
    V_ss_lcbw = structure.lcbw_seaside_mass/dr; % Seaside Median Volume of Armor Stone
    SDn_lcbw = V_ss_lcbw^(1/3);% (LCBW) Seaside Nominal Stone Diameter (m)
end

%% COMPUTE STRUCTURE RESPONSE
if no_resp~=0
    % Call Eurotop Influence Factors
    gammas = cellfun(@(x,y) call_eurotop_ifactors(config, structure, x, y),SWL,Hm0,'un',false);
    % Compute Structure Type Dependant Responses
    switch struc_type
        case 2 % Floodwall
            % Reformat Slope If Needed
            if length(slope) == 1
                slope_aux = cellfun(@(y) repmat(berm_slope, size(y)), SWL, 'un', false);
            end
            % Compute runup & Overtopping
            if calc_q == 1 || calc_nappe == 1
                [~,~, Resp.q, q_overflow, Resp.q_wave_ot]=cellfun(@(a, b, c, d, e, f) Eurotop_r2p_q_Final(a, b, c, d,...
                    f, e.gamma_f, e.gamma_beta_r2p, e.gamma_beta_q, e.gamma_star, e.gamma_v, e.gamma_b,...
                    wall_bottom_elev, berm_width, g, struc_type),...
                    Hm0, Tp, SWL, Rc, gammas, slope_aux,'un',false);
            end
            % Compute Tm1_0
            Tm10 = cellfun(@(x) x./1.1,Tp,'un',false);
            % Compute Water Depth @ Berm
            hb = cellfun(@(x) x - berm_elev, SWL,'un',false);
            % Compute Wall Pressures
            if calc_p1 == 1 || calc_p2_p3 == 1
                % P1
                Resp.p1 = cellfun(@(a, b, c, d) goda_forces_on_vertical_p1(a, b, 1.8,...
                    0, c, d, berm_width, berm_slope, rho_w, g), Hm0, Tm10, h, hb, 'un', false);
            end
            %
            if calc_p2_p3 == 1
                % Compute P2 & P3 Wall Pressures (Plots)
                [Resp.p2dyn, Resp.p2sta, Resp.p2total,...
                    Resp.p3dyn, Resp.p3sta, Resp.p3total, Resp.pu] = cellfun(@(a, b, c, d, e, f) goda_forces_on_vertical_p2p3(a, b, 1.8,...
                    0, c, d, e, hw, f, rho_w, g), Hm0, Tm10, h, hb, Rc, Resp.p1, 'un', false);
            end
            %
            if calc_nappe == 1
                [Resp.X_low, Resp.theta_low, Resp.X_up,...
                    Resp.theta_up, Resp.Bx, Resp.X_c_surge,...
                    Resp.theta_center, Resp.Bjet, Resp.Vjet,...
                    Resp.Fjet] = cellfun(@(a, b, c) floodwall_nappe_response(a, b,...
                    c, hw, rho_w), SWL, Hm0, Resp.q, 'un', false);
            end
        case {1,3} % Levees & Rubblemound
            % Reformat Slope If Needed
            if length(slope) == 1
                slope_aux = cellfun(@(y) repmat(slope, size(y)), SWL, 'un', false);
            else
                slope_aux = {slope};
            end
            % Compute runup & Overtopping
            if calc_r2p == 1 || calc_q == 1 || calc_q_vol == 1
                [Resp.R2p, Resp.R2p_SWL, Resp.q, ~, Resp.q_wave_ot]=cellfun(@(a, b, c, d, e,f) Eurotop_r2p_q_Final(a, b, c, d,...
                    f, e.gamma_f, e.gamma_beta_r2p, e.gamma_beta_q, e.gamma_star, e.gamma_v, e.gamma_b,...
                    toe_elev, berm_width, g, struc_type),...
                    Hm0, Tp, SWL, Rc, gammas, slope_aux,'un',false);
            end
            % Compute Mean Period
            Tm = cellfun(@(x) x./1.2,Tp,'un',false); % This should be removed
            % Compute Zeroth Moment Spectral Wave Period
            Tm10 = cellfun(@(x) x./1.1,Tp,'un',false); % This should be removed
            % Compute Stone Size Using S Limit State
            if struc_type == 3 || struc_type == 4
                % Dn50 Seaside (Melby - Momentum Flux)
                if calc_dn50_ss == 1
                    [Resp.Dn50] = cellfun(@(a, b, c, d) melby_Dn50_seaside_stability(a, b, c,...
                        duration, slope, delta, P, S, g, emp_coeff.km1, emp_coeff.km2, d),...
                        Hm0, Tm, h, Rc,'un',false);
                end
                % Leeside
                if calc_dn50_ls == 1
                    [Resp.Dn50_Lee] = cellfun(@(a,b,c,d,e) ...
                        van_gent_Dn50_leeside_stability(S_ls, a, b, c, d,...
                        crest_width, slope, slope_lee, duration, delta, g,...
                        emp_coeff.k_ls1, emp_coeff.k_ls2, e.gamma_f),...
                        Hm0, Tm10, Tm, Rc,gammas,'un',false);
                end
                % Dn50 Seaside Low Crested Breakwater
                if calc_dn50_lcbw == 1
                    %{
                    Melby addition for LCBW. This is a temporary fix for Midbay. Ultimately we will have a branch whether  
                    breakwater is normal or low-crested.  In that case, there will not be a separate crest elevation for low-crested structure.  
                    However, for Midbay, we have both normal structure and low crested because toe berm is at MLLW. 
                    So we have both normal and LC (toe berm) stability computed in same sim.
                    %}
                    if workflow == 3
                        calc_dn50_lcbw = 0; % Turn Of To Pull Correct Label
                        calc_FS_lcbw = 1; % Turn On To Pull Correct Label
                        % Compute LCBW FS
                        [Resp.FS_LCBW] = cellfun(@(a,b) melby_low_crested_stability(a, b, delta, SDn_lcbw), Hm0, Rc_lcbw,'un', false);
                    else
                        [Resp.Dn50_LCBW] = cellfun(@(a,b) melby_low_crested_stability(a, b, delta, []), Hm0, Rc_lcbw, 'un', false);
                    end
                end
            end
    end
    % Damaging Depth Response
    if calc_dd == 1
        [Resp.DamDepthElev, Resp.DamDepth]= cellfun(@(x, y, z) damaging_depth(x, y, z, SPdepth, g, calc_dd_ks, calc_dd_slope), SWL, Hm0, Tp, 'un', false);
    end
    % Compute Overtopping Volume
    if calc_q_vol == 1 && length(Resp.q{1}(:,1)) > 1
        Resp.Q_vol = cell2mat(cellfun(@(x) sum(x,1,"omitnan"),Resp.q,'un',false));
        Resp.Q_vol_wave_ot = cell2mat(cellfun(@(x) sum(x,1,"omitnan"),Resp.q_wave_ot,'un',false));
    end
else % StormSim:EVA was called, no structure responses
    Resp = [];
end

%% REPLACE SSL, Hm0, Tp FIELDS IF USER REQUESTED FORCING HC (PROS ONLY -> WORKFLOW 1)
% For TC SSL, Hm0, Tp Datasets -> Need storm data with replicates without Ua, Ur. JPM accounts for this uncertainty component during the integration process.
% For XC SSL, Hm0, Tp Datasets -> Need storm data without replicates and without Ua, Ur. PST accounts for both uncertainty components through the bootstrapping process
% Define Replicate Condition Per Storm Type
if ismember(workflow, [1,2,4])
    if compute_HC == 1 & any(contains(fieldnames(project_forcing),{'_no_rep'}))
        % Grab Values With No Uncertainty For HC Calculations
        SWL = project_forcing.('SWL_no_rep');
        Hm0 = project_forcing.('Hm0_no_rep');
        Tp = project_forcing.('Tp_no_rep');
        % Find SWL Max For Each Storm
        Resp.('SWL') = cellfun(@(x) max(x,[],1),SWL,'un',false);
        % Find Hm0 Max For Each Storm
        [Resp.('Hm0'), Hm0_indx] = cellfun(@(x) max(x,[],1),Hm0,'un',false);
        %
        Resp.('Tp') = cellfun(@(x,y) x(y), Tp, Hm0_indx, 'un', false);
        %
        forcing_bool = [1, 1, 1];
    else
        forcing_bool = [0, 0, 0];
    end
else
    forcing_bool = [0, 0, 0];
end

%% FLATTEN DATA & STORE RESPONSES
if get_max == 1
    % Build Var Inventory Logical Vector
    var_bool = [forcing_bool, calc_dn50_ss, calc_dn50_ls, calc_dn50_lcbw, calc_FS_lcbw, calc_r2p, calc_r2p, calc_q, calc_q, calc_p1, calc_dd, calc_dd];
    var_names = {'SWL', 'Hm0', 'Tp', 'Dn50', 'Dn50_Lee', 'Dn50_LCBW', 'FS_LCBW', 'R2p', 'R2p_SWL', 'q', 'q_wave_ot', 'p1', 'DamDepth', 'DamDepthElev'};
    % Evaluate According To Workflow
    switch workflow
        case {1, 2, 4} % Find Max Responses For Timeseries (RB3)
            %
            var_names = var_names(var_bool == 1);
            %
            if calc_q_vol == 1
                vars_to_find = [var_names,{'Q_vol_wave_ot', 'Q_vol'}];
            else
                vars_to_find = var_names;
            end
            % Remove Unwanted Fields
            rm_indx = sum(cell2mat(cellfun(@(x) strcmp(fieldnames(Resp), x), vars_to_find, 'un', false)), 2) == 0;
            if any(rm_indx)
                rm_names = fieldnames(Resp);
                Resp = rmfield(Resp, rm_names(rm_indx));
            end
            % Loop Through Each Response
            for vv = 1:length(var_names)
                Resp.(var_names{vv}) = cell2mat(cellfun(@(x) max(x,[],1), Resp.(var_names{vv}), 'un', false));
            end
    end
end
end