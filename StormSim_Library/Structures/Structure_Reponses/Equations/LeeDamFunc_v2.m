% Program to compute breakwater/revetment stone armor stability
% Written by Jeff Melby April 2009
%
% Armor damage based on Melby revision of 
% van Gent, M., and Pozueta, B. (2004).  “?,” 
% Proc. of Coastal Structures 2003, ASCE, Reston, VA, ?. 
%
% function[output] = LeeDamFunc(input)
%============================================================
function[S,u1p] = LeeDamFunc_v2(u1p,Ru,SLast,...
    H,Tp,u1p_last,LDn,Lslp,Rc,Nz,Delta,K_ls1,K_ls2)
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
  if Ru > abs(Rc)
    if u1p > 0
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

%============================================================
return
