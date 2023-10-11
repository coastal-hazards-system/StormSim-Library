function  [Output]= call_hazard_curve_builder(config, structure, project_forcing, Resp, storm_type, use_aep, outPath)
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
case_name = strrep(config.case_name,'_',' ');
struc_id = strrep(config.struc_id,'_',' ');
% Get Workflow
workflow = config.workflow;
% Compute Forcing Hazard Curves Switch
if ismember(workflow,[2,4])
    compute_forcing_hc = 1; % EVA & FB
else
    compute_forcing_hc = config.pros_compute_forcing_HC;
end
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
    % Grab Forcing Uncertainty
    swl_u_a = config.chs_swl_u_a; % SWL Absolute
    swl_u_r = config.chs_swl_u_r; % SWL Proportional
    hm0_u_a = config.chs_hm0_u_a; % Hm0 Absolute
    hm0_u_r = config.chs_hm0_u_r; % Hm0 Proportional
end
% Grab Prob Masses
if strcmp(storm_type, 'TC')
    TC_Prob = project_forcing.TC_Prob;
    % Remove Tc Prob From Filenames
    vars_2_get = vars_2_get(~contains(vars_2_get,{'TC_Prob'}));
end
% Save Name
save_name = [outPath filesep config.project_name,'_', config.struc_id];

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
else
    x_lim = num2str(10^-4);
end
% Define Default Log Scale
y_scale_log = 0;

%% COMPUTE HAZARD CURVES WITH STORMSIM: SST/JPM
% Initialize Counter
ctr = 1;Output = [];
% Loop Through All Stations
for ii = 1:length(vars_2_get)
    % Define Workflow String
    wstr = strsplit(outPath,filesep);
    wstr = wstr{end}(1:3);
    % Define Default Log Scale
    y_scale_log = 0;
    % Define Station ID
    staID = vars_2_get{ii};
    % Assign Uncertainty Based On Station
    switch staID
        case 'SWL'
            % Define Uncertainty Parameters
            U_a = swl_u_a; % Define Absolute Uncertainty
            U_r = swl_u_r; % Define Relative Uncertainty
            uncert_treatment_jpm = 'combined';% JPM Uncertainty Treatment
            uncert_treatment_sst = 'combined';% SST Uncertainty Treatment
            % Define Var Properties
            unit_label = 'm';
            y_label = ['SWL [' unit_label ']'];
            var_name = 'SWL';
        case 'Hm0'
            U_a = hm0_u_a;
            U_r = hm0_u_r;
            uncert_treatment_jpm = 'combined';
            uncert_treatment_sst = 'combined';
            unit_label = 'm';
            y_label = ['H_{m_{0}} [' unit_label ']'];
            var_name = 'H_{m_{0}}';
        case 'Tp'
            U_a = 0;
            U_r = sqrt(1+hm0_u_r)-1;
            uncert_treatment_jpm = 'relative';
            uncert_treatment_sst = 'relative';
            unit_label = 's';
            y_label = ['T_p [' unit_label ']'];
            var_name = 'T_p';
        case {'R2p','R2p_SWL'}
            U_a=0;
            U_r = r2p_u;
            uncert_treatment_jpm = 'relative';
            uncert_treatment_sst = 'relative';
            unit_label = 'm';
            y_label = ['R_{2%} [' unit_label ']'];
            var_name = 'R_{2%}';
            if strcmp(staID,'R2p_SWL')
                y_label = ['R_{2%} + SWL [' unit_label ']'];
                var_name = 'R_{2%} + SWL';
            end
        case {'Dn50','Dn50_LCBW', 'Dn50_Lee'}
            U_a=0;
            U_r = dn50_u;
            uncert_treatment_jpm = 'relative';
            uncert_treatment_sst = 'relative';
            unit_label = 'm';
            y_label = ['D_{n_{50}} [' unit_label ']'];
            var_name = 'D_{n_{50}}';
            if any(strcmp(staID,{'Dn50_LCBW', 'Dn50_Lee'}))
                switch staID
                    case 'Dn50_LCBW'
                        str_suffix = 'LCBW';
                    case 'Dn50_Lee'
                        str_suffix = 'Lee';
                end
                y_label = ['D_{n_{50}} ' str_suffix ' [' unit_label ']'];
                var_name = ['D_{n_{50}} ' str_suffix];
            end
        case 'p1'
            U_a=0;
            U_r = p1_u;
            uncert_treatment_jpm = 'relative';
            uncert_treatment_sst = 'relative';
            unit_label = 'Pa';
            y_label = ['P_1 [ ' unit_label ']'];
            var_name = 'P_1';
        case 'q'
            U_a=0;
            U_r = q_u;
            uncert_treatment_jpm = 'relative';
            uncert_treatment_sst = 'relative';
            unit_label = 'm^3/s per m';
            y_label = ['q [ ' unit_label ']'];
            var_name = 'q';
            y_scale_log = 1;
        case 'q_wave_ot'
            U_a=0;
            U_r = q_u;
            uncert_treatment_jpm = 'relative';
            uncert_treatment_sst = 'relative';
            unit_label = 'm^3/s per m';
            y_label = ['q_{wave OT} [ ' unit_label ']'];
            var_name = 'q_{wave OT}';
            y_scale_log = 1;
        case 'q_overflow'
            U_a=0;
            U_r = q_u;
            uncert_treatment_jpm = 'relative';
            uncert_treatment_sst = 'relative';
            unit_label = 'm^3/s per m';
            y_label = ['q_{overflow} [ ' unit_label ']'];
            var_name = 'q_{overflow}';
            y_scale_log = 0;
        case 'Q_vol'
            U_a=0;
            U_r = q_u;
            uncert_treatment_jpm = 'relative';
            uncert_treatment_sst = 'relative';
            unit_label = 'm^3 per m';
            y_label = ['Q [ ' unit_label ']'];
            var_name = 'Q_{vol}';
            y_scale_log = 1;
    end
    % Assign Input Data
    if contains(staID,{'SWL','Hm0','Tp'}) && ~contains(staID,'R2p_SWL')
        if contains(storm_type,{'TC'})
            c_indx = 1:size(project_forcing.(staID),2);
            input_data.data_values = project_forcing.(staID);
            input_data.time_values = zeros(size(project_forcing.(staID)));
            if workflow == 4
                wstr(1:2) = 'RB';
            end
        else
            c_indx = 1;% Only process 1st replicate, no double dipping for uncertainty
            input_data.data_values = project_forcing.(staID)(:,c_indx);
            input_data.time_values = zeros(size(project_forcing.(staID)(:,c_indx)));
        end
    else
        c_indx = 1:size(Resp.(staID),2);
        input_data.data_values = Resp.(staID);
        input_data.time_values = zeros(size(Resp.(staID)));
    end
    % Define Workflow Name
    switch workflow
        case 1
            wname = ['StormSim: PROS - ' wstr ' | '  case_name ' | ' struc_id];
        case 2
            wname = ['StormSim: EVA - ' wstr ' | '  case_name ' | ' struc_id];
        case 4
            wname = ['StormSim: PROS - ' wstr ' | '  case_name ' | ' struc_id];
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
                [dummy] = call_stormsim_sst(input_data, staID, Nyrs_XC, prc, use_aep, U_a, U_r, uncert_treatment_sst);
                % Define Limtis For Frequency/Probability Vectors
                s_indx = 1:length(dummy.HC_plt_x);%eval(['s_indx = dummy.HC_plt_x>' x_lim ';']);
                % Define Figure Title
                %                 title_str = {['StormSim: SST Hazard Curve - SP: ' num2str(sp_ID)],...
                %                     ['' storm_type ' | ' var_name ' [' unit_label ']']};
                title_str = {wname,...
                    ['' storm_type ' | ' var_name ' [' unit_label ']']};
                % Store SST Outputs
                Output =  rb_response_appender(Output, ctr, staID, y_label, title_str,...
                    dummy.HC_plt_x(s_indx), dummy.SST_output.HC_plt(:, s_indx)',...
                    dummy.HC_tbl_x', dummy.SST_output.HC_tbl', input_data.data_values,...
                    y_scale_log, [50,prc], [save_name '_StormSim_SST_' staID '_Hazard_Curve.png']);
                % Add "_rsp" Fields For Hazard Combinations
                if use_aep == 1
                    Output(ctr).tbl_rsp_x = dummy.SST_output.HC_tbl_rsp_x'; % x here implies Responses, AEP/AEF -> Responses
                    Output(ctr).x_table_ARI = ceil(1./aep2aef(Output(ctr).x_table_ARI));
                else
                    Output(ctr).tbl_rsp_x = aef2aep(dummy.SST_output.HC_tbl_rsp_x');
                    Output(ctr).x_table_ARI = ceil(1./Output(ctr).x_table_ARI);
                end
                Output(ctr).tbl_rsp_y = dummy.HC_tbl_rsp_y; % y here implies AEF/AEp, Response -> AEP/AEF
            catch
                disp(['               Stochastic Simulation Technique (SST) returned error, skipping: ', staID]);
            end
        case 'TC'
            disp(['               Performing Joint Probability Method (JPM) for station (',num2str(ii),'/',num2str(length(vars_2_get)),'): ', staID]);
            try
                [dummy] = call_stormsim_jpm(staID, prc, use_aep, U_a, U_r, input_data.data_values, TC_Prob(:,c_indx), uncert_treatment_jpm);
                % Define Limtis For Frequency/Probability Vectors
                s_indx = 1:length(dummy.HC_plt_x);%eval(['s_indx = dummy.HC_plt_x>' x_lim ';']);
                % Define Figure Title
                %                 title_str = {['StormSim: JPM Hazard Curve - SP: ' num2str(sp_ID)],...
                %                     ['' storm_type ' | ' var_name ' [' unit_label ']']};
                title_str = {wname,...
                    ['' storm_type ' | ' var_name ' [' unit_label ']']};
                % Store/Format JPM Outputs
                Output =  rb_response_appender(Output, ctr, staID, y_label, title_str,...
                    dummy.HC_plt_x(s_indx), dummy.HC_data.HC_plt_y(s_indx, :),...
                    dummy.HC_tbl_x', dummy.HC_data.HC_tbl_y, input_data.data_values,...
                    y_scale_log, [50,prc], [save_name '_StormSim_JPM_' staID '_Hazard_Curve.png']);
                % Add "_rsp" Fields For Hazard Combinations
                if use_aep == 1
                    Output(ctr).tbl_rsp_x = dummy.HC_data.HC_tbl_rsp_x;
                    Output(ctr).x_table_ARI = ceil(1./aep2aef(Output(ctr).x_table_ARI));
                else
                    Output(ctr).tbl_rsp_x = aef2aep(dummy.HC_data.HC_tbl_rsp_x);
                    Output(ctr).x_table_ARI = ceil(1./Output(ctr).x_table_ARI);
                end
                Output(ctr).tbl_rsp_y = dummy.HC_tbl_rsp_y; % y here implies AEF/AEp, Response -> AEP/AEF
            catch
                disp(['               Joint Probability Method (JPM) returned error, skipping: ', staID]);
            end
    end
    % Increase Counter
    ctr = ctr + 1;
end
% Remove Empty Entries (If Any)
rm_indx = cell2mat(cellfun(@(x) isempty(x), {Output.y_table}, 'un', false));% Get Logical Index
Output = Output(~rm_indx);% Keep Valid Fields

%% COMPUTE SECONDARY STRUCTURE RESPONSES FROM HC (P2, P3, Nappe)
if compute_forcing_hc == 1 && ~ismember(workflow,[2,4])
    switch struc_type
        case 2 % Floodwall
            % Find Data Indexes
            sIndx = cell2mat(cellfun(@(x) find(contains({Output.var}',x)==1),{'p1','Hm0','Tp','SWL','q'},'un',false));
            % If All Primary responses Are Valid
            if length(sIndx)==5
                % Grab Example Save Name
                outName = strsplit(Output(sIndx(5)).save_name,'q');
                % Compute Water Depth @ Structure Toe
                h_plt = toe_elev + Output(sIndx(4)).y_plot;
                h_tbl = toe_elev + Output(sIndx(4)).y_table;
                % Compute Water Depth @ Berm
                if berm_elev == 0 % No Berm
                    hb_plt = h_plt;
                    hb_tbl = h_tbl;
                else
                    hb_plt = berm_elev + Output(sIndx(4)).y_plot;
                    hb_tbl = berm_elev + Output(sIndx(4)).y_table;
                end
                % Compute Freeboard
                Rc_plt = crest_elev - Output(sIndx(4)).y_plot;
                Rc_tbl = crest_elev - Output(sIndx(4)).y_table;
                % Compute P2 & P3 Wall Pressures (Plots)
                [p2dyn_plt, p2sta_plt, p2total_plt,...
                    p3dyn_plt, p3sta_plt, p3total_plt, pu_plt]=goda_forces_on_vertical_p2p3(Output(sIndx(2)).y_plot, Output(sIndx(3)).y_plot,...
                    1.8,0,h_plt,hb_plt,Rc_plt,hw,Output(sIndx(1)).y_plot,rho_w,[1 1]);
                % Compute P2 & P3 Wall Pressures (Table)
                [p2dyn_tbl, p2sta_tbl, p2total_tbl,...
                    p3dyn_tbl, p3sta_tbl, p3total_tbl, pu_tbl]=goda_forces_on_vertical_p2p3(Output(sIndx(2)).y_table, Output(sIndx(3)).y_table,...
                    1.8,0,h_tbl,hb_tbl,Rc_tbl,hw,Output(sIndx(1)).y_table,rho_w,[1 1]);
                % Define Pressure Fields To Append
                pFields = who('p2*_plt','p3*_plt','pu*_plt');
                % Define Pressure Fields Y Labels (For Plots)
                y_labels = {'P_2 (Dynamic) [Pa]', 'P_2 (Static) [Pa]', 'P_2 (Total) [Pa]',...
                    'P_3 (Dynamic) [Pa]', 'P_3 (Static) [Pa]', 'P_3 (Total) [Pa]',...
                    'P_u [Pa]'};
                % Get Last Row Index
                rIndx = length(Output);
                % Define Title String Base
                title_base = Output(rIndx).title;
                % Loop Through Fieldnames
                for kk = 1:length(pFields)
                    % Define Variable Name
                    sVar = strrep(pFields{kk},'_plt','');
                    % Define Title String
                    title_str = title_base;
                    title_str(2) =  {['' storm_type ' | ' y_labels{kk}]};
                    % Call Data Appender
                    Output =  rb_response_appender(Output, rIndx+kk, sVar, y_labels{kk}, title_str,...
                        Output(rIndx).x_plot, eval([sVar '_plt;']), Output(rIndx).x_table, eval([sVar '_tbl;']), {'Derived from primary responses hazard curves'},...
                        y_scale_log, [50,prc], [outName{1} sVar outName{2}]);
                end
                % Compute Nappe Response (Table)
                [Nappe_tbl] = floodwall_nappe_response(Output(sIndx(4)).y_table, Output(sIndx(2)).y_table, Output(sIndx(5)).y_table, hw, rho_w);
                % Compute Nappe Response (Plot)
                [Nappe_plt] = floodwall_nappe_response(Output(sIndx(4)).y_plot, Output(sIndx(2)).y_plot, Output(sIndx(5)).y_plot, hw, rho_w);
                % Get Filenames
                pFields = fieldnames(Nappe_tbl);
                % Define Name & Units, Order Of Fields Is Fixed
                y_labels = [{'x_L';'\theta_L';'x_U';'\theta_U';'B_x';'x_{c_{surge}}';'\theta_c';'B_{jet}';'V_{jet}';'F_{jet}'},{'m';char(176);'m';char(176);'m';'m';char(176);'m';'m/s';'N/m'}];
                % Get Last Row Index
                rIndx = length(Output);
                % Define Title String Base
                title_base = Output(rIndx).title;
                % Loop Through Fieldnames
                for kk = 1:length(pFields)
                    % Define Title String
                    title_str = title_base;
                    title_str(2) =  {[y_labels{ii,1} ' [' y_labels{ii,2} ']']};
                    % Call Data Appender
                    Output =  rb_response_appender(Output, rIndx+kk, pFields{kk,1}, [y_labels{kk,1} ' [' y_labels{kk,2} ']'], title_str,...
                        Output(rIndx).x_plot, Nappe_plt.(pFields{kk}), Output(rIndx).x_table, Nappe_tbl.(pFields{kk}), {'Derived from primary responses hazard curves'},...
                        y_scale_log, [50,prc], [outName{1} pFields{kk} outName{2}]);
                end
            end
    end
end

%% AUX FUNCTIONS (CONSOLIDATE LINES OF CODE)
    function Output =  rb_response_appender(Output, rIndx, sVar, y_label, title_str, x_plt, y_plt, x_tbl, y_tbl, POT, y_log_scale, CL, outName)
        % Initialize Entry
        %         if ~isempty(Output)
        %             Output(rIndx) = Output(end);
        %         end
        % Replace Fields For P2
        Output(rIndx).('var') = sVar;
        Output(rIndx).CL = CL; % Percentiles (Cols)
        % Only Grab Frequency Bound On The Table 
        Output(rIndx).('x_plot') = x_plt(x_plt >= min(x_tbl) & x_plt <= max(x_tbl),:);
        Output(rIndx).('y_plot') = y_plt(x_plt >= min(x_tbl) & x_plt <= max(x_tbl),:);
        Output(rIndx).('x_table') = x_tbl;
        Output(rIndx).('y_table') = y_tbl;
        Output(rIndx).('x_table_ARI') = x_tbl;
        Output(rIndx).('POT') = POT;
        Output(rIndx).('y_label') = y_label;
        Output(rIndx).('title') = title_str;
        Output(rIndx).y_log_scale = y_log_scale; % Y Log Scale For Overtopping
        Output(rIndx).('save_name') = outName;
    end
end