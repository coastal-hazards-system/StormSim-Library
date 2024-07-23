function  [project_forcing] = apply_pros_uncertainty(config, project_forcing, data_type, RandNorm)

%% GET INFORMATION FROM "config"
% Water Level Uncertainty
swl_u_a = config.chs_swl_u_a; % Absolute
swl_u_r = config.chs_swl_u_r; % Proportional
% Wave Height Uncertainty
hm0_u_a = config.chs_hm0_u_a; % Absolute
hm0_u_r = config.chs_hm0_u_r; % Proportional

%% GET INFORMATION FROM "project_forcing"
% Water Level
SWL = project_forcing.('SWL');
% Wave Height
Hm0 = project_forcing.('Hm0');
% Wave Peak Period
Tp = project_forcing.('Tp');

%% APPLY SWL UNCERTAINTY FOR STRUCTURE RESPONSE COMPUTATIONS
switch data_type
    case 'Peaks'
        % Determine Size
        [Nstrm,~] = size(SWL);
        % Re-arrange Discrete Normal Dist. prior to adding uncertainty to SWL
        % The Idea to Build nstorm * ndist with each col being a different Randnorm?
        normU = repmat(RandNorm,Nstrm,1);
        % Apply uncertainty using a random normal distribution
        % ------------------ SWL ------------------
        project_forcing.('SWL') = pcha_forcing_uncertainty(SWL, swl_u_a, swl_u_r, normU);
    case 'Timeseries'
        % Determine Size Per Storm
        Nstrm = cellfun(@(x) size(x,1),SWL,'un',false);
        % Re-arrange Discrete Normal Dist. prior to adding uncertainty to SWL
        % The Idea to Build nstorm * ndist with each col being a different Randnorm?
        normU = cellfun(@(x) repmat(RandNorm,x,1),Nstrm,'un',false);
        % Apply uncertainty using a random normal distribution
        % ------------------ SWL ------------------
        project_forcing.('SWL') = cellfun(@(x,y) pcha_forcing_uncertainty(x, swl_u_a, swl_u_r, y),SWL,normU,'un',false);
end

%% APPLY Hm0 & Tp UNCERTAINTY FOR STRUCTURE RESPONSE COMPUTATIONS
% ------------------ Hm0 & Tp ------------------
% Estimate Tp_U as a function of Hm0_U, assume constant wave steepness
if hm0_u_r ~= 1 %apply uncertainty to normal replicates
    switch data_type
        case 'Peaks'
            % Remove zero Hm0 values
            Hm0 (Hm0 == 0) = NaN;      
            % Apply Uncertainty
            Hm0_w_Uncert = pcha_forcing_uncertainty(Hm0, hm0_u_a, hm0_u_r, normU);
            % cannot have negative Hm0, so set these to very small number.
            % per discussions with Burns and Melby this is ok.
            Hm0_w_Uncert(Hm0_w_Uncert<=0)=0.01;
            % Assign Back To "project_forcing"
            project_forcing.('Hm0') = Hm0_w_Uncert; % Hm0
            % Tp
            Tp_U = sqrt(1+hm0_u_r)-1; %0.0724
            project_forcing.('Tp') = Tp.*(1+Tp_U.*normU);    % Apply uncertainty to Tp
        case 'Timeseries'
            % Check For Hm0 == 0
            Hm0_w_Uncert = cellfun(@(x) Hm0_replace(1,x), Hm0, 'un', false);
            % Apply Uncertainty
            Hm0_w_Uncert = cellfun(@(x,y) pcha_forcing_uncertainty(x, hm0_u_a, hm0_u_r, y), Hm0_w_Uncert, normU, 'un', false);
            % Check For Hm0 < 0.01
            Hm0_w_Uncert = cellfun(@(x) Hm0_replace(2,x), Hm0_w_Uncert, 'un', false);
            % Assign Back To "project_forcing"
            project_forcing.('Hm0') = Hm0_w_Uncert; % Hm0
            % Tp
            Tp_U = sqrt(1+hm0_u_r)-1; %0.0724
            project_forcing.('Tp') = cellfun(@(x,y) x.*(1+Tp_U.*y), Tp, normU, 'un', false);
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