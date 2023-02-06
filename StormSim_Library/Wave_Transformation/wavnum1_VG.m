%=========================================================
%  function wavenum
%  Jeff Melby 4/27/09
%
%  Solves linear wave theory dispersion relation for
%  wave number, k = 2pi/L
%  Also solves using empirical estimate using relation from 
%  Guo, J.  (2002).  “Simple and explicit solution of wave dispersion 
%  equation,”  Coastal Engineering, Vol 45, No. 2, pp 71-74.
%
% 
%     INPUT:
%     T............wave period (HZ)
%     depth........water depth (m or ft)
%     grav.........acceleration of gravity (m/s^2 or ft/s^2)
%
%     OUTPUT:
%     km...........wave number (1/m or 1/ft)
%     kmest........wave number empirical estimate
%     error........in case slope causes error
%=========================================================
function[km,kmest,ERROR] = wavnum1_VG(T,depth,grav)
TOL = 1.0E-5;
CORR = 2 * TOL;
ERROR = 1;
fq = 1./T;
% solve for kh(x1) using iterative method
% initial guess for X1 based on WHSQ
WHSQ = (depth/grav).* (2*pi*fq).^2;
if WHSQ > 1.0
   X1 = WHSQ;
   if tanh(X1) > 1.-TOL  % deep water limits
     CORR = TOL - 1e-6;  % done, return to calling program
   end
else  
   X1 = sqrt(WHSQ);
   if abs(X1-tanh(X1)) < TOL % shallow water limits
     CORR = TOL - 1e-6;  % done, return to calling program
   end
end

%
% iterative loop
while abs(CORR) > TOL
%   while ERROR >0
      numer = X1 .* tanh(X1) - WHSQ;
      denom = tanh(X1) + X1./(cosh(X1)).^2;
% Check slope to avoid divide by zero
      if abs(denom) < TOL
         ERROR = 0; %ERROR IN SLOPE CHECK IN WAVNUM SUBROUTINE
         CORR = TOL - 1e-6;
      else
         CORR = numer./denom;
         X1 = X1 - CORR;
      end
%   end
end
km = X1 ./ depth;
% check against the empirical estimate
arg=2*pi/T*sqrt(depth/grav);
A = grav.*T.^2/2/pi;
wavelen = A*(1-exp(-(arg^2.5)))^(0.4);
kmest = (2*pi)/wavelen;
return