function gammas = call_eurotop_ifactors(config, structure, SWL, Hm0)
%% GRAB DETAILS FROM "config"
strucType = config.struc_type;
% Surface roughness coefficient
gamma_f = config.roughness_ifactor;

%% GRAB DETAILS FROM "structure"
% Crest Elevation
crest_ele = structure.crest_elevation;
% Toe Elevation
toe_ele = structure.toe_elevation;
% Berm Elevation
berm_elev = structure.berm_elevation;
% Toe Elevation
berm_width = structure.berm_width;
% Seaward Slope
seaward_slope = structure.seaside_slope;
% Compute Freeboard
Rc = crest_ele - SWL;

%% COMPUTE INFLUENCE FACTORS
% Wall Influence Factor
[gammas.gamma_v, gammas.gamma_star] = wall_influence_factor(crest_ele,toe_ele,Rc,strucType);
% Surface roughness Influence Factor
gammas.gamma_f = surface_roughness_influence_factor(gamma_f, Hm0);
% Oblique wave coefficients - Not implemented in StormSim as of 9/03/20
[gammas.gamma_beta_r2p, gammas.gamma_beta_q] = oblique_waves_influence_factor(1);
% Berm Influence Factor (Not used)
[gammas.gamma_b] = berm_influence_factor(berm_width, berm_elev, Hm0, SWL, seaward_slope);
end