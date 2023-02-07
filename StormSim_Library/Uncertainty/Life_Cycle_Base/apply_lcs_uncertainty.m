function [project_forcing] = apply_lcs_uncertainty(config, project_forcing, data_type)
%% GRAB INFORMATION FROM "config"
nLC = config.mcs_nLC;
swl_u_a = config.chs_swl_u_a;
hm0_u_a = config.chs_hm0_u_a;
swl_u_r = config.chs_swl_u_r;
hm0_u_r = config.chs_hm0_u_r;

%% DEFINE SWL COL INDEX 
% Define Starting Col Index For Grabbing Storm Data
switch data_type
    case 'Peaks'
        swl_indx = 4;
    case 'Timeseries'
        swl_indx = 5;
end

%% APPLY UNCERTAINTY TO FORCING PARAMETERS
% Apply Uncertainty
for jj = 1:nLC
    % Water Level
    if swl_u_r ~= 1
        SWL = project_forcing(jj).LCNUM(:,swl_indx); % Get SWL From LC
        project_forcing(jj).LCNUM(:,swl_indx) = pcha_forcing_uncertainty(SWL, swl_u_a, swl_u_r, randn(size(SWL)));
    end
    % Wave Height & Tp
    if hm0_u_r ~= 1
        % Hm0
        Hm0 = project_forcing(jj).LCNUM(:,swl_indx+1); % Get Hm0 From LC
        Hm0 (Hm0 == 0) = NaN; % Remove zero Hm0 values
        Hm0_w_Uncert = pcha_forcing_uncertainty(Hm0, hm0_u_a, hm0_u_r, randn(size(Hm0)));
        % cannot have negative Hm0, so set these to very small number.
        % per discussions with Burns and Melby this is ok.
        Hm0_w_Uncert(Hm0_w_Uncert<=0)=0.01;
        project_forcing(jj).LCNUM(:,swl_indx+1) = Hm0_w_Uncert; % Assign back to data
        % Tp
        Tp = project_forcing(jj).LCNUM(:,swl_indx+2); % Get Tp From LC
        Tp_U = sqrt(1+hm0_u_r)-1; % Compute Uncertianty As a f(Hm0)
        project_forcing(jj).LCNUM(:,swl_indx+2) = Tp.*(1+Tp_U.*randn(size(Hm0))); % Apply uncertainty to Tp
    end
end
end
