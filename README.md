![SSLogo](https://github.com/Coastal-Hazards-System/StormSim-Library/assets/51959561/2b532547-1716-4bdb-815e-9e646b93615a)
## 👋 Welcome, Beta Testers!
Thank you for being a part of our exciting journey as we unveil CHG's cutting-edge probabilistic tool suite, the StormSim-Library. Your interest and participation are truly appreciated, and we're genuinely excited to have you on board.
As you explore this early distribution of our software, we want to share a few friendly reminders:

🚀 Passion Project: The entire development of this tool suite has been without a direct source of funding. Your enthusiasm and engagement make it all worthwhile!

🧪 Development Stage: While we've put the existing tools through extensive testing, remember that we're still in the development stage. Bugs might pop up based on inputs or application, but fear not—we're here to tackle them head-on.

🗺️ Limited Data Landscape: Currently, we're working with CHS native data, but don't let that hold you back! Custom modeling is absolutely supported; it just requires a little one-on-one setup. Let's make it happen together.

🤝 Your Input Matters: We value your feedback on various aspects—whether it's about the ease of use, missing physics or responses, data visualizations, or post-processing computations. Your insights help us shape this tool into something extraordinary.

Once again, thank you for being a part of this exciting beta testing phase. Together, we're paving the way for a future of robust and innovative probabilistic workflows. Let's make it an incredible journey!

## StormSim External Dependencies 
### 1. Coastal Hazard System (CHS) regional study modeling results (https://chs.erdc.dren.mil)
CHS is a unique data resource that spans probability space, was developed with high-fidelity modeling, is spatially uniform and dense on a national scale, and includes aleatory and epistemic uncertainty information necessary for determining probabilistic responses. Modeling results are reported through save points across regional studies. Save points include modeling results for both circulation (ADCIRC) and wave models (STWAVE/WAM/SWAN). Additionally, results hosted on CHS include different Sea Level Rise (SLR) scenarios and tidal conditions for tropical (TC) and/or extra-tropical (XC) events. Currently, StormSim supports the use of Base Conditions modeling results (peaks and timeseries) for the following regional studies: CHS-NACCS, CHS_SACSS, FEMA RiskMap. Additional CHS regional study statistical results can be downloaded (here) (Distributed Storm Weights & SWL Bias/Uncertainty) <-----Link

![image](https://github.com/Coastal-Hazards-System/StormSim-Library/assets/51959561/df664577-5593-4410-99c1-b967f68ba59f)

The following figure summarizes the CHS data download process; 1) choose a regional study, 2) apply the **Base Modeling** filter, 3). Through CHS, you can choose the most suitable save point for your project. When selecting project-forcing data, consider the hazards you want to include (XC vs TC vs both) and the level of fidelity (Peaks vs Timeseries vs both). Currently, StormSim only supports base modeling conditions as a forcing input. Utilizing CHS data means any analysis will involve the full storm suite for a given regional study. The downloaded zip folder must contain Peaks and/or Timeseries files for both models associated with a savepoint (ADCIRC + Wave Model). For a more detailed guide on accessing and navigating CHS files/website, visit (https://chs.erdc.dren.mil/Content/documents/CHSQuickGuide.pdf).

<p align="center" width="100%">
    <img width="100%" src="https://github.com/Coastal-Hazards-System/StormSim-Library/assets/51959561/f8f5a12f-3e75-44bd-a6b5-e7af0845a877">
</p>

### 2. Tidal prediction file
File can be created by running auxiliary routine "create_tide_file.m" with the specification of a NOAA water level station ID. Active stations can be found at: https://tidesandcurrents.noaa.gov/stations.html?type=Water+Levels File must be a 2 column csv file with headers [Date, Prediction]. 

## Getting Started 
1.Take time and familirize yourself with CHS and the modeling results associated to your project. The CHS website host a library with technical reports associated to how the modeling was executed and stored (link).
2.Go to tides and currents and search for the nearest gage to the project 
3.Make sure to have all structure 
4. A GUI is envisioned but no in formal development 


![image](https://github.com/Coastal-Hazards-System/StormSim-Library/assets/51959561/09ff69a1-ba3b-4214-a6d3-4b63ab608b32)

### Available StormSim Modules
1. StormSim: Probabilistic Responses  Of Structures (PROS): Description pending 
2. StormSim: Life Cycle Simulation (LCS): Description pending
3. StormSim: LCS - Coastal Structure Reliability (LCS-CSR): Description pending
4. StormSim: Stochastic Simulation Technique (SST): Description pending
5. StormSim: Joint Probability Method (JPM): Description pending

## StormSim Input File (config)
The StormSim-Library is fully controlled trhough the configuration file (StormSim_Inputs.xlsx). The following section will cover all items in the input file. 
1. StormSim Project General Inputs
   *
3. StormSim Project Foricng Data
4. Structure Geometry
5. Structure Properties
6. StormSim Project Forcing Uncertainty
7. StormSim Project Structure Response Uncertainty
8. StormSim Module Specific 
 
## Project Folder Structure (Outputs)
<img align="right" width="33%" src="https://github.com/Coastal-Hazards-System/StormSim-Library/assets/51959561/0c1d96cb-1b13-4e1a-b444-907d47cab3fe](https://github.com/Coastal-Hazards-System/StormSim-Library/assets/51959561/6d82b958-c5a6-48f6-b5f1-17b9711498bf">
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

