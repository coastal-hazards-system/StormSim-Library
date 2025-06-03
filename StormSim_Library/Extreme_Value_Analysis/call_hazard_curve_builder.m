function  [Output]= call_hazard_curve_builder(config, TC_Prob, Resp, storm_type, use_aep, outPath)
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

%% QUICK ABORT COMMANDS
if ~isstruct(Resp)
    error('Error: Variables "Resp" needs to be populated or empty MATLAB structures....');
end

%% GRAB DETAILS FROM "config"
case_name = strrep(config.case_name,'_',' ');
struc_id = strrep(config.struc_id,'_',' ');
% Grab Percentiles
try
    prc = [cellfun(@str2double,strsplit(config.project_CLs(2:end-1),{' '}))];
catch
    prc = [];
end
% Save Name
save_name = fullfile(outPath, [config.project_name,'_', config.struc_id]);

%% DEFINE RESPONSE VARIABLES TO PROCESS
% Grab Strucutre Response Fields If Provided
vars_to_process = fieldnames(Resp);
% Append Data Structure
data_to_process = Resp;
% Remove Tc Prob From Filenames
vars_to_process = vars_to_process(~contains(vars_to_process,{'TC_Prob'}));

%% INITIALIZE FIELDS && RESPONSE LOOP
% Initialize Counter
ctr = 1;Output = [];
% Loop Through All Responses
for ii = 1:length(vars_to_process)
    %% PREP RESPONSE FOR PST/JPM
    % Define Station ID
    resp_var = vars_to_process{ii};
    % Search Response Library For Uncertainty Values & Associated Labels
    [U_a, U_r, uncert_treatment,...
        unit_label,...
        var_name, y_label, y_scale_log] = response_library_headers(config, resp_var);
    % Get Data Size
    [drows, dcols] = size(data_to_process.(resp_var));
    % Response Information
    response_data = struct('data', [zeros(drows*dcols, 1) data_to_process.(resp_var)(:) zeros(drows*dcols, 1)],...
        'flag_value', [],'Ua', U_a,'Ur', U_r, 'SLC', config.swl_slr, 'tid_std', 0,...
        'lambda', [],'Nyrs', config.Nyrs_XC*dcols, 'gprMdl', [], 'DataType', 'POT');
    % PST/JPM Options
    eva_options = struct('integration_method', 1,...
        'uncertainty_treatment', uncert_treatment,...
        'tide_application', 0, 'ind_Skew', 0, 'use_AEP', config.pros_use_aep,...
        'prc', prc, 'stat_print', 0, 'tLag', 0, 'GPD_TH_crit', 2,...
        'apply_GPD_to_SS', 1, 'bootstrap_sims', 100);
    % Plot Options
    plot_options = struct('create_plots', 0,'staID', resp_var,'yaxis_Label', [],...
        'yaxis_Limits', [], 'y_log', y_scale_log,'path_out', '');
    % Check For Full NaN Vector
    if all(isnan(response_data.data(:, 2))) || all(response_data.data(:, 2)==0)
        % Response Variable Has NaNs For All Entries
        disp(['               No valid responses for ' resp_var ', Skipping response var....']);
        % Skip Iteration
        continue;
    end

    %% PREP NAMING STRINGS
    % Define Workflow String
    wstr = strsplit(outPath,filesep);
    wstr = wstr{end};
    wstr = strsplit(wstr,'_');
    wstr = wstr{1};
    % PROS-RB Naming Overwrite When Calling PROS-FB
    if ismember(resp_var,{'SWL','Hm0','Tp'})
        % For FB Analysis SSL, Hm0, Tp HC are created using RB
        if config.workflow == 4
            wstr = 'PROS-RB'; % Forcing Fields Are Computed With Response Base
        end
        % Redifine Integration Method For JPM
        eva_options.integration_method = 2; % Let JPM Manage Replicates
    end
    % Define Figure Title
    title_str = {['StormSim: ' wstr ' | '  case_name ' | ' struc_id],...
        ['' storm_type ' | ' var_name ' [' unit_label ']']};

    %% CALL PST/JPM TO BUILD HAZARD CURVES
    switch storm_type
        case 'XC' % PST
            % Disp Progress
            disp(['               Performing Stochastic Simulation Technique (SST) for station (',num2str(ii),'/',num2str(length(vars_to_process)),'): ', resp_var]);
            % Call SST
            try
                [dummy] = StormSim_PST(response_data, eva_options, plot_options);
            catch
                disp(['               Stochastic Simulation Technique (SST) returned error, skipping: ', resp_var]);
                ctr = ctr+1;
                continue;
            end
        case 'TC' % JPM
            disp(['               Performing Joint Probability Method (JPM) for station (',num2str(ii),'/',num2str(length(vars_to_process)),'): ', resp_var]);
            % Append DSWs
            if eva_options.integration_method == 2
                response_data.data = [response_data.data, TC_Prob(:, 1)];
            else
                response_data.data = [response_data.data, TC_Prob(:)];
            end
            % Call JPM
            try
                [dummy] = StormSim_JPM(response_data, eva_options, plot_options);
            catch
                disp(['               Joint Probability Method (JPM) returned error, skipping: ', resp_var]);
                ctr = ctr+1;
                continue;
            end
    end

    %% STORE OUTPUTS
    % Overwrite Var Name When Dealing With SSL (Surge)
    if strcmp(var_name, 'SSL')
        resp_var2 = 'SSL';
    else
        resp_var2 = resp_var;
    end
    % Append Results To Output Data Structure
    Output =  rb_response_appender(Output, ctr, resp_var2, y_label, title_str,...
        dummy.HC_plt_x, dummy.HC_plt,...
        dummy.HC_tbl_x, dummy.HC_tbl, data_to_process.(resp_var),...
        y_scale_log, [50,prc], [save_name '_' resp_var2 '_' storm_type '_Hazard_Curve.png']);
    % Add "_rsp" Fields For Hazard Combinations
    if use_aep == 1
        Output(ctr).tbl_rsp_x = dummy.HC_tbl_rsp_x; % x here implies Responses, AEP/AEF -> Responses
        Output(ctr).x_table_ARI = ceil(1./aep2aef(Output(ctr).x_table_ARI));
    else
        Output(ctr).tbl_rsp_x = aef2aep(dummy.HC_tbl_rsp_x);
        Output(ctr).x_table_ARI = 1./Output(ctr).x_table_ARI;
    end
    Output(ctr).tbl_rsp_y = dummy.HC_tbl_rsp_y; % y here implies AEF/AEp, Response -> AEP/AEF

    % Increase Counter
    ctr = ctr + 1;
end

%% REMOVE EMPTY RESPONSES
% Remove Empty Entries (If Any)
if ~isempty(Output)
    rm_indx = cell2mat(cellfun(@(x) isempty(x), {Output.y_table}, 'un', false));% Get Logical Index
    Output = Output(~rm_indx);% Keep Valid Fields
else
    return;
end

%% AUX FUNCTIONS (CONSOLIDATE LINES OF CODE)
    function Output =  rb_response_appender(Output, rIndx, sVar, y_label, title_str, x_plt, y_plt, x_tbl, y_tbl, POT, y_log_scale, CL, outName)
        % Replace Fields For P2
        Output(rIndx).('var') = sVar;
        Output(rIndx).CL = CL; % Percentiles (Cols)
        % Only Grab Frequency Bound On The Table
        Output(rIndx).('x_plot') = x_plt(x_plt >= 0.001 & x_plt <= max(x_tbl),:);
        Output(rIndx).('y_plot') = y_plt(x_plt >= 0.001 & x_plt <= max(x_tbl),:);
        Output(rIndx).('x_table') = x_tbl(x_tbl >= 0.001 & x_tbl <= max(x_tbl),:);
        Output(rIndx).('y_table') = y_tbl(x_tbl >= 0.001 & x_tbl <= max(x_tbl),:);
        Output(rIndx).('x_table_ARI') = x_tbl;
        Output(rIndx).('POT') = POT;
        Output(rIndx).('y_label') = y_label;
        Output(rIndx).('title') = title_str;
        Output(rIndx).y_log_scale = y_log_scale; % Y Log Scale For Overtopping
        Output(rIndx).('save_name') = outName;
    end
end