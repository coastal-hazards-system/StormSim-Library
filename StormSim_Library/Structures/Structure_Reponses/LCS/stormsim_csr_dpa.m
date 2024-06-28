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
            (01) Storm ID                 [-]
            (02) Time Series Length       [-]
            (03) Timestep Counter         [-]
            (04) Date/Time                [-]
            (05) Water Level              [meters, MSL]
            (06) Wave Height              [meters]
            (07) Peak Wave Period         [seconds]
            (08) Wave Direction           [degrees; N=0, E=+90, S=+/-180, W=-90]
            (09) Storm Duration           [days]

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
grav = 9.80665;
% Limits Damage Accumulation To Increments Of Roughly S>.8
Szerolim = 0.2;
% Determine Number Of Life Cycles
nLC = length(LC_SimOUT_hyd);
% Determine Number Of Timesteps Per Life Cycle
nTimes_per_LC = cellfun(@(x) length(x(:,1)),LC_SimOUT_hyd);
% Define Number of Years
nYears = config.mcs_nYears;
% Determine Forcing Data Cols
%     matrix_width = length(LC_SimOUT_hyd{1}(1,:));

%% GRAB INPUTS FROM "config"
% ---------- PROJECT DETAILS ----------
% Water density (kg/m^3)
dw = config.water_density;
% Seaside Damage Ultimate Limit State (ULS)
Ssea_ULS = config.seaside_S_uls;
% Leeside Damage Ultimate Limit State (ULS)
Slee_ULS = config.leeside_S_uls;
% Structure Type
structure_type = config.struc_type;
% Coefficients are found in CEM and in Eurotop. For levees with grass, the
% surface roughness influence increses for small wave heights.
gamma_f = config.roughness_ifactor;
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
%{
'crest_elevation'	'crest_elevation_lcbw'	'crest_width'	'toe_elevation'	
'seaside_slope'	    'leeside_slope'	        'berm_width'	'berm_elevation'	
'berm_slope'	    'armor_delta'	        'lcbw_mass'	    'seaside_mass'	
'leeside_mass'      'water_density'	        'cem_P'	        'seaside_design_S'
'leeside_design_S'  'seaside_init_S'	    'leeside_init_S'	
'roughness_ifactor' 'seaside_S_uls'	        'leeside_S_uls'
%}
% Grab Fieldnames
sFields = fieldnames(structure);
% Extract Strcutural Paramaters From Structure
for ii = 1:length(sFields)
    eval([sFields{ii} ' = structure.(sFields{ii});']);
end
%
% wall_bottom_elev = toe_elevation;
% Armor Stone Specific Gravity
SG = 1 + armor_delta;
% Armor Stone Density [kg/m^3]
dr = SG*dw;
% Seaside Median Volume of Armor Stone
V_ss = seaside_mass/dr;
% Seaside Nominal Stone Diameter (m)
SDn = V_ss^(1/3);
% % (LCBW) Seaside Median Volume of Armor Stone
V_ss_lcbw = lcbw_seaside_mass/dr;
% % (LCBW) Seaside Nominal Stone Diameter (m)
SDn_lcbw = V_ss_lcbw^(1/3);
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
LCBW_FS =  cellfun(@(x) zeros(x,1),num2cell(nTimes_per_LC),'un',false);
% q =  cellfun(@(x) zeros(x,1),num2cell(nTimes_per_LC),'un',false);

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
    % Repair Indexes Storage Variables
    Seaside_Repair_Indexes(NlcS).LCNUM = [];
    Leeside_Repair_Indexes(NlcS).LCNUM = [];
    Leestlen = 0;
    stlen = 0;
    stlen_Ks=0;
    Ks = Ksi; %start with accelerated early damage
    dS = 0.5; %start with accelerated early damage
    Ks_DwR = Ksi;
    dS_DwR = 0.5;
    Ks_DnR = Ksi;
    dS_DnR = 0.5;
    %    StormIndex_last=LC_SimOUT_hyd{1,NlcS}(1);
    first_damaging_storm_DnR = 0; % logical indicating first storm has not been triggered yet
    first_damaging_storm_DwR = 0; % logical indicating first storm has not been triggered yet
    DwR = 0; %logical indicating damage with repairs is zero
    DnR = 0; %logical indicating damage no repairs is zero
    %% BEGIN LIFE CYCLE LOOP
    for Ntime=1:nTimes_per_LC(NlcS)
        %% COMPUTE RESPONSE

        if DwR && first_damaging_storm_DwR % have damage and it is still the first damaging storm
            % set coefficient Ks to Ksi (first storm damage) or Ksp (progressive damage)
            % Note that there is one for "with_repairs" and one for "no_repairs"
            stlen_Ks = LC_SimOUT_hyd{NlcS}(Ntime:end,3); % 0:73 or 0:96 repeated for 70ish storms except missing first Ntime values
            % Find Row Index Of 1st TimeStep of Storms In LC
            stmindx = find(stlen_Ks==0);
            % Find End Row Of present Storm
            if isempty(stmindx)==0 % if true, then all storms but last storm
                stlen_Ks = Ntime+stmindx(1)-2; % all storms but last storm
            else
                stlen_Ks = Ntime:Ntime+length(LC_SimOUT_hyd{NlcS}(Ntime:end,3))-1; % last storm because no zeros
            end
            if Ntime<stlen_Ks(end)
                Ks_DwR = Ksi;
                dS_DwR = 0.5;
                first_damaging_storm_DwR = 1; % logical indicating first storm has not been triggered yet
            else
                Ks_DwR = Ksp;
                dS_DwR = 0;
                first_damaging_storm_DwR = 0;
            end
        elseif DwR
            Ks_DwR = Ksp;
            dS_DwR = 0;
        else
            Ks_DwR = Ksi;
            dS_DwR = 0.5;
        end % DwR &&

        if DnR && first_damaging_storm_DnR % have damage and it is still the first damaging storm
            % set coefficient Ks to Ksi (first storm damage) or Ksp (progressive damage)
            % Note that there is one for "with_repairs" and one for "no_repairs"
            stlen_Ks = LC_SimOUT_hyd{NlcS}(Ntime:end,3); % 0:73 or 0:96 repeated for 70ish storms except missing first Ntime values
            % Find Row Index Of 1st TimeStep of Storms In LC
            stmindx = find(stlen_Ks==0);
            % Find End Row Of present Storm
            if isempty(stmindx)==0 % if true, then all storms but last storm
                stlen_Ks = Ntime+stmindx(1)-2; % all storms but last storm
            else
                stlen_Ks = Ntime:Ntime+length(LC_SimOUT_hyd{NlcS}(Ntime:end,3))-1; % last storm because no zeros
            end
            if Ntime<stlen_Ks(end)
                Ks_DnR = Ksi;
                dS_DnR = 0.5;
                first_damaging_storm_DnR = 1; % logical indicating first storm has not been triggered yet
            else
                Ks_DnR = Ksp;
                dS_DnR = 0;
                first_damaging_storm_DnR = 0;
            end
        elseif DnR
            Ks_DnR = Ksp;
            dS_DnR = 0;
        else
            Ks_DnR = Ksi;
            dS_DnR = 0.5;
        end %if DnR &&

        %% SEASIDE STABILITY WITH REPAIRS ANALYSIS
        if Ssea_with_repairs_last>Ssea_ULS && repair_switch == 1
            %% Determine Remaning Timesteps (After Breach) Of LC Storm Being Evaluated
            if stlen(1) == 0 %exist('stlen','var')==0
                % Get Remaining TimeSteps In LC
                stlen = LC_SimOUT_hyd{NlcS}(Ntime:end,3);
                % Find Row Index Of 1st TimeStep of Storms In LC
                stdummy = find(stlen==0); % find indexes of all initial storm values
                % Find End Row Of Breaching Storm
                if isempty(stdummy)==0
                    stlen = Ntime+stdummy(1)-2; % last storm
                else
                    stlen = Ntime:Ntime+length(LC_SimOUT_hyd{NlcS}(Ntime:end,3))-1; % all storms but last storm
                end
                % Store Row Index Where Breaching Occoured
                Seaside_Repair_Indexes(NlcS).LCNUM = [Seaside_Repair_Indexes(NlcS).LCNUM;Ntime-1];
            end

            %% Compute Damage Accumulation
            % Compute Seaside Zero Damage S Value
            if Hm0{NlcS}(Ntime)<0.1
                Szero_no_repairs{NlcS}(Ntime)=0;
            else
                [Szero_no_repairs{NlcS}(Ntime)] = ZeroSeaDamFunc(Hm0{NlcS}(Ntime),h{NlcS}(Ntime),Tm{NlcS}(Ntime),...
                    Ssea_no_repairs_last,seaside_slope,SDn,SG,...
                    grav,cem_P,Nz{NlcS}(Ntime),Km1,Km2,Ks_DwR);
            end

            % Compute Incremental Seaside Damage
            [Ssea_no_repairs{NlcS}(Ntime)] = SeaDamFunc(Szero_no_repairs{NlcS}(Ntime),h{NlcS}(Ntime),Ssea_no_repairs_last,...
                Hm0{NlcS}(Ntime),Tm{NlcS}(Ntime),crest_elevation,seaside_slope,SDn,SG,grav,...
                cem_P,Nz{NlcS}(Ntime),Rc{NlcS}(Ntime),Szerolim,cutoff_delta,WL{NlcS}(Ntime),...
                cutoff_switch,Km1,Km2,Ks_DnR,dS_DnR);
            % Store Previous Seaside Damage Value

            if Ssea_with_repairs_last == 0 && Ssea_with_repairs{NlcS}(Ntime) > 0
                DwR  = 1; % have damage
                first_damaging_storm_DwR = 1; % logical indicating first storm has been triggered
            end
            if Ssea_no_repairs_last == 0 && Ssea_no_repairs{NlcS}(Ntime) > 0
                DnR  = 1; % have damage
                first_damaging_storm_DnR = 1; % logical indicating first storm has been triggered
            end

            Ssea_no_repairs_last = Ssea_no_repairs{NlcS}(Ntime);

            %% Seaside Damage With Repairs Assignment (NaN=Breaching -> Repair Period)
            % Seaside Damage Trigger
            Szero_with_repairs{NlcS}(Ntime) = NaN(1,1);
            % Seaside Damage
            Ssea_with_repairs{NlcS}(Ntime) = NaN(1,1);

            %% Exit Breaching Analysis When Storm Ends
            if Ntime==stlen(end)
                % Reset Seaside Damages
                Ssea_with_repairs_last = 0;
                stlen = 0;%clearvars('stlen');
            end
        else %Ssea_with_repairs_last>Ssea_ULS && repair_switch == 1
            %% SEASIDE STABILITY WITHOUT REPAIRS ANALYSIS
            %% Compute Damage Accumulation
            % Compute Seaside Zero Damage S Value
            if Hm0{NlcS}(Ntime)<0.1
                % Szero for With Repairs Analysis
                Szero_with_repairs{NlcS}(Ntime)=0;
                % Szero for No Repairs Analysis
                Szero_no_repairs{NlcS}(Ntime)=0;
            else
                % Szero for With Repairs Analysis
                [Szero_with_repairs{NlcS}(Ntime)] = ZeroSeaDamFunc(Hm0{NlcS}(Ntime),h{NlcS}(Ntime),Tm{NlcS}(Ntime),...
                    Ssea_with_repairs_last,seaside_slope,SDn,SG,...
                    grav,cem_P,Nz{NlcS}(Ntime),Km1,Km2,Ks_DwR);
                % Szero for No Repairs Analysis
                [Szero_no_repairs{NlcS}(Ntime)] = ZeroSeaDamFunc(Hm0{NlcS}(Ntime),h{NlcS}(Ntime),Tm{NlcS}(Ntime),...
                    Ssea_no_repairs_last,seaside_slope,SDn,SG,grav,...
                    cem_P,Nz{NlcS}(Ntime),Km1,Km2,Ks_DnR);
            end

            % Seaside Damage With Repairs
            [Ssea_with_repairs{NlcS}(Ntime)] = SeaDamFunc(Szero_no_repairs{NlcS}(Ntime),h{NlcS}(Ntime),Ssea_no_repairs_last,...
                Hm0{NlcS}(Ntime),Tm{NlcS}(Ntime),crest_elevation,seaside_slope,SDn,SG,grav,...
                cem_P,Nz{NlcS}(Ntime),Rc{NlcS}(Ntime),Szerolim,cutoff_delta,WL{NlcS}(Ntime),...
                cutoff_switch,Km1,Km2,Ks_DnR,dS_DnR);

            % Seaside Damage Without Repairs
            [Ssea_no_repairs{NlcS}(Ntime)] = SeaDamFunc(Szero_no_repairs{NlcS}(Ntime),h{NlcS}(Ntime),Ssea_no_repairs_last,...
                Hm0{NlcS}(Ntime),Tm{NlcS}(Ntime),crest_elevation,seaside_slope,SDn,SG,grav,...
                cem_P,Nz{NlcS}(Ntime),Rc{NlcS}(Ntime),Szerolim,cutoff_delta,WL{NlcS}(Ntime),...
                cutoff_switch,Km1,Km2,Ks_DnR,dS_DnR);




            if Ssea_with_repairs_last == 0 && Ssea_with_repairs{NlcS}(Ntime) > 0
                DwR  = 1; % have damage
                first_damaging_storm_DwR = 1; % logical indicating first storm has been triggered
            end
            if Ssea_no_repairs_last == 0 && Ssea_no_repairs{NlcS}(Ntime) > 0
                DnR  = 1; % have damage
                first_damaging_storm_DnR = 1; % logical indicating first storm has been triggered
            end

            %% Store Damage Calculations For Next Iteration
            % Seaside Damage With Repairs
            Ssea_with_repairs_last = Ssea_with_repairs{NlcS}(Ntime);
            % Seaside Damage Without Repairs
            Ssea_no_repairs_last = Ssea_no_repairs{NlcS}(Ntime);
        end %Ssea_with_repairs_last>Ssea_ULS && repair_switch == 1
        %% LEESIDE STABILITY WITH REPAIRS ANALYSIS
        if SLee_with_repairs_last>Slee_ULS && repair_switch == 1
            %% Determine Remaning Timesteps (After Breach) Of LC Storm Being Evaluated
            if Leestlen(1) == 0 %exist('Leestlen','var')==0
                % Get Remaining TimeSteps In LC
                Leestlen = LC_SimOUT_hyd{NlcS}(Ntime:end,3);
                % Find Row Index Of 1st TimeStep of Storms In LC
                Leestdummy = find(Leestlen==0);
                % Find End Row Of Breaching Storm
                if isempty(Leestdummy)==0
                    Leestlen = Ntime+Leestdummy(1)-2; % -2 ensures we keep the breaching timestep responses
                else
                    Leestlen = Ntime:Ntime+length(LC_SimOUT_hyd{NlcS}(Ntime:end,3))-1;
                end
                % Store Row Index Where Breaching Occoured
                Leeside_Repair_Indexes(NlcS).LCNUM = [Leeside_Repair_Indexes(NlcS).LCNUM;Ntime-1];
            end

            %% Compute Damage Accumulation
            % Compute Wave Runup
            if Hm0{NlcS}(Ntime)<0.1 || Tp{NlcS}(Ntime)<0
                z1p{NlcS}(Ntime)=0;
            end
            % Compute Incremental Leeside Damage
            [SLee_no_repairs{NlcS}(Ntime),u1p{NlcS}(Ntime)] = LeeDamFunc_v2(u1p{NlcS}(Ntime),z1p{NlcS}(Ntime),SLee_no_repairs_last,...
                Hm0{NlcS}(Ntime),Tp{NlcS}(Ntime),u1p_last,LDn,...
                leeside_slope,Rc{NlcS}(Ntime),Nz{NlcS}(Ntime),armor_delta,K_ls1,K_ls2,crest_width,gamma_f);

            % Store Previous Leeside Damage Value (Incremental)
            SLee_no_repairs_last = SLee_no_repairs{NlcS}(Ntime);
            u1p_last = u1p{NlcS}(Ntime);

            %% Leeside Damage Assignment (NaN=Breaching -> Repair Period)
            % Leeside Damage
            SLee_with_repairs{NlcS}(Ntime) = NaN(1,1);

            %% Exit Breaching Analysis When Storm Ends
            if Ntime==Leestlen(end)
                % Reset Leeside Damages
                SLee_with_repairs_last = 0;
                Leestlen(1) = 0; %clearvars('Leestlen');
            end

        else %SLee_with_repairs_last>Slee_ULS && repair_switch == 1
            %% LEESIDE STABILITY WITHOUT REPAIRS ANALYSIS
            %% Compute Damage Accumulation
            % Compute Wave Runup
            if Hm0{NlcS}(Ntime)<0.1 || Tp{NlcS}(Ntime)<0
                z1p{NlcS}(Ntime)=0;
            end
            % Leeside Damage With Repairs
            [SLee_with_repairs{NlcS}(Ntime),u1p{NlcS}(Ntime)] = LeeDamFunc_v2(u1p{NlcS}(Ntime),z1p{NlcS}(Ntime),SLee_with_repairs_last,...
                Hm0{NlcS}(Ntime),Tp{NlcS}(Ntime),u1p_last,LDn,...
                leeside_slope,Rc{NlcS}(Ntime),Nz{NlcS}(Ntime),armor_delta,K_ls1,K_ls2,crest_width,gamma_f);
            % Leeside Damage Without Repairs
            [SLee_no_repairs{NlcS}(Ntime),u1p{NlcS}(Ntime)] = LeeDamFunc_v2(u1p{NlcS}(Ntime),z1p{NlcS}(Ntime),SLee_no_repairs_last,...
                Hm0{NlcS}(Ntime),Tp{NlcS}(Ntime),u1p_last,LDn,...
                leeside_slope,Rc{NlcS}(Ntime),Nz{NlcS}(Ntime),armor_delta,K_ls1,K_ls2,crest_width,gamma_f);

            %% Store Damage Calculations For Next Iteration
            % Leeside Damage With Repairs
            SLee_with_repairs_last = SLee_with_repairs{NlcS}(Ntime);
            % Leeside Damage Without Repairs
            SLee_no_repairs_last = SLee_no_repairs{NlcS}(Ntime);
        end %SLee_with_repairs_last>Slee_ULS && repair_switch == 1
        %             disp(['LC: ' num2str(NlcS) ' , Timestep: ' num2str(Ntime) ' / ' num2str(nTimes_per_LC(NlcS))]);

        %% toe berm limit state
        [LCBW_FS{NlcS}(Ntime)] = melby_low_crested_LCS(Hm0{NlcS}(Ntime),Rc{NlcS}(Ntime),armor_delta,SDn_lcbw);
        %% Overtopping limit state
        %             gammas = call_eurotop_ifactors(config, structure, WL{NlcS}(Ntime), Hm0{NlcS}(Ntime));
        %             [~, ~, q{NlcS}(Ntime), ~, ~]=Eurotop_r2p_q_Final(Hm0{NlcS}(Ntime), Tp{NlcS}(Ntime), WL{NlcS}(Ntime), Rc{NlcS}(Ntime),...
        %                berm_slope, gammas.gamma_f, gammas.gamma_beta_r2p, gammas.gamma_beta_q, gammas.gamma_star, gammas.gamma_v, gammas.gamma_b,...
        %                wall_bottom_elev, berm_width, structure_type);

    end %Ntime_per_LC  %structure_type == 3 % Rubblemound
    fprintf(1,'\b\b\b\b%3.0f%%',(100*(NlcS/nLC)));
end  % NLS
disp([newline '      Computing Post Damage Statistics....']);
%% STORE LAST COMPUTED DAMAGE FOR EACH LC
% This will turn into a mean sigular value once percentiles are computed
% Seaside
Smean = cell2mat(cellfun(@(x) x(end),Ssea_no_repairs,'un',false));
LSmean = cell2mat(cellfun(@(x) x(end),SLee_no_repairs,'un',false));

%% DIAGNOSTICS STRUCTURE
diagnostics(1,:) = cellfun(@(a) table(WL{a},Hm0{a},...
    Tp{a},h{a},Nz{a},Rc{a},z1p{a},u1p{a},Szero_no_repairs{a},Ssea_no_repairs{a},Szero_with_repairs{a},...
    Ssea_with_repairs{a}, SLee_no_repairs{a}, SLee_with_repairs{a}, LCBW_FS{a}', 'VariableNames',...
    {'WL','Hm0','Tp','h','Nz','Rc','z1p','u1p',...
    'Szero_no_repairs','Ssea_no_repairs','Szero_with_repairs','Ssea_with_repairs',...
    'SLee_no_repairs','SLee_with_repairs','LCBW_FS'}),...
    num2cell(1:nLC),'un',false)';

%% COMPUTE MEAN DAMAGE CURVE
[LSmax,LSPcurves,~] = compute_lcs_yearly_curve(LC_SimOUT_hyd, SLee_no_repairs, nYears, 0);
[Smax,SPcurves,~] = compute_lcs_yearly_curve(LC_SimOUT_hyd, Ssea_no_repairs, nYears, 0);

% Fill values for year 0
years = [0:length(Smax)]';
Smax = [0;Smax];
LSmax = [0;LSmax];
SPcurves = [zeros(size(SPcurves(1,:)));SPcurves];
LSPcurves = [zeros(size(SPcurves(1,:)));LSPcurves];

%% COMPUTE STATISTICS - TABLE
% Define Percentiles
p = [10 16 84 90]';
% Compute Percentiles
Sp = prctile(Smean,[10 16 84 90])';
LSp = prctile(LSmean,[10 16 84 90])';
% Compute Mean Accumulated Damage For Bin
Smean = repmat(mean(Smean,'omitnan'),size(p));
LSmean = repmat(mean(LSmean,'omitnan'),size(p));
% Build Stats Table
stats = table(p,Smean,Sp,LSmean,LSp);

%% COMPUTE AMOUNT OF REPAIRS
if repair_switch == 1
    % Seaside N Repairs
    sea_repairs = cell2mat(cellfun(@(x) length(x),{Seaside_Repair_Indexes.LCNUM},'UniformOutput',false));
    % Leeside N Repairs
    lee_repairs = cell2mat(cellfun(@(x) length(x),{Leeside_Repair_Indexes.LCNUM},'UniformOutput',false));
else
    % Seaside N Repairs
    sea_repairs = length(find(cell2mat(cellfun(@(x) max(x),Ssea_no_repairs,'UniformOutput',false))>=Ssea_ULS));
    % Leeside N Repairs
    lee_repairs = length(find(cell2mat(cellfun(@(x) max(x),SLee_no_repairs,'UniformOutput',false))>=Slee_ULS));
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

%% COMPUTE RELIABILITY
if repair_switch == 1
    % Seaside Reliability
    Reliability_Seaside = 1 - length(find(cell2mat(cellfun(@(x) length(x),{Seaside_Repair_Indexes.LCNUM},'UniformOutput',false))>0))/nLC;
    % Leeside Reliability
    Reliability_Leeside = 1 - length(find(cell2mat(cellfun(@(x) length(x),{Leeside_Repair_Indexes.LCNUM},'UniformOutput',false))>0))/nLC;
else
    % Seaside Reliability
    Reliability_Seaside = 1 - length(find(cell2mat(cellfun(@(x) max(x),Ssea_no_repairs,'UniformOutput',false))>Ssea_ULS))/nLC;
    % Leeside Reliability
    Reliability_Leeside = 1 - length(find(cell2mat(cellfun(@(x) max(x),SLee_no_repairs,'UniformOutput',false))>Slee_ULS))/nLC;
end

%% GENERATE OUTPUTS DATA STRUCTURE
% Damage with no breaching
CSR_Timeseries_DPA.S_seaside_no_repairs = Ssea_no_repairs;
CSR_Timeseries_DPA.S_leeside_no_repairs = SLee_no_repairs;
% Damage with breaching
CSR_Timeseries_DPA.S_seaside_with_repairs = Ssea_with_repairs;
CSR_Timeseries_DPA.S_leeside_with_repairs = SLee_with_repairs;
% Stores Timestep Where Breaching Occoured For Each Strom At Each LC
CSR_Timeseries_DPA.Seaside_Repair_Indexes = {Seaside_Repair_Indexes.LCNUM};
CSR_Timeseries_DPA.Leeside_Repair_Indexes = {Leeside_Repair_Indexes.LCNUM};
% Mean & Percentiles For THe Final Accumulated Damage Of All LC's
CSR_Timeseries_DPA.stats = stats;
% Repairs Stats
CSR_Timeseries_DPA.Repairs_Stats = Repairs_Stats;
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
CSR_Timeseries_DPA.diagnostics = diagnostics;
