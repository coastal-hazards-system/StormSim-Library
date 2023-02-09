function [gamma_beta_r2p,gamma_beta_q] = oblique_waves_influence_factor(Nstrm)
    % Oblique wave coefficients - Not implemented in StormSim as of 9/03/20
    % will use Eurotop eq 6.9 for RM ; eq. 5.28-5.31 for levees
    gamma_beta_r2p = ones(Nstrm,1);
    gamma_beta_q   = ones(Nstrm,1);
end