![SSLogo](https://github.com/Coastal-Hazards-System/StormSim-Library/assets/51959561/2b532547-1716-4bdb-815e-9e646b93615a)
## 👋 Welcome Beta Testers!
 We are happy that you are interested in testing the CHG's probabilistic tool's suite. The StormSim-Library is a collection of functions/modules that are interconnected to build robust probabilistic workflows. While using this early distribution of the software please have in mind the following:
* This has all been developed without a direct source of funding.
* Although we have extensively tested the existing tools this is still in the development stage. This means bugs can arise based on inputs/application.
* Limited to CHS native data for the time being. Custom modeling is supported but requires one-on-one to set-up.
* We encourage feedback on ease of use, missing physics/responses, data visualizations, post-processing computations.

## Requirements (External)
The following files will be provided with the software to allow users to use data from any CHS regional study.
* Probability Masses/Distributed Storm Weights -> PMs for each CHS  regional study. Required for tropical cyclone events analysis.
* Regional SWL Bias & Uncertainty Files -> CHS ADCIRC SWL bias and uncertainty per savepoint.
Download here ---> insert link
* Tidal prediction file -> File can be created by running auxiliary routine "" with the specification of a NOAA water level station ID. Active stations can be found at: https://tidesandcurrents.noaa.gov/stations.html?type=Water+Levels File must be a 2 column csv file with headers [Date, Prediction]. 

## Bug Reporting 
Create an issue with the following information:
* Error message print out in the command window (red text).
* Input file (config)
* CHS SP Lat, Lon, ADCIRC SP ID, STWAVE SP ID

## Feedback/Ideas 
Please feel free to use this space to communicate any feedback/ideas. Any idea that needs further discussion (potential SoN) can be transitioned to a Discussion item on the repo.

