function  [project_forcing] = apply_rb_uncertainty(config, project_forcing, sType, RandNorm)

%% GET INFORMATION FROM "config"
% Water Level Uncertainty 
swl_u_a = config.chs_swl_u_a; % Absolute
swl_u_r = config.chs_swl_u_r; % Proportional
% Wave Height Uncertainty
hm0_u_a = config.chs_hm0_u_a; % Absolute
hm0_u_r = config.chs_hm0_u_r; % Proportional

%% GET INFORMATION FROM "project_forcing"
% Water Level
SWL = project_forcing.(sType).('Peaks').SWL;
% Wave Height
Hm0 = project_forcing.(sType).('Peaks').Hm0;
% Wave Peak Period
Tp = project_forcing.(sType).('Peaks').Tp;
% Probability Masses
if strcmp(sType,'TC')
    TC_Freq = project_forcing.(sType).('Peaks').TC_Freq;
end

%% APPLY FORCING UNCERTAINTY
% Determine Size
[Nstrm,Ndscrt] = size(SWL);
% Re-arrange Discrete Normal Dist. prior to adding uncertainty to SWL
% Is the Idea to Build nstorm * ndist with each col being a different Randnorm?
normU = repmat(RandNorm,Nstrm,1);
% Apply uncertainty using a random normal distribution
% ------------------ SWL ------------------
if swl_u_r ~= 1 %apply uncertainty to normal replicates
    a = swl_u_a+SWL; r = swl_u_r.*SWL;
    SWL_Uncert = 1./sqrt(1./(a).^2 + 1./(r).^2);
    SWL_Uncert = SWL_Uncert .* (a./abs(a));
    SWL_w_Uncert = SWL + SWL_Uncert.*normU;
else %apply no uncertainty to normal replicates
    SWL_w_Uncert = SWL;
end
% Assign Back To "project_forcing"
 project_forcing.(sType).('Peaks').SWL = SWL_w_Uncert;

% ------------------ Hm0 & Tp ------------------
Hm0 (Hm0 == 0) = NaN;       % Remove zero Hm0 values
% Estimate Tp_U as a function of Hm0_U, assume constant wave steepness
if hm0_u_r ~= 1 %apply uncertainty to normal replicates
    a = hm0_u_a+Hm0; r = hm0_u_r.*Hm0;
    Hm0_Uncert = 1./sqrt(1./(a).^2 + 1./(r).^2);
    Hm0_Uncert = Hm0_Uncert .* (a./abs(a));
    Hm0_w_Uncert = Hm0 + Hm0_Uncert.*normU;
    Tp_U = sqrt(1+hm0_u_r)-1; %0.0724
    Tp_w_Uncert = Tp.*(1+Tp_U.*normU);    % Apply uncertainty to Tp
else %apply no uncertainty to normal replicates
    Hm0_w_Uncert = Hm0;
    Tp_w_Uncert = Tp;
end
% cannot have negative Hm0, so set these to very small number.
% per discussions with Burns and Melby this is ok.
Hm0_w_Uncert(Hm0_w_Uncert<=0)=0.01;
% Assign Back To "project_forcing"
 project_forcing.(sType).('Peaks').Hm0 = Hm0_w_Uncert; % Hm0 
  project_forcing.(sType).('Peaks').Tp = Tp_w_Uncert; % Tp

% ------------------ Probability Masses ------------------
if strcmp(sType,'TC')
    % Creat TC Prob Field
    project_forcing.(sType).('Peaks').TC_Prob = repmat(TC_Freq/Ndscrt,1,Ndscrt);
end

%% STRUCTURAL PARAMETERS UNCERTAINTY 
% None , why?
end