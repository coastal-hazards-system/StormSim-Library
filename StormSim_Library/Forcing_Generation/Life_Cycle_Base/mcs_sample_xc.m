function [INDEX_XC_TS,LC_MCSimOUT_XC,LC_MCSimOUT_XC_WLP,LC_MCSimOUT_XC_WHP] = ...
        mcs_sample_xc(storm,simulation_years,XC_Nstm,XC_Nyrs,WLP_switch,WHP_switch)

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
        (01) Storm Year                     [-]
        (02) Storm type                     [0 = extratropical]
        (03) Number of storm in storm year  [-]
        (04) Water Level                    [meters, MSL]
        (05) Wave Height                    [meters]
        (06) Peak Wave Period               [seconds]
        (07) Wave Direction                 [degrees; N=0, E=+90, S=+/-180, W=-90]
        (08) Storm ID                       [-]


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
    % Maxima Dataset
    storm_peaks = storm.('XC').('Maxima');
    % WLP Dataset
    storm_wlp_peaks = storm.('XC').('WLP');
    % WHp Datasets
    storm_whp_peaks = storm.('XC').('WHP');
    
    %% POISSON PROCESS
    % Rate of extratropical cyclones (storms/year)
    XC_lambda = XC_Nstm/XC_Nyrs;
    % Make Distribuition Object
    XC_pd = makedist('Poisson','lambda',XC_lambda);
    % Initializing While Loop Exit Trigger
    XC_EPY=0;
    % Insert Comment
    while abs(XC_EPY-XC_lambda)>SIM_Flag %cannot be higher than Nsimulation_years
        XC_MCS = random(XC_pd,[simulation_years,1]);%sampled number of storms based on Poisson distribution
        XC_EPY = sum(XC_MCS)/simulation_years;
    end

    %% SAMPLE EXTRATROPICAL STORMS
    n=1; clear SimOUT_XC
    for j = 1:simulation_years
        if (XC_MCS(j,1)>0)
            m=1;
            for k = 1:XC_MCS(j,1)
                % Storm Year
                SimOUT_XC(n,1) = j;
                % Storm Type (0 = Extratropical)
                SimOUT_XC(n,2) = 0;
                % Number of Storm In Storm Year
                SimOUT_XC(n,3) = m;
                % Sample Random Storm
                XC_INDEX(n,1) = randsample(storm_peaks(:,5),1);
                % Increment Storm
                n=n+1;
                % Increment Number Of Storm In Storm Year
                m=m+1;
            end%for k
        end%if
    end%for j

    %% SAMPLE EXTRATROPICAL STORM PARAMETERS FROM GAUSSIAN COPULA
    %% COMPUTE GAUSSIAN COPULA STATISTICAL PARAMETERS
    % Returns a probability density estimate, f, for each sample data column
    for k = 1:4
        % Maximums
        X(:,k) = ksdensity(storm_peaks(:,k),storm_peaks(:,k),'function','cdf');
        if WLP_switch == 1
            % Water Level Priority
            X_WLP(:,k) = ksdensity(storm_wlp_peaks(:,k),storm_wlp_peaks(:,k),'function','cdf');
        end
        if WHP_switch == 1
            % Wave Height Priority
            X_WHP(:,k) = ksdensity(storm_whp_peaks(:,k),storm_whp_peaks(:,k),'function','cdf');
        end
    end

    % Compute Tau
    Tau = corr(X,'type','Kendall'); % Maximums
    % Compute matrix of linear correlations (Rho)
    Rho = copulaparam('Gaussian',Tau,'type','Kendall'); % Maximums
    % Compute random values; where 'r' = normal probabilities (pdf)
    %sample random values from Gaussian copula
    r = copularnd('Gaussian',Rho,size(SimOUT_XC,1)); % Maximums
    %%% WLP
    if WLP_switch == 1
        % Compute Tau
        Tau_WLP = corr(X_WLP,'type','Kendall'); % Water Level Priority
        % Compute matrix of linear correlations (Rho)
        Rho_WLP = copulaparam('Gaussian',Tau_WLP,'type','Kendall'); % Water Level Priority
        % Compute random values; where 'r' = normal probabilities (pdf)
        %sample random values from Gaussian copula
        r_WLP = copularnd('Gaussian',Rho_WLP,size(SimOUT_XC,1)); % Water Level Priority
    end
    %%% WHP
    if WHP_switch == 1
        % Compute Tau
        Tau_WHP = corr(X_WHP,'type','Kendall'); % Wave Height Priority
        % Compute matrix of linear correlations (Rho)
        Rho_WHP = copulaparam('Gaussian',Tau_WHP,'type','Kendall'); % Wave Height Priority
        % Compute random values; where 'r' = normal probabilities (pdf)
        %sample random values from Gaussian copula
        r_WHP = copularnd('Gaussian',Rho_WHP,size(SimOUT_XC,1)); % Wave Height Priority
    end




    % Computes 'inverse cumulative probability' (real values)
    for k = 1:4
        % Maximums
        Y(:,k) = ksdensity(storm_peaks(:,k),r(:,k),'function','icdf');
        if WLP_switch == 1
            % Water Level Priority
            Y_WLP(:,k) = ksdensity(storm_wlp_peaks(:,k),r_WLP(:,k),'function','icdf');
        end
        if WHP_switch == 1
            % Wave Height Priority
            Y_WHP(:,k) = ksdensity(storm_whp_peaks(:,k),r_WHP(:,k),'function','icdf');
        end
    end

    %% SAMPLE STORM PARAMETERS FROM GAUSSIAN COPULA - WORST CASE SCENARIO
    % Compute Water Level
    Y(:,1) = Y(:,1)*nanmean(storm_peaks(:,1))/nanmean(Y(:,1));
    % Compute Wave Height
    Y(:,2) = Y(:,2)*nanmean(storm_peaks(:,2))/nanmean(Y(:,2));
    % Compute Wave Period
    Y(:,3) = Y(:,3)*nanmean(storm_peaks(:,3))/nanmean(Y(:,3));
    % Compute Wave Direction
    Y(:,4) = Y(:,4)*nanstd(storm_peaks(:,4))/nanstd(Y(:,4));
    % Assign Sampled Extratropical Storm Indexes
    Y(:,5)= XC_INDEX;
    % Cap sampled waves to positive values
    Y(Y(:,2)<0.05,2)=0.05;

    %% SAMPLE STORM PARAMETERS FROM GAUSSIAN COPULA - WATER LEVEL PRIORITY
    if WLP_switch ==  1
        % Compute Water Level
        Y_WLP(:,1) =Y_WLP(:,1)*nanmean(storm_wlp_peaks(:,1))/nanmean(Y_WLP(:,1));
        % Compute Wave Height
        Y_WLP(:,2) =Y_WLP(:,2)*nanmean(storm_wlp_peaks(:,2))/nanmean(Y_WLP(:,2));
        % Compute Wave Period
        Y_WLP(:,3) =Y_WLP(:,3)*nanmean(storm_wlp_peaks(:,3))/nanmean(Y_WLP(:,3));
        % Compute Wave Direction
        Y_WLP(:,4) =Y_WLP(:,4)*nanstd(storm_wlp_peaks(:,4))/nanstd(Y_WLP(:,4));
        % Assign Sampled Extratropical Storm Indexes
        Y_WLP(:,5)= XC_INDEX;
        % Cap sampled waves to positive values
        Y_WLP(Y_WLP(:,2)<0.05,2)=0.05;
    end
    %% SAMPLE STORM PARAMETERS FROM GAUSSIAN COPULA - WAVE HEIGHT PRIORITY
    if WHP_switch == 1
        % Compute Water Level
        Y_WHP(:,1) =Y_WHP(:,1)*nanmean(storm_whp_peaks(:,1))/nanmean(Y_WHP(:,1));
        % Compute Wave Height
        Y_WHP(:,2) =Y_WHP(:,2)*nanmean(storm_whp_peaks(:,2))/nanmean(Y_WHP(:,2));
        % Compute Wave Period
        Y_WHP(:,3) =Y_WHP(:,3)*nanmean(storm_whp_peaks(:,3))/nanmean(Y_WHP(:,3));
        % Compute Wave Direction
        Y_WHP(:,4) =Y_WHP(:,4)*nanstd(storm_whp_peaks(:,4))/nanstd(Y_WHP(:,4));
        % Assign Sampled Extratropical Storm Indexes
        Y_WHP(:,5)= XC_INDEX;
        % Cap sampled waves to positive values
        Y_WHP(Y_WHP(:,2)<0.05,2)=0.05;
    end
    %% STORE SAMPLED EXTRATROPICAL STORMS
    % Monte Carlo Simulation Outputs (Sample Extratropical Storms Peaks)
    MCSimOUT_XC = [SimOUT_XC(:,1:3),Y]; % Maximums
    % Sampled Storm Indexes
    INDEX_XC_TS = [SimOUT_XC(:,1:3),XC_INDEX];
    % Assign Outputs To Life Cycle Data Structure
    LC_MCSimOUT_XC=MCSimOUT_XC; % Maximums
    if WLP_switch == 1
        MCSimOUT_XC_WLP = [SimOUT_XC(:,1:3),Y_WLP]; % Water Level Priority
        % Assign Outputs To Life Cycle Data Structure
        LC_MCSimOUT_XC_WLP=MCSimOUT_XC_WLP; % Water Level Priority
    else
        LC_MCSimOUT_XC_WLP = [];
    end
    if WHP_switch == 1
        MCSimOUT_XC_WHP = [SimOUT_XC(:,1:3),Y_WHP]; % Wave Height Priority
        % Assign Outputs To Life Cycle Data Structure
        LC_MCSimOUT_XC_WHP=MCSimOUT_XC_WHP; % Wave Height Priority
    else
        LC_MCSimOUT_XC_WHP = [];
    end
end
