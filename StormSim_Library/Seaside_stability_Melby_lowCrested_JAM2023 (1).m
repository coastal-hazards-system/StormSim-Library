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
%     grav..........Acceleration of Gravity (m/s^2 or ft/s^2)
%     Nz............Number of Waves = duration/Tm
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
% Change by Melby on 1/6/2023
% Very small wave heights cause Mf to soar.  So changed limit from 
% Hm0 = 0 to Hm0 = 0.1.
%
%============================================================
function [Dn50_Melby,Dn50_LCBW] = Seaside_stability_Melby_lowCrested_JAM2023(Hsig,Tm,h,Nz,Sslp,delta,P,S,grav,km1,km2,Rc)


%% Melby
% Hard Coded Coeff 
ks = 1;

if ((Hsig>0.1) & (h>0)) % ALS updated (depth>0) to (h>0)
    %% Momentum Flux Computation
    A0 = 0.639*(Hsig/h)^2.026;
    A1 = 0.180*(Hsig/h)^-0.391;
    Mf = A0*(h/grav/Tm^2)^-A1;
    
    %% WAVE PARAMETERS COMPUTATIOSN
    % Estimate Wave Number
    [km,~,~] = wavnum1_VG(Tm,h,grav);
    % Compute Wave length Based On Mean Period
    Lm = 2*pi/km;
    % Compute Wave Steepness Based On Mean Period
    sm = Hsig/Lm;
    % Compute Critical Wave Steepness (Melby & Kobayashi 2011)
    smc = Sslp^-3; % JAM change 11/18/22 for continuous equation
    
    %% COMPUTE a_m COEFFICIENT (Melby & Kobayashi 2011)
    if sm>=smc
        % Plunging 
        am = 1/(km1*P^0.18*sqrt(Sslp));
    else
        % Surging 
        am = 1/(km2*P^0.18*Sslp^(0.5-P)*sm^(-P/3)); 
    end
    
    %% COMPUTE MEDIAN STONE SIZE FOR STABLISHED DAMAGE LIMIT STATE
    % Median Stone Size 
    Dn50_Melby = sqrt(Mf/delta)*h*am*((ks*sqrt(Nz))/S)^0.2;
    
else
%     error('Check H or h for negative values')
    Dn50_Melby = NaN;
end


%% Low Crested
% From Burcharth et al 2006 - stability of low crested structures. 
% Equation 5.
% Assume same armor layer size for the whole structure and is valid for -3
% <= Rc/Dn_50 < 2 and slope 1:1.5 exposed to non-depth limited waves, and
% slopes 1:2 exposed to depth limited short-crested waves. 
% Hard coded Coeff


a = 1.36; 

if ((Hsig>0.1) & (h>0)) % ALS updated (depth>0) to (h>0)
    % Compute freeboard of structure
%     Rc = CrestEle - h; 
    if Rc <0
        Rc = 0; 
    end
             
    Dn50_LCBW=Hsig/Delta/1.75; 
    
    m=Rc/Dn50_LCBW; 
    Dn50_LCBW(m<-3 || m>=2) = NaN; 
    
else 
    Dn50_LCBW=NaN; 
end


%% Ahrens 1989 reef breakwaters
% Need to relate damate limit state S with N_s_star or K
% N_s_star is from Gravensen et al (1980), while N_s is from Hudson (1959)

% Dn50_Ahrens89 = ((Hsig^2 * Lm)^(1/3))/(N_s_star *(W_r/W_w)-1);
% Dn50_Ahrens89 = (W_50/W_r)^(1/3); 

%% Burcharth RoT (eq 8)
%valid for wide range of sumbergence
%inequality, but minimum is equal. h_c is breakwater height. For gentle foreshore slope

% Dn50_BurcharthRoT = 0.28*(Rc+h); 



