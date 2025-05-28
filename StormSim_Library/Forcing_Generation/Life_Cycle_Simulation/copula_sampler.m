function Y = copula_sampler_mod(storm_peaks, storm_indexes)  
%% COMPUTE GAUSSIAN COPULA STATISTICAL PARAMETERS & SAMPLE STORMS
    % Returns a probability density estimate, f, for each sample data column
    for k = 1:4
        X(:,k) = ksdensity(storm_peaks(:,k),storm_peaks(:,k),'function','cdf');
    end
    % Compute Tau
    Tau = corr(X,'type','Kendall'); % Maximums
    % Compute matrix of linear correlations (Rho)
    Rho = copulaparam('Gaussian',Tau,'type','Kendall'); % Maximums
    % Compute random values; where 'r' = normal probabilities (pdf)
    %sample random values from Gaussian copula
    r = copularnd('Gaussian',Rho,size(storm_indexes,1)); % Maximums
    % Computes 'inverse cumulative probability' (real values)
    for k = 1:4
        Y(:,k) = ksdensity(storm_peaks(:,k),r(:,k),'function','icdf');
    end

    %% SCALE SAMPLED STORM RESPONSES
    % Scale Responses By Individual Means
    Y = Y.*mean(storm_peaks, 1, "omitnan")./mean(Y, 1, "omitnan");
    % Cap sampled waves to positive values
    Y(Y(:,2)<0.05,2)=0.05;
end