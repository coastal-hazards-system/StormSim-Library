clc;clear all;close all;
addpath(genpath('StormSim_Library'));
% diary 'Log.txt';
%% USER INPUTS
%{
MCS/CSR Requires:
    MCSim_Inputs -> TC Storm Probability Masses 
%}
% Define StormSim Input File Name
stormsim_input_file = 'StormSim_Inputs.xlsx'; % Include relative path if not in parent directory

%% STEP 1: SET-UP PROJECT ENVIRONMENT
%{
 Description:
   In order to use the full functionalities included within the StormSim
   library it is necesary to provide an input file. Please copy and fill
   out the provided "StormSim_Inputs.xlsx" template. Do not change the
   values written under "Model Variable Symbol" as this will brake the
   toolbox in its entirety.
  Outputs:
   1. config: Contains parsed information from StormSim input file | 1 x 1 | structure, with nFields 
   2. structure: Contains parsed information for the specified structure type. | 1x1 | structure, with nFields
%}
t1 = tic;
% Parse StormSim Configuration File
[config, structure] = call_input_parser(stormsim_input_file);
t1 = toc(t1);

%% STEP 2: IMPORT, PROCESS & FORMAT COASTAL HAZARD SYSTEM (CHS) DATA (h5 -> MATLAB Memory)
%{
 Description:
   First step of any project is to screen and format the forcing data. In
   this case we are showcasing the use of CHS data. CHS host tropical (TC)
   and extratropical (XC) "Peaks" and "Timeseries" data in a save point
   context. Within each save point you can find ADCIRC & wave model
   (STWAVE/SWAN/WAM) storm data. The function "call_chs_data_formatter.m"
   reads the provided CHS zip folder (or files) and imports, formats and 
   screens storm data. Additional screening and datasets can be
   constructed if corresponding timeseries files are provided.

Inputs:
  Files:
    1. CHS HDF5 files (or packaged in .zip from CHS). Files must include
    at least 1 data pair ( ADCIRC & Wave Model ) of "Peaks" datasets for a
    given storm type (XC or TC). If data pair corresponding timeseries
    files are included then additional screening (timeseries inspection)
    and datasets are created (WLP and/or WHP) at the request of the user 
    (config). Max amount of files accepted is 8 -> 2 data pairs
    (4 Peaks files) + corresponding timeseries files (4 timeseries files).
   Vars:
    1. config

Outputs: 
  Output variables will be in the form of MATLAB data structures in order
  to keep everything organized through the whole process. Structures will
  have additional levels if needed. Structure levels include: storm type
  (XC, TC or CC), data type (Peaks or Timeseries), dataset (Maxima, WLP,
  WHP). 

  Files (.mat):
    1. Raw converted CHS HDF5 files -> exported to project folder with
    suffix "_raw_files"
    2. Formated and screened  CHS File Data, prob_masses, parsed inputs (config) -> exported to project folder with
    suffix "CHS_region_SP####"
  Vars:
    1. config: Contains parsed information from StormSim input file | 1 x 1 | structure, with nFields 

    2. storm: Contains screened and formated CHS storm data. | 1 X 1 | structure, with nfields
              Peaks storm data is formated in nStorms x 5 
              array ([ SWL Hm0 Tp wave_dir stormID ]). 
              Timeseries storm data is formated in nStorms x 2
              cell array ([storm ID, storm hydrograph]) where,
              storm hydrograph is a nStorms x 6 array 
              ([datenum SWL Hm0 Tp wave_dir storm_duration])

    3. prob_mass: Contains screened and formated CHS storm data probability masses. | 1 X 1 | structure, with nfields
                  For specified CHS region includes Param, TC_SRR, TC_Freq,
                  dist, TotalFreq, smpl0, smpl1. LCS workflows use all
                  these variables. RB workflows only use TC_freq.

%}
t2 = tic;
% Call CHS Set-up Function 
[storm, ~, prob_mass, config] = call_chs_data_formater(config);
t2 = toc(t2);

%% STEP 3: CREATE STORM FORCING 
%{
 Description:
   Once input storm data has been formated the next step is to generate the
   project forcing. There are three options to choose here: 1 - Response
   Base (RB1 & RB3, StormSim: PROS), 2 - MCS (LCS, StormSim: MCS) , 3 - MCS/CSR
   (LCS, StormSim: MCS/CSR. The key difference being a response base
   approach or doing a life cycle simulation (LCS) using
   peaks and timeseries. Option 3 computes structure response (S, R2p, q) after
   performing MCS storm sampling. Forcing generation options can be changed
   in input file by changing row with "workflow" as Model Variable
   Symbol.

Inputs:
   Vars:
    1. config
    2. storm 
    3. prob_mass

Outputs: 
  Output variables will be in the form of MATLAB data structures in order
  to keep everything organized through the whole process. Structures will
  have additional levels if needed. Structure levels include: storm type
  (XC, TC or CC), data type (Peaks or Timeseries), dataset (Maxima, WLP,
  WHP). 

  Files (.mat):
    1. Project forcing data -> exported to project folder with
    suffix " _project_forcing"
  
  Vars:
    1. project_forcing: Contains project forcing data. | 1 x 1 | structure, with nFields 

    First Level:
    Size (# of LC's, 1) -> (Rows,Col)
    Each row contains a matrix which size depends on the ammount of
    storms sampled for that specific life cycle.
    
    Peaks LC Format (Maxima, WHP, WLP):
        Size (# of LC's, 8) -> (Rows,Col)
        (01) Year                         [-]
        (02) Cyclone Type                 [XC=0; TC=1]
        (03) Same year counter            [-]
        (04) Water Level                  [meters, MSL]
        (05) Wave Height                  [meters]
        (06) Peak Wave Period             [seconds]
        (07) Wave Direction               [degrees; N=0, E=+90, S=+/-180, W=-90]
        (08) Storm Duration               [hours]
    
     Timeseries LC Format:
        (01) Storm ID                 [-]
        (02) Time Series Length       [-]
        (03) Timestep Counter         [-]
        (04) Date/Time                [-]
        (05) Water Level              [meters, MSL]
        (06) Wave Height              [meters]
        (07) Peak Wave Period         [seconds]
        (08) Wave Direction           [degrees; N=0, E=+90, S=+/-180, W=-90]
        (09) Storm Duration           [days]
        (10) Simulation Year          [years]

%}
t3 = tic;
[project_forcing] = call_project_forcing_formater(config, storm, prob_mass);
t3 = toc(t3);

%% STEP 4: APPLY UNCERTAINTY TO PROJECT STRUCTURE AND FORCING PER WORKFLOW
t4 = tic;
[project_forcing, config] = call_uncertainty_engine(config, project_forcing);
t4 = toc(t4);

%% STEP 5: APPLY PORJECT FORCING ADJUSTMENTS 
% For Response Base Analysis:
% _no_rep fields are used for SWL, Hm0, Tp, hazard curve calculations
% Hence will not have depth limitation applied. Hm0 @ Savepoint Depth 
% SLR, Rand Tide, Depth Limitation
t5 = tic;
[project_forcing, config] = call_project_forcing_adjuster(config, project_forcing, structure);
t5 = toc(t5);

%% STEP 6: COMPUTE  PROJECT RESPONSES 
t6 = tic;
Resp = call_project_response(config, project_forcing, structure, prob_mass, config.create_plots);
t6 = toc(t6);

%% PRINT TIME 
disp(['Simulation Completed. Total run time: ' num2str(round(sum([t1,t2,t3,t4,t5,t6])/60,2)) ' mins...']);
% diary 'off';



