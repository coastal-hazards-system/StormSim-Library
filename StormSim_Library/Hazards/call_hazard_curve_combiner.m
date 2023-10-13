function cc_resp = call_hazard_curve_combiner(config, structure, tc_resp, xc_resp, use_aep)
%% GRAB DETAILS FORM "config"
struc_type = config.struc_type;
workflow = config.workflow;
% Build Uncertainty Vector 
u_names = fieldnames(config);
u_vector = struct2cell(config);
% Grab Uncertainty Fields 
u_vector = u_vector(contains(u_names, {'u_a','_u'}));
u_names = u_names(contains(u_names, {'u_a','_u'}));
% Remove U_r Fields 
u_vector = u_vector(~contains(u_names,{'u_r'}));
u_names = u_names(~contains(u_names,{'u_r'}));


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

%% COMBINE HAZARD CURVES FOR PRIMARY RESPONSES
% Define AEP's or AEF's
if use_aep == 1
    rp_out = tc_resp(1).x_table;
    x_plot_tc = tc_resp(1).x_plot;
    x_tbl_tc = tc_resp(1).x_table;
else
    rp_out = aef2aep(tc_resp(1).x_table);
    x_plot_tc = aef2aep(tc_resp(1).x_plot);
    x_tbl_tc = aef2aep(tc_resp(1).x_table);
end
% Find Primary Responses Indexes
s_indx = 1:min(length(tc_resp),length(xc_resp));
% Remove Resposes With Missing Pairs
if length(s_indx)~=max(length(tc_resp),length(xc_resp))
    if length(tc_resp)>length(xc_resp)
        tc_resp = tc_resp(ismember({tc_resp.var},{xc_resp.var}));
    else
        xc_resp = xc_resp(ismember({xc_resp.var},{tc_resp.var}));
    end
end
% s_indx = 1:length(tc_resp);%find(cellfun(@length,{tc_resp.tbl_rsp_x})~=0);
% Find Secondary Responses Indexes
s_indx2 = find(cellfun(@length,{tc_resp.tbl_rsp_x})==0);
% Initialize Storage Var & Fields For CC HC
cc_resp = tc_resp(s_indx);
% Remove Plot & Table Fields
cc_resp = rmfield(cc_resp,{'tbl_rsp_x','tbl_rsp_y'});
% Define Counter
ctr = 1;
% Loop Through Each Parameter
for j = s_indx
    % Determine Corresponding Uncertainty Field 
    switch tc_resp(j).var
        case 'R2p_SWL'
            u_field = 0;
        case 'Tp'
            u_field = 0;
        case {'q_overflow', 'Q_vol_overflow'}
            u_field = 0;
        case {'Q_vol_wave_ot','Q_vol','q_wave_ot'}
            u_field = u_vector{contains(u_names, 'q')};
        otherwise
            u_field = u_vector{contains(u_names, lower(tc_resp(j).var))};
    end
    %
    disp(['               Combining ' tc_resp(j).var ' hazard curves....']);
    % Combine HCs To Create Table
    cc_resp(ctr).y_table = combine_hazard_curves(tc_resp(j).tbl_rsp_x, xc_resp(j).tbl_rsp_x,...
xc_resp(j).tbl_rsp_y, x_tbl_tc, tc_resp(j).y_log_scale, tc_resp(j).CL, u_field);
    % Combine HCs To Create Plot
    cc_resp(ctr).y_plot = combine_hazard_curves(tc_resp(j).tbl_rsp_x, xc_resp(j).tbl_rsp_x,...
        xc_resp(j).tbl_rsp_y, x_plot_tc, tc_resp(j).y_log_scale, tc_resp(j).CL, u_field);
    % ADjust Figure Title
%     cc_resp(ctr).title(1) = {strrep(cc_resp(ctr).title{1},'JPM','Combined')};
    cc_resp(ctr).title(2) = {strrep(cc_resp(ctr).title{2},'TC','CC')};
    % Adjust Figure Output Names
    cc_resp(ctr).save_name = strrep(cc_resp(ctr).save_name,'JPM','CC');
    % Define POT
    cc_resp(ctr).POT = {'Hazard curve computed by combining TC & XC primary responses'};
    % Increase Counter
    ctr = ctr + 1;
end

%% COMPUTE SECONDARY STRUCTURE RESPONSES (P2, P3, Pu, Nappe)
if struc_type == 2 && ~ismember(workflow,[2,4])
    % Find Data Indexes
    sIndx = cell2mat(cellfun(@(x) find(contains({cc_resp.var}',x)==1),{'p1','Hm0','Tp','SWL','q'},'un',false));
    % MAke Sure Primary Responses Exist
    if length(sIndx) == 5
        % Secondary responses are HCs that are generated as a function of other HC.
        for j = s_indx2
            % Grab Example Save Name
            outName = strsplit(cc_resp(sIndx(5)).save_name,'q');
            % Compute Water Depth @ Structure Toe
            h_plt = toe_elev + cc_resp(sIndx(4)).y_plot;
            h_tbl = toe_elev + cc_resp(sIndx(4)).y_table;
            % Compute Water Depth @ Berm
            if berm_elev == 0 % No Berm
                hb_plt = h_plt;
                hb_tbl = h_tbl;
            else
                hb_plt = berm_elev + cc_resp(sIndx(4)).y_plot;
                hb_tbl = berm_elev + cc_resp(sIndx(4)).y_table;
            end
            % Compute Freeboard
            Rc_plt = crest_elev - cc_resp(sIndx(4)).y_plot;
            Rc_tbl = crest_elev - cc_resp(sIndx(4)).y_table;
            % Compute P2 & P3 Wall Pressures (Plots)
            [p2dyn_plt, p2sta_plt, p2total_plt,...
                p3dyn_plt, p3sta_plt, p3total_plt, pu_plt]=goda_forces_on_vertical_p2p3(cc_resp(sIndx(2)).y_plot, cc_resp(sIndx(3)).y_plot,...
                1.8,0,h_plt,hb_plt,Rc_plt,hw,cc_resp(sIndx(1)).y_plot,rho_w,[1 1]);
            % Compute P2 & P3 Wall Pressures (Table)
            [p2dyn_tbl, p2sta_tbl, p2total_tbl,...
                p3dyn_tbl, p3sta_tbl, p3total_tbl, pu_tbl]=goda_forces_on_vertical_p2p3(cc_resp(sIndx(2)).y_table, cc_resp(sIndx(3)).y_table,...
                1.8,0,h_tbl,hb_tbl,Rc_tbl,hw,cc_resp(sIndx(1)).y_table,rho_w,[1 1]);
            % Define Pressure Fields To Append
            pFields = who('p2*_tbl','p3*_tbl','pu*_tbl');
            % Loop Through Fieldnames
            for kk = 1:length(pFields)
                % Grab Field Name
                sVar = strrep(pFields{kk},'_tbl','');
                % Find Storage Index
                v_indx = strcmp(sVar, {cc_resp.var});
                % Store Values
                cc_resp(v_indx).y_plot = eval([sVar '_plt']);
                cc_resp(v_indx).y_table = eval([sVar '_tbl']);
                % Define POT
                cc_resp(v_indx).POT = {'Derived from primary responses hazard curves'};
            end
            % Compute Nappe Response (Table)
            [Nappe_tbl] = floodwall_nappe_response(cc_resp(sIndx(4)).y_table, cc_resp(sIndx(2)).y_table, cc_resp(sIndx(5)).y_table, hw, rho_w);
            % Compute Nappe Response (Plot)
            [Nappe_plt] = floodwall_nappe_response(cc_resp(sIndx(4)).y_plot, cc_resp(sIndx(2)).y_plot, cc_resp(sIndx(5)).y_plot, hw, rho_w);
            % Get Filenames
            pFields = fieldnames(Nappe_tbl);
            % Loop Through Fieldnames
            for kk = 1:length(pFields)
                % Find Storage Index
                v_indx = strcmp(pFields{kk,1}, {cc_resp.var});
                % Store Values
                cc_resp(v_indx).y_plot = Nappe_plt.(pFields{kk});
                cc_resp(v_indx).y_table = Nappe_tbl.(pFields{kk});
                % Define POT
                cc_resp(v_indx).POT = {'Derived from primary responses hazard curves'};
            end
        end
    end
end
end
