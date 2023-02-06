function [p1dyn]=goda_ForcesOnVertical_p1(Hm0,Tp,beta,hs,d,hw,Bm,m)

%{ 
This script computes Goda pressures, forces, and moments on a vertical wall
using methods from Table VI-5-53 and Table VI-5-55 in the CEM. 

Assumptions: Full wall (not partial), irregular non-breaking waves,
includes berm option

Input Definitions: 
    Hm0     = significant wave height, ft
    Tp      = peak wave period, s
    beta    = wave obliquity, degrees
    hs      = seaward depth, ft
    d       = water depth from top of berm, ft
    hw      = height of wall - toe to crest, ft
    B       = width of caisson, ft    
    gamma_c = specific weight of caisson, pcf
    Bm      = berm width, ft
    m       = cotangent of slope of berm

Output Definitions:
    p
        p.p1 = total pressure at still water level
        p.p2 = total pressure at top of wall
        p.p3 = total pressure at ground./top of fill
    F 
        F.F_horiz = horizontal force (includes uncertainty)
        F.F_up = uplift force (includes uncertainty)
        F.FG = reduced weight of vertical structure due to buoyancy 
    M
        M.M_horiz = horizontal moment (includes uncertainty)
        M.M_up = uplift moment (includes uncertainty)
        M.MG = moment due to buoyancy


Written by Abigail L. Stehno (abigail.l.stehno@erdc.dren.mil) 11./17./21

Validation test: 
[p,F,M]=goda_ForcesOnVertical(6.4,7.7,2,18.9,16.9,19.5,2,155,1,10)
p = 
         p1: 187.7356
         p2: 90.9741
         p3: 1.4018e+03
F = 
    F_horiz: 2.9205e+03
       F_up: 117.7368
         FG: 3.8811e+03
M = 
    M_horiz: 2.5689e+04
       M_up: 146.7887
         MG: 3.8811e+03


Comments from Jeff
- Include a code that calls this function set up with one of the examples. 
- Looks like this is for a wall with no water on back side because it has 
  hydro static.  That needs a clear comment up front.  Ideally it is not 
  assumed but there should be a user-defined logical for hydrostatic./no hydrostatic.
- put all user modifiable things in a section at front of code after header 
  comments and have a statement that says "Do not change anything below here"
- Specific weight of water should be a user input (fresh or salt)
- H_design_factor (1.8) should be a user input
- Breaker index (0.6) should be a user input
- Lambdas should be user inputs
- The period in Goda equation is not Tp, it is "significant wave period" or 
  Tm-1,0 or 1.1Tm or Tp./1.1 
- Need to describe units.  You have input units described but not output.  
  Ideally, acceleration of gravity is a user input that defines the units.  
  So if it is 32.1719 then it is english standard, if it is 9.8066, then it is SI.  
  Then the output units are stated in the output structure 
- Uplift force assumes caisson is sitting on a gravel base.  What if structure 
  is not on a gravel base?  What if it is a pile-founded I-wall or T-wall?  
  This could be a logical (uplift pressures are possible or not). 
- For moments, add to comments that they are computed about heel of caisson. 
  The actual rotation point is fairly complex and there is a method to compute
  it for caissons.  But if it is a floodwall, it is very different and depends
  on the geometry and the geotechnical failure location.   

%} 


try
    hs = max(hs,0); d=max(d,0); 
%% Input pre-processing 
    % Steepness correction - breakerRatio = 0.6
%     if Hm0./d > 0.6
%         Hm0= d.*0.6; % ft
%     end

    % compute hb with respect to the berm width
    if 5.*hs < Bm
        hb = d; 
    elseif 5.*hs>Bm+(hs-d).*m
        hb = hs; 
    else
        hb = ((5.*hs-Bm)./m)+d;
    end

    % lambda coefficients 
    lambda1 = 1; 
    lambda2 = 1; 
    lambda3 = 1; 

    g = 32.1719; % Acceleration of gravity ft./s.^2
    gamma_w = 1.99.*g; % Specific weight of water, pcf
    H_design = 1.80.*Hm0; % Design wave height, ft
    Rc = hw - d; % Freeboard, ft

    % Wave length
    [kp,~,~]=wavnum1_VG(Tp,min(hb,d),g); % 1./ft
    kp_hs = kp.*hs; % k_p .* h_s, unitless

    % Alpha coefficients
    alpha1 = 0.6+0.5.*(2.*kp_hs./sinh(2.*kp_hs)).^2;
    alpha2 = min((hb-d)./3./hb.*(H_design./d).^2, 2.*d./H_design); 
    alpha3 = 1-(hw-Rc)./hs.*(1-1./cosh(kp_hs)); 
    alphaStar = alpha2; 

    etaStar = 0.75.*(1+cos(beta)).*H_design.*lambda1; % ft

%% Pressures (Table VI-5-53 in CEM)
    p1dyn=0.5.*(1+cos(beta)).*(lambda1.*alpha1+lambda2.*alphaStar.*...
        (cos(beta).^2)).*gamma_w.*H_design; % hydrodynamic p1 at SWL

%     if etaStar>Rc %hydrodynamic p2 at top of wall
%         p2dyn=(1-Rc./etaStar).*p1dyn; 
%     else
%         p2dyn=0; 
%     end
%     p2sta=max(gamma_w.*-1.*(hw-d),0); % hydrostatic p2 at top of wall
%     p2total = p2dyn+p2sta; % total p2 at top of wall
% 
%     p3dyn = alpha3.*p1dyn; % hydrodynamic p3 at ground./top of fill
%     p3sta = max(gamma_w.*hw,0); % hydrostatic p3 at ground./top of fill
%     p3total = p3dyn+p3sta; % total p3 at ground./top of fill
% 
%     % uplift pressure at seaward edge
%     pu = 0.5.*(1+cos(beta)).*lambda3.*alpha1.*alpha3.*gamma_w.*H_design; 
% 
% %% Forces and Moments(Table VI-5-55 in CEM)
%     % Stochastic variables signifiying bias and uncertainty
%     UFH = 0.9; % horizontal force 
%     UFU = 0.77; % uplift force  
%     UMH = 0.81; % horizontal moment 
%     UMU = 0.72; % uplift moment 
% 
%     FH = Rc.*(p1dyn+p2dyn)./2+d.*(p1dyn+p3dyn)./2; % horizontal force
%     UFH_FH = UFH.*FH;% horizontal force with uncertainty 
% 
%     FU = pu.*B./2; % uplift force
%     UFU_FU = UFU.*FU; % uplift force with uncertainty
% 
%     FG = gamma_c.*B.*hw-gamma_w.*B.*d; % reduced wt of vert struct due to buoyancy 
% 
%     MH = (2.*p1dyn+p3dyn).*d.^2./6+(p1dyn+p2dyn).*d.*(hw-d)./2+(p1dyn+2.*p2dyn)...
%         .*(hw-d).^2./6; % horizontal moment 
%     UMH_MH = UMH.*MH; % horizontal moment with uncertainty
% 
%     MU = 1./3.*pu.*B.^2; % uplift moment 
%     UMU_MU = UMU.*MU; % uplift moment with uncertainty
% 
%     MG = 0.5.*B.^2.*(gamma_c.*hw-gamma_w.*d); % moment due to buoyancy
% 
% %% Create output variables
%     p.p1 = p1dyn; p.p2=p2total; p.p3=p3total; 
%     F.F_horiz = UFH_FH; F.F_up = UFU_FU; F.FG = FG; 
%     M.M_horiz = UMH_MH; M.M_up = UMU_MU; M.MG = MG; 

catch 
    disp('Please check inputs for pressure calculation')
end


