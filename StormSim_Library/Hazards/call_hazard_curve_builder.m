function  [Output]= call_hazard_curve_builder(config, project_forcing, Resp, storm_type)
%% GRAB DETAILS FROM "config"
% Get Number Of Years (XC Storms)
try
    Nyrs_XC = config.Nyrs_XC;
end
% Compute Forcing Hazard Curves Switch
compute_forcing_hc = config.pros_compute_forcing_HC;
% Grab Percentiles
prc = [cellfun(@str2double,strsplit(config.project_CLs(2:end-1),{' '}))];
% Initialize Vars 2 Get
vars_2_get = [];
% Grab Strucutre Response Fields If Provided
if ~isempty(Resp)
    % Add Structure Responses To List
    vars_2_get = [vars_2_get;fieldnames(Resp)];
    % Grab Response Uncertainty
    r2p_u = config.r2p_u; % Runup
    q_u = config.q_u; % Overtopping
    dn50_u = config.dn50_u; % Median Stone Size
    p1_u = config.p1_u; % Goda Pressure (P1)
end
% Get Project Forcign Fields If Provided
if ~isempty(project_forcing) && compute_forcing_hc == 1
    % Add Project Forcing To List
    vars_2_get = [vars_2_get;fieldnames(project_forcing)];
    % Grab Prob Masses
    if strcmp(storm_type, 'TC')
        TC_Prob = project_forcing.TC_Prob;
    end
    % Grab Forcing Uncertainty
    swl_u_a = config.chs_swl_u_a; % SWL Absolute
    swl_u_r = config.chs_swl_u_r; % SWL Proportional
    hm0_u_a = config.chs_hm0_u_a; % Hm0 Absolute
    hm0_u_r = config.chs_hm0_u_r; % Hm0 Proportional
end
% Initialize Dummy Time Vector
try
    input_data.time_values = zeros(size(Resp.('R2p')));
catch
    input_data.time_values = zeros(size(Resp.('SWL')));
end

%% COMPUTE HAZARD CURVES WITH STORMSIM: SST/JPM
% Loop Through All Stations
for ii = 1:length(vars_2_get)
    % Define Station ID
    staID = vars_2_get{ii};
    % Assign Uncertainty Based On Station
    switch staID
        case 'SWL'
            U_a = swl_u_a;
            U_r = swl_u_r;
            uncert_treatment = 'combined';
        case 'Hm0'
            U_a = hm0_u_a;
            U_r = hm0_u_r;
            uncert_treatment = 'combined';
        case 'Tp'
            U_a=0;
            U_r=sqrt(1+hm0_u_r)-1;
            uncert_treatment = 'relative';
        case {'R2p','R2p_SWL'}
            U_a=0;
            U_r = r2p_u;
            uncert_treatment = 'relative';
        case {'Dn50','Dn50_LCBW'}
            U_a=0;
            U_r = dn50_u;
            uncert_treatment = 'relative';
        case 'p1'
            U_a=0;
            U_r = p1_u;
            uncert_treatment = 'relative';
    end
    % Assign Input Data
    if contains(staID,{'SWL','Hm0','Tp'}) && ~contains(staID,'R2p_SWL')
        input_data.data_values = project_forcing.(staID);
    else
        input_data.data_values = Resp.(staID);
    end
    % Call SST/JPM
    switch storm_type
        case 'XC'
            disp(['Performing Stochastic Simulation Technique (SST) for station (',num2str(ii),'/',num2str(length(vars_2_get)),'): ', staID]);
            % Set Time Values TO Empty 
            input_data.time_values = [];
            [Output(ii)] = call_stormsim_sst(input_data, staID, Nyrs_XC, prc, U_a, U_r, uncert_treatment);
        case 'TC'
            disp(['Performing Joint Probability Method (JPM) for station (',num2str(ii),'/',num2str(length(vars_2_get)),'): ', staID]);
            % JPM Expects Data Matrix
            input_data = input_data.data_values;
            [Output(ii)] = call_stormsim_jpm(staID, prc, U_a, U_r, input_data, TC_Prob, uncert_treatment);
    end
end
end