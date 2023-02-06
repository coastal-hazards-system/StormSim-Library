clc;clear all;


%% NOTES 
%{
Life cycle base variables will be organized in:
Peaks:
    var.(storm_type).
%}
%% USER INPUTS
%{
MCS/CSR & PROS Require:
    MCSim_Inputs -> TC Storm Probability Masses 
    norm_444.mat -> -3 to 3 z-scores discretized normalized curve (TCs only)
    norm_20.mat -> (XCs only)
%}
% Define StormSim Input File Name
stormsim_input_file = 'StormSim_Inputs.xlsx'; % Include relative path if not in parent directory

%% STEP 0: SET-UP ENVIRONMENT
%{
 Description:
   In order to use the full functionalities included within the StormSim
   library it is necesary to provide an input file. Please copy and fill
   out the provided "StormSim_Inputs.xlsx" template. Do not change the
   values written under "Model Variable Symbol" as this will brake the
   toolbox in its entirety.
  Outputs:
   1. config: Contains parsed information from StormSim input file | 1 x 1 | structure, with nFields 
    
%}
% Parse StormSim Configuration File  
config = call_input_parser(stormsim_input_file);
 
%% STEP 1: IMPORT, PROCESS & FORMAT COASTAL HAZARD SYSTEM (CHS) DATA (h5 -> MATLAB Memory)
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
tic;
% Call CHS Set-up Function 
[storm, ~, prob_mass, config] = call_chs_data_formater(config);
toc
%% STEP 2: CREATE STORM FORCING 
%{
 Description:
   Once input storm data has been formated the next step is to generate the
   project forcing. There are three options to choose here: 1 - Response
   Base I (RB1, StormSim: PROS), 2 - MCS (LCS, StormSim: MCS) , 3 - MCS/CSR
   (LCS, StormSim: MCS/CSR. The key difference being a response base
   approach using peaks (RB1) or doing a life cycle simulation (LCS) using
   peaks and timeseries. Option 3 computes structure response (S, R2p, q) after
   performing MCS storm sampling. Forcing generation options can be changed
   in input file by changing row with "cast_workflow" as Model Variable
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
[project_forcing] = call_project_forcing_formater(config, storm, prob_mass);

 
%% STEP 3: CREATE STRUCTURE GEOMETRY

% Create Project Structure Geometry
[structure] = create_structure_geometry(config, project_forcing, 1);% Second input argument: 1 - show plot 0 - hide plot

%% STEP 4: APPLY UNCERTAINTY TO PROJECT STRUCTURE AND FORCING PER WORKFLOW
%{
% This functions applies uncertianty to forcing, structural parameters and
empirical ecoefficients if supported by requested workflow.

Things to fix:
MCS-LC:
- Forcing uncertainty for MCS-LC is no the same as PROS (current PCHA).
- Do we want to change how uncertainty is applied to the forcing ?
- Structural parameters that support uncertainty are being treated with:
    normrnd(structure_param_for_LC, param_std) -> nstorms_at_LC * 1
    Crest height is caped to the design crest height 
PROS:
- Forcing unceratinty follows the lates PCHA method
- There is no uncertainty applied to structural parameters. Why?
    Uncertainty is applied to the response, hence no need to double account
    for uncertainty?

%}
[structure, project_forcing, emp_coeff] = call_uncertainty_engine(config, structure, project_forcing);


%% STEP 5: COMPUTE  RESPONSE 
% Need to vectorize equations (Eurotop_.... and other)
% StormSim PROS Has not been incorporated 
% MCS-CSR Peaks is working, need to sort out uncertianty. Needs to be
% accompanied by report to address the selection of storm duration.
% MCS-LC Its working but need to change K_ss in line 212 of
% stormsim_csr_dpa.m. Also, need to update damage functions to latest.
call_structure_response(config, project_forcing, structure, emp_coeff);


% Start work on defining an hdf5 file format to store outputs from MCS to
% feed to Go-Consequences -> No raw data.
% Give damaging depths to will worked by us + Hm0 future (Peaks Only)


