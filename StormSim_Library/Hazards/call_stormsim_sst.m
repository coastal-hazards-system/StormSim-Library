function [OUTPUT] = call_stormsim_sst(input_data,staID,Nyrs,prc,use_AEP,U_a,U_r,uncert_treatment, y_label_str)
% JAM modified on 11/30/22 to use StormSim_SST_Tool_R1_v20220523
%% General settings
    ExecMode = 'Fast';
    DataType = 'POT';
    GPD_TH_crit = 2; %must be zero to run parallel
    HC_tbl_rsp_y = [];
    apply_GPD_to_SS = 1; %empirical=0, GPD=1
    apply_Parallel = 0;
    path_out = [];
    flag_value = [];
    tLag = [];
    lambda = [];
    app_type = 1; % Application Type -> 1-> StormSim (Nsim = 100), 2-> PCHA (Nsim = 1e3)
    %% Plot settings
    yaxis_Label = {y_label_str};
    yaxis_Limits = [];
    stat_print = 0;
    switch staID
        case {'q','q_wave_ot'}
            y_log = 'log';
        otherwise
            y_log = 'linear';
    end
    %% Uncertainty Settings
    apply_Tides = 'none';
    gprMdl(1).mdl = [];
    SLC = [];
    tide_SD = [];
    ind_Skew = 0; 
%     if contains(staID,{'hm0','swl'})
%        uncert_treatment = 'combined';        
%     else
%        U_a = [];
%        uncert_treatment = 'relative';
%     end
    %% CALL SST
    % Old Version Of SST
%     [OUTPUT.HC_plt_x,OUTPUT.HC_tbl_x,OUTPUT.HC_tbl_rsp_y,~,~,OUTPUT.SST_output] = StormSim_SST_Tool_R1_FGM(input_data,flag_value,tLag,lambda,Nyrs,path_out,staID,yaxis_Label,yaxis_Limits,...
%         prc,use_AEP,GPD_TH_crit,SLC,apply_Tides,gprMdl,DataType,ExecMode,HC_tbl_rsp_y,apply_GPD_to_SS,apply_Parallel,tide_SD,U_a,U_r,uncert_treatment);
% Latest Version Of SST 
    [OUTPUT.HC_plt_x,OUTPUT.HC_tbl_x,OUTPUT.HC_tbl_rsp_y,~,~,OUTPUT.SST_output] = StormSim_SST_Tool_R1_v20210809(input_data,flag_value,tLag,lambda,Nyrs,path_out,{staID},yaxis_Label,yaxis_Limits,...
        prc,use_AEP,GPD_TH_crit,SLC,ind_Skew,gprMdl,DataType,ExecMode,HC_tbl_rsp_y,apply_GPD_to_SS,apply_Parallel, stat_print, app_type,y_log);
% close all;
%     rmdir ('SST_output','s');    
end