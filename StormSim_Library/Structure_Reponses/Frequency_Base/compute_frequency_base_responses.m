function HC_out = compute_frequency_base_responses(config, structure, emp_coeff, HC_out, f_str, use_aep)
%% DEFINE AUX VARIABLES
% Force Structure Response Calculations
config.workflow = 1;
struc_type = config.struc_type;
toe_elev = structure.toe_elevation;
berm_elev = structure.berm_elevation;
crest_elev = structure.crest_elevation;
rho_w = config.water_density;
% Compute Wall Height
hw = toe_elev + crest_elev;
% Get Storm Types
level_1 = fieldnames(HC_out);
% Loop Through All Storm Types
for ii = 1:length(level_1)
    %% CREATE PROXY "project_forcing" FROM "HC_out"
    for jj = 1:length(HC_out.(level_1{ii}).(f_str))
        % Table Data
        prox_var_table.(level_1{ii}).(HC_out.(level_1{ii}).(f_str)(jj).var) = HC_out.(level_1{ii}).(f_str)(jj).('y_table');
        % Plot Data
        prox_var_plot.(level_1{ii}).(HC_out.(level_1{ii}).(f_str)(jj).var) = HC_out.(level_1{ii}).(f_str)(jj).('y_plot');
    end

    %% COMPUTE PRIMARY RESPONSES FOR ALL STORM TYPES (R2p, q, Dn50, P1)
    % Compute Primary Response Responses
    [resp_plot, ~] = compute_structure_response(config, structure, prox_var_plot,  emp_coeff, level_1{ii});
    [resp_table, ~] = compute_structure_response(config, structure, prox_var_table,  emp_coeff, level_1{ii});

    %% ADJUST OUTPUT STRUCTURE FIELDS FOR NEW RESPONSES
    % Get Responses
    resp_names = fieldnames(resp_plot);
    % Reference Entry
    row_ref = HC_out.(level_1{ii}).(f_str)(1);
    % Initialize Row Index
    r_indx = length(HC_out.(level_1{ii}).(f_str)) + 1;
    % Loop Through Each Response
    for kk = 1:length(resp_names)
        % Define Station ID
        staID = resp_names{kk};
        % Assign Uncertainty Based On Station
            [~, ~, ~,...
    ~, ~,...
    ~, y_label, y_scale_log] = response_library_headers(config, staID);
        % Adjust Title String
        row_ref.title{2} = [level_1{ii} ' | ' y_label];
        % Split Save Name
        [s_path, s_name, s_ext] = fileparts(row_ref.save_name);
        % Split File Name
        new_s_name = strsplit(s_name,'_');
        % Replace Response Variable
        new_s_name(end-2) = {staID};
        % Remove SST/JPM
        new_s_name(end-3) = {[level_1{ii} '_PROS-FB']};
        % Append New Save Name ANd Store
        new_s_name = [s_path filesep strjoin(new_s_name,'_') s_ext];
        %% APPEND RESPONSE TO "HC_out"
        HC_out.(level_1{ii}).(f_str) = rb_response_appender(HC_out.(level_1{ii}).(f_str), r_indx, staID, y_label, row_ref.title,...
            row_ref.x_plot, resp_plot.(resp_names{kk}), row_ref.x_table, resp_table.(resp_names{kk}), {'Derived from primary responses hazard curves'}, y_scale_log, row_ref.CL, new_s_name);
        % Append ARIs
        if use_aep == 1
            HC_out.(level_1{ii}).(f_str)(r_indx).x_table_ARI = ceil(1./aep2aef(HC_out.(level_1{ii}).(f_str)(1).x_table));
        else
            HC_out.(level_1{ii}).(f_str)(r_indx).x_table_ARI = ceil(1./HC_out.(level_1{ii}).(f_str)(1).x_table);
        end
        % Increase Index
        r_indx = r_indx + 1;
    end
    % Make Forcing HC Be After Structure Responses For Consistency
    HC_out.(level_1{ii}).(f_str) = [HC_out.(level_1{ii}).(f_str)(4:end),HC_out.(level_1{ii}).(f_str)(1:3)];

    %% COMPUTE SECONDARY RESPONSES
    if struc_type == 2 % Floodwall
        % Create Aux Variable
        Output = HC_out.(level_1{ii}).(f_str);
        % If All Primary responses Are Valid
        if sum(ismember({Output.var}',{'p1','Hm0','Tp','SWL','q'}))==5
            % Find Data Indexes
            sIndx = cell2mat(cellfun(@(x) find(strcmp(x, {Output.var}')), {'p1','Hm0','Tp','SWL','q'}, 'un', false));
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
                title_str(2) =  {['' level_1{ii} ' | ' y_labels{kk}]};
                % Call Data Appender
                Output =  rb_response_appender(Output, rIndx+kk, sVar, y_labels{kk}, title_str,...
                    Output(rIndx).x_plot, eval([sVar '_plt;']), Output(rIndx).x_table, eval([sVar '_tbl;']), {'Derived from primary responses hazard curves'},...
                    y_scale_log, row_ref.CL, [outName{1} sVar outName{2}]);
                % Append ARIs
                if use_aep == 1
                    Output(rIndx+kk).x_table_ARI = ceil(1./aep2aef(Output(1).x_table));
                else
                    Output(rIndx+kk).x_table_ARI = ceil(1./Output(1).x_table);
                end
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
                    y_scale_log, row_ref.CL, [outName{1} pFields{kk} outName{2}]);
                % Append ARIs
                if use_aep == 1
                    Output(rIndx+kk).x_table_ARI = ceil(1./aep2aef(Output(1).x_table));
                else
                    Output(rIndx+kk).x_table_ARI = ceil(1./Output(1).x_table);
                end
            end
        end
        % Append To HC_Out
        HC_out.(level_1{ii}).(f_str) = [HC_out.(level_1{ii}).(f_str),Output];
    end
    %     % Plot Frequency Based HCs
    %     plot_hazard_curves(HC_out.(level_1{ii}).(f_str), use_aep);
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
        Output(rIndx).('x_plot') = x_plt;
        Output(rIndx).('y_plot') = y_plt;
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