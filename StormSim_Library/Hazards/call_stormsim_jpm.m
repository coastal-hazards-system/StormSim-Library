
function [JPM_output] = call_stormsim_jpm(staID, prc, ind_aep, U_a, U_r, Resp, ProbMass, uncert_treatment, y_label_str)
%% General settings
vg_id = 1;
vg_ColNum = [];
if contains(staID,{'SWL','Hm0','Tp'})
    integrate_Method = 'PCHA Standard'; %this will partition uncertainty between mean and CL curves
else
    integrate_Method = 'PCHA ATCS'; %no partition of uncertainty
end
apply_Parallel=0;
path_out = [];
HC_tbl_rsp_y=[];
switch staID
    case {'q','q_wave_ot'}
        y_log = 'log';
    otherwise
        y_log = 'linear';
end
%% Uncertainty settings
U_tide_app = 0;
U_tide = [];
U_tide_type = [];
SLC = [];

%% Plot settings
plot_results = 0;
yaxis_label = y_label_str;
yaxis_limits = [];
stat_print = 0;

%% CALL JPM TOOL
JPM_output.staID = staID;
% Old Version Of JPM 
% [JPM_output.HC_data,JPM_output.HC_plt_x,JPM_output.HC_tbl_x,JPM_output.HC_tbl_rsp_y,~ ] = ...
%     StormSim_JPM_PROS_Tool_R1_v20210831_20230126PROS(Resp(:),ProbMass(:),vg_id,vg_ColNum,U_a,...
%     U_r,U_tide,U_tide_app,U_tide_type,uncert_treatment,prc,integrate_Method,...
%     path_out,yaxis_label,yaxis_limits,SLC,plot_results,ind_aep,apply_Parallel,HC_tbl_rsp_y);

% Latest Version Of JPM 
[JPM_output.HC_data,JPM_output.HC_plt_x,JPM_output.HC_tbl_x,JPM_output.HC_tbl_rsp_y,~ ] = StormSim_JPM_Tool_R1_v20210831(Resp(:),ProbMass(:),vg_id,vg_ColNum,U_a,...
    U_r,U_tide,U_tide_app,U_tide_type,uncert_treatment,prc,integrate_Method,...
    path_out,yaxis_label,yaxis_limits,SLC,plot_results,ind_aep,apply_Parallel,HC_tbl_rsp_y, stat_print, y_log, staID);
close all;


rmdir('JPM_output','s');
end
