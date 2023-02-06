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
    CSR_Peaks_DLL2.m.

CALLED BY:
    MCS_CSR_Main_Script.m

PURPOSE:
    This script is used to compute the rubblemound structure reliability and
    probability of failure using the sample storms from the Monte Carlo
    Simulation (MCS_DLL1.m).

INPUTS:
    |   Vars Name   |  Vars Type  |               Description                |
    |---------------|-------------|------------------------------------------|
    |  input_param  |    String   |  File name of input CSV file             |
    |---------------|-------------|------------------------------------------|
    |  LC_MCSimOUT  |  Structure  |  Peaks data of sampled storms            |
    |---------------|-------------|------------------------------------------|

OUTPUTS:
    |   Vars Name   |  Vars Type  |               Description                |
    |---------------|-------------|------------------------------------------|
    | PF_Summary,   |  Tables     |  Probability of failure and reliability  |
    | Reliab_Summary|             |  of structure.                           |
    |---------------|-------------|------------------------------------------|

INPUTS HEADERS:
    LC_MCSimOUT:
        Size (# of LC's, 8) -> (Rows,Col)
        (01) Year                         [-]
        (02) Cyclone Type                 [XC=0; TC=1]
        (03) Same year counter            [-]
        (04) Water Level                  [meters, MSL]
        (05) Wave Height                  [meters]
        (06) Peak Wave Period             [seconds]
        (07) Wave Direction               [degrees; N=0, E=+90, S=+/-180, W=-90]
        (08) Storm Duration               [hours]

EXTERNAL FUNCTIONS:
    Wave Transformation:
        wavnum1_VG(Tp,h,grav)
   
AUTHORS:
    By:  Jeffrey A. Melby, PhD,
    Norberto Nadal-Caraballo, PhD,
    and Victor M. Gonzalez,PE

MODIFICATIONS:
    |   DATE (mm/dd/yyyy)   |      EDITOR      |         SUMMARY               |
    |-----------------------|------------------|-------------------------------|
    |      06/05/2020       |   Fabian Garcia  |  Code optimization,clean-up,  |
    |                       |                  |  and incorporation onto       |
    |                       |                  |  streamlined workflow.        |
    |-----------------------|------------------|-------------------------------|
    
RELEVANT PUBLICATIONS:
    Source Material:
        TBD
    Application Of Methodology:
        (01) Gonzalez, Victor M. et. al. 2020. "Alabama Barrier Island Restauration Assesment life-cycle
                structure response modeling." ERDC/CHL TR-20-5. Vicksburg, MS: US Army Engineer Research
                and Development Center.
%}

function [PF_Summary,Reliab_Summary] = stormsim_csr_peaks(config, structure, emp_coeff, LC_MCSimOUT)
%% GRAB INPUTS FROM "config"
% Define Storm Type ('XC' or 'TC')
storm_sampling = config.storm_sampling;
% Define Sea Level Rise
slr = config.swl_slr;
% Water density (kg/m^3)
dw = config.water_density;dw = dw.mean;
% Storm duration (hr)
Dstm = config.storm_duration;
% Depth Limitation
depth_limitation = config.apply_depth_limitation;
% Output Save Dir
outDir = [config.project_name, filesep, config.struc_id, filesep,...
    config.project_name,'_', config.struc_id];

%% GRAB STRUCTURAL PARAMETERS FROM "structure"
% Grab Fieldnames
sFields = fieldnames(structure);
% Extract Strcutural Paramaters From Structure
for ii = 1:length(sFields)
    eval([sFields{ii} ' = {structure.(sFields{ii})};']);
end



%% READ & FORMAT ADDITIONAL DATA
% Gravitational acceleration (m/s^2)
g = 9.80665;
% Loop Through All Life Cycles
for lcS=1:size(LC_MCSimOUT,2)

    %% BUILD STORM FORCING DATA MATRIX
    if ~isempty(LC_MCSimOUT{lcS})
        % Extract LC
        current_LC = LC_MCSimOUT{lcS};
        % Build Forcing Parameters Matrix For Current LC
        WL=current_LC(:,4); %Water Level
        Hm0=current_LC(:,5); %Wave Height
        Tp=current_LC(:,6); %Peak Wave Period
        % Reference Elevation Used For Water Depth Computation (h)
        depth = -1*structure(lcS).('toe_elevation');
        % Deterministic value of zero damage level seaside
        S_ss = {structure.seaside_init_S};
        % Deterministic value of zero damage level leeside
        S_ls = {structure.leeside_init_S};

        %% ADJUST FORCING DATA
        % Apply Water Level Adjustment
        WL = WL+slr;
        % Compute Water Depth
        h = depth + WL;
        % Negative Water Column Fail Safe
        h(h<0)=0.01;
        % Apply Depth Limitation
        if depth_limitation == 1
            Hm0 = apply_depth_limitation(Hm0, Tp, h);
        end

        %% DETERMINE NUMBER OF SIMULATIONS IN LC's
        % Number Of Simulations (# Of Storms)
        nSim = size(WL,1);

        %% READ EMPERICAL COEFFICIENTS
        % Empirical Coefficient (Seaside) - Momentum Flux
        km1 = emp_coeff(lcS).km1;%i.e. 5,0.3
        % Empirical Coefficient (Seaside) - Momentum Flux
        k_ss = emp_coeff(lcS).k_si;% ?
        % Empirical Coefficient (Leeside) - Momentum Flux
        k_ls1 = emp_coeff(lcS).k_ls1;
        % Empirical Coefficient (Leeside) - Momentum Flux
        k_ls2 = emp_coeff(lcS).k_ls2;

        %% APPLY UNCERTAINTY TO Tp AND COMPUTE ADDITIONAL PARAMETERS
        % Mean wave period (sec)
        Tm = Tp/1.2;
        % wave period (sec)
        Tm10 = Tp/1.1;
        % Number of waves per storm
        Nz = (Dstm*3600)./Tm;
        % deep water wave length based on mean wave period
        Lm0 = (g*Tm.^2)/(2*pi);
        % Linear solution (dispersion eq) Local wave steepness deep water
        Sm_dw = Hm0./Lm0;

        %% SEASIDE STRUCTURAL PARAMETERS
        % Ratio of armor stone density to water density (specific gravity)
        Sr = 1+armor_delta{lcS};
        % Armor stone density
        dr = Sr.*dw;
        % Median volume of armor stone
        V_ss = seaside_mass{lcS}./dr;
        % Seaside stone nominal diameter (m)
        Dn_ss = V_ss.^(1/3);
        % Tangent of the seaside stone armor slope angle
        tan_ss = 1./seaside_slope{lcS};

        %% LEESIDE STRUCTURAL PARAMETERS
        % Ratio of armor stone density to water density
        Sr = 1+armor_delta{lcS};
        % Armor stone density
        dr = Sr.*dw;
        % Median volume of armor stone
        V_ls = leeside_mass{lcS}./dr;
        % Seaside stone nominal diameter (m)
        Dn_ls = V_ls.^(1/3);
        % Tangent of the leeside stone armor slope angle
        tan_ls = 1./leeside_slope{lcS};

        %% SEASIDE STABILITY LIMIT STATE (MELBY AND KOBAYASHI 2011)
        % Fourrier Solution Coefficient
        A0 = 0.639*(Hm0./h).^2.026;
        % Fourier Solution Exponent
        A1 = 0.180*(Hm0./h).^(-0.391);
        % Surf Similarity Parameter
        Irm0 = tan_ss./sqrt(Hm0./Lm0);
        % van der Meer critical value of the surf similarity parameter(Not in use)
        Irmc = (6.2*(cem_P{lcS}.^0.31).*sqrt(tan_ss)).^(1./(cem_P{lcS}+0.5));
        % Plunging Waves Coefficient
        am = 1./(km1.*(cem_P{lcS}.^0.18).*sqrt(seaside_slope{lcS}));
        % Compute Response Component
        R_ss = (sqrt(armor_delta{lcS}).*Dn_ss.*(S_ss{lcS}.^0.2))./am;
        % Momentum Flux
        A = A0.*(h./(g*Tm.^2)).^(-A1);
        % Compute Forcing Component
        F_ss = h.*(Nz.^0.1).*k_ss.*(A.^0.5);
        % Seaside Stability Performance
        G_ss = R_ss-F_ss;
        % Compute Reliability
        Reliab_ss(lcS,1) = 1-sum(G_ss<0)/nSim;

        %% LEESIDE STABILITY LIMIT STATE (VAN GENT AND POZUETA 2004; MELBY 2009)
        % for constant wave conditions
        r = 6;
        % Freeboard Seaside
        Rc_ss = crest_elevation{lcS}+depth-h; %h=depth+WL, Hc = crest elevation
        % Freeboard Leeside
        Rc_ls = crest_elevation{lcS}+depth-h;
        % Empirical Coefficient
        c0 = 1.45;
        % Empirical Coefficient
        c1 = 5.1;
        % Empirical Coefficient
        c2 = 0.25*(c1^2)/c0;
        % Empirical Coefficient
        p = 0.5*c1/c0;
        % Leeside Stability Coefficient
        a_ls = leeside_slope{lcS}.^(-2.5/r).*(1+10*exp(-Rc_ls./Hm0)).^(1/r);
        % Compute Response Component
        R_ls = (sqrt(armor_delta{lcS}).*Dn_ls.*S_ls{lcS}.^(1/6))./a_ls;
        % Wave Length
        Lm10 = (g*Tm10.^2)/(2*pi);
        % Surf Similarity Parameter
        Irs1 = tan_ls./sqrt(Hm0./Lm10);

        %% COMPUTE WAVE RUNUP
        ixIrs1 = (Irs1<=2);
        Yfc(ixIrs1,1) = 0.55; %friction factor on crest
        ixIrs1 = (Irs1>2 & Irs1<10);
        Yfc(ixIrs1,1) = 0.05625*(Irs1(ixIrs1)-2)+0.55;
        ixIrs1 = (Irs1>=10);
        Yfc(ixIrs1,1) = 1.0;

        ixIrs1 = (Irs1<=p);
        z1p(ixIrs1,1) = Yfc(ixIrs1).*Hm0(ixIrs1).*(c0*Irs1(ixIrs1));% runup exceeded by % of the waves.
        ixIrs1 = (Irs1>p);
        z1p(ixIrs1,1) = Yfc(ixIrs1).*Hm0(ixIrs1).*(c1-c2./Irs1(ixIrs1));

        %% CONTINUE LEESIDE STABILITY COMPUTATION
        % Negative Freeboard Failsafe
        if Rc_ls<0.6
            Rc_ls=0;
            u1p = 0;
        else
            % Compute 1% Overtopping Velocity
            u1p = sqrt(g*Hm0).*(1.7*Yfc.^0.5).*((z1p-Rc_ls)./(Yfc.*Hm0)).^0.5./(1+0.1*crest_width{lcS}./Hm0);
        end
        % Compute Forcing Component
        F_ls = k_ls2.^(1/6).*Nz.^(1/12).*(u1p.*Tm10./k_ls1);
        % Leeside Stability Performance
        G_ls = R_ls-F_ls;
        % Compute Reliability
        Reliab_ls(lcS,1) = 1-sum(G_ls<0)/nSim;

        %% Overall Stability Limit State
        % Overall Stability Performance
        G_all = min(G_ss,G_ls);
        % Compute Overall Reliability
        Reliab_all(lcS,1) = 1-sum(G_all<0)/nSim;

    else
        % If Life Cycle Is Empty Assign Empty Value
        Reliab_ss(lcS,1)=NaN;
        Reliab_ls(lcS,1)=NaN;
        Reliab_all(lcS,1)=NaN;
    end
    % Clear Workspace
    clearvars('MCSimOUT','Yfc','z1p');
end

%% LIFE CYCLE RELIABILITY MATRIX
% Overall Reliability Vector
Reliability_LC(:,1)=Reliab_all;
% Seaside Reliability Vector
Reliability_LC(:,2)=Reliab_ss;
% Leaside Reliability Vector
Reliability_LC(:,3)=Reliab_ls;

%% RELIABILITY AVERAGES AND PERCENTILES
% Mean Seaside Reliability
Reliab_ss_mean = nanmean(Reliab_ss,1);
% Seaside 84 Percentile Reliability
Reliab_ss_84 = prctile(Reliab_ss,84,1);
% Seaside 90 Percentile Reliability
Reliab_ss_90 = prctile(Reliab_ss,90,1);
% Seaside 95 Percentile Reliability
Reliab_ss_95 = prctile(Reliab_ss,95,1);
% Seaside 98 Percentile Reliability
Reliab_ss_98 = prctile(Reliab_ss,98,1);
% Seaside Reliability Standard Deviation
Reliab_ss_SIGMA = nanstd(Reliab_ss,1);

% Mean Leeside Reliability
Reliab_ls_mean = nanmean(Reliab_ls,1);
% Leeside 84 Percentile Reliability
Reliab_ls_84 = prctile(Reliab_ls,84,1);
% Leeside 90 Percentile Reliability
Reliab_ls_90 = prctile(Reliab_ls,90,1);
% Leeside 95 Percentile Reliability
Reliab_ls_95 = prctile(Reliab_ls,95,1);
% Leeside 98 Percentile Reliability
Reliab_ls_98 = prctile(Reliab_ls,98,1);
% Leeside Reliability Standard Deviation
Reliab_ls_SIGMA = nanstd(Reliab_ls,1);

% Overall Reliability Mean
Reliab_all_mean = nanmean(Reliab_all,1);
% Overall Reliability 84 Percentile
Reliab_all_84 = prctile(Reliab_all,84,1);
% Overall Reliability 90 Percentile
Reliab_all_90 = prctile(Reliab_all,90,1);
% Overall Reliability 95 Percentile
Reliab_all_95 = prctile(Reliab_all,95,1);
% Overall Reliability 98 Percentile
Reliab_all_98 = prctile(Reliab_all,98,1);
% Overall Reliability Standard Deviation
Reliab_all_SIGMA = nanstd(Reliab_all,1);

%% RELIABILITY SUMMARY AVERAGES AND PERCENTILES
% Mean Seaside Reliability Summary
Reliab_Summary(1,1) = Reliab_ss_mean;
% Seaside 84 Percentile Reliability Summary
Reliab_Summary(2,1) = Reliab_ss_84;
% Seaside 90 Percentile Reliability Summary
Reliab_Summary(3,1) = Reliab_ss_90;
% Seaside 95 Percentile Reliability Summary
Reliab_Summary(4,1) = Reliab_ss_95;
% Seaside 98 Percentile Reliability Summary
Reliab_Summary(5,1) = Reliab_ss_98;
% Seaside Reliability Standard Deviation
Reliab_Summary(6,1) = Reliab_ss_SIGMA;

% Mean Leeside Reliability Summary
Reliab_Summary(1,2) = Reliab_ls_mean;
% Leeside 84 Percentile Reliability Summary
Reliab_Summary(2,2) = Reliab_ls_84;
% Leeside 90 Percentile Reliability Summary
Reliab_Summary(3,2) = Reliab_ls_90;
% Leeside 95 Percentile Reliability Summary
Reliab_Summary(4,2) = Reliab_ls_95;
% Leeside 98 Percentile Reliability Summary
Reliab_Summary(5,2) = Reliab_ls_98;
% Leeside Reliability Standard Deviation
Reliab_Summary(6,2) = Reliab_ls_SIGMA;

% Overall Reliability Mean
Reliab_Summary(1,3) = Reliab_all_mean;
% Overall Reliability 84 Percentile
Reliab_Summary(2,3) = Reliab_all_84;
% Overall Reliability 90 Percentile
Reliab_Summary(3,3) = Reliab_all_90;
% Overall Reliability 95 Percentile
Reliab_Summary(4,3) = Reliab_all_95;
% Overall Reliability 98 Percentile
Reliab_Summary(5,3) = Reliab_all_98;
% Overall Reliability Standard Deviation
Reliab_Summary(6,3) = Reliab_all_SIGMA;

%% PROBABILITY OF FAILURE AVERAGES AND PERCENTILES
% Seaside Probability Of Failure
PF_ss = 1-Reliab_ss;
% Leeside Probability Of Failure
PF_ls = 1-Reliab_ls;
% Overall Probability Of Failure
PF_all = 1- Reliab_all;


% Mean Seaside Probability Of Failure
PF_ss_mean = nanmean(PF_ss,1);
% Seaside 84 Percentile Probability Of Failure
PF_ss_84 = prctile(PF_ss,84,1);
% Seaside 90 Percentile Probability Of Failure
PF_ss_90 = prctile(PF_ss,90,1);
% Seaside 95 Percentile Probability Of Failure
PF_ss_95 = prctile(PF_ss,95,1);
% Seaside 98 Percentile Probability Of Failure
PF_ss_98 = prctile(PF_ss,98,1);
% Seaside Probability Of Failure Standard Deviation
PF_ss_SIGMA = nanstd(PF_ss,1);

% Mean Leeside Probability Of Failure
PF_ls_mean = nanmean(PF_ls,1);
% Leeside 84 Percentile Probability Of Failure
PF_ls_84 = prctile(PF_ls,84,1);
% Leeside 90 Percentile Probability Of Failure
PF_ls_90 = prctile(PF_ls,90,1);
% Leeside 95 Percentile Probability Of Failure
PF_ls_95 = prctile(PF_ls,95,1);
% Leeside 98 Percentile Probability Of Failure
PF_ls_98 = prctile(PF_ls,98,1);
% Leeside Probability Of Failure Standard Deviation
PF_ls_SIGMA = nanstd(PF_ls,1);

% Overall Probability Of Failure Mean
PF_all_mean = nanmean(PF_all,1);
% Overall Probability Of Failure 84 Percentile
PF_all_84 = prctile(PF_all,84,1);
% Overall Probability Of Failure 90 Percentile
PF_all_90 = prctile(PF_all,90,1);
% Overall Probability Of Failure 95 Percentile
PF_all_95 = prctile(PF_all,95,1);
% Overall Probability Of Failure 98 Percentile
PF_all_98 = prctile(PF_all,98,1);
% Overall Probability Of Failure Standard Deviation
PF_all_SIGMA = nanstd(PF_all,1);

%% PROBABILITY OF FAILURE SUMMARY AVERAGES AND PERCENTILES
% Mean Seaside Probability Of Failure Summary
PF_Summary(1,1) = PF_ss_mean;
% Seaside 84 Percentile Probability Of Failure Summary
PF_Summary(2,1) = PF_ss_84;
% Seaside 90 Percentile Probability Of Failure Summary
PF_Summary(3,1) = PF_ss_90;
% Seaside 95 Percentile Probability Of Failure Summary
PF_Summary(4,1) = PF_ss_95;
% Seaside 98 Percentile Probability Of Failure Summary
PF_Summary(5,1) = PF_ss_98;
% Seaside Probability Of Failure Standard Deviation
PF_Summary(6,1) = PF_ss_SIGMA;

% Mean Leeside Probability Of Failure Summary
PF_Summary(1,2) = PF_ls_mean;
% Leeside 84 Percentile Probability Of Failure Summary
PF_Summary(2,2) = PF_ls_84;
% Leeside 90 Percentile Probability Of Failure Summary
PF_Summary(3,2) = PF_ls_90;
% Leeside 95 Percentile Probability Of Failure Summary
PF_Summary(4,2) = PF_ls_95;
% Leeside 98 Percentile Probability Of Failure Summary
PF_Summary(5,2) = PF_ls_98;
% Leeside Probability Of Failure Standard Deviation
PF_Summary(6,2) = PF_ls_SIGMA;

% Overall Probability Of Failure Mean
PF_Summary(1,3) = PF_all_mean;
% Overall Probability Of Failure 84 Percentile
PF_Summary(2,3) = PF_all_84;
% Overall Probability Of Failure 90 Percentile
PF_Summary(3,3) = PF_all_90;
% Overall Probability Of Failure 95 Percentile
PF_Summary(4,3) = PF_all_95;
% Overall Probability Of Failure 98 Percentile
PF_Summary(5,3) = PF_all_98;
% Overall Probability Of Failure Standard Deviation
PF_Summary(6,3) = PF_all_SIGMA;

%% SAVE
out_path = [outDir '_CSR_Outputs'];
if ~exist(out_path,'dir')
    mkdir(out_path);
end
% Save Sampled Storm Indexes
save([out_path '_CSR_Peaks_Reliability.mat'],'PF_Summary','Reliab_Summary','-v7.3');

end