% Program to
%     compute cross-section overtopping transmission
% Written by Jeff Melby April 2009
% updated by JAM on 2-10-12 to use van Gent equations
%
% Input:
%     Tp............Mean wave period (sec)
%     H.............Sig Wave height(m or ft)
%     Rc............Free board(m or ft)
%     slope.........cot of Structure slope
%     grav..........Acceleration of gravity (m./s.^2 or ft./s.^2)
%	gamma_R.........Correction for wave direction and./or roughness
%
% Output:
%     z2............2 % exceedance runup value (m or ft)
% 
%
% Runup equation based on 
%
% function[output] = Runup(input)
%============================================================
function[z1p] = z1p_calc(H,Tmm1,Rc,Sslp,grav)

%============================================================


%============================================================
  % preliminary calculations
  Lmm1=grav.*Tmm1.^2./2./pi;
  som  = H./Lmm1;
  SSPm = 1./Sslp./sqrt(som);  % Iribarren param
  c0 = 1.45;
  c1 = 5.1;
  c2 = 0.25.*c1.^2./c0;
  pR = 0.5.*c1./c0;

  % roughness coefficient for rubble mound
  gamf = 0.05625.*(SSPm-2)+0.55;
  gamf(SSPm <= 2) = 0.55;
  gamf(SSPm >= 10) = 1.0;


  gam_beta = 1.0;   % reduction factor for wave obliquity
  gamma = gamf.*gam_beta;
  %============================================================

  %============================================================
  % Runup
  z1p = gamma .* H .* (c1 - c2./SSPm);
  z1p(SSPm <= pR) = gamma(SSPm <= pR) .* H(SSPm <= pR) .* c0 .* SSPm(SSPm <= pR);
  % Freeboard Restriciton
  z1p(Rc<0.6) = 0;
  %============================================================

return