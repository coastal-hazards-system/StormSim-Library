function [U_a, U_r, uncert_treatment_jpm,...
    uncert_treatment_sst, unit_label,...
    var_name, y_label, y_scale_log] = response_library_headers(config, staID)

%% Grab Response Uncertainty
r2p_u = config.r2p_u; % Runup
q_u = config.q_u; % Overtopping
dn50_u = config.dn50_u; % Median Stone Size
p1_u = config.p1_u; % Goda Pressure (P1)
swl_u_a = config.chs_swl_u_a; % SWL Absolute
swl_u_r = config.chs_swl_u_r; % SWL Proportional
hm0_u_a = config.chs_hm0_u_a; % Hm0 Absolute
hm0_u_r = config.chs_hm0_u_r; % Hm0 Proportional

%% Determine Response Fields
% Set Y Scale
y_scale_log = 0;
% Grab Information Accroding To Case
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
        U_r = swl_u_a;
        uncert_treatment_jpm = 'relative';
        uncert_treatment_sst = 'relative';
        unit_label = 'm^3/s per m';
        y_label = ['q_{overflow} [ ' unit_label ']'];
        var_name = 'q_{overflow}';
        y_scale_log = 0;
    case 'Q_vol'
        U_a=0;
        U_r = q_u;
        y_scale_log = 1;
        uncert_treatment_jpm = 'relative';
        uncert_treatment_sst = 'relative';
        unit_label = 'm^3 per m';
        y_label = ['Q [ ' unit_label ']'];
        var_name = 'Q_{vol}';
    case 'Q_vol_overflow'
        U_a=0;
        U_r = swl_u_a;
        uncert_treatment_jpm = 'relative';
        uncert_treatment_sst = 'relative';
        unit_label = 'm^3 per m';
        y_label = ['Q_{overflow} [ ' unit_label ']'];
        var_name = 'Q_{vol_{overflow}}';
    case 'Q_vol_wave_ot'
        U_a=0;
        U_r = q_u;
        y_scale_log = 1;
        uncert_treatment_jpm = 'relative';
        uncert_treatment_sst = 'relative';
        unit_label = 'm^3 per m';
        y_label = ['Q_{overtop} [ ' unit_label ']'];
        var_name = 'Q_{vol_{overtop}}';
    case 'DamDepthElev'
        U_a=0;
        U_r = swl_u_a;
        y_scale_log = 0;
        uncert_treatment_jpm = 'relative';
        uncert_treatment_sst = 'relative';
        unit_label = 'm';
        y_label = ['Damaging Depth Elevation [ ' unit_label ']'];
        var_name = 'damaging_depth_elev';
    case 'DamDepth'
        U_a=0;
        U_r = swl_u_a;
        y_scale_log = 0;
        uncert_treatment_jpm = 'relative';
        uncert_treatment_sst = 'relative';
        unit_label = 'm';
        y_label = ['Damaging Depth [ ' unit_label ']'];
        var_name = 'damaging_depth';
end
end
