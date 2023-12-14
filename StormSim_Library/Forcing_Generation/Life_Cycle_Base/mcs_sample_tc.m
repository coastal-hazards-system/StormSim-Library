function [index, MCSimOUT, sampled_intensity,...
    MCSimOUT_WLP, MCSimOUT_WHP] = mcs_sample_tc(storm, simulation_years, prob_mass, WLP_switch, WHP_switch, sample_method)
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
    |    TC_B1RT    |   Double    |  Extra tropical storm response variable  |
    |---------------|-------------|------------------------------------------|
    |  storm_whp_peaks  |   Double    |  Extra tropical storm response variable  |
    |               |             |  - water level priority                  |
    |---------------|-------------|------------------------------------------|
    |  storm_wlp_peaks  |   Double    |  Extra tropical storm response variable  |
    |               |             |  - wave height priority                  |
    |---------------|-------------|------------------------------------------|
    |    SIMyrs     |   Double    |  Extra tropical storm response variable  |
    |---------------|-------------|------------------------------------------|
    |    SIM_Flag   |   Double    |  Simulation flag to ensure sampled storms|
    |               |             |  match sampling rate                     |
    |---------------|-------------|------------------------------------------|
    |     TC_SRR    |   Double    |  Tropical storm recurrance rate          |
    |---------------|-------------|------------------------------------------|
       
OUTPUTS:
    |   Vars Name      |  Vars Type  |               Description                |
    |------------------|-------------|------------------------------------------|
    |    INDEX_TC_TS   |   Double    |  Sampled Storm Indexes                   |
    |------------------|-------------|------------------------------------------|
    | LC_MCSimOUT_TC   |   Double    |  Life Cycle Data Structure - Maximums    |
    |------------------|-------------|------------------------------------------|
    |LC_MCSimOUT_TC_WHP|   Double    |  Life Cycle Data Structure               |
    |                  |             |  - wave height priority                  |
    |------------------|-------------|------------------------------------------|
    |LC_MCSimOUT_TC_WLP|   Double    |  Life Cycle Data Structure               |
    |                  |             |  - water level priority                  |
    |------------------|-------------|------------------------------------------|
    |     TC_iclass    |   Double    |  Sampled Storms Intensity Index          |
    |------------------|-------------|------------------------------------------|

OUTPUTS HEADERS:
    LC_MCSimOUT_TC, LC_MCSimOUT_TC_WHP, LC_MCSimOUT_TC_WLP :
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
smpl1 = prob_mass.smpl1;
smpl2 = prob_mass.smpl2;
smpl3 = prob_mass.smpl3;
% Storm Probability Masses
TC_SRR = prob_mass.TC_SRR;
% Storm Frequency
TC_Freq = prob_mass.TC_Freq;
% Simulation flag, internal. Stops two 'while' loops below to ensure sampled
% storms match sampling rate.
if simulation_years == 1e5
    SIM_Flag = 1e-4;
else
    SIM_Flag = 10^-(log10(simulation_years));
end
% Maxima Dataset
storm_peaks = storm.('TC').('Peaks').('Maxima');
% WLP Dataset
if WLP_switch == 1
    storm_wlp_peaks = storm.('TC').('Peaks').('WLP');
else
    storm_wlp_peaks = [];
end
% WHP Datasets
if WHP_switch == 1
    storm_whp_peaks = storm.('TC').('Peaks').('WHP');
else
    storm_whp_peaks = [];
end



%% POISSON PROCESS
% Assing SRR for all intensities as lambda
TC_lambda = TC_SRR(1,end);
% Make Distribuition Object
TC_pd = makedist('Poisson','lambda',TC_lambda);
% Initializing While Loop Exit Trigger
TC_EPY=0;
% Insert Comment
while abs(TC_EPY-TC_lambda)>SIM_Flag %cannot be higher than NSIMyrs
    % Sample Number Of TCs Sampled For The Simulation Year.
    TC_MCS = random(TC_pd,[simulation_years,1]);
    % Recomputes The Storm Rate Of The Simulation Period To Check Against SRR.
    TC_EPY = sum(TC_MCS)/simulation_years;
end

%% SAMPLE TROPICAL STORMS
% Initialize Storm Counter
n=1;
if sample_method == 0
    SimOUT_TC = zeros(sum(TC_MCS),11);
else
    SimOUT_TC = zeros(sum(TC_MCS),10);
end

% Loop Through Simulation Length
for j = 1:simulation_years
    %
    if (TC_MCS(j,1)>0)
        m=1;
        for k = 1:TC_MCS(j,1)
            % Storm Year
            SimOUT_TC(n,1) = j;
            % Storm Type (1 = Tropical)
            SimOUT_TC(n,2) = 1;
            % Number of Storm In Storm Year
            SimOUT_TC(n,3) = m;
            % Random Number from 0 - 1
            IIdx = rand;
            % Sample Storms 
            switch sample_method
                case 0 % historical
                    % Define NaN for Intensity
                    SimOUT_TC(n,4) =  -9;
                    % Sample Random Storm Index
                    SimOUT_TC(n,5) =  randsample(storm_peaks(:,5),1);
                    % Extract Data Corresponding To Sampled Storm (
                    SimOUT_TC(n,6:end) = storm_peaks(storm_peaks(:,5)==SimOUT_TC(n,5),:);
                case 1 % probabilistic
                    % Determine Random Intensity To Sample
                    [~, IIdx] = max([IIdx<=(1-TC_SRR(1,1)/TC_SRR(1,end)),...
                        IIdx>(1-TC_SRR(1,1)/TC_SRR(1,end)) && IIdx<(1-TC_SRR(1,3)/TC_SRR(1,end))...
                        IIdx>=(1-TC_SRR(1,3)/TC_SRR(1,end))]);
                    % Make Sure Resulting Intensity Has A Population
                    chk = [];
                    while isempty(chk)
                        % Look Into Resulting Intensity Population
                        chk = eval(['smpl' num2str(IIdx) ';']);
                        % Need to Switch Intensity if Not Available For Study
                        if isempty(chk)
                            % Random Number from 0 - 1
                            IIdx = rand;
                            % Determine Random Intensity To Sample
                            [~, IIdx] = min([IIdx<=(1-TC_SRR(1,1)/TC_SRR(1,end)),...
                                IIdx>(1-TC_SRR(1,1)/TC_SRR(1,end)) && IIdx<(1-TC_SRR(1,3)/TC_SRR(1,end))...
                                IIdx>=(1-TC_SRR(1,3)/TC_SRR(1,end))]);
                            % Try New Intensity
                            chk = eval(['smpl' num2str(IIdx) ';']);
                        end
                    end
                    % Evaluate Corresponding Case
                    switch IIdx
                        case 1% Low Intensity
                            % Low Intensity Index (Maybe?)
                            SimOUT_TC(n,4) = 0;
                            % Grab Valid Storm Id List
                            valid_storms = storm.('TC').('Peaks').Maxima(:,5);
                            % Find Correcponding Frequency
                            freq_indx = ismember(valid_storms,smpl1);
                            % Remove Missing Storms
                            smpl1 = smpl1(ismember(smpl1,valid_storms));
                            % Sample Random Low Intensity Storm Index
                            SimOUT_TC(n,5) = randsample(smpl1,1,true,TC_Freq(freq_indx));
                            % Extract Data Corresponding To Sampled Storm (
                            SimOUT_TC(n,6:end) = storm_peaks(storm_peaks(:,5)==SimOUT_TC(n,5),1:end-1);
                        case 2 % Mid Intensity IIdx>=(1-TC_SRR(1,2)/TC_SRR(1,end)) ?
                            % Mid Intensity Index (Maybe?)
                            SimOUT_TC(n,4) = 2;
                            % Grab Valid Storm Id List
                            valid_storms = storm.('TC').('Peaks').Maxima(:,5);
                            % Find Correcponding Frequency
                            freq_indx = ismember(valid_storms,smpl2);
                            % Remove Missing Storms
                            smpl2 = smpl2(ismember(smpl2,valid_storms));
                            % Sample Random High Intensity Storm Index
                            SimOUT_TC(n,5) = randsample(smpl2,1,true,TC_Freq(freq_indx));
                            % Extract Data Corresponding To Sampled Storm
                            SimOUT_TC(n,6:end) = storm_peaks(storm_peaks(:,5)==SimOUT_TC(n,5),1:end-1); % Maximums
                        case 3 % High Intensity
                            % High Intensity Index (Maybe?)
                            SimOUT_TC(n,4) = 1;
                            % Grab Valid Storm Id List
                            valid_storms = storm.('TC').('Peaks').Maxima(:,5);
                            % Find Correcponding Frequency
                            freq_indx = ismember(valid_storms,smpl3);
                            % Remove Missing Storms
                            smpl3 = smpl3(ismember(smpl3,valid_storms));
                            % Sample Random High Intensity Storm Index
                            SimOUT_TC(n,5) = randsample(smpl3,1,true,TC_Freq(freq_indx));
                            % Extract Data Corresponding To Sampled Storm
                            SimOUT_TC(n,6:end) = storm_peaks(storm_peaks(:,5)==SimOUT_TC(n,5),1:end-1); % Maximums
                    end%if
            end
            % Increment Storm
            n=n+1;
            % Increment Number of Storm In Storm Year
            m=m+1;
        end% for k
    end% if
end% for j


%% STORE SAMPLED TROPICAL STORMS
% Monte Carlo Simulation Outputs (Sample Tropical Storms Peaks) - Maximums
if sample_method == 0 %historical
    sort_indx = [1 2 3 6 7 8 9 10 11];
    store_indx = 1:6;
else
    sort_indx = [1 2 3 6 7 8 9 10];
    store_indx = 1:5;
end
MCSimOUT = SimOUT_TC(:,sort_indx); % (Headers in script header)
% Sampled Storm Indexes
index = SimOUT_TC(:,[1 2 3 10]); % (Headers in script header)
% Store Sampled Storms Intensity Index
sampled_intensity = SimOUT_TC(:,4);

%% REPLICATE TROPICAL STROM SAMPLING WITH ALTERNATE DATASETS
% Wave height Priority
if WHP_switch == 1
    % Search For Storm IDs
    search_indx = arrayfun(@(x) find(storm_whp_peaks(:,5)==x),SimOUT_TC(:,5),'un',false);
    % Check For Unmatched Storms
    match_indx = ~cellfun(@isempty,search_indx);
    % Extract Data Corresponding To Storm
    SimOUT_TC_WHP = SimOUT_TC;
    SimOUT_TC_WHP(match_indx,6:end) = storm_whp_peaks(cell2mat(search_indx),store_indx);
    % Monte Carlo Simulation Outputs (Sample Tropical Storms Peaks) - Wave Height Priority
    MCSimOUT_WHP = SimOUT_TC_WHP(:,sort_indx); % (Headers in script header)
else
    MCSimOUT_WHP = [];
end
% Water Level Priority
if WLP_switch == 1
    % Search For Storm IDs
    search_indx = arrayfun(@(x) find(storm_wlp_peaks(:,5)==x),SimOUT_TC(:,5),'un',false);
    % Check For Unmatched Storms
    match_indx = ~cellfun(@isempty,search_indx);
    % Extract Data Corresponding To Storm
    SimOUT_TC_WLP = SimOUT_TC;
    SimOUT_TC_WLP(match_indx,6:end) = storm_wlp_peaks(cell2mat(search_indx),store_indx);
    % Monte Carlo Simulation Outputs (Sample Tropical Storms Peaks) - Water Level Priority
    MCSimOUT_WLP = SimOUT_TC_WLP(:,sort_indx); % (Headers in script header)
else
    MCSimOUT_WLP = [];
end
end