function [OUTPUT] = call_stormsim_sst(input_data,staID,Nyrs,prc,U_a,U_r,uncert_treatment)
% JAM modified on 11/30/22 to use StormSim_SST_Tool_R1_v20220523
%% General settings
    ExecMode = 'Fast';
    DataType = 'POT';
    use_AEP = 1;
    GPD_TH_crit = 2; %must be zero to run parallel
    HC_tbl_rsp_y = [];
    apply_GPD_to_SS = 1; %empirical=0, GPD=1
    apply_Parallel = 0;
    path_out = [];
    flag_value = [];
    tLag = [];
    lambda = [];
    
    %% Plot settings
    yaxis_Label = {'~'};
    yaxis_Limits = [];
    
    %% Uncertainty Settings
    apply_Tides = 'none';
    gprMdl(1).mdl = [];
    SLC = [];
    tide_SD = [];
%     if contains(staID,{'hm0','swl'})
%        uncert_treatment = 'combined';        
%     else
%        U_a = [];
%        uncert_treatment = 'relative';
%     end
    %% CALL SST
    [OUTPUT.HC_plt_x,OUTPUT.HC_tbl_x,OUTPUT.HC_tbl_rsp_y,~,~,OUTPUT.SST_output] = StormSim_SST_Tool_R1_FGM(input_data,flag_value,tLag,lambda,Nyrs,path_out,staID,yaxis_Label,yaxis_Limits,...
        prc,use_AEP,GPD_TH_crit,SLC,apply_Tides,gprMdl,DataType,ExecMode,HC_tbl_rsp_y,apply_GPD_to_SS,apply_Parallel,tide_SD,U_a,U_r,uncert_treatment);
    rmdir ('SST_output','s')    
end