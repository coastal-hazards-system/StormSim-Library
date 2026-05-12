% Program to compute breakwater/revetment stone armor stability
% Written by Jeff Melby April 2009
%
% Armor damage based on Melby revision of 
% van Gent, M., and Pozueta, B. (2004).  “?,” 
% Proc. of Coastal Structures 2003, ASCE, Reston, VA, ?. 
%
% function[output] = LeeDamFunc(input)
%============================================================
function[S,u1p] = leeside_armor_stone_damage(SLast,...
    H, Tp, u1p_last, LDn, Lslp, h, Rc, Nz, Delta, K_ls1, K_ls2, crest_width, crest_elevation, grav, compute_S_submerged, cutoff_switch, cutoff)
%============================================================
Tmm1=Tp/1.1;     % spectral mean wave period in sec
%============================================================
% Coeffs from Melby 2009
if SLast>0
    K_ls2=0.04;
    r=1;
else
    r=6;
end

%============================================================
% Check to see if runup exceeds the crest elevation.
% If not, then no leeside calculation is required.
% If there is velocity on crest, compute damage

% Restrictions Taken Care Of By u1p & z1p (Ru)
% Rc >= 0.6 else z1p = 0
% Rc/Hs >= 0.3 else u1p = 0
% z1p-Rc > 0 else u1p = 0
% z1p = 0 then u1p = 0


if cutoff_switch == 0 % Evaluate Actual Design
    % Compute Run-up Exceeded By 1% Of The Incident Waves
    [z1p] = z1p_calc(H, Tp, Rc, Lslp, grav);
    % Compute Crest Velocity Exceeded By 1% Of The Incident Waves
    u1p = u1p_calc(crest_width, Rc, z1p, Tp, H, Lslp, grav);
else % Artificially Increase Freeboard (Raise Structure)
    % Compute "New" Crest Elevation
    cutoff_elevation = crest_elevation + cutoff;
    % Compute Artificial Freeboard
    Rc_artificial = cutoff_elevation - WL;
    % Recompute u1p, z1p
    % Compute Run-up Exceeded By 1% Of The Incident Waves
    [z1p] = z1p_calc(H, Tp, Rc_artificial, Lslp, grav);
    % Compute Crest Velocity Exceeded By 1% Of The Incident Waves
    u1p = u1p_calc(crest_width, Rc_artificial, z1p, Tp, H, Lslp, grav);
end
%
if Rc<0 && compute_S_submerged == 1
    % Call Submerged Equation Here
    % The "Potential" Damage (S_pot): This calculates how much damage the current wave conditions would cause if they persisted for exactly N_ref waves.
    % Formula is typically are  calibrated to N_ref = 3000 waves. 
    % By using this as a reference, we can calculate the "potential damage" for the current hour and then scale it based on
    % the square-root-of-time rule (S proportional sqrt{N}) to maintain consistency with your Melby seaside functions.
    %     Nref = 3000;
    % [S, S_pot] = submerged_armor_stone_damage(h, SLast, H, Tp, crest_elevation, LDn, Delta, grav, Nref, Nz);
    S= SLast;
elseif (z1p-Rc)>0 % In case of Rc<0 this will be true
    if u1p > 0 % u1p already accounts for Rc<0 restriction
        als = (Lslp^(-2.5/r))*(1 + 10*exp(-Rc/H))^(1/r);
        Nls = u1p*Tmm1/sqrt(Delta)/LDn/K_ls1;
        Nze = (SLast/K_ls2/(als*Nls)^r)^2;
        S= K_ls2*sqrt(Nze+Nz)*(als*Nls)^r;
    else
        S= SLast;
    end
else
    S = SLast;
    u1p=u1p_last;
end
% Equation Validity Range
% Eq_invalid_range = any([Nz>=4000,...
% Rc./H<0.3 | Rc./H>6,...
% crest_width./H<1.3 | crest_width./H>1.6,...
% H./(Delta.*LDn)<5.5 | H./(Delta.*LDn)<8.5,...
% (Ru-Rc)./(gamma_f.*H)<0 | (Ru-Rc)./(gamma_f.*H)>1.4]);
% % If Any Of The Conditions Yields True , Neglect Damage
% if Eq_invalid_range
%     S = SLast;
%     u1p = u1p_last;
% end
%============================================================
return
