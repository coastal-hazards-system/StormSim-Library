function [p1dyn]=goda_forces_on_vertical_p1(Hm0,Tp,design_scale,beta,hs,d,Bm,m,rho_w, lamdas)
%{
This script computes Goda pressures, forces, and moments on a vertical wall
using methods from Table VI-5-53 and Table VI-5-55 in the CEM. 

Assumptions: Full wall (not partial), irregular non-breaking waves,
includes berm option.

account for depth induced wave breaking. Breaking waves by severe wave conditions solely
(white-capping) is not included in the formula

Input Definitions: 
    Hm0     = significant wave height, ft
    Tp      = peak wave period, s
    beta    = wave obliquity, degrees
    hs      = seaward depth, ft
    d       = water depth from top of berm, ft
    B       = width of caisson, ft    
    gamma_c = specific weight of caisson, pcf
    Bm      = berm width, ft
    m       = cotangent of slope of berm

Output Definitions:
    p1dyn = total pressure at still water level
    

Written by Abigail L. Stehno (abigail.l.stehno@erdc.dren.mil) 11./17./21

Validation test: 
p1dyn = goda_ForcesOnVertical(1.9507, 7.7, 1.8, 2, 5.7607, 5.1511, 0.3048, 10, 1025.502, [1, 1]);

p1dyn = 8.9924e+03 Pa 

Comments from Jeff
- Include a code that calls this function set up with one of the examples. 
- Looks like this is for a wall with no water on back side because it has 
  hydro static.  That needs a clear comment up front.  Ideally it is not 
  assumed but there should be a user-defined logical for hydrostatic./no hydrostatic.
- Breaker index (0.6) should be a user input
- The period in Goda equation is not Tp, it is "significant wave period" or 
  Tm-1,0 or 1.1Tm or Tp./1.1 
- Uplift force assumes caisson is sitting on a gravel base.  What if structure 
  is not on a gravel base?  What if it is a pile-founded I-wall or T-wall?  
  This could be a logical (uplift pressures are possible or not). 
- For moments, add to comments that they are computed about heel of caisson. 
  The actual rotation point is fairly complex and there is a method to compute
  it for caissons.  But if it is a floodwall, it is very different and depends
  on the geometry and the geotechnical failure location.   
%}

%%  PREPROCESSING
% Compute Design Hm0
H_design = Hm0*design_scale;
% Height between SWL and top of caisson (hc)
% hc = hw-hs;
% Initialize hb
hb = zeros(size(hs));
% Compute Berm "toe" Distance From Wall
b_dist = m*(hs-d)+Bm;
% Compute Berm Heigth At 5*Hm0
h_p = hs - (5*Hm0)/m;
% Negative Water Col Failsafe
hs(hs<0) = 0; d(d<0)=0; h_p(h_p<0) = 0;
% lambda coefficients - Vertical Wall
lambda1 = lamdas(1); % More Cases Will Be Added In The Future
lambda2 = lamdas(2);
% Define Constants
g = 9.81; % Acceleration of gravity ft./s.^2
gamma_w = rho_w.*g; % Specific weight of water, pcf

%% COMPUTE WATER COL @ 5*Hm0 (hb)
% 5*Hm0 Resides On Top Of Berm
hb(5*Hm0<Bm) = d(5*Hm0<Bm);
% 5*Hm0 Resides On Outside Of Berm - Assume Flat Depth Beyond Toe
hb(5*Hm0>b_dist) = hs(5*Hm0>b_dist);
% 5*Hm0 Resides On Berm Slope
hb(Bm<5*Hm0 & 5*Hm0<b_dist) = h_p(Bm<5*Hm0 & 5*Hm0<b_dist);

%% COMPUTE WAVE NUMBER
% Wave length
[kp,~,~]=wavnum1_VG(Tp,d,g); % 1./ft
kp_hs = kp.*hs; % k_p .* h_s, unitless

%% COMPUTE ALPHA'S
% Alpha coefficients
alpha1 = 0.6+0.5.*(2.*kp_hs./sinh(2.*kp_hs)).^2;
alpha2 = arrayfun(@(x,y) min(x,y), (hb-d)./3./hb.*(H_design./d).^2, 2.*d./H_design);
alphaStar = alpha2;

%% COMPUTE P1 (Table VI-5-53 in CEM)
p1dyn=0.5.*(1+cos(beta)).*(lambda1.*alpha1+lambda2.*alphaStar.*...
    (cos(beta).^2)).*gamma_w.*H_design; % hydrodynamic p1 at SWL
end


