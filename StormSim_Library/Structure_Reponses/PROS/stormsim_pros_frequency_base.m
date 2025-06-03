function data_out = stormsim_pros_frequency_base(config, structure, data_in, outPath)
%% GET DETAILS FROM CONFIG
% project name
proj_name = config.project_name;
% Transect Id
struc_id = strrep(config.struc_id,'_',' ');
% Define Case  Name
case_name = strrep(config.case_name,'_',' ');
% Gravity Constant
g = config.gravity_constant;
% Get Secondary Responses To Compute
calc_p2_p3 = config.compute_p2_p3;
calc_nappe = config.compute_nappe;

%% INITIALIZE FIELDS
% Get Storm Types On Data
storm_types = fieldnames(data_in);
% Fields To Get From hazard Tables
field_to_get = {'y_table', 'y_plot'};
% Save Name
save_name = fullfile(outPath, [proj_name,'_', struc_id]);


%% GET DETAILS FROM STRUCTURE
% Define Structure Crest Elevation
crest_elev = structure.crest_elevation;
% Berm Elevation (<0 Below Datum Zero)
berm_elev = structure.berm_elevation; %
% Rubblemound Fields
switch config.struc_type
    case  2
        wall_bottom_elev = structure.wall_bottom_elevation;
        hw = wall_bottom_elev + crest_elev;
end
% Define Structure Toe Elevation (<0 below datum zero)
toe_elev = structure.toe_elevation; % Flip convention
% Water Density kg/m^3
rho_w = structure.water_density;
% Load Empirical Coefficients
[emp_coeff] = load_empirical_coefficients();

%% GRAB DATA AND INITIALIZE FIELDS
for st = 1:length(storm_types)
    % Initialize Storage Variable
    Output = [];
    hc_data = data_in.(storm_types{st});
    % Get Plot & Table Frequency Vector
    x_plt =  hc_data(1).x_plot;
    x_tbl = hc_data(1).x_table;
    % Get COnfidence Limits
    cl = hc_data(1).CL;
    % Check For Additional Data
    chk1 = calc_nappe == 1 & any(strcmp({hc_data.var}, 'q'));
    chk2 = calc_p2_p3 == 1 & any(strcmp({hc_data.var}, 'p1'));
    % Loop For Each Dataset (table, plot)
    for dd = 1:2
        % Grab Hazard Curve Data (y_tbl, y_plt)
        [SWL, swl_pass] = get_hc_data(hc_data, 'SWL', field_to_get{dd});
        [Hm0, hm0_pass] = get_hc_data(hc_data, 'Hm0', field_to_get{dd});
        [Tp, tp_pass] = get_hc_data(hc_data, 'Tp', field_to_get{dd});
        Tm10 = cellfun(@(x) x./1.1, Tp, 'un', false);
        % Check For Minimum Requirement (SWL, Hm0, Tp HC Must Exist)
        if sum([swl_pass, hm0_pass, tp_pass])~=3
            Resp = [];
            continue;
        end
        % Compute Additional Fields
        h = cellfun(@(x) x - toe_elev, SWL, 'un', false);
        Rc = cellfun(@(x) crest_elev - x, SWL, 'un', false);
        hb = cellfun(@(x) x - berm_elev, SWL,'un',false);

        %%  ALREADY HAVE ALL HAZARDS FOR SECONDARY RESPONSE (PROS-RB + PROS-FB)
        % In this section responses such as q & p1 are computed using RB approach
        % and only p2, p3, & nappe reesponses are computed using FB.
        % Compute Secondary Responses
        if sum([calc_p2_p3, calc_nappe]) == sum([chk1, chk2])
            % 3. Compute P2, P3, Pu
            if calc_p2_p3 == 1
                % Grab Additional Dependency
                p1 = num2cell(hc_data(strcmp('p1', {hc_data.var})).(field_to_get{dd}), 1);
                % Compute P2 & P3 Wall Pressures (Plots)
                [Resp.(field_to_get{dd}).p2dyn,...Resp.y_table
                    Resp.(field_to_get{dd}).p2sta, Resp.(field_to_get{dd}).p2total,...
                    Resp.(field_to_get{dd}).p3dyn, Resp.(field_to_get{dd}).p3sta,...
                    Resp.(field_to_get{dd}).p3total, Resp.(field_to_get{dd}).pu] = ...
                    cellfun(@(a, b, c, d, e, f) goda_forces_on_vertical_p2p3(a, b, 1.8,...
                    0, c, d, e, hw, f, rho_w, g), Hm0, Tm10, h, hb, Rc, p1, 'un', false);
            end
            % Compute Nappe Responses
            if calc_nappe == 1
                % Grab Additional Dependency
                q = num2cell(hc_data(strcmp('q', {hc_data.var})).(field_to_get{dd}), 1);
                %
                [Resp.(field_to_get{dd}).X_low,...
                    Resp.(field_to_get{dd}).theta_low, Resp.(field_to_get{dd}).X_up,...
                    Resp.(field_to_get{dd}).theta_up, Resp.(field_to_get{dd}).Bx,...
                    Resp.(field_to_get{dd}).X_c_surge,...
                    Resp.(field_to_get{dd}).theta_center,...
                    Resp.(field_to_get{dd}).Bjet, Resp.(field_to_get{dd}).Vjet,...
                    Resp.(field_to_get{dd}).Fjet] = cellfun(@(a, b, c) floodwall_nappe_response(a, b,...
                    c, hw, rho_w), SWL, Hm0, q, 'un', false);
            end
        else
            %% NEED TO COMPUTE ALL NON FORCING RESPONSES WITH PROS-FB
            % in this section only SWL, Hm0, Tp hazard curves are created using
            % PROS-RB things such as: q, Q, R2p, Dn50, P1, P2, P3, ... are FB.
            % Grab Hazard Curve Data & Create Proxy Dataset
            project_forcing.SWL = SWL;
            project_forcing.Hm0 = Hm0;
            project_forcing.Tp = Tp;
            % Compute All Requested Structure Responses as a f(SWL, Hm0, Tp)
            [Resp.(field_to_get{dd}), ~] = compute_structure_response(config, structure, project_forcing, emp_coeff, 0);
        end
    end

    %% CREATE AND APPEND HAZARD TABLE
    if ~isempty(Resp)
        % Get List Of Responses
        resp_var = fieldnames(Resp.y_table);
        % Loop Through Each Response
        for vv = 1:length(resp_var)
            % Search Response Library For Uncertainty Values & Associated Labels
            [~, ~, ~,...
                unit_label,...
                var_name, y_label, y_scale_log] = response_library_headers(config, resp_var{vv});
            % Create Title String For Plots
            title_str = {['StormSim: PROS-FB | '  case_name ' | ' struc_id],...
                ['' storm_types{st} ' | ' var_name ' [' unit_label ']']};
            % Create Hazard Table Outputs
            Output =  response_appender(Output, vv, resp_var{vv}, y_label,...
                title_str, x_plt, [Resp.y_plot.(resp_var{vv}){:}],...
                x_tbl, [Resp.y_table.(resp_var{vv}){:}],...
                {'Computed using frequency base approach.'}, y_scale_log, cl,...
                [save_name '_' resp_var{vv} '_' storm_types{st} '_Hazard_Curve.png']);
        end
        % Remove Additional Fields
        if isfield(data_in.(storm_types{st}),'tbl_rsp_x')
            data_in.(storm_types{st}) = rmfield(data_in.(storm_types{st}), {'tbl_rsp_x', 'tbl_rsp_y'});
        end
        % Ensure We Keep Response Base Over FB
        rm_indx = contains({Output.var}, {data_in.(storm_types{st}).var});
        % Append To Hazard Tables
        data_out.(storm_types{st}) = [data_in.(storm_types{st}), Output(~rm_indx)];
    else % Nothing To Append
        data_out.(storm_types{st}) = data_in.(storm_types{st});
    end
end

%% AUX FUNCTIONS
% Create Hazard Tables
    function Output =  response_appender(Output, rIndx, sVar, y_label, title_str, x_plt, y_plt, x_tbl, y_tbl, POT, y_log_scale, CL, outName)
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

% Get HC Data And Flag If Passed
    function [var_out, pass_indx] = get_hc_data(data, varname, field_get)
        % Check If Var Exist
        var_indx = strcmp(varname, {data.var});
        %
        if ~any(var_indx)
            var_out = {NaN};
            pass_indx = 0;
        else
            pass_indx = 1;
            var_out = num2cell(data(strcmp(varname, {data.var})).(field_get), 1);
        end
    end
end