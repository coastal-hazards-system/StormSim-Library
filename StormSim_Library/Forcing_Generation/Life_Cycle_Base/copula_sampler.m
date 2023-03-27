function [Y, Y_WLP, Y_WHP] = copula_sampler(storm_peaks, storm_wlp_peaks, storm_whp_peaks, storm_indexes)  
%% DEFINE INPUTS 
WLP_switch = ~isempty(storm_wlp_peaks);
WHP_switch = ~isempty(storm_whp_peaks);

%% COMPUTE GAUSSIAN COPULA STATISTICAL PARAMETERS
    % Returns a probability density estimate, f, for each sample data column
    for k = 1:4
        % Maximums
        X(:,k) = ksdensity(storm_peaks(:,k),storm_peaks(:,k),'function','cdf');
        if WLP_switch == 1
            % Water Level Priority
            X_WLP(:,k) = ksdensity(storm_wlp_peaks(:,k),storm_wlp_peaks(:,k),'function','cdf');
        end
        if WHP_switch == 1
            % Wave Height Priority
            X_WHP(:,k) = ksdensity(storm_whp_peaks(:,k),storm_whp_peaks(:,k),'function','cdf');
        end
    end

    % Compute Tau
    Tau = corr(X,'type','Kendall'); % Maximums
    % Compute matrix of linear correlations (Rho)
    Rho = copulaparam('Gaussian',Tau,'type','Kendall'); % Maximums
    % Compute random values; where 'r' = normal probabilities (pdf)
    %sample random values from Gaussian copula
    r = copularnd('Gaussian',Rho,size(storm_indexes,1)); % Maximums
    %%% WLP
    if WLP_switch == 1
        % Compute Tau
        Tau_WLP = corr(X_WLP,'type','Kendall'); % Water Level Priority
        % Compute matrix of linear correlations (Rho)
        Rho_WLP = copulaparam('Gaussian',Tau_WLP,'type','Kendall'); % Water Level Priority
        % Compute random values; where 'r' = normal probabilities (pdf)
        %sample random values from Gaussian copula
        r_WLP = copularnd('Gaussian',Rho_WLP,size(storm_indexes,1)); % Water Level Priority
    end
    %%% WHP
    if WHP_switch == 1
        % Compute Tau
        Tau_WHP = corr(X_WHP,'type','Kendall'); % Wave Height Priority
        % Compute matrix of linear correlations (Rho)
        Rho_WHP = copulaparam('Gaussian',Tau_WHP,'type','Kendall'); % Wave Height Priority
        % Compute random values; where 'r' = normal probabilities (pdf)
        %sample random values from Gaussian copula
        r_WHP = copularnd('Gaussian',Rho_WHP,size(storm_indexes,1)); % Wave Height Priority
    end
    % Computes 'inverse cumulative probability' (real values)
    for k = 1:4
        % Maximums
        Y(:,k) = ksdensity(storm_peaks(:,k),r(:,k),'function','icdf');
        if WLP_switch == 1
            % Water Level Priority
            Y_WLP(:,k) = ksdensity(storm_wlp_peaks(:,k),r_WLP(:,k),'function','icdf');
        end
        if WHP_switch == 1
            % Wave Height Priority
            Y_WHP(:,k) = ksdensity(storm_whp_peaks(:,k),r_WHP(:,k),'function','icdf');
        end
    end

    %% SAMPLE STORM PARAMETERS FROM GAUSSIAN COPULA - WORST CASE SCENARIO
    % Compute Water Level
    Y(:,1) = Y(:,1)*nanmean(storm_peaks(:,1))/nanmean(Y(:,1));
    % Compute Wave Height
    Y(:,2) = Y(:,2)*nanmean(storm_peaks(:,2))/nanmean(Y(:,2));
    % Compute Wave Period
    Y(:,3) = Y(:,3)*nanmean(storm_peaks(:,3))/nanmean(Y(:,3));
    % Compute Wave Direction
    Y(:,4) = Y(:,4)*nanstd(storm_peaks(:,4))/nanstd(Y(:,4));
    % Assign Sampled Extratropical Storm Indexes
    Y(:,5)= storm_indexes;
    % Cap sampled waves to positive values
    Y(Y(:,2)<0.05,2)=0.05;

    %% SAMPLE STORM PARAMETERS FROM GAUSSIAN COPULA - WATER LEVEL PRIORITY
    if WLP_switch ==  1
        % Compute Water Level
        Y_WLP(:,1) =Y_WLP(:,1)*nanmean(storm_wlp_peaks(:,1))/nanmean(Y_WLP(:,1));
        % Compute Wave Height
        Y_WLP(:,2) =Y_WLP(:,2)*nanmean(storm_wlp_peaks(:,2))/nanmean(Y_WLP(:,2));
        % Compute Wave Period
        Y_WLP(:,3) =Y_WLP(:,3)*nanmean(storm_wlp_peaks(:,3))/nanmean(Y_WLP(:,3));
        % Compute Wave Direction
        Y_WLP(:,4) =Y_WLP(:,4)*nanstd(storm_wlp_peaks(:,4))/nanstd(Y_WLP(:,4));
        % Assign Sampled Extratropical Storm Indexes
        Y_WLP(:,5)= storm_indexes;
        % Cap sampled waves to positive values
        Y_WLP(Y_WLP(:,2)<0.05,2)=0.05;
    else
        Y_WLP = [];
    end
    %% SAMPLE STORM PARAMETERS FROM GAUSSIAN COPULA - WAVE HEIGHT PRIORITY
    if WHP_switch == 1
        % Compute Water Level
        Y_WHP(:,1) =Y_WHP(:,1)*nanmean(storm_whp_peaks(:,1))/nanmean(Y_WHP(:,1));
        % Compute Wave Height
        Y_WHP(:,2) =Y_WHP(:,2)*nanmean(storm_whp_peaks(:,2))/nanmean(Y_WHP(:,2));
        % Compute Wave Period
        Y_WHP(:,3) =Y_WHP(:,3)*nanmean(storm_whp_peaks(:,3))/nanmean(Y_WHP(:,3));
        % Compute Wave Direction
        Y_WHP(:,4) =Y_WHP(:,4)*nanstd(storm_whp_peaks(:,4))/nanstd(Y_WHP(:,4));
        % Assign Sampled Extratropical Storm Indexes
        Y_WHP(:,5)= storm_indexes;
        % Cap sampled waves to positive values
        Y_WHP(Y_WHP(:,2)<0.05,2)=0.05;
    else 
        Y_WHP = [];
    end
end