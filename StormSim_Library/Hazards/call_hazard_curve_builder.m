function  [Output]= call_hazard_curve_builder(config, structure, project_forcing, Resp, storm_type, use_aep)
% CALL_STRUCTURE_CURVE_BUILDER Computes hazard curve for provided forcing
% and structure responses using StormSim's SST & JPM. Supports hazard curve
% calculations for: SWL, Hm0, Tp, R2p, R2p+SWL, q, Dn50, Dn50_LCBW, p1.
% Additionally, computes structure secondary responses from resulting
% hazard curves. This is meant to be used in a response base context and
% not as a caller function for StormSim SST/JPM.
%
% Example usage:
%
% [Output]= call_hazard_curve_builder(config, project_forcing, Resp, storm_type)
%
% Inputs:
%
%   1. config: MATLAB structure containing parsed input file.
%   2. project_forcing: MATLAB structure containing formatted project_forcing.
%   3. Resp: MATLAB structure containing project structure responses.
%   4. storm_type: String specifying the storm type to call ('XC' or 'TC').
%
% Outputs:
%
%   1.


disp('            Building hazard curves....');
%% GRAB DETAILS FROM "config"
% Get Number Of Years (XC Storms)
try
    Nyrs_XC = config.Nyrs_XC;
end
% Compute Forcing Hazard Curves Switch
compute_forcing_hc = config.pros_compute_forcing_HC;
% Grab Percentiles
try
    prc = [cellfun(@str2double,strsplit(config.project_CLs(2:end-1),{' '}))];
catch
    prc = [];
end
% SP ID
sp_ID = config.sp_ID;
% Structure Type
struc_type = config.struc_type;
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
% Get Project Forcing Fields If Provided
if ~isempty(project_forcing) && compute_forcing_hc == 1
    % Add Project Forcing To List
    vars_2_get = [vars_2_get;fieldnames(project_forcing)];
    % Grab Prob Masses
    if strcmp(storm_type, 'TC')
        TC_Prob = project_forcing.TC_Prob;
        % Remove Tc Prob From Filenames
        vars_2_get = vars_2_get(~contains(vars_2_get,{'TC_Prob'}));
    end
    % Grab Forcing Uncertainty
    swl_u_a = config.chs_swl_u_a; % SWL Absolute
    swl_u_r = config.chs_swl_u_r; % SWL Proportional
    hm0_u_a = config.chs_hm0_u_a; % Hm0 Absolute
    hm0_u_r = config.chs_hm0_u_r; % Hm0 Proportional
end
% Initialize Dummy Time Vector
% try
%     input_data.time_values = zeros(size(Resp.('q')));
% catch
%     input_data.time_values = zeros(size(project_forcing.('SWL')));
% end
% Save Name
save_name = [config.project_name, filesep, config.struc_id, filesep,...
    config.project_name,'_', config.struc_id];

%% GRAB DETAILS FROM "structure"
% Define Structure Crest Elevation
crest_elev = structure.crest_elevation;
% Define Structure Toe Elevation (<0 below datum zero)
toe_elev = structure.toe_elevation*-1; % Flip convention
% Berm Elevation (<0 Below Datum Zero)
berm_elev = structure.berm_elevation*-1; %
% Compute Wall Height
hw = toe_elev + crest_elev;
% Get Water Density
rho_w = structure.water_density;

%% DEFINE SWITCHES BASED ON AEF/AEP
% Define HC Limt for Plots
if use_aep == 1
    x_lim = num2str(10^-3);
    l_str = '>';
else
    x_lim = num2str(10^-4);
    l_str = '>';
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
            unit_label = 'm';
            y_label = ['SWL [' unit_label ']'];
            var_name = 'SWL';
        case 'Hm0'
            U_a = hm0_u_a;
            U_r = hm0_u_r;
            uncert_treatment = 'combined';
            unit_label = 'm';
            y_label = ['H_{m_{0}} [' unit_label ']'];
            var_name = 'H_{m_{0}}';
        case 'Tp'
            U_a=0;
            U_r=sqrt(1+hm0_u_r)-1;
            uncert_treatment = 'relative';
            unit_label = 's';
            y_label = ['T_p [' unit_label ']'];
            var_name = 'T_p';
        case {'R2p','R2p_SWL'}
            U_a=0;
            U_r = r2p_u;
            uncert_treatment = 'relative';
            unit_label = 'm';
            y_label = ['R_{2%} [' unit_label ']'];
            var_name = 'R_{2%}';
            if strcmp(staID,'R2p_SWL')
                y_label = ['R_{2%} + SWL [' unit_label ']'];
                var_name = 'R_{2%} + SWL';
            end
        case {'Dn50','Dn50_LCBW'}
            U_a=0;
            U_r = dn50_u;
            uncert_treatment = 'relative';
            unit_label = 'm';
            y_label = ['D_{n_{50}} [' unit_label ']'];
            var_name = 'D_{n_{50}}';
            if strcmp(staID,'R2p_SWL')
                y_label = ['D_{n_{50}} LCBW' unit_label ''];
                var_name = 'D_{n_{50}} LCBW';
            end
        case 'p1'
            U_a=0;
            U_r = p1_u;
            uncert_treatment = 'relative';
            unit_label = 'Pa';
            y_label = ['P_1 [ ' unit_label ']'];
            var_name = 'P_1';
        case 'q'
            U_a=0;
            U_r = q_u;
            uncert_treatment = 'relative';
            unit_label = 'm^3/s per m';
            y_label = ['q [ ' unit_label ']'];
            var_name = 'q';
    end
    % Assign Input Data
    if contains(staID,{'SWL','Hm0','Tp'}) && ~contains(staID,'R2p_SWL')
        c_indx = 1;% Only process 1st replicate, no double dipping for uncertainty
        input_data.data_values = project_forcing.(staID)(:,c_indx);
        input_data.time_values = zeros(size(project_forcing.(staID)(:,c_indx)));
    else
        c_indx = 1:size(Resp.(staID),2);
        input_data.data_values = Resp.(staID)(:,c_indx);
        input_data.time_values = zeros(size(Resp.(staID)(:,c_indx)));
    end
    % Check For Full NaN Vector
    if sum(isnan(input_data.data_values(:)))==length(input_data.data_values(:))
        % Response Variable Has NaNs For All Entries
        disp(['               No valid responses for ' staID ', Skipping response var....']);
        % Skip Iteration
        continue;
    end
    % Initialize AEF/AEP Search Vector
    s_indx = [];
    % Call SST/JPM
    switch storm_type
        case 'XC'
            % Disp Progress
            disp(['               Performing Stochastic Simulation Technique (SST) for station (',num2str(ii),'/',num2str(length(vars_2_get)),'): ', staID]);
            % Set Time Values TO Empty
            input_data.time_values = input_data.time_values(:);
            % Call SST
            try
                [dummy] = call_stormsim_sst(input_data, staID, Nyrs_XC, prc, use_aep, U_a, U_r, uncert_treatment);
                % Define Limtis For Frequency/Probability Vectors
                eval(['s_indx = dummy.HC_plt_x' l_str x_lim ';']);
                % Organize Outputs
                Output(ii).var = staID; % Station ID
                Output(ii).y_label = y_label; % Y Axis Label
                Output(ii).title = {['StormSim: SST Hazard Curve - SP: ' num2str(sp_ID)],...
                    ['' storm_type ' | ' var_name ' [' unit_label ']']}; % Title
                Output(ii).x_plot = dummy.HC_plt_x(s_indx); % Hazard Curve AEP/AEF For Plot
                Output(ii).y_plot = dummy.SST_output.HC_plt(:, s_indx)'; % Hazard Curve Data For Plot
                Output(ii).x_table = dummy.HC_tbl_x'; % Hazard Curve ARF For Table
                Output(ii).y_table = dummy.SST_output.HC_tbl'; % Hazard Curve Data For Table
                if use_aep == 1
                    Output(ii).tbl_rsp_x = dummy.SST_output.HC_tbl_rsp_x'; % x here implies Responses, AEP/AEF -> Responses
                else
                    Output(ii).tbl_rsp_x = aef2aep(dummy.SST_output.HC_tbl_rsp_x');
                end
                Output(ii).tbl_rsp_y = dummy.HC_tbl_rsp_y; % y here implies AEF/AEp, Response -> AEP/AEF
                Output(ii).CL = [50,prc]; % Percentiles (Cols)
                Output(ii).save_name = [save_name '_StormSim_SST_' staID '_Hazard_Curve.png']; % Figure Save Name
                % OVertopping Special Case
                if strcmp(staID,'q')
                    % Convert From [m^3/s per m] to [liters/s per m]
                    %                 Output(ii).y_plot = Output(ii).y_plot * 1000;
                    Output(ii).y_log_scale = 1; % Y Log Scale For Overtopping
                else
                    Output(ii).y_log_scale = 0; % Regular Scale For The Rest
                end
                % THIS SHOULD BE REMOVED ONCE SST/JPM HC COMBINATION IS SORTED
                if contains(staID,{'Hm0','SWL'})
                    % Add rsp_
                end
            catch
                disp(['               Stochastic Simulation Technique (SST) returned error, skipping: ', staID]);
            end
        case 'TC'
            disp(['               Performing Joint Probability Method (JPM) for station (',num2str(ii),'/',num2str(length(vars_2_get)),'): ', staID]);
            % JPM Expects Data Matrix
            input_data.data_values = input_data.data_values;
            try
                [dummy] = call_stormsim_jpm(staID, prc, use_aep, U_a, U_r, input_data.data_values, TC_Prob(:,c_indx), uncert_treatment);
                % Define Limtis For Frequency/Probability Vectors
                eval(['s_indx = dummy.HC_plt_x' l_str x_lim ';']);
                % Organize Outputs
                Output(ii).var = staID; % Station ID
                Output(ii).y_label = y_label; % Y Axis Label
                Output(ii).title = {['StormSim: JPM Hazard Curve - SP: ' num2str(sp_ID)],...
                    ['' storm_type ' | ' var_name ' [' unit_label ']']}; % Title
                Output(ii).x_plot = dummy.HC_plt_x(s_indx); % Hazard Curve AEF For Plot
                Output(ii).y_plot = dummy.HC_data.HC_plt_y(s_indx, :); % Hazard Curve Data For Plot
                Output(ii).x_table = dummy.HC_tbl_x'; % Hazard Curve ARF For Table
                Output(ii).y_table = dummy.HC_data.HC_tbl_y; % Hazard Curve Data For Table
                Output(ii).tbl_rsp_x = aef2aep(dummy.HC_data.HC_tbl_rsp_x);
                if use_aep == 1
                    Output(ii).tbl_rsp_x = dummy.HC_data.HC_tbl_rsp_x;
                else
                    Output(ii).tbl_rsp_x = aef2aep(dummy.HC_data.HC_tbl_rsp_x);
                end
                Output(ii).tbl_rsp_y = dummy.HC_tbl_rsp_y; % y here implies AEF/AEp, Response -> AEP/AEF
                Output(ii).CL = [50,prc]; % Percentiles (Cols)
                Output(ii).save_name = [save_name '_StormSim_JPM_' staID '_Hazard_Curve.png']; % Figure Save Name
                % OVertopping Special Case
                if strcmp(staID,'q')
                    % Convert From [m^3/s per m] to [liters/s per m]
                    %                 Output(ii).y_plot = Output(ii).y_plot * 1000;
                    Output(ii).y_log_scale = 1; % Y Log Scale For Overtopping
                else
                    Output(ii).y_log_scale = 0; % Regular Scale For The Rest
                end
            catch
                disp(['               Joint Probability Method (JPM) returned error, skipping: ', staID]);
            end
    end
end

%% COMPUTE SECONDARY STRUCTURE RESPONSES FROM HC (P2, P3, Nappe)
if compute_forcing_hc == 1
    switch struc_type
        case 2 % Floodwall
            % Find Data Indexes
            sIndx = cell2mat(cellfun(@(x) find(contains({Output.var}',x)==1),{'p1','Hm0','Tp','SWL','q'},'un',false));
            % Grab Example Save Name
            outName = strsplit(Output(sIndx(5)).save_name,'q');
            % Compute Water Depth @ Structure Toe
            h_plt = toe_elev + Output(sIndx(4)).y_plot;
            h_tbl = toe_elev + Output(sIndx(4)).y_table;
            % Compute Water Depth @ Berm
            hb_plt = berm_elev + Output(sIndx(4)).y_plot;
            hb_tbl = berm_elev + Output(sIndx(4)).y_table;
            % Compute Freeboard
            Rc_plt = crest_elev - Output(sIndx(4)).y_plot;
            Rc_tbl = crest_elev - Output(sIndx(4)).y_table;
            % Compute P2 & P3 Wall Pressures (Plots)
            [p2_plt,p3_plt,pu_plt]=goda_forces_on_vertical_p2p3(Output(sIndx(2)).y_plot, Output(sIndx(3)).y_plot,...
                1.8,0,h_plt,hb_plt,Rc_plt,hw,Output(sIndx(1)).y_plot,rho_w,[1 1]);
            % Compute P2 & P3 Wall Pressures (Table)
            [p2_tbl,p3_tbl,pu_tbl]=goda_forces_on_vertical_p2p3(Output(sIndx(2)).y_table, Output(sIndx(3)).y_table,...
                1.8,0,h_tbl,hb_tbl,Rc_tbl,hw,Output(sIndx(1)).y_table,rho_w,[1 1]);
            % Copy Row From Previous Entry
            rIndx = length(Output)+1;
            Output(rIndx) = Output(sIndx(1));
            % Replace Fields For P2
            Output(rIndx).('var') = 'p2';
            Output(rIndx).('y_label') = 'P_2 [Pa]';
            Output(rIndx).('title')(2) = {[storm_type ' | P_2 [Pa]']};
            Output(rIndx).('y_plot') = p2_plt;
            Output(rIndx).('y_table') = p2_tbl;
            Output(rIndx).('save_name') = [outName{1} Output(rIndx).('var') outName{2}];
            % Copy Row From Previous Entry
            rIndx = length(Output)+1;
            Output(rIndx) = Output(sIndx(1));
            % Replace Fields For P3
            Output(rIndx).('var') = 'p3';
            Output(rIndx).('y_label') = 'P_3 [Pa]';
            Output(rIndx).('title')(2) = {[storm_type ' | P_3 [Pa]']};
            Output(rIndx).('y_plot') = p3_plt;
            Output(rIndx).('y_table') = p3_tbl;
            Output(rIndx).('save_name') = [outName{1} Output(rIndx).('var') outName{2}];
            % Copy Row From Previous Entry
            rIndx = length(Output)+1;
            Output(rIndx) = Output(sIndx(1));
            % Replace Fields For Pu
            Output(rIndx).('var') = 'pu';
            Output(rIndx).('y_label') = 'P_u [Pa]';
            Output(rIndx).('title')(2) = {[storm_type ' | P_u [Pa]']};
            Output(rIndx).('y_plot') = pu_plt;
            Output(rIndx).('y_table') = pu_tbl;
            Output(rIndx).('save_name') = [outName{1} Output(rIndx).('var') outName{2}];
            % Compute Nappe Response (Table)
            [Nappe_tbl] = floodwall_nappe_response(Output(sIndx(4)).y_table, Output(sIndx(2)).y_table, Output(sIndx(5)).y_table, hw, rho_w);
            % Compute Nappe Response (Plot)
            [Nappe_plt] = floodwall_nappe_response(Output(sIndx(4)).y_plot, Output(sIndx(2)).y_plot, Output(sIndx(5)).y_plot, hw, rho_w);
            % Get Filenames
            fnames = fieldnames(Nappe_tbl);
            % Define Name & Units, Order Of Fields Is Fixed
            var_info = [{'x_L';'\theta_L';'x_U';'\theta_U';'B_x';'x_{c_{surge}}';'\theta_c';'B_{jet}';'V_{jet}';'F_{jet}'},{'m';char(176);'m';char(176);'m';'m';char(176);'m';'m/s';'N/m'}];
            % Loop Through Fieldnames
            for ii = 1:length(fnames)
                % Compute Row Index
                rIndx = length(Output)+1;
                % Add Row
                Output(rIndx) = Output(end);
                % Replace Fields
                Output(rIndx).('var') = fnames{ii};
                Output(rIndx).('y_label') = [var_info{ii,1} ' [' var_info{ii,2} ']'];
                Output(rIndx).('title')(2) = {[storm_type ' | ' Output(rIndx).('y_label')]};
                Output(rIndx).('y_plot') = Nappe_plt.(fnames{ii});
                Output(rIndx).('y_table') = Nappe_tbl.(fnames{ii});
                Output(rIndx).('save_name') = [outName{1} Output(rIndx).('var') outName{2}];
            end
    end
end
end