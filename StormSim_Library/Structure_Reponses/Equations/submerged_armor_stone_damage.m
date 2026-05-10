function [S, S_pot] = submerged_armor_stone_damage(h, SLast, Hs, Tp, hc, Dn50, delta, g, Nref, Nz)
% SUBMERGED_ARMOR_STONE_DAMAGE computes incremental damage for submerged rubble mounds
% Based on the van der Meer and Daemen (1994) / CEM VI-5-25 approach.
%
% Inputs:
%   h         - Water depth at toe (m or ft)
%   SLast     - Damage level from previous timestep
%   Hs        - Significant wave height (m or ft)
%   Tp        - Peak wave period (sec)
%   hc        - Structure height from bottom to crest (m or ft)
%   Dn50      - Median stone size (m or ft)
%   delta     - Relative buoyant density (SG - 1)
%   g         - Gravity (m/s^2 or ft/s^2)
%   Nref      - Reference number of waves for the equation (typically 3000)
%   dt_hours  - Timestep duration in hours (e.g., 1)

%% 1. INITIALIZE AND CALCULATE WAVE PARAMETERS
S = SLast;
S_pot = 0;

if (Hs > 0.1) && (h > 0)
    % Estimate Wave Number and Local Wavelength
    % Ensure wavnum1_VG is in your path
    [kp, ~, ~] = wavnum1_VG(Tp, h, g);
    Lp = 2 * pi / kp;
    
    % Compute Local Wave Steepness
    sp = Hs / Lp;
    
    %% 2. SOLVE FOR POTENTIAL DAMAGE (S_pot)
    % S_pot represents the damage the sea state would cause if it lasted Nref waves.
    % Rearranged from CEM Table VI-5-25 / vdM & Daemen Eq 11:
    % Dn50 = -0.14 * Hs / (delta * sp^(1/3) * ln(hc / (h * (2.1 + 0.1*S))))
    
    % Intermediate calculation for the exponent
    % We use 0.14 because the original eq is: log(hc/(h*(2.1+0.1S))) = -0.14*Ns*
    exponent_term = (0.14 * Hs) / (delta * Dn50 * sp^(1/3));
    
    % Calculate S_pot
    S_pot = 10 * ( (hc / h) * exp(exponent_term) - 2.1 );
    
    % Ensure S_pot isn't negative (meaning waves are too small to move stone)
    S_pot = max(0, S_pot);

    %% 3. TIME INTEGRATION (ACCUMULATION)
    % This follows the same sqrt(N) logic as the Melby seaside equation
    if S_pot > 0
        % Calculate Equivalent Number of Waves (Nze) 
        % Current damage SLast expressed as waves of the CURRENT sea state
        Nze = (SLast / S_pot)^2 * Nref;
        
        % Calculate New Cumulative Damage adding this timestep's waves (Nz)
        S = S_pot * sqrt((Nze + Nz) / Nref);
    else
        % Sea state below motion threshold, carry over previous damage
        S = SLast;
    end
else
    % Calm conditions
    S = SLast;
    S_pot = 0;
end

end