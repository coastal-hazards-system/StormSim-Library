% Program to
%     compute cross-section incremental damage
% Written by Jeff Melby May 2012
%
% Modified Dec 2020 Abigail Stehno to compare Melby eqs with low-crested
% breakwater and Van Gent LC-BW equations
%       - added CrestEle to inputs for low-crested eqs
%       - changed function output to include Low Crested Eqs and Burcharth RoT
% Modified Nov 2021 Abigail Stehno - change Crest elevation input to Rc
%
% Input:
%     Tm............Mean Wave Period (sec)
%     Hsig..........Hm0 Significant Wave height(m or ft)
%     Sslp..........cot of Structure Slope
%     grav..........Acceleration of Gravity (m./s.^2 or ft./s.^2)
%     Nz............Number of Waves = duration./Tm
%     depth.........Water Depth near Toe (m or ft)
%     P.............Structure Notional Permeability
%     S.............Damage Limit State
%     delta.........Armor Immersed Relative Denstity
%
%       CrestEel .... Crest elevation (depth + freeboard)
%
% Output:
%     Dn50..........Armor Stone Nominal Size (m or ft)
%
%
%
%============================================================
function [Dn50_Melby, Dn50_LCBW] = Seaside_stability_Melby_lowCrested(Hsig,Tm,h,Nz,Sslp,delta,P,S,grav,km1,km2,Rc)


%% Melby
% JAM 3/22/2023 Equation for main armor stability updated based on new equation
% instersect and new fit against Van Gent's and Melby's model data.
% Hard Coded Coeff
% JAM 3/22/2023 Low-crested equation reworked in terms of high-crested
% stability.  Now only get a stone reduction if negative freeboard.
ks = 1;

%% VECTORIZE INPUTS
data_dims = size(Hsig);
Hsig = Hsig(:);
Tm = Tm(:);
h = h(:);
Rc = Rc(:);

%% COMPUTE Dn50
% Momentum Flux Computations
A0 = 0.639.*(Hsig./h).^2.026;
A1 = 0.180.*(Hsig./h).^-0.391;
Mf = A0.*(h./grav./Tm.^2).^-A1;
% Estimate Wave Number
[km,~,~] = wavnum1_VG(Tm,h,grav);
% Compute Wave length Based On Mean Period
Lm = 2.*pi./km;
% Compute Wave Steepness Based On Mean Period
sm = Hsig./Lm;
% Compute Critical Wave Steepness (Melby & Kobayashi 2011)
smc = Sslp.^-3; % JAM change 11./18./22 for continuous equation
% Initialize am
am = zeros(size(Hsig));
% Compute Plunging
am(sm>=smc) = 1./(km1.*P.^0.18.*sqrt(Sslp));
% Compute Surging
am(sm<smc) = 1./(km2.*P.^0.18.*Sslp.^(0.5-P).*sm(sm<smc).^(-P./3));
% COmpute Median Stone Size For Given S
Dn50_Melby = sqrt(Mf./delta).*h.*am.*((ks.*sqrt(Nz))./S).^0.2;
% Assign NaNs
Dn50_Melby(Hsig<=0 | h<0) = NaN;
% Reshape
Dn50_Melby = reshape(Dn50_Melby, data_dims);
%% Low Crested
% From Burcharth et al 2006 - stability of low crested structures. 
% Equation 5 Recomputed here to be in terms of a normal emergent structure.
% Assume equation is valid for -4 <= Rc/Dn_50 < 0 
% and slope 1:1.5 exposed to non-depth limited waves, and
% slopes 1:2 exposed to depth limited short-crested waves. 
% Hard coded Coeff a = -0.5 slope of curve
% Compute Dn50_LCBW
if Rc>=0
    Dn50_LCBW = Dn50_Melby;
else
    Dn50_LCBW = Dn50_Melby+Rc/2; % Rc<0
end
    % COmpute m
Dn50_LCBW = reshape(Dn50_LCBW, data_dims);
%}
end


