function[DamDepth]=Damaging_Depth_v02212023(SPdepth,Hm0,Tp,SWL,Ks)
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
    Damaging_Depth_v02212023.m

DESCRIPTION:
    Function to compute damaging depth as the total water column height from 
    the topographic surface to the peak of the controlling wave height.  The 
    controlling wave height is defined as the average height of the highest 
    1-percent of waves during storm conditions. It is crudely limited to
    the theoretical breaker limit on a flat bottom which is 78 percent of the 
    local storm depth. Further, 70 percent of the controlling wave height is 
    assumed to lie above the SWL, resulting in the wave crest elevation being 
    above the SWL by 0.55 times the depth of the SWL, or 1.55 times the local 
    depth of the SWL above the ground elevation.

INPUT/OUTPUT ARGUMENTS:
    SPdepth: datum depth of save point
    Hm0: zero moment significant wave height
    Tp:  peak wave period
    SWL: total water level
    Ks: Shielding parameter
        1 for 0 - 1 rows of buildings
        0.7 for 2 - 3 rows of buildings
        0.5 for 5 - 5 rows of buildings
        0.3 for >= 6 rows of buildings

AUTHORS:
    Jeffrey A. Melby (JAM)

POC: 
	Paul.Atreides@usace.army.mil   
	U.S. Army Engineer Research & Development Center 
	Coastal & Hydraulics Laboratory                  
	Vicksburg, MS                                   

HISTORY OF REVISIONS:

***************  ALPHA  VERSION  **  FOR INTERNAL TESTING ONLY ************
%}

cond = Hm0<=0 | Tp<=0 | SWL<=-100 | isnan(Hm0) | isnan(Tp) | isnan(SWL);% (h+SWL)<0

% The following is the old approach as in, for example, ASCE7
% Approximate 1% Hm0 using Rayleigh Distribution assumption
Total_SWL_depth = SPdepth + SWL;
MaxDD = SWL + Ks .* (0.7 .* 0.78 .* Total_SWL_depth); % depth-limited
DamDepth = min(SWL + Ks .* 0.7 .* 1.6 .* Hm0, MaxDD);
% Do not calculate structure response if no storm forcing
DamDepth(cond) = NaN;
% Alternative approach



end