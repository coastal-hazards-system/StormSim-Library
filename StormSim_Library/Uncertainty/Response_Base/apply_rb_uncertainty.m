function  [project_forcing] = apply_rb_uncertainty(config, project_forcing, TC_Freq, data_type, RandNorm)

%% GET INFORMATION FROM "config"
% Water Level Uncertainty
swl_u_a = config.chs_swl_u_a; % Absolute
swl_u_r = config.chs_swl_u_r; % Proportional
% Wave Height Uncertainty
hm0_u_a = config.chs_hm0_u_a; % Absolute
hm0_u_r = config.chs_hm0_u_r; % Proportional

%% GET INFORMATION FROM "project_forcing"
SWL_fnames = fieldnames(project_forcing);
% SWL_fnames = SWL_fnames(contains(SWL_fnames, {'SWL'}));
SWL_fnames = SWL_fnames(strcmp(SWL_fnames, {'SWL'}));

Tp_fnames = fieldnames(project_forcing);
% Tp_fnames = Tp_fnames(contains(Tp_fnames, {'Tp'}));
Tp_fnames = Tp_fnames(strcmp(Tp_fnames, {'Tp'}));

Hm0_fnames = fieldnames(project_forcing);
% Hm0_fnames = Hm0_fnames(contains(Hm0_fnames, {'Hm0'}));
Hm0_fnames = Hm0_fnames(strcmp(Hm0_fnames, {'Hm0'}));

% For Each Var Pair
for gg = 1:length(SWL_fnames)
    % Water Level
    SWL = project_forcing.(SWL_fnames{gg});
    % Wave Height
    Hm0 = project_forcing.(Hm0_fnames{gg});
    % Wave Peak Period
    Tp = project_forcing.(Tp_fnames{gg});

    %% APPLY FORCING UNCERTAINTY
    switch data_type
        case 'Peaks'
            % Determine Size
            [Nstrm,Ndscrt] = size(SWL);
            % Re-arrange Discrete Normal Dist. prior to adding uncertainty to SWL
            % Is the Idea to Build nstorm * ndist with each col being a different Randnorm?
            if contains(SWL_fnames{gg},{'_no_rep'})
                normU = randn(size(SWL));
            else
                normU = repmat(RandNorm,Nstrm,1);
            end
            % Apply uncertainty using a random normal distribution
            % ------------------ SWL ------------------
            if swl_u_r ~= 1 %apply uncertainty to normal replicates
                project_forcing.(SWL_fnames{gg}) = pcha_forcing_uncertainty(SWL, swl_u_a, swl_u_r, normU);
            end
        case 'Timeseries'
            % Determine Size Per Storm
            Nstrm = cellfun(@(x) size(x,1),SWL,'un',false);
            Ndscrt = length(RandNorm);
            % Re-arrange Discrete Normal Dist. prior to adding uncertainty to SWL
            % Is the Idea to Build nstorm * ndist with each col being a different Randnorm?
            if contains(SWL_fnames{gg},{'_no_rep'})
                normU = cellfun(@(x) randn(x,1),Nstrm,'un',false);
            else
                normU = cellfun(@(x) repmat(RandNorm,x,1),Nstrm,'un',false);
            end
            if swl_u_r ~= 1 %apply uncertainty to normal replicates
                % Apply uncertainty using a random normal distribution
                % ------------------ SWL ------------------
                project_forcing.(SWL_fnames{gg}) = cellfun(@(x,y) pcha_forcing_uncertainty(x, swl_u_a, swl_u_r, y),SWL,normU,'un',false);
            end
    end

    % ------------------ Hm0 & Tp ------------------
    % Estimate Tp_U as a function of Hm0_U, assume constant wave steepness
    if hm0_u_r ~= 1 %apply uncertainty to normal replicates
        switch data_type
            case 'Peaks'
                Hm0 (Hm0 == 0) = NaN;       % Remove zero Hm0 values
                Hm0_w_Uncert = pcha_forcing_uncertainty(Hm0, hm0_u_a, hm0_u_r, normU);
                % cannot have negative Hm0, so set these to very small number.
                % per discussions with Burns and Melby this is ok.
                Hm0_w_Uncert(Hm0_w_Uncert<=0)=0.01;
                % Assign Back To "project_forcing"
                project_forcing.(Hm0_fnames{gg}) = Hm0_w_Uncert; % Hm0
                % Tp
                Tp_U = sqrt(1+hm0_u_r)-1; %0.0724
                project_forcing.(Tp_fnames{gg}) = Tp.*(1+Tp_U.*normU);    % Apply uncertainty to Tp
            case 'Timeseries'
                % Check For Hm0 == 0
                Hm0_w_Uncert = cellfun(@(x) Hm0_replace(1,x), Hm0, 'un', false);
                % Apply Uncertainty
                Hm0_w_Uncert = cellfun(@(x,y) pcha_forcing_uncertainty(x, hm0_u_a, hm0_u_r, y), Hm0_w_Uncert, normU, 'un', false);
                % Check For Hm0 < 0.01
                Hm0_w_Uncert = cellfun(@(x) Hm0_replace(2,x), Hm0_w_Uncert, 'un', false);
                % Assign Back To "project_forcing"
                project_forcing.(Hm0_fnames{gg}) = Hm0_w_Uncert; % Hm0
                % Tp
                Tp_U = sqrt(1+hm0_u_r)-1; %0.0724
                project_forcing.(Tp_fnames{gg}) = cellfun(@(x,y) x.*(1+Tp_U.*y), Tp, normU, 'un', false);
        end
    end
end

% ---- Define internal Aux Function
    function Hm0 = Hm0_replace(cond,Hm0)
        switch cond
            case 1 % Hm0 == 0
                Hm0(Hm0 == 0) =  NaN;
            case 2 % Hm0 < 0.1
                Hm0(Hm0 < 0.1) =  0.01;
        end
    end
end