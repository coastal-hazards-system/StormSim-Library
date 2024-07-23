function [project_forcing] = call_stormsim_mcs(config, storm, prob_mass)
%{
INPUTS:
     config.StormSamplingDropDown.Value; -> 'Extratropical Only' , 'Tropical Only' , 'Combined Sampling'
     config.nLifeCycles.Value -> Number of life cycles
     config.SimLength.Value -> Simulation Length
     config.SPID; -> Savepoint ID
     config.UseTimeseriesCheckBox.Value; -> True or False
     config.Data; -> CHS Data from matlab CHS Data Converter
     config.WaterLevelPriorityCheckBox.Value; -> True or False
     config.WaveHeightPriorityCheckBox.Value; -> True or False
     config.SaveNameEditField.Value; -> Output Dir Save Name
OUTPUTS:
    |   Vars Name   |  Vars Type  |               Description                |
    |---------------|-------------|------------------------------------------|
    | LC_SimOUT_hyd |  Structure  |  Time series life cyle structure used in |
    |               |             |  damage progression analysis (timeseries)|
    |---------------|-------------|------------------------------------------|
    |   MCSimOUT    |   Matrix    |  Contains peak water level and wave      |
    |               |             |  height values of sampled storms.        |
    |---------------|-------------|------------------------------------------|
    |    MC_indx    |  Structure  |  Contains storm indexes of sampled       |
    |               |             |  storms. Used to build LC_SimOUT_hyd     |
    |---------------|-------------|------------------------------------------|
    |  t1, t2, t3   |   Double    |  Process timing variables                |
    |---------------|-------------|------------------------------------------|

OUTPUTS HEADERS:
    LC_MCSimOUT:
        Size (# of LC's, 8) -> (Rows,Col)
        (01) Storm Year                   [-]
        (02) Cyclone Type                 [XC=0; TC=1]
        (03) Same year counter            [-]
        (04) Water Level                  [meters, MSL]
        (05) Wave Height                  [meters]
        (06) Peak Wave Period             [seconds]
        (07) Wave Direction               [degrees; N=0, E=+90, S=+/-180, W=-90]
        (08) Storm ID                     [-]
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
    MC_indx:
        First Level:
            Size (# of LC's, 1) -> (Rows,Col)
            Each row contains a vector which size depends on the ammount of
            storms sampled for that specific life cyccle.
        Second Level:
            (01) Storm Year               [-]
            (02) Storm Type               [-]
            (03) Same Year Counter        [-]
            (04) Storm ID                 [-]

%}
warning('off','all');
%% DEFINE VARIABLES
tMCS_Gen = tic;
%% GRAB INPUT FROM "config"
%{
        This section meant to provide an easy way to make changes to config
        variable calls without having to alter core code.
%}
% Storm Sampling Scheme
storm_sampling = config.storm_sampling;
% Number Of Life Cycles
number_of_life_cyles = config.mcs_nLC;
% Simulation Length
simulation_years = config.mcs_nYears;
% Create Water Level Priority Switch
wlp_switch = config.create_wlp;
% Create Wave Height Priority Switch
whp_switch = config.create_whp;
switch storm_sampling
    case 'TC'
        XC_Nstm = [];
        XC_Nyrs = [];
    otherwise
        % Define Number Of Extratropical Storms In Data
        XC_Nstm = config.Nstm_XC;
        % Define Number of Years IN Extratropical Data
        XC_Nyrs = config.Nyrs_XC;
end
% Define MCS Sample Method
sample_method = config.mcs_sampling_mode;

%% DEFINE ADDITIONAL VARIABLES
% Initialize Life Cycle Storage Vars
if contains(storm_sampling,{'XC','CC'})
    % Initialize Maxima Dataset MC Storage Variable
    project_forcing.('XC').Peaks.Maxima = repmat(struct('LCNUM',1),number_of_life_cyles,1);
    % Initialize WLP Dataset MC Storage Variable
    project_forcing.('XC').Peaks.WLP = repmat(struct('LCNUM',1),number_of_life_cyles,1);
    % Initialize WHP Dataset MC Storage Variable
    project_forcing.('XC').Peaks.WHP = repmat(struct('LCNUM',1),number_of_life_cyles,1);
    % Initialize Maxima Dataset MC Sampled Index Storage Variable
    project_forcing.('XC').Peaks.sampled_storms_indx = repmat(struct('LCNUM',1),number_of_life_cyles,1);
end
if contains(storm_sampling,{'TC','CC'})
    % Initialize Maxima Dataset MC Storage Variable
    project_forcing.('TC').Peaks.Maxima = repmat(struct('LCNUM',1),number_of_life_cyles,1);
    % Initialize WLP Dataset MC Storage Variable
    project_forcing.('TC').Peaks.WLP = repmat(struct('LCNUM',1),number_of_life_cyles,1);
    % Initialize WHP Dataset MC Storage Variable
    project_forcing.('TC').Peaks.WHP = repmat(struct('LCNUM',1),number_of_life_cyles,1);
    % Initialize Maxima Dataset MC Sampled Index Storage Variable
    project_forcing.('TC').Peaks.sampled_storms_indx = repmat(struct('LCNUM',1),number_of_life_cyles,1);
    % Initialize TC Sampled Intensity Index
    project_forcing.('TC').Peaks.TC_iclass  = repmat(struct('LCNUM',1),number_of_life_cyles,1);
end



%% CYCLE THROUGH LIFE CYCLES
% Command Prompts
disp('   Running StormSim: Monte Carlo Simulation (Storm Sampling)....');
fprintf(1,'      Completion Progress: %3d%%\n',0);
for lc=1:number_of_life_cyles

    %% MONTE CARLO SIMULATION - EXTRATROPICAL CYCLONES
    if strcmp(storm_sampling,'CC')==1 || strcmp(storm_sampling,'XC')==1
        [project_forcing.('XC').Peaks.sampled_storms_indx(lc,1).LCNUM,...
            project_forcing.('XC').Peaks.Maxima(lc,1).LCNUM,...
            project_forcing.('XC').Peaks.WLP(lc,1).LCNUM,...
            project_forcing.('XC').Peaks.WHP(lc,1).LCNUM] = ...
            mcs_sample_xc(storm, simulation_years, XC_Nstm, XC_Nyrs, wlp_switch, whp_switch, sample_method);
    end

    %% MONTE CARLO SIMULATION - TROPICAL CYCLONES
    if strcmp(storm_sampling,'CC')==1 || strcmp(storm_sampling,'TC')==1
        [project_forcing.('TC').Peaks.sampled_storms_indx(lc,1).LCNUM,...
            project_forcing.('TC').Peaks.Maxima(lc,1).LCNUM,...
            project_forcing.('TC').Peaks.TC_iclass(lc,1).LCNUM,...
            project_forcing.('TC').Peaks.WLP(lc,1).LCNUM,...
            project_forcing.('TC').Peaks.WHP(lc,1).LCNUM] = ...
            mcs_sample_tc(storm, simulation_years, prob_mass, wlp_switch, whp_switch, sample_method);
    end

    %% COMBINE TROPICAL AND EXTRATROPICAL SAMPLED STORMS
    if strcmp(storm_sampling,'CC')==1
        % Combined Suite Of XC and TC for Simulation Period Per Each Modeled Life-Cycle
        project_forcing.('CC').Peaks.Maxima(lc,1).LCNUM = sortrows([project_forcing.('TC').Peaks.Maxima(lc,1).LCNUM;...
            project_forcing.('XC').Peaks.Maxima(lc,1).LCNUM],[1 2 3]);

        if whp_switch
            % Combined Suite Of XC and TC for Simulation Period Per Each Modeled Life-Cycle
            project_forcing.('CC').Peaks.WHP(lc,1).LCNUM = sortrows([project_forcing.('TC').Peaks.WHP(lc,1).LCNUM;...
                project_forcing.('XC').Peaks.WHP(lc,1).LCNUM],[1 2 3]);
        end
        if wlp_switch
            % Combined Suite Of XC and TC for Simulation Period Per Each Modeled Life-Cycle
            project_forcing.('CC').Peaks.WLP(lc,1).LCNUM = sortrows([project_forcing.('TC').Peaks.WLP(lc,1).LCNUM;...
                project_forcing.('XC').Peaks.WLP(lc,1).LCNUM],[1 2 3]);
        end
        % Indexes Of Combined Suite Of XC and TC for Simulation Period Per Each Modeled Life-Cycle
        project_forcing.('CC').Peaks.sampled_storms_indx(lc,1).LCNUM = sortrows([project_forcing.('TC').Peaks.sampled_storms_indx(lc,1).LCNUM;...
            project_forcing.('XC').Peaks.sampled_storms_indx(lc,1).LCNUM],[1 2 3]);
    end

    fprintf(1,'\b\b\b\b%3.0f%%',(100*(lc/number_of_life_cyles)));
end%outside LC loop
fprintf(1,['\b\b\b\b%3.0f%%' newline],(100*(lc/number_of_life_cyles)));

%% REMOVE ADDITIONAL FIELDS (IF NEEDED)
% Wave Height Priority
if whp_switch == 0
    % Remove Empty Field (Tropicals)
    if contains(storm_sampling,{'TC','TS','CC'})
        project_forcing.('TC').Peaks = rmfield(project_forcing.('TC').Peaks,'WHP');
    end
    % Remove Empty Field (Extratropicals)
    if contains(storm_sampling,{'XC','XH','CC'})
        project_forcing.('XC').Peaks = rmfield(project_forcing.('XC').Peaks,'WHP');
    end
end
% Water Level Priority
if wlp_switch == 0
    % Remove Empty Field (Tropicals)
    if contains(storm_sampling,{'TC','TS','CC'})
        project_forcing.('TC').Peaks = rmfield(project_forcing.('TC').Peaks,'WLP');
    end
    % Remove Empty Field (Extratropicals)
    if contains(storm_sampling,{'XC','XH','CC'})
        project_forcing.('XC').Peaks = rmfield(project_forcing.('XC').Peaks,'WLP');
    end
end

warning('on','all');
end