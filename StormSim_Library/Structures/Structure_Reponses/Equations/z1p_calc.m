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
function[z1p] = z1p_calc(H,Tp,Rc,Sslp,grav)

%============================================================


%============================================================
  % preliminary calculations
  Tmm1=Tp./1.1;     % spectral mean wave period in sec
  Lmm1=grav.*Tmm1.^2./2./pi;
  som  = H./Lmm1;
  SSPm = 1./Sslp./sqrt(som);  % Iribarren param
  c0 = 1.45;
  c1 = 5.1;
  c2 = 0.25.*c1.^2./c0;
  pR = 0.5.*c1./c0;

 % roughness coefficient for rubble mound
    if SSPm <= 2
      gamf=0.55;
    elseif SSPm >= 10
      gamf=1.0;
    else
      gamf=0.05625.*(SSPm-2)+0.55;
    end
  
   gam_beta = 1.0;   % reduction factor for wave obliquity
   gamma = gamf.*gam_beta;
   %============================================================

  %============================================================
  % Runup
  if SSPm <= pR
    z1p = gamma .* H .* c0 .* SSPm;
  else
    z1p = gamma .* H .* (c1 - c2./SSPm);
  end
 if Rc < 0.6 
  z1p = 0;
 end
%============================================================

return