%function [Kt]= Wave_Transmission_All(Hm0,Tp,beta,Rc,Dn50,B,tana,ht,grav,struc_type)
function [Kt]= eurotop_wave_transmission(Hm0,Tp,Rc,B,tana,grav)
%{
LICENSING:
    This code is part of StormSim software suite developed by the U.S. Army
    Engineer Research and Development Center Coastal and Hydraulics
    Laboratory (hereinafter “ERDC-CHL”). This material is distributed in
    accordance with DoD Instruction 5230.24. Recipient agrees to abide by
    all notices, and distribution and license markings. The controlling DOD
    office is the U.S. Army Engineer Research and Development Center
    (hereinafter, "ERDC"). This material shall be handled and maintained in
    accordance with For Official Use Only, Export Control, and AR 380-19
    requirements. ERDC-CHL retains all right, title and interest in
    StormSim and any portion thereof and in all copies, modifications and
    derivative works of StormSim and any portions thereof including,
    without limitation, all rights to patent, copyright, trade secret,
    trademark and other proprietary or intellectual property rights.
    Recipient has no rights, by license or otherwise, to use, disclose or
    disseminate StormSim, in whole or in part.

DISCLAIMER:
    STORMSIM IS PROVIDED “AS IS” BY ERDC-CHL AND THE RESPECTIVE COPYRIGHT
    HOLDERS. ERDC-CHL MAKES NO OTHER WARRANTIES WHATSOEVER EITHER EXPRESS
    OR IMPLIED WITH RESPECT TO STORMSIM OR ANYTHING PROVIDED BY ERDC-CHL,
    AND EXPRESSLY DISCLAIMS ALL WARRANTIES OF ANY KIND, EITHER EXPRESSED OR
    IMPLIED, INCLUDING WITHOUT LIMITATION, WARRANTIES OF MERCHANTABILITY,
    NON-INFRINGEMENT, FITNESS FOR A PARTICULAR PURPOSE, FREEDOM FROM BUGS,
    CORRECTNESS, ACCURACY, RELIABILITY, AND RESULTS, AND REGARDING THE USE
    AND RESULTS OF THE USE, AND THAT THE ASSOCIATED SOFTWARE’S USE WILL BE
    UNINTERRUPTED. ERDC-CHL DISCLAIMS ALL WARRANTIES AND LIABILITIES
    REGARDING THIRD PARTY SOFTWARE, IF PRESENT IN STORMSIM, AND DISTRIBUTES
    IT “AS IS.” RECIPIENT AGREES TO WAIVE ANY AND ALL CLAIMS AGAINST
    ERDC-CHL, THE UNITED STATES GOVERNMENT AND ITS CONTRACTORS AND
    SUBCONTRACTORS, AND SHALL INDEMNIFY AND HOLD HARMLESS ERDC-CHL, THE
    UNITED STATES GOVERNMENT AND ITS CONTRACTORS AND SUBCONTRACTORS FOR ANY
    LIABILITIES, DEMANDS, DAMAGES.

SOFTWARE NAME:
    Wave_Transmission_All.m

DESCRIPTION:
    Function to Wave transmission due to overtopping according to 
    1. CEM Table VI-5-15, pg VI-5-47
    2. EurOtop II Manual pg 65, Eq 4.7
    3. Goda LCS (originally from Goda and Ahrens) pg 150, 
    Eq 3.60-3.62, Random Seas and Design of Maritime Structures
Compared the various equations for Midbay and Goda and EurOtop seem
reasonable, CEM not.  Goda Beff is a bit strange. For eample, if SWL is
just above crest vs just below, eq gives very different results. Probably
better to just use Beff=B when SWL near crest.  Also, any eq with Dn50 in
it creates problems because Dn50 can change a lot depending on
conventional, low-crest or reef.  So Decided to comment everything but
EurOtop equation.


INPUT/OUTPUT ARGUMENTS:
    Hm0: incident zero moment significant wave height
    Dn50:  Seaside armor stone size
    beta: wave angle, 0<beta<70 deg
    Tp:  peak wave period
    Rc: Freeboard
    B: Crest Width

AUTHORS:
    Jeffrey A. Melby (JAM)

HISTORY OF REVISIONS:

***************  ALPHA  VERSION  **  FOR INTERNAL TESTING ONLY ************
%}
var_shape = size(Tp);
Hm0 = Hm0(:);
Tp = Tp(:);
Rc = Rc(:);
L0p = grav*Tp.^2/2/pi;
s0p = Hm0./L0p;
xsi = tana/sqrt(s0p);
% HonD(:, 1) = Hm0/Dn50;
% RonD(:, 1) = Rc/Dn50;
% BonD(:, 1) = B/Dn50;
RonH(:, 1) = Rc./Hm0;
BonH(:, 1) = B./Hm0;

% The expectation is that exceptions are handled outside of routine
% so, for example, negative Hm0 has already been set to NaN.

% switch struc_type
%     case 2 %vertical wall
% %       Kt = 0.45-0.3*RonH %EurOtop pg 68, eq 4.9 
%         Kt=exp(-(1.14+1.16*RonH)); % Goda book pg 147, eq 3.57 from Alberti et al.
%     case 3 %conventional rubble mound CEM
%         b = -5.42*s0p + 0.0323*HonD - 0.0017*BonD^1.84 + 0.51;
%         Kt = (0.031*HonD - 0.24)*RonD + b;
%         Kt(Kt>0.75) = 0.75;
%         Kt(Kt<0) = 0.0;
%     case 4  %Reef CEM
%         b = -2.6*sop - 0.05*HonD + 0.85;
%         Kt = (0.031*HonD - 0.24)*RonD + b;
%         Kt(Kt>0.60) = 0.60;
%         Kt(Kt<0) = 0.0;
%     case 5 %EurOtop
%         if Dn50==0 %smooth structure?
%             Kt = (-0.3*RonH + 0.75*(1-exp(-0.5*xsi)))*(cos(beta))^(2/3);
%         else
            temp1=(1.-exp(-0.5*xsi))';
            Kt = -0.4*RonH + (0.64*BonH.^-0.31).*temp1;
%         end
%     case 6 %LCS, Goda
%         C=zeros(size(Rc));
%         indx_posR=find(Rc>0);
%         indx_negR=find(Rc<0);
%         indx_zerR=find(Rc=0);
%         C(indx_posR)=B+2*Rc(indx_posR)/tana; %width at SWL
%         C(indx_negR)=B+2*ht/tana; %ave width
%         C(indx_zerR)=B+2*ht/tana;
%         Beff(indx_posR)=C(indx_posR);
%         Beff(indx_negR)=(4*B+C(indx_negR))/5;
%         Beff(indx_zerR)=(9*B+C(indx_zerR))/10;
%         if Dn50==0 %smooth structure?
%             F0 = 1;
%         else
%             F0 = max(0.5, min(1,HonD));
%         end
%         a = 0.248*exp(-0.384*ln(Beff/L0p));
%         Kt = max(0,1 - exp(a*(RonH - F0)));
%     otherwise
%         error('Unsupported  structure type.');
% end
%Kt(abs(beta)>0.70) = 0.0; %highly oblique waves
Kt(Kt>0.80) = 0.80;
Kt(Kt<0) = 0.0;
% Resahpe Variables
Kt = reshape(Kt, var_shape);
end