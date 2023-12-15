![SSLogo](https://github.com/Coastal-Hazards-System/StormSim-Library/assets/51959561/2b532547-1716-4bdb-815e-9e646b93615a)
## 👋 Welcome Beta Testers!
 We are happy that you are interested in testing the CHG's probabilistic tool's suite. The StormSim-Library is a collection of functions/modules that are interconnected to build robust probabilistic workflows. While using this early distribution of the software please have in mind the following:
* This has all been developed without a direct source of funding.
* Although we have extensively tested the existing tools this is still in the development stage. This means bugs can arise based on inputs/application.
* Limited to CHS native data for the time being. Custom modeling is supported but requires one-on-one to set-up.
* We encourage feedback on ease of use, missing physics/responses, data visualizations, post-processing computations.

## Requirements (External)
The following files will be provided with the software to allow users to use data from any CHS regional study.
* Coastal Hazard System (CHS) regional study modeling results (Peaks and/or timeseries files) for Base Conditions from https://chs.erdc.dren.mil. 
* Probability Masses/Distributed Storm Weights -> PMs for each CHS  regional study. Required for tropical cyclone events analysis.
* Regional SWL Bias & Uncertainty Files -> CHS ADCIRC SWL bias and uncertainty per savepoint.
Download here ---> insert link
* Tidal prediction file -> File can be created by running auxiliary routine "" with the specification of a NOAA water level station ID. Active stations can be found at: https://tidesandcurrents.noaa.gov/stations.html?type=Water+Levels File must be a 2 column csv file with headers [Date, Prediction]. 

## Getting Started 
Description is pending

## Available StormSim Modules
1. StormSim: Probabilistic Responses  Of Structures (PROS): Description pending 
2.  StormSim: Life Cycle Simulation (LCS): Description pending
3. StormSim: LCS - Coastal Structure Reliability (LCS-CSR): Description pending
4. StormSim: Stochastic Simulation Technique (SST): Description pending
5. StormSim: Joint Probability Method (JPM): Description pending

## Project Folder Structure (Outputs)
StormSim stablishes and keeps track of all associated project files by storing outputs in a folder heirarchy built with: 
1. project name: StormSim project parent folder. 
2. transect id: Second level in the StormSim project output folder. Represents the PSE being designed/evaluated
3. case name: Third level in the StormSim project output folder. Used to evaluate different alternatives for the same transect.

The files stored within these folders serve as checkpoints or points of reference for the StormSim library. These checkpoints help reduce computational times across all workflows when iterating different alternatives for a project.

## Project Files (Outputs)
Files created/exported by the StormSim library will have a prefix appended to them that is built by using project_name, struc_id, and case_name from provided configuration file. Most files follow the same organizational scheme where information is sorted by storm type, data type and data matching type (Maxima, WLP or WHP). Currently, StormSim only exports 5 types of files:

1. *_CHS_NACCS_SP15104_raw_files.mat: Created in “call_chs_data_formater.m”. Contains  raw CHS files that have been converted using StormSim’s native CHS h5 converter. Information extracted includes storm data, attributes , headers and units.Created workspace variables: CHS_data.

2. *_CHS_NACCS_SP15104.mat: Created in “call_chs_data_formater.m”. Contains processed CHS data and the associated storm probability masses. Data processing includes:
ADCIRC/STWAVE storm data matching
Storm hydrograph QA/QC (timestep matching and correction)
Incomplete/Bad storms flagging and removal
Storm data is stored by storm type, data type, and data matching type. Forexample storm.XC.Peaks.Maxima refers to the extratropical storm data contained within the CHS “Peaks” files and matched using the Maxima concept. Created workspace variables: storm, prob_mass.

3. *_XX_project_forcing.mat: XX represents the workflow called to create this file (LCS or RB). This file is created in “call_project_forcing_formater.m”. Contains the formated project forcing data. In the context of an LCS workflow this implies sampling storms using the Monte Carlo Statistical framework. For RB workflows this implies reshaping storm data to have n replicates (depends on storm type) to cover 3 standard deviations. Created workspace variables: project_forcing. This dataset does not include any adjustments (SLR, tides, depth limitation or uncertainty)

4. *_config_file.mat: This file is created in “call_input_parser.m”. This file contains the parsed StormSim configuration file. Additionally, it may also include the structure geometry being evaluated for the specified case. Config also gets some additional information appended to it in “call_chs_data_formater.m”. Config serves as the central schema for the whole StormSim library.

5. XX_project_responses.mat: XX represents the workflow called to create this file (LCS or RB). This file is created in “call_project_response.m”. Contains the project responses computed by the StormSim library based on user specified workflow.

## Bug Reporting 
Create an issue with the following information:
* Error message print out in the command window (red text).
* Input file (config)
* CHS SP Lat, Lon, ADCIRC SP ID, STWAVE SP ID

## Feedback/Ideas 
Please feel free to use this space to communicate any feedback/ideas. Any idea that needs further discussion (potential SoN) can be transitioned to a Discussion item on the repo.

