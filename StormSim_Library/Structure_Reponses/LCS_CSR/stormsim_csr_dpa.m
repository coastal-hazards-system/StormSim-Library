 function [CSR_Timeseries_DPA] = stormsim_csr_dpa(config, structure, emp_coeff, LC_SimOUT_hyd)
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
    CSR_timeseries_DLL3.m.

CALLED BY:
    MCS_CSR_Main_Script.m

PURPOSE:
    This script is used to compute incremental damage for historical
    conditions using the life cylce structure built by the function
    LC_Structure_Builder.m. This version of the damage progression script
    has the capability of accounting for structure repairs throughout the
    whole analysis by setting limit states for seaide and leeside damage
    in the input CSV file. Repairs are applied per storm in the current
    life cycle if accumulated damage surpases the limit state. Also,
    it computes yearly averages and percentiles by taking the maximum average
    of the accumulated damage per year. Yearly values do not take repairs into
    account. This means that damage is allowed to accumulate until the end
    of the life cycle being evaluated.

INPUTS:
    |   Vars Name   |  Vars Type  |               Description                |
    |---------------|-------------|------------------------------------------|
    |  input_param  |    String   |  File name of input CSV file             |
    |---------------|-------------|------------------------------------------|
    | LC_SimOUT_hyd |  Structure  |  Time series data of sampled storms      |
    |---------------|-------------|------------------------------------------|

OUTPUTS:
    |   Vars Name   |  Vars Type  |               Description                |
    |---------------|-------------|------------------------------------------|
    |    outputs    |  Structure  |  Contains damage progression analysis    |
    |               |             |  outputs.                                |
    |---------------|-------------|------------------------------------------|

INPUTS HEADERS:
    LC_SimOUT_hyd:
        First Level:
            Size (# of LC's, 1) -> (Rows,Col)
            Each row contains a matrix which size depends on the ammount of
            storms sampled for that specific life cyccle.
        Second Level:
            (01) Storm ID                       [-]
            (02) Storm type                     [0 = extratropical]
            (03) Storm Year                     [-]
            (04) Number of storm in storm year  [-]
            (05) Water Level                    [meters, MSL]
            (06) Wave Height                    [meters]
            (07) Peak Wave Period               [seconds]
            (08) Wave Direction                 [degrees; N=0, E=+90, S=+/-180, W=-90]
            (09) Storm Duration           [days]
            (10) Timestep Counter         [0:storm_tstp-1]

EXTERNAL FUNCTIONS:
    Wave Transformation:
        wavnum1_VG(Tp,h,grav)
    Seaside Damage:
        ZeroSeaDamFunc(Hm0,h,Tm,SseaLast_full,Sslp,SDn,SG,grav,P,Nz,Km1)
        SeaDamFunc(Szero,h,SseaLast,...
                    SseaSDLast,SseaMaxLast,Hm0,Tm,Sslp,SDn,SG,grav,P,Nz,...
                        Szerolim,Cheight+cutoff_delta_new,WL,Cheight,Km1)
    Leeside Damage:
        LeeDamFunc(z1p,SLeeLast_full,SLeeSDLast_full,...
                    SLeeMaxLast_full,Hm0,Tp,u1p,LDn,SG,grav,Sslp,Lslp,Rc,wdth,Nz,INPUT);
        RunupFunc(Hm0,Tp,Rc,Sslp,grav)
    Yearly Maximum Averaging:
        S_yearly_v2(LC_SimOUT_hyd,Ssave_full,Leesave_full,INPUT{2,1))

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
%% IMPORT INPUT FILES
disp(['   Running StormSim: Coastal Structure Reliability - Damage Progression Analysis....']);
fprintf(1,'      Completion Progress: %3d%%\n',0);

%% DEFINE CONSTANTS
% Gravitational acceleration (m/s^2)
grav = config.gravity_constant;
% Limits Damage Accumulation To Increments Of Roughly S>.8
Szerolim = 0.2;
% Determine Number Of Life Cycles
nLC = length(LC_SimOUT_hyd);
% Determine Number Of Timesteps Per Life Cycle
nTimes_per_LC = cellfun(@(x) length(x(:,1)),LC_SimOUT_hyd);
% Define Number of Years
nYears = config.mcs_nYears;
% Grab Submergance Switch
compute_S_submerged = config.csr_compute_S_submerged;

%% GRAB INPUTS FROM "config"
% ---------- PROJECT DETAILS ----------
% Water density (kg/m^3)
dw = config.water_density;
% Seaside Damage Ultimate Limit State (ULS)
Ssea_ULS = structure.seaside_S_uls;
% Leeside Damage Ultimate Limit State (ULS)
Slee_ULS = structure.leeside_S_uls;
% Seaside Damage Serviceability Limit State (SLS)
Ssea_SLS = structure.seaside_design_S;%e.g. S=7, just before exposure of underlayer
% Leeside Damage Serviceability Limit State (SLS)
Slee_SLS = structure.leeside_design_S; %e.g. S=7, just before exposure of underlayer
% Coefficients are found in CEM and in Eurotop. For levees with grass, the
% surface roughness influence increses for small wave heights.
gamma_f = structure.roughness_ifactor;
% ---------- LOGICAL SWITCHES ----------
% Structure Repair Assesment; 0 - Repairs Not Included In Analysis, 1 - Repairs Are Included In Analysis
repair_switch = config.csr_apply_structure_repair;
% Cutoff Elevation Adjustment Flag;
% 0 - Seaside Damage is computed even if the structure is submerged
% 1 - Water Level Is Compared With Crest Height + Cutoff Elevation Delta To Determine Structure Submergence
cutoff_switch = config.csr_apply_cutoff_correction;
% Cutoff Elevation Delta [m]
cutoff_delta = config.csr_cutoff_offset;

%% GRAB INPUTS FROM "structure"
% Extract Strcutural Paramaters From Structure
crest_elevation = structure.crest_elevation;
crest_width = structure.crest_width;
toe_elevation = structure.toe_elevation;
seaside_slope = structure.seaside_slope;
leeside_slope = structure.leeside_slope;
armor_delta = structure.armor_delta;
seaside_mass = structure.seaside_mass;
leeside_mass = structure.leeside_mass;
cem_P = structure.cem_P;
% Armor Stone Specific Gravity
SG = 1 + armor_delta;
% Armor Stone Density [kg/m^3]
dr = SG*dw;
% Seaside Median Volume of Armor Stone
V_ss = seaside_mass/dr;
% Seaside Nominal Stone Diameter (m)
SDn = V_ss^(1/3);
%Leeside Median Volume of Armor Stone
LV_ss = leeside_mass/dr;
% Leeside Nominal Stone Diameter (m)
LDn = LV_ss^(1/3);

%% EMPIRICAL COEFFICIENTS
% Need to define wqhat K_ss is
Km1 = emp_coeff.km1; % Seaside Damage Coeff
Km2 = emp_coeff.km2; % Seaside Damage Coeff
Ksi = emp_coeff.k_si;
Ksp = emp_coeff.k_sp;
K_ls1 = emp_coeff.k_ls1; % Leeside Damage Coeff
K_ls2 = emp_coeff.k_ls2; % Leeside Damage Coeff
Nz_ini = emp_coeff.ini_waves;

%% ADJUST AND COMPUTE FORCING PARAMETERS
% Extract Water Level
WL = cellfun(@(x) x(:,5),LC_SimOUT_hyd,'un',false);
% Compute Water Column
h = cellfun(@(x) x-toe_elevation,WL,'un',false);
% Compute Freeboard
Rc = cellfun(@(x,y) crest_elevation - x,WL,'un',false);
% Extract Wave Height
Hm0 = cellfun(@(x) x(:,6),LC_SimOUT_hyd,'un',false);
% Extract Wave Peak Period
Tp = cellfun(@(x) x(:,7),LC_SimOUT_hyd,'un',false);
% Spectral Wave Period (Tm_-1,0)
Tm10 = cellfun(@(x) x(:,7)/1.1,LC_SimOUT_hyd,'un',false);
% Mean wave period (sec)
Tm = cellfun(@(x) x./1.2,Tp,'un',false);
% Storm increment duration (hr)
Dstm = cellfun(@(x) x(:,9).*24,LC_SimOUT_hyd,'un',false);
% Number of waves per increment
Nz = cellfun(@(x,y) (x.*3600)./y,Dstm,Tm,'un',false);

%% COMPUTE INITIAL STRUCTURE RESPONSES (runup & runup_vel)
% Compute Run-up
z1p = cellfun(@(w,x,y) z1p_calc(w,x,y,seaside_slope,grav),Hm0,Tm10,Rc,'un',false);
% Compute u1%
u1p = cellfun(@(v,w,x,y) u1p_calc(crest_width,v,w,x,y,seaside_slope,grav),Rc,z1p,Tm10,Hm0,'un',false);

%% INITIALIZE DAMAGE VARIABLES
Szero_no_repairs = cellfun(@(x) zeros(x,1),num2cell(nTimes_per_LC),'un',false);
Ssea_no_repairs = cellfun(@(x) zeros(x,1),num2cell(nTimes_per_LC),'un',false);
Szero_with_repairs = cellfun(@(x) zeros(x,1),num2cell(nTimes_per_LC),'un',false);
Ssea_with_repairs = cellfun(@(x) zeros(x,1),num2cell(nTimes_per_LC),'un',false);
SLee_with_repairs =  cellfun(@(x) zeros(x,1),num2cell(nTimes_per_LC),'un',false);
SLee_no_repairs =  cellfun(@(x) zeros(x,1),num2cell(nTimes_per_LC),'un',false);
% LCBW_FS =  cellfun(@(x) zeros(x,1),num2cell(nTimes_per_LC),'un',false);
% Repair Indexes Storage Variables
Seaside_Repair_Indexes = {};
Leeside_Repair_Indexes =  {};

%% BEGIN LC LOOP
for NlcS = 1:nLC

    %% INITIALIZE PREVIOUS STATE DAMAGE VARIABLES
    % Seaside Damage With Repairs
    Ssea_with_repairs_last = 0;
    % Seaside Damage Without Repairs
    Ssea_no_repairs_last = 0;
    % Leeside Damage With Repairs
    SLee_with_repairs_last = 0;
    % Leeside Damage Without Repairs
    SLee_no_repairs_last = 0;
    % U1% Storage Initialization
    u1p_last=0;
    storm_end_leeside = 0;
    storm_end_seaside = 0;
    % Repair Index
    repair_seaside = [];
    repair_leeside = [];
    %    StormIndex_last=LC_SimOUT_hyd{1,NlcS}(1);
    first_damaging_storm_DnR = 0; % logical indicating first storm has not been triggered yet
    first_damaging_storm_DwR = 0; % logical indicating first storm has not been triggered yet
    DwR = 0; %logical indicating damage with repairs is zero
    DnR = 0; %logical indicating damage no repairs is zero

    %% BEGIN TIMESTEP LOOP
    for Ntime=1:nTimes_per_LC(NlcS)
        %% SEASIDE DAMAGE PROGRESSION - WITH REPAIRS
        % Verify Damage State (Define Ks, dS)
        [Ks_DwR, dS_DwR, first_damaging_storm_DwR] = ...
            damage_state(DwR, first_damaging_storm_DwR, LC_SimOUT_hyd, NlcS, Ntime, Ksi, Ksp);
        % Determine Repair Conditions 
        repair_sea_now = repair_condition(repair_switch, Ssea_SLS, Ssea_ULS, Ssea_with_repairs_last);
        % Verify For Breaching Condition
        if repair_sea_now && repair_switch > 0
            % Store Breaching Timestep (Row ID)
            if storm_end_seaside == 0
                % Update Storm End Row
                storm_end_seaside = find_storm_end(LC_SimOUT_hyd, NlcS, Ntime);
                % Store Row Index Where Breaching Occoured
                repair_seaside = [repair_seaside;Ntime-1];
            end
            % Set Damage Vectors To NaN
            Szero_with_repairs{NlcS}(Ntime) = NaN(1,1); % Szero
            Ssea_with_repairs{NlcS}(Ntime) = NaN(1,1); % Ssea
            % Verify If Reached End Of Breaching Storm
            if Ntime == storm_end_seaside
                % Reset Seaside Damages
                Ssea_with_repairs_last = 0;
                storm_end_seaside = 0;
                DwR = 0; % Reset Damage Flag
            end
        else
            % Compute Seaside Armor Stone Damage Accumulation (S)
            [Ssea_with_repairs{NlcS}(Ntime), Szero_with_repairs{NlcS}(Ntime)] = ...
                seaside_armor_stone_damage(h{NlcS}(Ntime), Ssea_with_repairs_last,...
                Hm0{NlcS}(Ntime), Tm{NlcS}(Ntime), crest_elevation, seaside_slope, SDn, SG, grav,...
                cem_P, Nz{NlcS}(Ntime), Rc{NlcS}(Ntime), Szerolim, cutoff_delta, WL{NlcS}(Ntime),...
                cutoff_switch, Km1, Km2, Ks_DwR, dS_DwR, compute_S_submerged);
            % Store t-1 Damage State
            Ssea_with_repairs_last = Ssea_with_repairs{NlcS}(Ntime);
        end
        % Check For Initial Damage
        if Ssea_with_repairs_last == 0 && Ssea_with_repairs{NlcS}(Ntime) > 0
            DwR  = 1; % have damage
            first_damaging_storm_DwR = 1; % logical indicating first storm has been triggered
        end

        %% SEASIDE DAMAGE PROGRESSION - NO REPAIRS
        % Verify Damage State (Define Ks, dS)
        [Ks_DnR, dS_DnR, first_damaging_storm_DnR] = ...
            damage_state(DnR, first_damaging_storm_DnR, LC_SimOUT_hyd, NlcS, Ntime, Ksi, Ksp);
        % Compute Seaside Armor Stone Damage Accumulation (S)
        [Ssea_no_repairs{NlcS}(Ntime), Szero_no_repairs{NlcS}(Ntime)] = ...
            seaside_armor_stone_damage(h{NlcS}(Ntime), Ssea_no_repairs_last,...
            Hm0{NlcS}(Ntime), Tm{NlcS}(Ntime), crest_elevation, seaside_slope, SDn, SG, grav,...
            cem_P, Nz{NlcS}(Ntime), Rc{NlcS}(Ntime), Szerolim, cutoff_delta, WL{NlcS}(Ntime),...
            cutoff_switch, Km1, Km2, Ks_DnR, dS_DnR, compute_S_submerged);
        % Check For Initial Damage
        if Ssea_no_repairs_last == 0 && Ssea_no_repairs{NlcS}(Ntime) > 0
            DnR  = 1; % have damage
            first_damaging_storm_DnR = 1; % logical indicating first storm has been triggered
        end
        % Store t-1 Damage State
        Ssea_no_repairs_last = Ssea_no_repairs{NlcS}(Ntime);

        %% LEESIDE DAMAGE PROGRESSION - WITH REPAIRS
        % Verify Run-up
        if Hm0{NlcS}(Ntime)<0.1 || Tp{NlcS}(Ntime)<0 || Rc{NlcS}(Ntime)<0
            z1p{NlcS}(Ntime)=0;
        end
                % Determine Repair Conditions 
        repair_lee_now = repair_condition(repair_switch, Slee_SLS, Slee_ULS, SLee_with_repairs_last);
        % Verify For Breaching Condition
        if repair_lee_now && repair_switch > 0 % Breach
            % Store Breaching Timestep (Row ID)
            if storm_end_leeside == 0
                % Update Storm End Row
                storm_end_leeside = find_storm_end(LC_SimOUT_hyd, NlcS, Ntime);
                % Store Row Index Where Breaching Occoured
                repair_leeside = [repair_leeside;Ntime-1];
            end
            % Set Damage Vectors To NaN
            SLee_with_repairs{NlcS}(Ntime) = NaN(1,1);
            % Verify If Reached End Of Breaching Storm
            if Ntime == storm_end_leeside
                % Reset Seaside Damages
                SLee_with_repairs_last = 0;
                storm_end_leeside = 0;
            end
        else
            % Compute Incremental Leeside Damage
            [SLee_with_repairs{NlcS}(Ntime),u1p{NlcS}(Ntime)] = ...
                leeside_armor_stone_damage(SLee_with_repairs_last,...
                Hm0{NlcS}(Ntime), Tp{NlcS}(Ntime), u1p_last, LDn,...
                leeside_slope, h{NlcS}(Ntime),Rc{NlcS}(Ntime), Nz{NlcS}(Ntime), ...
                armor_delta, K_ls1, K_ls2, crest_width, crest_elevation, grav, compute_S_submerged);
            % Store t-1 Damage State
            SLee_with_repairs_last = SLee_with_repairs{NlcS}(Ntime);
        end

        %% LEESIDE DAMAGE PROGRESSION - NO REPAIRS
        % Compute Incremental Leeside Damage
        [SLee_no_repairs{NlcS}(Ntime),u1p{NlcS}(Ntime)] = leeside_armor_stone_damage(SLee_no_repairs_last,...
            Hm0{NlcS}(Ntime),Tp{NlcS}(Ntime),u1p_last,LDn,...
            leeside_slope,h{NlcS}(Ntime),Rc{NlcS}(Ntime),Nz{NlcS}(Ntime),armor_delta,K_ls1,K_ls2,crest_width,crest_elevation,grav, compute_S_submerged);
        % Store t-1 Damage State
        u1p_last = u1p{NlcS}(Ntime);
        SLee_no_repairs_last = SLee_no_repairs{NlcS}(Ntime);

    end %Ntime_per_LC  %structure_type == 3 % Rubblemound

    %% APPEND REPAIR INDEXES
    % Store Repair Indexes (If Any)
    if ~isempty(repair_leeside)
        Leeside_Repair_Indexes = [Leeside_Repair_Indexes;[{repair_leeside}, {NlcS}]];
    end
    % Store Repair Indexes (If Any)
    if ~isempty(repair_seaside)
        Seaside_Repair_Indexes = [Seaside_Repair_Indexes;[{repair_seaside}, {NlcS}]];
    end
    fprintf(1,'\b\b\b\b%3.0f%%',(100*(NlcS/nLC)));
end  % NLS
disp([newline '      Computing Post Damage Statistics....']);

%% STORE LAST COMPUTED DAMAGE FOR EACH LC
% This will turn into a mean sigular value once percentiles are computed
% Seaside
S_final = cellfun(@(x) x(end),Ssea_no_repairs,'un',true);
LS_final = cellfun(@(x) x(end),SLee_no_repairs,'un',true);

%% DIAGNOSTICS STRUCTURE
diagnostics(1,:) = cellfun(@(a) table(WL{a},Hm0{a},...
    Tp{a},h{a},Nz{a},Rc{a},z1p{a},u1p{a},Szero_no_repairs{a},Ssea_no_repairs{a},Szero_with_repairs{a},...
    Ssea_with_repairs{a}, SLee_no_repairs{a}, SLee_with_repairs{a}, 'VariableNames',...
    {'WL','Hm0','Tp','h','Nz','Rc','z1p','u1p',...
    'Szero_no_repairs','Ssea_no_repairs','Szero_with_repairs','Ssea_with_repairs',...
    'SLee_no_repairs','SLee_with_repairs'}),...
    num2cell(1:nLC),'un',false)';

%% COMPUTE MEAN DAMAGE CURVE
[LSmax,LSPcurves,~] = compute_lcs_yearly_curve(LC_SimOUT_hyd, SLee_no_repairs, nYears);
[Smax,SPcurves,~] = compute_lcs_yearly_curve(LC_SimOUT_hyd, Ssea_no_repairs, nYears);
% Fill values for year 0
Smax = [0;Smax];
LSmax = [0;LSmax];
SPcurves = [zeros(size(SPcurves(1,:)));SPcurves];
LSPcurves = [zeros(size(SPcurves(1,:)));LSPcurves];

%% COMPUTE STATISTICS - TABLE
% Define Percentiles
p = [10 16 84 90]';
% Compute Percentiles
Sp = prctile(S_final,[10 16 84 90])';
LSp = prctile(LS_final,[10 16 84 90])';
% Compute Mean Accumulated Damage For Bin
Smean = repmat(mean(S_final,'omitnan'),size(p));
LSmean = repmat(mean(LS_final,'omitnan'),size(p));
% Build Stats Table
stats = table(p,Smean,Sp,LSmean,LSp);

%% COMPUTE AMOUNT OF REPAIRS
if repair_switch > 0 
    % Seaside N Repairs
    if ~isempty(Seaside_Repair_Indexes)
        sea_repairs = cellfun(@(x) length(x), Seaside_Repair_Indexes(:, 1),'UniformOutput',true);
    else
        sea_repairs = 0;
    end
    % Leeside N Repairs
    if ~isempty(Leeside_Repair_Indexes)
        lee_repairs = cellfun(@(x) length(x), Leeside_Repair_Indexes(:, 1),'UniformOutput',true);
    else
        lee_repairs = 0;
    end
    % Compute Seaside Mean Repairs
    sea_repairs_mean = mean(sea_repairs);
    % Compute Leeside Mean Repairs
    lee_repairs_mean = mean(lee_repairs);
    % Compute Seaside Repairs Percentiles
    sea_repairs_percentiles = prctile(sea_repairs,[10 16 84 90]);
    % Compute Leeside Repairs Percentiles
    lee_repairs_percentiles = prctile(lee_repairs,[10 16 84 90]);
    % Build Table
    Repairs_Stats = table(sum(sea_repairs),sea_repairs_mean,sea_repairs_percentiles(1),sea_repairs_percentiles(2),...
        sea_repairs_percentiles(3),sea_repairs_percentiles(4),sum(lee_repairs),lee_repairs_mean,...
        lee_repairs_percentiles(1),lee_repairs_percentiles(2),lee_repairs_percentiles(3),...
        lee_repairs_percentiles(4),'VariableNames',{'Total_Seaside_Repairs','Mean_Seaside_Repairs',...
        'Seaside_Repair_10_Percentile','Seaside_Repair_16_Percentile','Seaside_Repair_84_Percentile',...
        'Seaside_Repair_90_Percentile','Total_Leeside_Repairs','Mean_Leeside_Repairs',...
        'Leeside_Repair_10_Percentile','Leeside_Repair_16_Percentile','Leeside_Repair_84_Percentile',...
        'Leeside_Repair_90_Percentile'});
else
    % Seaside N Repairs
    sea_repairs = sum(cellfun(@(x) max(x), Ssea_no_repairs, 'UniformOutput', true)>=Ssea_ULS);
    % Leeside N Repairs
    lee_repairs = sum(cellfun(@(x) max(x), SLee_no_repairs, 'UniformOutput', true)>=Slee_ULS);
end

%% COMPUTE RELIABILITY
if repair_switch == 1
    % Seaside Reliability
    Reliability_Seaside = 1 - length(sea_repairs)/nLC;
    % Leeside Reliability
    Reliability_Leeside = 1 - length(lee_repairs)/nLC;
else
    % Seaside Reliability
    Reliability_Seaside = 1 - sea_repairs/nLC;
    % Leeside Reliability
    Reliability_Leeside = 1 - lee_repairs/nLC;
end

%% GENERATE OUTPUTS DATA STRUCTURE
% Damage with no breaching
CSR_Timeseries_DPA.S_seaside_no_repairs = Ssea_no_repairs;
CSR_Timeseries_DPA.S_leeside_no_repairs = SLee_no_repairs;
% Damage with breaching
CSR_Timeseries_DPA.S_seaside_with_repairs = Ssea_with_repairs;
CSR_Timeseries_DPA.S_leeside_with_repairs = SLee_with_repairs;
% Stores Timestep Where Breaching Occoured For Each Strom At Each LC
CSR_Timeseries_DPA.Seaside_Repair_Indexes = Seaside_Repair_Indexes;
CSR_Timeseries_DPA.Leeside_Repair_Indexes = Leeside_Repair_Indexes;
% Mean & Percentiles For THe Final Accumulated Damage Of All LC's
CSR_Timeseries_DPA.stats = stats;
% Repairs Stats
if repair_switch > 0
    CSR_Timeseries_DPA.Repairs_Stats = Repairs_Stats;
else
    CSR_Timeseries_DPA.seaside_repair_count = sea_repairs;
    CSR_Timeseries_DPA.leeside_repair_count = lee_repairs;
end
% Overall Structure Seaside Reliability
CSR_Timeseries_DPA.Reliability_Seaside = Reliability_Seaside;
% Overall Structure Seaside Reliability
CSR_Timeseries_DPA.Reliability_Leeside = Reliability_Leeside;
% Yearly Mean Maximum Cummulative Damages
CSR_Timeseries_DPA.Smax = Smax;
CSR_Timeseries_DPA.LSmax = LSmax;
% Yearly Mean Maximum Cummulative Damages Percentiles
CSR_Timeseries_DPA.LSPcurves = LSPcurves;
CSR_Timeseries_DPA.SPcurves = SPcurves;
% Diagnostics Data Structure 
CSR_Timeseries_DPA.diagnostics = diagnostics;

%% AUX FUNCTIONS
% DETERMINE STORM END ROW
    function  storm_end_row = find_storm_end(LC_SimOUT_hyd, NlcS, Ntime)
        storm_tstps = LC_SimOUT_hyd{NlcS}(Ntime:end,10); % 0:73 or 0:96 repeated for 70ish storms except missing first Ntime values
        % Find Row Index Of 1st TimeStep of Storms In LC
        storm_end_row = find(storm_tstps==0);
        % Find End Row Of present Storm
        if isempty(storm_end_row)==0 % if true, then all storms but last storm
            storm_end_row = Ntime+storm_end_row(1)-2; % all storms but last storm
        else
            storm_end_row = Ntime+length(storm_tstps)-1; % last storm because no zeros
        end
    end
% DETERMINE CORRESPONDING Ks & dS
    function [Ks_DwR, dS_DwR, on_first_storm] = damage_state(got_damage, on_first_storm, LC_SimOUT_hyd, NlcS, Ntime, Ksi, Ksp)
        if got_damage && on_first_storm % have damage and it is still the first damaging storm
            % set coefficient Ks to Ksi (first storm damage) or Ksp (progressive damage)
            % Note that there is one for "with_repairs" and one for "no_repairs"
            storm_end_row = find_storm_end(LC_SimOUT_hyd, NlcS, Ntime);
            if Ntime<storm_end_row
                Ks_DwR = Ksi;
                dS_DwR = 0.5;
                on_first_storm = 1; % logical indicating first storm has not been triggered yet
            else
                Ks_DwR = Ksp;
                dS_DwR = 0;
                on_first_storm = 0;
            end
        elseif got_damage
            Ks_DwR = Ksp;
            dS_DwR = 0;
        else
            Ks_DwR = Ksi;
            dS_DwR = 0.5;
        end % DwR &&
    end
% Determine Repair Condition 
     function repair_flag = repair_condition(repair_switch, SLS, ULS, S_last)
        % Determine Repair Conditions 
        switch repair_switch
            case 1 % Include Service Limit State Repairs (SLS)
                if S_last>SLS
                    repair_flag = true;
                else
                    repair_flag = false;
                end
            case 2 % Repair for Ultimate Limit State (ULS)
                if S_last>ULS
                    repair_flag = true;
                else
                    repair_flag = false;
                end
            case 3 % Repair for Service & Ultimate Limit State
                if S_last>ULS || S_last>SLS
                    repair_flag = true;
                else
                    repair_flag = false;
                end
            case 0  % No Repairs
                repair_flag = false;
            otherwise 
                error(['Error: Please specify supported repair scenario: ' newline ...
                    '0 - Repairs Not Included In Analysis' newline ...
                    '1 - SLS Repairs Are Included In Analysis' newline ...
                    '2 - repairs for ULS only' newline ...
                    '3 - repairs for both ULS and SLS']);
        end
    end
end
