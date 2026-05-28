function [project_forcing] = apply_uncertainty(config, project_forcing, RandNorm)
%% GRAB INFORMATION FROM "config"
nLC = config.mcs_nLC;
swl_u_a = config.chs_swl_u_a;
hm0_u_a = config.chs_hm0_u_a;
swl_u_r = config.chs_swl_u_r;
hm0_u_r = config.chs_hm0_u_r;
% Grab Data Cells According To Workflow
switch config.workflow
    case  {1, 2, 4}
        % Water Level
        SWL = project_forcing.('SWL');
        % Wave Height
        Hm0 = project_forcing.('Hm0');
        % Wave Peak Period
        Tp = project_forcing.('Tp');
        % Copy Normal Distirbution Accross All Events 
        RandNorm = repmat({RandNorm}, size(SWL));
    case {3} % LCS
        SWL = cellfun(@(x) x(:, 5), project_forcing, 'un', false); % Get SWL From LC
        Hm0 = cellfun(@(x) x(:, 6), project_forcing, 'un', false); % Get Hm0 From LC
        Tp = cellfun(@(x) x(:, 7), project_forcing, 'un', false); % Get Tp From LC
        RandNorm =cellfun(@(x) zeros(size(x)), SWL, 'un', false);
end

%% APPLY SWL UNCERTAINTY FOR STRUCTURE RESPONSE COMPUTATIONS
% Apply uncertainty using a random normal distribution
% ------------------ SWL ------------------
SWL = cellfun(@(x, y) pcha_forcing_uncertainty(x, swl_u_a, swl_u_r, y),SWL, RandNorm,'un',false);

%% APPLY Hm0 & Tp UNCERTAINTY FOR STRUCTURE RESPONSE COMPUTATIONS
% Check For Hm0 == 0
Hm0_w_Uncert = cellfun(@(x) Hm0_replace(1,x), Hm0, 'un', false);
% Apply Uncertainty
Hm0_w_Uncert = cellfun(@(x, y) pcha_forcing_uncertainty(x, hm0_u_a, hm0_u_r, y), Hm0_w_Uncert, RandNorm, 'un', false);
% Check For Hm0 < 0.01
Hm0  = cellfun(@(x) Hm0_replace(2,x), Hm0_w_Uncert, 'un', false);
% Tp
Tp_U = sqrt(1+hm0_u_r)-1; %0.0724
Tp = cellfun(@(x, y) x.*(1+Tp_U.*y), Tp, RandNorm, 'un', false);

%% Store Results
switch config.workflow
    case  {1, 2, 4}
        project_forcing.SWL = SWL; % Get SWL From LC
        project_forcing.Hm0 = Hm0; % Get Hm0 From LC
        project_forcing.Tp = Tp; % Get Tp From LC
    case {3}
        for jj = 1:nLC
            project_forcing{jj}(:,5) = SWL{jj}; % Get SWL From LC
            project_forcing{jj}(:,6) = Hm0{jj}; % Get Hm0 From LC
            project_forcing{jj}(:,7) =Tp{jj}; % Get Tp From LC
        end
end

%% Define internal Aux Function
    function Hm0 = Hm0_replace(cond,Hm0)
        switch cond
            case 1 % Hm0 == 0
                Hm0(Hm0 == 0) =  NaN;
            case 2 % Hm0 < 0.1
                Hm0(Hm0 < 0) =  0.01;
        end
    end
end