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
    ZeroSeaDamFunc.m

CALLED BY:
    CSR_timeseries_DLL3.m

SCRIPT PATH:
    Functions\Damage_Calc

PURPOSE:
    This script computes the damage initiation value for the structure.


INPUTS:
    |   Vars Name   |  Vars Type  |               Description                |
    |---------------|-------------|------------------------------------------|
    |      Tm       |   double    |  Mean Wave Period [s].                   |
    |---------------|-------------|------------------------------------------|
    |     Hsig      |   double    |  Significant Wave Height [m].            |
    |---------------|-------------|------------------------------------------|
    |     Sslp      |   double    |  Cot Of Seaside Slope.                   |
    |---------------|-------------|------------------------------------------|
    |     grav      |   double    |  Acceleration Of Gravity [m/s^2].        |
    |---------------|-------------|------------------------------------------|
    |     SDn       |   double    |  Armor Stone Nominal Size [m].           |
    |---------------|-------------|------------------------------------------|
    |      Nz       |   double    |  Number of Waves [duration/Tm].          |
    |---------------|-------------|------------------------------------------|
    |     depth     |   double    |  Water Column Near Toe [m].              |
    |---------------|-------------|------------------------------------------|
    |       P       |   double    |  Structure Notional Permeability.        |
    |---------------|-------------|------------------------------------------|
    |      km1      |   double    |  Seaside empirical coefficient.          |
    |---------------|-------------|------------------------------------------|
    |       SG      |   double    |  Armor Stone Specific Gravity.           |
    |---------------|-------------|------------------------------------------|
    |     SLast     |   double    |  Damage state from previous time step    |
    |---------------|-------------|------------------------------------------|

OUTPUTS:
    |   Vars Name   |  Vars Type  |               Description                |
    |---------------|-------------|------------------------------------------|
    |    Szero      |    Double   |   Damage initiation variable.            |
    |               |             |   S = Ae/Dn^2.                           |
    |---------------|-------------|------------------------------------------|

EXTERNAL FUNCTIONS:
    Wave Transformation:
        wavnum1_VG(Tp,h,grav)
    
AUTHORS:
    By:  Jeffrey A. Melby, PhD,
    
MODIFICATIONS:
    |   DATE (mm/dd/yyyy)   |      EDITOR      |         SUMMARY               |
    |-----------------------|------------------|-------------------------------|
    |      06/05/2020       |   Fabian Garcia  |  Code optimization,clean-up,  |
    |                       |                  |  and incorporation onto       |
    |                       |                  |  streamlined workflow.        |
    |-----------------------|------------------|-------------------------------|
    
RELEVANT PUBLICATIONS:
    Source Material:
        (01) Melby, J. A. 1999. Damage Progression on Breakwaters. Dissertation in partial fulfillment of PhD.
                Newark, Delaware: University of Delaware.
        (02) Melby, J. A. 2009. “Time-Dependent Life-Cycle Analysis of Coastal Structures.
                ”Proceedings of Coastal Structures 2007, 1842–1853. Singapore: World Scientific.
        (03) Melby, J. A., and S. A. Hughes. 2004. “Armor Stability Based on Wave Momentum Flux.
                ”Proceedings of Coastal Structures 2003, 53–65. Reston, VA: ASCE.
        (04) Melby, J. A., and N. K. Kobayashi. 2011. “Stone Armor Damage Initiation and Progression.
                Journal of Coastal Research 27(1): 110–119.
        (05) Van Gent, M. R. A., and B. Pozueta. 2005. “Rear-Side Stability of Rubble Mound Structures.
                ”Coastal Engineering 2004, 3481–93. World Scientific Publishing Company.
    Application Of Methodology:
        (01) Gonzalez, Victor M. et. al. 2020. "Alabama Barrier Island Restauration Assesment life-cycle
                structure response modeling." ERDC/CHL TR-20-5. Vicksburg, MS: US Army Engineer Research
                and Development Center.
 
%}

function [Szero] = ZeroSeaDamFunc(Hsig,depth,Tm,S_last,Sslp,SDn,SG,grav,P,Nz,km1,km2,Ks)
%% DEFINE EMPIRICAL COEFFICIENTS

%% DAMAGE INITIATION (Szero) COMPUTATION
if ((Hsig~=0) && (depth>0))
    %% DEFINE WATER COLUM AND WAVE PARAMETERS
    % Define Water Column
    h = depth;
    % Estimate Wave Number
    [km,kmest,error] = wavnum1_VG(Tm,h,grav);
    % Compute Wave Length
    Lm = 2*pi/km;
    % Compute Wave Steepness
    sm = Hsig/Lm;
    % Determine Critical Wave Steepness
    smc = Sslp^-3;
    
    %% MOMENTUM FLUX COMPUTATIONS
    A0 = 0.639*(Hsig/h)^2.026;
    A1 = 0.180*(Hsig/h)^-0.391;
    Mf = A0*(h/grav/Tm^2)^-A1;
    
    %% DETERMINE am RELATIONSHIP TO USE BASED ON WAVE STEEPNESS
    if sm>=smc
       am = 1/(km1*P^0.18*sqrt(Sslp)); %plunging
    else
       am = 1/(5.0*P^0.18*Sslp^(0.5-P)*sm^(-P/3)); %surging
    end
    
    %% COMPUTE Nm & Szero
    Nm = sqrt(Mf/(SG-1)) * h/SDn;
    Szero = Ks*sqrt(Nz)*(am*Nm)^5;
    
else
    % No Damage Initiation
    Szero = 0;
end

end