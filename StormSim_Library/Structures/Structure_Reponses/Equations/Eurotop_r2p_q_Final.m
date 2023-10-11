function [R2p, R2p_SWL, q, q_overflow, q_wave_ot]=Eurotop_r2p_q_Final(Hm0, Tp, SWL,...
    Rc, slope, gamma_f, gamma_beta_r2p, gamma_beta_OT, ...
    gamma_star, gamma_v, gamma_b, wall_toe, berm_width, structure_type)


%{
 LICENSING:
    This code is part of StormSim software suite developed by the U.S. Army
    Engineer Research and Development Center Coastal and Hydraulics Laboratory
    (hereinafter “ERDC-CHL”). This material is distributed in accordance with DoD
    Instruction 5230.24. Recipient agrees to abide by all notices, and distribution
    and license markings. The controlling DOD office is the U.S. Army Engineer
    Research and Development Center (hereinafter, "ERDC"). This material shall be
    handled and maintained in accordance with For Official Use Only, Export Control,
    and AR 380-19 requirements. ERDC-CHL retains all right, title and interest in
    StormSim and any portion thereof and in all copies, modifications and derivative
    works of StormSim and any portions thereof including, without limitation, all
    rights to patent, copyright, trade secret, trademark and other proprietary or
    intellectual property rights. Recipient has no rights, by license or otherwise, to
    use, disclose or disseminate StormSim, in whole or in part.

DISCLAIMER:
    STORMSIM IS PROVIDED “AS IS” BY ERDC-CHL AND THE RESPECTIVE COPYRIGHT HOLDERS.
    ERDC-CHL MAKES NO OTHER WARRANTIES WHATSOEVER EITHER EXPRESS OR IMPLIED WITH RESPECT
    TO STORMSIM OR ANYTHING PROVIDED BY ERDC-CHL, AND EXPRESSLY DISCLAIMS ALL WARRANTIES
    OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING WITHOUT LIMITATION, WARRANTIES OF
    MERCHANTABILITY, NON-INFRINGEMENT, FITNESS FOR A PARTICULAR PURPOSE, FREEDOM FROM BUGS,
    CORRECTNESS, ACCURACY, RELIABILITY, AND RESULTS, AND REGARDING THE USE AND RESULTS OF THE
    USE, AND THAT THE ASSOCIATED SOFTWARE’S USE WILL BE UNINTERRUPTED. ERDC-CHL DISCLAIMS ALL
    WARRANTIES AND LIABILITIES REGARDING THIRD PARTY SOFTWARE, IF PRESENT IN STORMSIM, AND
    DISTRIBUTES IT “AS IS.” RECIPIENT AGREES TO WAIVE ANY AND ALL CLAIMS AGAINST ERDC-CHL, THE
    UNITED STATES GOVERNMENT AND ITS CONTRACTORS AND SUBCONTRACTORS, AND SHALL INDEMNIFY AND HOLD
    HARMLESS ERDC-CHL, THE UNITED STATES GOVERNMENT AND ITS CONTRACTORS AND SUBCONTRACTORS FOR ANY
    LIABILITIES, DEMANDS, DAMAGES.
                
 SCRIPT NAME:
    Eurotop_r2p_q_Final.m

PURPOSE:        
    Calculates overtopping and runup on levees, and 
    overtopping on floodwalls   
            
INPUTS: 
|   Vars Name   |  Vars Type  |               Description                |
|---------------|-------------|------------------------------------------|
|      Hm0      |    Double   |  Zero moment significant wave height [m] |
|               |             |  (Nstm.*Ndsrt x 1)                        |
|---------------|-------------|------------------------------------------|
|      Tp       |    Double   |  Peak wave period                    [s] |
|               |             |  (Nstm.*Ndsrt x 1)                        |
|---------------|-------------|------------------------------------------|
|      SWL      |    Double   |  Storm water level            [m, datum] |
|               |             |  (Nstm.*Ndsrt x 1)                        |
|---------------|-------------|------------------------------------------|
|       h       |    Double   |  Water depth                         [m] |
|               |             |  (Nstm.*Ndsrt x 1)                        |
|---------------|-------------|------------------------------------------|
|      Rc       |    Double   |  Freeboard                           [m] |
|               |             |  (Nstm.*Ndsrt x 1)                        |
|---------------|-------------|------------------------------------------|                
|    slope      |    Double   |  cot(alpha)                              |
|               |             |  (Nstm.*Ndsrt x 1)                        |
|---------------|-------------|------------------------------------------|                
|    gamma_f    |    Double   |  Influence of surface friction           |
|               |             |  (Nstm.*Ndsrt x 1)                        |
|---------------|-------------|------------------------------------------|
| gamma_beta_r2p|    Double   |  Influence of wave direction on runup    |
|               |             |  (Nstm.*Ndsrt x 1)                        |
|---------------|-------------|------------------------------------------|                
| gamma_beta_OT |    Double   |  Influence of wave direction on          |
|               |             |  overtopping (Nstm.*Ndsrt x 1)            |
|---------------|-------------|------------------------------------------|
|  gamma_star   |    Double   |  Influence of wall on a levee            |
|               |             |  (Nstm.*Ndsrt x 1)                        |
|---------------|-------------|------------------------------------------|                
|   gamma_v     |    Double   |  Influence of wall on a slope            |
|               |             |  (Nstm.*Ndsrt x 1)                        |
|---------------|-------------|------------------------------------------|
|   wall_toe    |    Double   |  Elevation of wall toe        [m, datum] |
|               |             |  (Nstm.*Ndsrt x 1)                        |
|---------------|-------------|------------------------------------------| 
|   BermWidth   |    Double   |  Structure berm width                [m] |
|               |             |  (Nstm.*Ndsrt x 1)                        |
|---------------|-------------|------------------------------------------|  
|  strucType    |    Double   |  Switch (1 for levees, 2 for floodwalls, |
|               |             |  3 for rubble mound) (Nstm.*Ndsrt x 1)    |
|---------------|-------------|------------------------------------------|  

OUTPUTS:
|   Vars Name   |  Vars Type  |               Description                |
|---------------|-------------|------------------------------------------|
|   R2p_final   |    Double   |  Runup calculation for levees + Rubble   |
|               |             |  Mound (Nstm.*Ndsrt x 1)              [m] |
|---------------|-------------|------------------------------------------|
|    q_final    |    Double   |  Overtopping calculation for levees +    |
|               |             |  Rubble Mound (Nstm.*Ndsrt x 1)  [cm./s./m] |
|---------------|-------------|------------------------------------------|

AUTHORS: 
    Abigail L. Stehno and Jeffrey A. Melby, PhD

MODIFICATIONS: 
|  DATE (mm./dd./yyy) |  EDITOR          |          Description             |
|-------------------|------------------|----------------------------------|
|    04./04./19       |  Abigail Stehno  |  Created code from               |
|                   |                  |  Eurotop_r2p_q_v4.m              |  
|-------------------|------------------|----------------------------------|
|    04./08./19       |  Abigail Stehno  |  Updated capabilites, usability  |  
|       to          |                  |  and added rubble mound calcs.   |
|    09./03./20       |                  |  Updated comments                |
|-------------------|------------------|----------------------------------|
|    03./03./21       |  Abigail Stehno  |  Updated for distribution        |
|-------------------|------------------|----------------------------------|
|    05./28./21       |  Abigail Stehno  |  Updated for distribution more   |
|-------------------|------------------|----------------------------------|  
|    06./14./21       |  Abigail Stehno  |  Corrected rubble mound calc     |
|-------------------|------------------|----------------------------------| 
NOTES: 
If there is a foreshore influence: no significant mound is considered,non-
    impulsive is assumed, and no composite structures are considered.
Does not include battered wall types
Emergent toe of wall is considered a wall on embankment
Cr value is not considered for armored crests. See EurOtop Eq 6.8 for info.
Assume no berm influence 
                
REFERENCES:
   EurOtop - Wave Overtopping of Sea Defences and Related Structures:  
        Assessment Manual, August 2018.  
        http:././www.overtopping-manual.com./eurotop.pdf
%}

%% VECTORIZE INPUTS
data_dims = size(SWL);
Hm0 = Hm0(:);
SWL = SWL(:);
Tp = Tp(:);
Rc = Rc(:);
gamma_f = gamma_f(:);
gamma_beta_r2p = gamma_beta_r2p(:);
gamma_beta_OT = gamma_beta_OT(:);
gamma_star = gamma_star(:);
gamma_v = gamma_v(:);
gamma_b = gamma_b(:);

%% Define variables
g = 9.80665;                            % gravitational acceleration
T_m10 = Tp/1.1;                         % neg zero moment period tm_1,0
L_m10 = g*T_m10.^2 /(2*pi);              % Zero moment wave length
s_m10 = Hm0./L_m10;                      % Wave steepness
breaker_m10 = (1/slope)./sqrt(s_m10);    % Breaker parameter

% Assume no berm!
%     gamma_b = 1;

%% Negative freeboard influence
% Initialize Variables
q_overflow = zeros(size(Rc));
Rc_corrt = zeros(size(Rc));
% Compute Overflow When Strcuture Is Submerged
q_overflow(Rc<=0) = 0.54 * sqrt(g*abs(Rc(Rc<=0)).^3);% EurOtop Eq 5.20
%
Rc_corrt(Rc>0) = Rc(Rc>0);

%% Runup and overtopping loop
if slope > 0.1 &&  structure_type==1  % slope cota > 1 ->  (levee)
    %     disp('      Calculating Levee Overtopping and Runup...')
    % Embankment coefficients
    runup_coeff1 = 1.65; % EurOtop Eq 5.1
    runup_coeff2 = 1.00; % EurOtop Eq 5.2
    runup_coeff3 = 0.80; % EurOtop Eq 5.6

    OT_coeff1 = 0.023;   % EurOtop Eq 5.10
    OT_coeff2 = 2.700;   % EurOtop Eq 5.10
    OT_coeff3 = 0.090;   % EurOtop Eq 5.11
    OT_coeff4 = 1.500;   % EurOtop Eq 5.11

    if slope > 2
        % EurOtop Runup Eq 5.1 and 5.2
        R2p_a = Hm0.*runup_coeff1.*gamma_b.*gamma_f.*gamma_beta_r2p.*breaker_m10;
        R2p_max = Hm0.*runup_coeff2.*gamma_f.*gamma_beta_r2p.*...
            (4-1.5./sqrt(gamma_b.*breaker_m10));
        R2p = zeros(size(SWL));
        R2p(R2p_max>0) = min([R2p_a(R2p_max>0),R2p_max(R2p_max>0)],[],2,"omitnan");
        R2p(R2p_max<=0) = R2p_a(R2p_max<=0);

        % EurOtop Overtopping Eq 5.10 and 5.11
        q_a = sqrt(g.*Hm0.^3).*OT_coeff1./sqrt(1./slope).*gamma_b.*...
            breaker_m10.*exp(-(OT_coeff2.*Rc_corrt./breaker_m10./Hm0./...
            gamma_b./gamma_f./gamma_beta_OT./gamma_v).^1.3);

        q_max = sqrt(g.*Hm0.^3).*OT_coeff3.*...
            exp(-(OT_coeff4.*Rc_corrt./Hm0./gamma_f./gamma_beta_OT./...
            gamma_star).^1.3);
        %
        q_wave_ot = min([q_max,q_a],[],2,"omitnan");
    else % cota between 1:2 and 1:1 - embankment to vertical wall
        % EurOtop Runup Eq 5.6
        R2p_a = min([Hm0.*runup_coeff3./(1./slope) + 1.6 , (3.*Hm0)],[],2,"omitnan");
        R2p = max([zeros(size(SWL)),max([R2p_a,(1.8.*Hm0)],[],2,"omitnan")],[],2,"omitnan");

        % EurOtop Overtopping eq 5.18- assumes only smooth slopes
        a_a = (0.09 - 0.01.*(2-(1./slope)).^2.1);
        a = a_a+(a_a.*0.15.*randn);
        b_a = min((1.5+0.42.*(2-(1./slope)).^1.5),2.35);
        b = b_a+(b_a.*0.10.*randn);
        q_wave_ot = sqrt(g.*Hm0.^3).*a.*exp(-(b.*Rc_corrt./Hm0./gamma_beta_OT).^1.3);
    end
elseif slope > 0.1 &&  structure_type==3 % rubble mound
    %     disp('      Calculating Rubble Mound Overtopping and Runup...')
    % Embankment coefficients
    runup_coeff1 = 1.65; % EurOtop Eq 6.1
    runup_coeff2 = 1.00; % EurOtop Eq 6.1

    OT_coeff3 = 0.090;   % EurOtop Eq 6.5
    OT_coeff4 = 1.500;   % EurOtop Eq 6.5

    % gamma_f modifications
    gamma_f_surge = gamma_f;
    % May need to include a switch for user to turn on./off
    rIndx = breaker_m10 > 1.8 & breaker_m10 < 10;
    % EurOtop Eq. 6.1
    gamma_f_surge(rIndx) = gamma_f(rIndx) + (breaker_m10(rIndx)-1.8).*(1-gamma_f(rIndx))./8.2;
    % For overtopping, if there is a berm gamma_f is changed to gamma_BB in the
    % equations- assume hardly and partly reshaping berm breakwaters

    % Will also take care of instances where structure has steep slopes
    if berm_width > 0 % EurOtop Eq 6.11 - gamma_f is not used for berm structures
        gamma_f_orBB =  max([repmat(0.6,size(SWL)), 0.68-4.1.*s_m10-0.05.*berm_width./Hm0],[],2,"omitnan"); % Max influence is 0.6
    else
        gamma_f_orBB = ones(size(SWL));
    end
    % EurOtop Eq. 6.7 - gamma_f
    rIndx = breaker_m10 > 5 & breaker_m10 < 10;
    gamma_f_orBB(rIndx) = gamma_f(rIndx) + (breaker_m10(rIndx)-5).*(1-gamma_f(rIndx))./5;

    % EurOtop Runup Eq 6.1
    %%% Maximum Ru2%./Hm0 = 3 for impermeable and 2.0 for permeable

    R2p_a = Hm0.*runup_coeff1.*gamma_b.*gamma_f_surge.*gamma_beta_r2p.*breaker_m10;
    R2p_max = Hm0.*runup_coeff2.*gamma_f_surge.*gamma_beta_r2p.*...
        (4-1.5./sqrt(gamma_b.*breaker_m10));
    R2p = zeros(size(SWL));
    R2p(R2p_max>0) = min([R2p_a(R2p_max>0),R2p_max(R2p_max>0)],[],2,"omitnan");
    R2p(R2p_max<=0) = R2p_a(R2p_max<=0);
    q_wave_ot = sqrt(g.*Hm0.^3).*OT_coeff3.*...
        exp(-(OT_coeff4.*Rc_corrt./Hm0./gamma_f_orBB./gamma_beta_OT).^1.3);
else  % If the slope cota = 1 ------> Vertical walls
    %     disp('      Calculating Floodwall Overtopping...')
    R2p = NaN(size(SWL));
    % Vertical wall coefficients
    OT_coeff1 = 0.047 ;%+ 0.007;    % EurOtop Eq 7.1
    OT_coeff2 = 2.350 ;%+ 0.230;    % EurOtop Eq 7.1
    OT_coeff3 = 0.050 ;%+ 0.012;    % EurOtop Eq 7.5
    OT_coeff4 = 2.780 ;%+ 0.170;    % EurOtop Eq 7.5
    OT_coeff5 = 0.011 ;%+ 0.0045;   % EurOtop Eq 7.7 and 7.15
    OT_coeff6 = 0.0014 ;%+ 0.0006;  % EurOtop Eq 7.8 and 7.14

    % Franco equation (for reference)
    % q = sqrt(g.*Hm0.^3).*0.2.*exp(-4.7.*Rc_corrt./Hm0);
    % Sumberged depth of wall
    w_depth= SWL-wall_toe;
    % depth above toe mound./berm in front of vertical wall
    d_wall = Rc_corrt- w_depth;
    % Initialize
    q_wave_ot = zeros(size(SWL));
    rIndx = w_depth./Hm0>4;
    % no foreshore influence
    q_wave_ot(rIndx) = sqrt(g.*Hm0(rIndx).^3).*OT_coeff1.*...
        exp(-((OT_coeff2./gamma_beta_OT(rIndx)).*Rc_corrt(rIndx)./Hm0(rIndx)).^1.3);% EurOtop Overtopping Eq 7.1
    % foreshore influence
    q_wave_ot(~rIndx) = sqrt(g.*Hm0(~rIndx).^3).*OT_coeff3.*...
        exp(-(OT_coeff4./gamma_beta_OT(~rIndx)).*Rc_corrt(~rIndx)./Hm0(~rIndx));
end
% 
% q Overflow
q = q_wave_ot + q_overflow;
% Define NaN Index
rIndx = Hm0<=0 | Tp<=0 | SWL<=-100 | isnan(Hm0) | isnan(Tp) | isnan(SWL);
% Do not calculate structure response if no storm forcing
q(rIndx) = NaN;
q_wave_ot(rIndx) = NaN;
q_overflow(rIndx) = NaN;
R2p(rIndx) = NaN;
% Compute R2p + SWL
R2p_SWL = R2p + SWL;
% Reshape
q = reshape(q,data_dims);
q_wave_ot = reshape(q_wave_ot,data_dims);
q_overflow = reshape(q_overflow,data_dims);

R2p = reshape(R2p,data_dims);
R2p_SWL = reshape(R2p_SWL,data_dims);
end

%{
EurOtop notes

% Assumptions:
Equations are determined by emperical formula derived from experiment
The use of Tm1-0 is used to accomodate complex spectral shapes
Wave characteristics are at the toe of the structure

RUNUP:
> Thin layers are not considered run-up (i.e. wind driven layers)
> Runup height is measured when the thickness is approximately <= 2 cm
> Steep slopes up to vertical walls do not consider the influence of wave
  steepness
> Steep slopes up to vertical walls assume maximum Ru2%./Hm0 value in the
  presence of a gentle foreshore and for steep slopes

OVERTOPPING:
> Average overtopping can only be calculated for quasi-stationary wave
  and water level conditions, so for a time series, each set of 
  conditions must be calculated individually (not time dependent) 
> Eq 5.10 and 5.11 are only true for a freeboard >= 0; if the freeboard
  is < 0, assume Rc = 0 for the calculation then use the weir eq
> Eq 5.18 assumes relatively low freeboard, 0.36 < cota < 2.75, smooth 
  slopes, and non-breaking
> Steep slopes up to vertical walls require interpolation of influence
  factors (gamma_beta in particular)
> Overflow eq coefficient 0.54 varies with structure type
> Additional assumptions of overtopping volumes, velocities, and
  thicknesses will be added when that code is implemented

INFLUENCE FACTORS:
> Found using reference tests or well-known formula for comparison, wave
  conditions should be identical
> Roughness (gamma_f)
  - Grass has relatively greater hydraulic roughness for thin wave runup
      depths, gamma_f will be conservative for grass
  - Small Hm0 may effect roughness for all types of material; however,
      standard gamma_f will give a conservative result
> Oblique (gamma_beta)
  - Assume runup and overtopping is equally distributed along the
      longitudinal axis of a dike (this will decrease for convex curves 
      and increase for concave curves; however, this is not quatified)
  - There is limited research for short crested gamma_beta- only 
      0 < beta < 80 has been tested
  - Assume no significant influence of spreading widths for short crested
      waves
  - Assume a reduction in Hm0 and Tp for waves over 80 degrees, reducing
      Hm0 and Tp to zero for angles greater or equal to 110 degrees
> Currents are not currently considered; however, current effect
  definitions were expanded from a limited amount of tests
> Berms (gamma_b)
  - Assume the point of breaking is 1.5 Hm0 below SWL
  - Limitation of gamma_b = 0.6 corresponds to optimal width of 
      B = 0.4.*Lm10 at SWL
> Wave walls (gamma_v and gamma_star)
  - Submerged foot is limited to slopes between 1:2.5 and 1:3.5 and the
      foot of the wall is no lower than 1.2Hm0
  - Wall on top of emerged slope assumes a straight, smooth seaward slope
      of 1:2 or 1:3 (can also be average slope), valid for 
      0.01 < sm1-0 < 0.05, breaker parameter between 2.2-4.8, 
      Rc./Hmo > 0.6, and assumes that other gamma values are valid when
      wall is present (only tested when gamma_f=gamma_beta=gamma_b= 1)
  - Smooth dike slope and a storm wall is applicable for h_wall./Rc = 0.08
      to 1 [ we are assuming all walls are of this nature ] 

SCALE EFFECTS AND UNCERTAINTIES
> There are such large model uncertainties that no other uncertainties
  need to be considered if the full standard deviation is added to the
  coefficients
> Frictional scale effects are not significant if gamma_f > 0.9,
  uncertainties from scale effects for rough slopes is not well defined 

%}
