function [sampled_storms, lcs_data] = sample_xc_storm(storm_peaks, simulation_years, yearly_rate)

%{
LICENSING:
    This code is part of StormSim software suite developed by the U.S. Army
    Engineer Research and Development Center Coastal and Hydraulics Laboratory
    (hereinafter â€œERDC-CHLâ€?). This material is distributed in accordance with DoD
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
    STORMSIM IS PROVIDED â€œAS ISâ€? BY ERDC-CHL AND THE RESPECTIVE COPYRIGHT HOLDERS.
    ERDC-CHL MAKES NO OTHER WARRANTIES WHATSOEVER EITHER EXPRESS OR IMPLIED WITH RESPECT
    TO STORMSIM OR ANYTHING PROVIDED BY ERDC-CHL, AND EXPRESSLY DISCLAIMS ALL WARRANTIES
    OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING WITHOUT LIMITATION, WARRANTIES OF
    MERCHANTABILITY, NON-INFRINGEMENT, FITNESS FOR A PARTICULAR PURPOSE, FREEDOM FROM BUGS,
    CORRECTNESS, ACCURACY, RELIABILITY, AND RESULTS, AND REGARDING THE USE AND RESULTS OF THE
    USE, AND THAT THE ASSOCIATED SOFTWAREâ€™S USE WILL BE UNINTERRUPTED. ERDC-CHL DISCLAIMS ALL
    WARRANTIES AND LIABILITIES REGARDING THIRD PARTY SOFTWARE, IF PRESENT IN STORMSIM, AND
    DISTRIBUTES IT â€œAS IS.â€? RECIPIENT AGREES TO WAIVE ANY AND ALL CLAIMS AGAINST ERDC-CHL, THE
    UNITED STATES GOVERNMENT AND ITS CONTRACTORS AND SUBCONTRACTORS, AND SHALL INDEMNIFY AND HOLD
    HARMLESS ERDC-CHL, THE UNITED STATES GOVERNMENT AND ITS CONTRACTORS AND SUBCONTRACTORS FOR ANY
    LIABILITIES, DEMANDS, DAMAGES.

SCRIPT NAME:
    Sample_XC.m.

CALLED BY:
    MCS_DLL1.m

PURPOSE:
    This script reads and pre-processes CHS tropical storm data.

INPUTS:
    |   Vars Name   |  Vars Type  |               Description                |
    |---------------|-------------|------------------------------------------|
    |       lc      |   double    |  Number of life cycles                   |
    |---------------|-------------|------------------------------------------|
    |    storm_peaks    |   Double    |  Extra tropical storm response variable  |
    |---------------|-------------|------------------------------------------|
    |  storm_wlp_peaks  |   Double    |  Extra tropical storm response variable  |
    |               |             |  - water level priority                  |
    |---------------|-------------|------------------------------------------|
    |  storm_whp_peaks  |   Double    |  Extra tropical storm response variable  |
    |               |             |  - wave height priority                  |
    |---------------|-------------|------------------------------------------|
    |    simulation_years     |   Double    |  Extra tropical storm response variable  |
    |---------------|-------------|------------------------------------------|
    |    XC_Nstm    |   Double    |  Number of storms in storm data          |
    |---------------|-------------|------------------------------------------|
    |    XC_Nyrs    |   Double    |  Number of years of storm data           |
    |---------------|-------------|------------------------------------------|
    |    SIM_Flag   |   Double    |  Simulation flag to ensure sampled storms|
    |               |             |  match sampling rate                     |
    |---------------|-------------|------------------------------------------|    
       
OUTPUTS:
    |   Vars Name      |  Vars Type  |               Description                |
    |------------------|-------------|------------------------------------------|
    |    INDEX_XC_TS   |   Double    |  Sampled Storm Indexes                   |
    |------------------|-------------|------------------------------------------|
    | LC_MCSimOUT_XC   |   Double    |  Life Cycle Data Structure - Maximums    |
    |------------------|-------------|------------------------------------------|
    |LC_MCSimOUT_XC_WHP|   Double    |  Life Cycle Data Structure               |
    |                  |             |  - wave height priority                  |
    |------------------|-------------|------------------------------------------|
    |LC_MCSimOUT_XC_WLP|   Double    |  Life Cycle Data Structure               |
    |                  |             |  - water level priority                  |
    |------------------|-------------|------------------------------------------|


OUTPUTS HEADERS:
    LC_MCSimOUT_XC, LC_MCSimOUT_XC_WHP, LC_MCSimOUT_XC_WLP :
        Size (# of LC's, 8) -> (Rows,Col)
            (01) Storm ID                       [-]
            (02) Storm type                     [0 = extratropical]
            (03) Storm Year                     [-]
            (04) Number of storm in storm year  [-]
            (05) Water Level                    [meters, MSL]
            (06) Wave Height                    [meters]
            (07) Peak Wave Period               [seconds]
            (08) Wave Direction                 [degrees; N=0, E=+90, S=+/-180, W=-90]
            


EXTERNAL FUNCTIONS:
    import_options_ADCIRC_peaks(Peaks_CHS_CSV_filename)
    storm type flag => (0 - tropicals, 1 - extratropicals)
    import_options_waves_peaks(Peaks_CHS_CSV_filename)

AUTHORS:
    By: Norberto C. Nadal-Caraballo, PhD,
    Victor M. Gonzalez,PE, Fabian A. Garcia-Moreno

MODIFICATIONS:
    |   DATE (yyyy-mm-dd)   |      EDITOR      |         SUMMARY               |
    |-----------------------|------------------|-------------------------------|
    |      2021-03-02       |   Abigail Stehno |  Created function for storm   |
    |                       |                  |  sampling - xtrops            |
    |-----------------------|------------------|-------------------------------| 
RELEVANT PUBLICATIONS:
    Source Material:
        TBD
    Application Of Methodology:
        (01) Gonzalez, Victor M. et. al. 2020. "Alabama Barrier Island Restauration Assesment life-cycle
                structure response modeling." ERDC/CHL TR-20-5. Vicksburg, MS: US Army Engineer Research
                and Development Center.
%}

%% DEFINE INPUTS
% Simulation flag, internal. Stops two 'while' loops below to ensure sampled
% storms match sampling rate.
if simulation_years == 1e5
    SIM_Flag = 1e-4;
else
    SIM_Flag = 10^-(log10(simulation_years));
end

%% POISSON PROCESS
% Rate of extratropical cyclones (storms/year)
XC_lambda = yearly_rate;
% Make Distribuition Object
XC_pd = makedist('Poisson','lambda',XC_lambda);
% Initializing While Loop Exit Trigger
XC_EPY=0;
% Insert Comment
while abs(XC_EPY-XC_lambda)>SIM_Flag %cannot be higher than Nsimulation_years
    XC_MCS = random(XC_pd,[simulation_years,1]);%sampled number of storms based on Poisson distribution
    XC_EPY = sum(XC_MCS)/simulation_years;
end

%% SAMPLE XC STORM IDs
n=1; clear SimOUT_XC
for j = 1:simulation_years
    if (XC_MCS(j,1)>0)
        m=1;
        for k = 1:XC_MCS(j,1)
            % Storm Year
            SimOUT_XC(n,2) = j;
            % Storm intensity (0 = Extratropical, 1,2,3 = tropical cyclones (low, mid, high))
            SimOUT_XC(n,1) = 0;
            % Number of Storm In Storm Year
            SimOUT_XC(n,3) = m;
            % Sample Random Storm
            XC_INDEX(n,1) = randsample(storm_peaks(:,1), 1);
            % Increment Storm
            n=n+1;
            % Increment Number Of Storm In Storm Year
            m=m+1;
        end%for k
    end%if
end%for j
% Call Copula Sampler [ SSL, Hm0, Tp, wDir, storm_IDs ]
[Y] = copula_sampler(storm_peaks(:, 2:5), XC_INDEX);
% Get Storm Rows To Pull
[~, stm_2_pull] = find(cell2mat(arrayfun(@(x) XC_INDEX == x, storm_peaks(:, 1), 'un', false)'));
% Monte Carlo Simulation Outputs (Sample Extratropical Storms Peaks)
lcs_data = [XC_INDEX, SimOUT_XC, Y, storm_peaks(stm_2_pull, end)]; % Headers: [ storm_IDs, intensity_bin, Sim_Year, yearly_ocurrance_order, SSL, Hm0, Tp, wDir, storm_duration ]
% Sampled Storm Indexes (For Timeseries LC Creation)
sampled_storms = [XC_INDEX, SimOUT_XC]; % [ storm_IDs, intensity_bin, Sim_Year, yearly_ocurrance_order ]

end
