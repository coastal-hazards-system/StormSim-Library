



%% READ INPUT FILE (WILL BE REPLACED BY PARSER FUNCTION TO CREATE config)
% This will be replaced with a parser that outputs config var with all info
% The idea is to make it such that changes to Input CSV only impact 1
% function instead of N functions that call INPUT.

config = inputs_parser(config);

%% PREP CHS STORM DATA

%{

Output Variables:
    Storm   (Nstm x 5)
        col 1 : SWL          [m, datum]
        col 2 : Hm0          [m]
        col 3 : Tp           [s]
        col 4 : Direction    [degrees; N=0, E=+90, S=+/-180, W=-90]
        col 5 : Storm ID     [-]
    TC_Freq (Nstm x 1) - TC storms relative probability at desired save
        point
%}
% Call Storm Data Prep Function
[Storm,~,TC_Freq,config] = CHS_storm_data_prep(config);



%% Create Storm variable with added uncertainty (if applicable)
%{
Apply uncertainty to responses for stochastic analysis. For deterministic
analysis, uncertainty is not applied.

Output variables:
    Resp (Nstm*Ndsct x 1)
        SWL        - [m, datum]
        Hm0        - [m]
        Tp         - [s]
        Prob       - SRR for associated SP
        h          - Save point depth
%}
% Apply Uncertianty (Made changes and need to discuss)
[Resp]=apply_forcing_uncertainty(config,Storm,TC_Freq);

%% Create structure variable
%{
Output variables:
    Struc (Nstm*Ndsct x 1), unless data is a string
        Struc.CaseName       - String defining case
        Struc.CrestEle       - Structure crest elevation [m, datum]
        Struc.Rc             - Structure Freeboard [m]
        Struc.h              - Save Point depth [m, datum]
        Struc.ID             - Structure ID, string [-]
        Struc.toe            - Structure toe elevation [m, datum]
        Struc.type           - Switch (1 for levees, 2 for floodwalls, 3
                               for rubble mound)
        Struc.gamma_v        - Coeff for wall influence on a levee
        Struc.gamma_star     - Coeff for wall influence on a levee
        Struc.gamma_f        - Coeff for surface roughness
        Struc.gamma_beta_r2p - Coeff for oblique waves for runup equation
        Struc.gamma_beta_q   - Coeff for oblique waves for overtopping
                               equation
        Struc.slope          - Seaside slope of structure, 0 if floodwall
        Struc.B              - Structure berm width [m]
        Struc.Nz             - Storm Duration (s), empty if not rubble mound
        Struc.delta          - (Stone density/water density)-1, empty if not
                               rubble mound
        Struc.P              - Permeability coefficient for stability
                               equation, empty if not rubble mound
        Struc.S              - Damage limit state, empty if not rubble mound
        Struc.g              - Gravity [m/s^2], empty if not rubble mound
        Struc.km1 and km2    - Coefficients for stability equation, empty if
                               not rubble mound
%}
[Struc] = prep_project_structure(config,Resp);

%% Overtopping and runup + stone sizing calculation
%{
Output variables:
    Resp (Nstm*Ndsct x 1)
           R2p               - Runup [m, datum]
           q                 - Overtopping [m^3/s/m]
%}
% This needs some work 
[Resp] = compute_structure_reponse(Struc,Resp,config.strucType,config.storm_sampling);

%% ******************** Hazard calculations *************************
%{
Compute SWL, Hm0, Tp, levee and floodwall overtopping, and levee runup
using the joint probability method.

Output variable:
    OUTPUT -contains AEP hazard values for storm and responses
        OUTPUT.HC_SWL_EV            (m, datum)
        OUTPUT.HC_SWL_CL90          (m, datum)
        OUTPUT.HC_Hm0_EV            (m)
        OUTPUT.HC_Hm0_CL90          (m)
        OUTPUT.HC_Tp_EV             (s)
        OUTPUT.HC_Tp_CL90           (s)
        OUTPUT.HC_R2p_EV            (m, datum)
        OUTPUT.HC_R2p_CL90          (m, datum)
        OUTPUT.HC_R2pPlusSWL_EV     (m, datum)
        OUTPUT.HC_R2pPlusSWL_CL90   (m, datum)
        OUTPUT.HC_q_EV              (m^3/s/m)
        OUTPUT.HC_q_CL90            (m^3/s/m)
%}
[OUTPUT]= compute_hazard_curves(config,Resp);

%% Compute p2, p3, and nappe for floodwalls
if config.strucType==2 % floodwalls
    disp('Calculate SWL and Hm0 hazards to compute pressures p2 and p3 and nappe geometry and velocity for floodwalls')
    [OUTPUT]=compute_wall_pressures(config, OUTPUT, Struc);
end

%% Combine hazards  (if applicable)
if strcmp(config.storm_sampling,'CC')==1
    OUTPUT.CC_ARI = combine_hazard_curves(OUTPUT,1./OUTPUT.TC.JPM_output(1).HC_tbl_x);
end

%% Plot Hazard Curves
% Create Plot DAta Structure 
PLOT = pros_plot_prep(config,OUTPUT,'MSL');
% Call Plot Function
plot_hazard_curves(config,PLOT);


rmpath('StormSim_Library')








