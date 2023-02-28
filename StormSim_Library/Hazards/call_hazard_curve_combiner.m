function cc_resp = call_hazard_curve_combiner(tc_resp, xc_resp, use_aep)
% Define AEP's or AEF's
if use_aep == 1
    rp_out = tc_resp(1).x_table;
    x_plot_tc = tc_resp(1).x_plot;
else
    rp_out = aef2aep(tc_resp(1).x_table);
    x_plot_tc = aef2aep(tc_resp(1).x_plot);
end
% Find SWL & Hm0 Row Index
s_indx = find(sum([strcmp({xc_resp.var},{'SWL'});strcmp({xc_resp.var},{'Hm0'})],1));
% Initialize Storage Var & Fields For CC HC
cc_resp = tc_resp(s_indx);
% Remove Plot & Table Fields
cc_resp = rmfield(cc_resp,{'tbl_rsp_x','tbl_rsp_y'});
% Define Counter
ctr = 1;
% Loop Through Each Parameter
for j = s_indx % SWL and/or Hm0
    disp(['               Combining ' tc_resp(j).var ' hazard curves....']);
    % Combine HCs To Create Table
    cc_resp(ctr).y_table = combine_hazard_curves(tc_resp(j).tbl_rsp_x, xc_resp(j).tbl_rsp_x,...
        xc_resp(j).tbl_rsp_y, tc_resp(j).tbl_rsp_y, x_plot_tc);
    % Combine HCs To Create Plot
    cc_resp(ctr).y_plot = combine_hazard_curves(tc_resp(j).tbl_rsp_x, xc_resp(j).tbl_rsp_x,...
        xc_resp(j).tbl_rsp_y, tc_resp(j).tbl_rsp_y, x_plot_tc);
    % ADjust Figure Title
    cc_resp(ctr).title(1) = {strrep(cc_resp(ctr).title{1},'JPM','Combined')};
    cc_resp(ctr).title(2) = {strrep(cc_resp(ctr).title{2},'TC','CC')};
    % Adjust Figure Output Names
    strrep(cc_resp(ctr).save_name,'JPM','CC');
    cc_resp(ctr).save_name = strrep(cc_resp(ctr).save_name,'JPM','CC');
    % Increase Counter
    ctr = ctr + 1;
end
end
