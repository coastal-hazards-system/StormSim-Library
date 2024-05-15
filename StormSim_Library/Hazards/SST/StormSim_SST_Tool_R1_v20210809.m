%% StormSim_SST_Tool.m
%{
LICENSING:
    This code is part of StormSim software suite developed by the U.S. Army
    Engineer Research and Development Center Coastal and Hydraulics
    Laboratory (hereinafter “ERDC-CHL”). This material is distributed in
    accordance with DoD Instruction 5230.24. Recipient agrees to abide by
    all notices, and distribution and license markings. The controlling DOD
    office is the U.S. Army Engineer Research and Development Center
    (hereinafter, "ERDC"). This material shall be handled and maintained in
    accordance with For Official Use Only, Export Control, and AR 380-19
    requirements. ERDC-CHL retains all right, title and interest in
    StormSim and any portion thereof and in all copies, modifications and
    derivative works of StormSim and any portions thereof including,
    without limitation, all rights to patent, copyright, trade secret,
    trademark and other proprietary or intellectual property rights.
    Recipient has no rights, by license or otherwise, to use, disclose or
    disseminate StormSim, in whole or in part.

DISCLAIMER:
    STORMSIM IS PROVIDED “AS IS” BY ERDC-CHL AND THE RESPECTIVE COPYRIGHT
    HOLDERS. ERDC-CHL MAKES NO OTHER WARRANTIES WHATSOEVER EITHER EXPRESS
    OR IMPLIED WITH RESPECT TO STORMSIM OR ANYTHING PROVIDED BY ERDC-CHL,
    AND EXPRESSLY DISCLAIMS ALL WARRANTIES OF ANY KIND, EITHER EXPRESSED OR
    IMPLIED, INCLUDING WITHOUT LIMITATION, WARRANTIES OF MERCHANTABILITY,
    NON-INFRINGEMENT, FITNESS FOR A PARTICULAR PURPOSE, FREEDOM FROM BUGS,
    CORRECTNESS, ACCURACY, RELIABILITY, AND RESULTS, AND REGARDING THE USE
    AND RESULTS OF THE USE, AND THAT THE ASSOCIATED SOFTWARE’S USE WILL BE
    UNINTERRUPTED. ERDC-CHL DISCLAIMS ALL WARRANTIES AND LIABILITIES
    REGARDING THIRD PARTY SOFTWARE, IF PRESENT IN STORMSIM, AND DISTRIBUTES
    IT “AS IS.” RECIPIENT AGREES TO WAIVE ANY AND ALL CLAIMS AGAINST
    ERDC-CHL, THE UNITED STATES GOVERNMENT AND ITS CONTRACTORS AND
    SUBCONTRACTORS, AND SHALL INDEMNIFY AND HOLD HARMLESS ERDC-CHL, THE
    UNITED STATES GOVERNMENT AND ITS CONTRACTORS AND SUBCONTRACTORS FOR ANY
    LIABILITIES, DEMANDS, DAMAGES.

SOFTWARE NAME:
    StormSim-SST-Tool (Statistics)

GENERAL DESCRIPTION:
   This script receives and processes the input arguments to the StormSim's
   Stochastic Simulation Technique (SST) Tool, executes the diferent methodologies,
   and conveys the output arguments to the workspace window in addition to
   save them in a .mat file.

   The tool can be used to estimate the hazard curve (HC) in terms annual
   exceedance probability (AEP) or annual exceedance frequency (AEF) from one
   or many datasets consecutively (either raw time series or POT samples).

   *** NEED more info about the methods and logic inside the SST (i.e., MRL  ***
   *** method, bootstrap process, combination of emp with GPD fit)           ***

   This script enables the communication between the Peaks-Over-Threshold
   (POT) methodology (StormSim_POT.m) and the SST methodology. The SST is
   executed with one of the following three scripts:
     1) StormSim_SST_Fit.m: when GPD_TH_crit = 0, executes the SST by evaluating
        each of the GPD thresholds identified by the MRL method and produces
        a sample plot of the bootstrap process.
  
     2) StormSim_SST_Fit_Simple.m: when GPD_TH_crit = 1 or 2, executes the SST
        using the GPD threshold identified with the MRL method criterion specified
        by the user. No sample plot of the bootstrap process is produced.

     3) StormSim_SST_Fit_SimplePar.m: this is a parallelized version of the
        script StormSim_SST_Fit_Simple.m for faster execution. Will only be
        used when the Parallel Computing Toolbox is installed in the User's
        MATLAB software.

DESCRIPTION: MODES OF EXECUTION

   The tool offers two modes or types of execution for the user to select:
   'Regular' and 'Fast'. This modes are specified in ExecMode
   (see Section INPUT ARGUMENTS) and have the following implications:
    1) 'Regular': under this mode, the tool will return to the User all
       available outputs and plots for each input dataset (see Section OUTPUT
       ARGUMENTS). This provides the opportunity to test different setting
       values and see how the HC changes, so the User can decide which values
       are best per dataset.
    2) 'Fast': this mode limits the output information to increase
       execution time and decrease output size for a straight forward application
       of several datasets. The user is adviced to use this mode after selecting
       the best settings under the 'Regular' mode.

   The tool can also plot the results depending on the execution type selected
   by the User, as follows:
    1) 'Regular': when ExecMode = 'Regular', the tool will produce histogram
       plots of the GPD shape parameter values, plots of the HC for each GPD
       threshold identified by the MRL method, and a stacked plot of the
       MRL method results.

    2) 'Fast': when ExecMode = 'Fast', no plots
       will be produced for faster evaluation of the input datasets.

   The tool will store all available outputs on a .mat file named StormSim_SST_output.mat.
   This file will be saved inside the folder directory specified in path_out
   (see Section INPUT ARGUMENTS). For a detailed list and description of the
   outputs, see the Section OUTPUT ARGUMENTS. Some of the results are organized
   in a structure array with a different set of fields depending on the mode
   of execution selected by the User, as follows:
    1) 'Regular': when ExecMode = 'Regular', the output structure
       array will contain the station information (staID); the record length
      (RL); the POT sample (POT); the outputs of the MRL method (MRL_out);
       the HC as plotted (HC_plt) for the values in HC_plt_x; the summarized
       HC (HC_tbl) for the values in HC_tlb_x; the summarized HC (HC_tbl_rsp_x)
       for the values in HC_tbl_rsp_y; the empirical HC (HC_emp); and an error
       message when the tool failed to evaluate a dataset (ME).

    2) 'Fast': when ExecMode = 'Fast', the output
       structure array will only contain the station information (staID);
       the HC as plotted (HC_plt) for the values in HC_plt_x; the summarized
       HC (HC_tbl) for the values in HC_tlb_x; the summarized HC (HC_tbl_rsp_x)
       for the values in HC_tbl_rsp_y; and an error message when the tool
       failed to evaluate a dataset (ME).
      
DESCRIPTION: TYPES OF APPLICATIONS

   Current design of the StormSim-SST Tool enables the evaluation of
   general and case-specific applications. A general application considers the
   use of raw time series datasets or POT datasets of any type of parameter.
   Refer to Section INPUT ARGUMENTS for a description of each input. Settings
   for general applications are as follows:

    G1) For raw time series dataset(s) with regular setting:
       DataType = 'Timeseries' and ExecMode = 'Regular'. This is
       intended for a detailed evaluation of a dataset, when there is no
       knowledge of the input arguments values.
        
    G2) For raw time series dataset(s) with mass-production setting:
       DataType = 'Timeseries' and ExecMode = 'Fast'.
       This is intended for the evaluation of hundreds of datasets, after
       the input arguments values have been defined.

    G3) For POT dataset(s) with regular setting: DataType = 'POT' and
       ExecMode = 'Regular'. Same as #1 but using POT dataset.

    G4) For POT dataset(s) with mass-production setting, DataType = 'POT'
       and ExecMode = 'Fast'. Same as #2 but using POT dataset.

   Available case-specific applications are described below:
    C1) POT dataset of storm surge with skew tides added.
       The following must be specified for this application:
       - set input argument ind_Skew = 1.
       - storm surge POT dataset values cannot include tides.
       - storm surge values may/may not include sea level change.
         > If SLC is included, also specify that value in the input argument SLC.
         > If SLC is not included, set input argument SLC = 0.
       - a second POT dataset of storm surge with tides must be provided
         for replacement of the empirical distribution. Those need to be
         entered in the input argument input_data.data_values2.
       - a Gaussian regression model (GRM) per dataset. Those need to be
         entered in the input argument gprMdl.mdl.
    C2) Additional cases will be added in future versions.

INPUT ARGUMENTS:
  - DataType: indicator for specifying the type of input dataset. Current
      options are:
      > 'POT' for a Peaks-Over-Threshold sample
      > 'Timeseries' for a raw time series data set
  - ind_Skew: indicator for computing/adding skew tides to the storm surge.
      This applies when the input is a storm surge POT dataset with/without SLC.
      Use as follows:
      > 1 for the tool to compute and add the skew tides
      > 0 otherwise
      Example: ind_Skew = 1;
  - input_data: raw time series datasets or POT samples to be evaluated;
      specified as a structure array with fields time_values, data_values
      and data_values2. Each record of input_data must correspond to an input
      dataset. Use as follows:
      > When DataType = 'Timeseries':
        input_data.time_values: must have the timestamps as serial date
          numbers (see 'datenum' in the MATLAB Documentation)
        input_data.data_values: must have the time series data values
      > When DataType = 'POT':
          input_data.time_values can be empty []
          input_data.data_values must have the POT values
          input_data.data_values2 can be empty []
      > When ind_Skew = 1: (evaluating POT storm surge with skew tides)
          input_data.time_values can be empty []
          input_data.data_values must have the POT storm surge values without tides
          input_data.data_values2 must have the POT storm surge values with tides
  - ExecMode: mode or type of execution. Available options are 'Regular'
      or 'Fast'; specified as a character vector.
      Example: ExecMode = 'Regular'.
  - flag_value: any flag value to search and remove from the input dataset;
      specified as a scalar. Leave empty [] otherwise. Example: flag_value = -999;
  - tLag = inter-event time in hours; specified as a positive scalar or
      vector. Use as follows:
      > When DataType = 'POT': leave empty [].
      > When DataType = 'Timeseries': Enter one value per dataset or one
        value for all datasets. Examples: tLag = [48 24]; tLag = 48;
  - lambda = mean annual rate of events (events/year); specified as a positive
      scalar or vector.  Use as follows:
      > When DataType = 'POT': leave empty [].
      > When DataType = 'Timeseries': Enter one value per dataset or one
        value for all datasets. Examples: lambda = [12 6 3]; lambda = 12;
  - Nyrs: record length in years; specified as a positive scalar or vector.
      Use as follows:
      > When DataType = 'POT': enter one value per dataset or one value
        for all datasets. Examples: Nyrs = [50 15 30]; Nyrs = 50;
      > When DataType = 'Timeseries': leave empty [] since the tool will
        compute the effective duration.
  - path_out: path to output folder; specified as a character vector. Leave
      empty [] to apply default: '.\SST_output\'
  - staID: gauge station information for each input dataset; specified as a cell array with format:
      Col(01): gauge station ID number; as a character vector. Example: '8770570'
      Col(02): station name (OPTIONAL); as a character vector. Example: 'Sabine Pass North TX'
  - yaxis_Label: parameter name/units/datum for label of the plot y-axis;
      specified as a cell array of character vectors. Available options for this input are as follows:
      > Enter one label that applies to all input datasets. Example : yaxis_Label = {'Still Water Level (m, MSL)'};
      > Enter one label per input dataset. Example for three : yaxis_Label = [{'Still Water Level (m, MSL)'},{'Significant wave height (m)'},{'Peak wave period (s)'}];
      > When ExecMode = 'Fast', leave empty [].
      > When ind_Skew = 1 and the input data is of storm surge, set
        yaxis_Label = 'Still water level' with associated units and datum.
        Example: 'Still Water Level (m, MSL)'
  - yaxis_Limits: lower and upper limits for the plot y-axis; specified as a
      two-column numerical array. Available options for this input are as follows:
      > Enter a two-value vector that applies to all input datasets. Example: yaxis_Limits = [0 10];
      > Enter as a two-column matrix with one row per input dataset. Example for three input datasets: yaxis_Limits = [[0 10];[2 10];[0 20]];
      > When ExecMode = 'Fast', leave empty [].
      > Leave empty [] to apply default values.
  - prc: percentage values for computing the percentiles; specified as a
      scalar or vector of positive values. Leave empty [] to apply default
      values 2.28%, 15.87%, 84.13%, 97.72%. User can enter 1 to 4 values.
      Example: prc = [2 16 84 98];
  - use_AEP: indicator for expressing the hazard as AEF or AEP. Use 1 for
      AEP, 0 for AEF. Example: use_AEP = 1;
  - GPD_TH_crit: indicator for specifying the GPD threshold option of the
      Mean Residual Life (MRL) selection process; specified as a scalar. Use as follows:
      > GPD_TH_crit = 0: to evaluate all thresholds identified by the MRL method (one per criterion)
      > GPD_TH_crit = 1: to only evaluate the MRL threshold selected by the lambda criterion
      > GPD_TH_crit = 2: to only evaluate the MRL threshold selected by the minimum error criterion
  - SLC: magnitude of the sea level change implicit in the storm surge input
      dataset; specified as a positive scalar.
      > When ind_Skew = 1: Must have same units as the input POT storm surge dataset. Example: SLC = 1.8;
      > When ind_Skew = 0: Leave empty [].
  - gprMdl: Gaussian process regression (GPR) model created with the MATLAB
function 'fitrgp'; specified as a structure array with field 'mdl'.
      > When ind_Skew = 1: Field 'mdl' must contain one GPR object per
        input dataset included in input_data. Refer to MATLAB Documentation
        for 'fitrgp'. Train the GPR with storm surge as a predictor and skew
        tides as the response.
      > When ind_Skew = 0: Leave empty [].
  - HC_tbl_rsp_y: response values used to summarize the HC; specified as a
      numerical vector of positive values. Set as empty [] to apply default
      values (0 to 20). Example: HC_tbl_rsp_y = [0:05:10];
  - apply_GPD_to_SS: indicates if the hazard of small POT samples should evaluated
      with either the empirical or the GPD. A small sample has a sample size < 20 events
      and a record length < 20 years. Use 1 for GPD, 0 for empirical. Example: apply_GPD_to_SS = 1;
  - DELETED K_par_restriction: options to restrict the range of values of GPD shape
      parameter from the bootstrap process. Available options are:
        1 = range -.7 to .1
        2 = range -.8 to .2
        3 = apply fillsoutlier() to remove outliers from bootstrap results;
            TH_otlr cannot be [].
  - DELETED TH_otlr: 'ThresholdFactor' for the fillsoutlier function used to modify
      the GPD shape parameter collection resulting from the bootstrap process.
      Specified as a nonnegative scalar or vector. Refer to MATLAB Documentation
      for 'fillsoutlier', 'ThresholdFactor' option. Enter one value per dataset or one
      value for all datasets. Leave empty [] to apply default value: 10.
      Examples: TH_otlr = [1 2 3]; TH_otlr = 3;
  - apply_Parallel: Enter one (1) to run tool in parallel; enter zero (0)
      otherwise. The tool will execute in parallel ONLY when GPD_TH_crit =
      0, and the Parallel Computing Toolbox is installed.


OUTPUT ARGUMENTS:
  - HC_plt_x: predefined vector of probabilities used to plot the HC. The type is:
     > AEP when use_AEP = 1
     > AEF when use_AEP = 0

  - HC_tbl_x: predefined vector of probabilities used to summarize the HC. The type is:
     > AEP when use_AEP = 1
     > AEF when use_AEP = 0

  - HC_tbl_rsp_y: vector of response values used to summarize the HC.

  - Removed_datasets: Message with a list of the input datasets not evaluated due to one of the following reasons:
     > Dataset resulted empty after removing flag, zeros, NaN and/or Inf values.
     > Dataset has less than 3 unique values

  - Check_datasets:
     > When ind_Skew = 1: Message with a list of the input datasets to which the skew tides were not applied.
       For example: 'These stations were evaluated without applying skew tides since: ind_Skew = 1
            but entered invalid values for either the second POT dataset (with tides) or the GPR model'.
     > When ind_Skew = 0: will be empty.

  - SST_output: structure array containing the output data of the StormSim-SST
     Tool, with the following fields:
     > staID: identifier of the gauge station as specified by the user
     > RL: record length in years
     > POT:
         When DataType = 'Timeseries', this is the POT sample computed
           with the tool; as a matrix array with format:
           col(01): time of POT values in seriel date number format
           col(02): POT values
           col(03): data time range used for selection of POT value: lower bound
           col(04): data time range used for selection of POT value: upper bound
         When DataType = 'POT', this is the same input POT dataset.
     > MRL_output: output of Mean Residual Life (MRL) function; as a structure array with fields:
         Summary = summary of the threshold selection results, as a table array with format:
            Threshold: list of threshold values evaluated
            MeanExcess: mean excess
            Weight: weights
            WMSE: weighted mean square error (MSE)
            GPD_Shape: GPD shape parameter
            GPD_Scale: GPD scale parameter
            Events: number of events above each threshold
            Rate: sample intensity (mean annual rate of events using sample of events above threshold)

         Selection = selected threshold with other parameters, as a table array with format:
            Criterion: criterion applied by MRL method for selecting the threshold
            Threshold: selected threshold value
            id_Summary: location (row ID) of selected threshold in the Summary field
            Events: number of events above the selected threshold
            Rate: sample intensity (mean annual rate of events using sample of events above threshold)

         pd_TH_wOut = GPD threshold parameter values used in the bootstrap process
         pd_k_wOut = initial GPD shape parameter values obtained in the bootstrap process
         pd_sigma = GPD scale parameter values used in the bootstrap process
         pd_k_mod = modified GPD shape parameter values used in the bootstrap process
         eMsg = Status message indicating when the MRL methodology was not able
            to objectively determine a theshold for the GPD. In this case, the
            GPD threshold is set to 0.99 times the minimum value of the bootstrap sample.
            Otherwise, eMsg will be empty.

     > HC_plt: full HC; as a structure array with two fields: 'out' and 'MRL_Crit'. It may contain
         up to two records (one per MRL GPD threshold) with the following format:

         out = numerical array with the following 5 rows
            row(01): mean values
            row(02): values of 2% percentile or 1st percentage of input "prc"
            row(03): values of 16% percentile or 2nd percentage of input "prc"
            row(04): values of 84% percentile or 3rd percentage of input "prc"
            row(05): values of 98% percentile or 4th percentage of input "prc"

         MRL_Crit = character vector indicating the MRL threshold
            selection criterion used for the HC_plt.out record.

     > HC_tbl: summarized HC; as a structure array with two fields: 'out' and 'MRL_Crit'. It may contain
         up to two records (one per MRL GPD threshold) with the following format:

         out = numerical array with the following 5 rows
            row(01): mean values
            row(02): values of 2% percentile or 1st percentage of input "prc"
            row(03): values of 16% percentile or 2nd percentage of input "prc"
            row(04): values of 84% percentile or 3rd percentage of input "prc"
            row(05): values of 98% percentile or 4th percentage of input "prc"

         MRL_Crit = character vector indicating the MRL threshold
            selection criterion used for the HC_tbl.out record.

     > HC_tbl_rsp_x: hazard values interpolated from the HC, that correspond
         to the responses in HC_tbl_rsp_y; as a structure array with two fields: 'out' and 'MRL_Crit'. It may contain up
         to two records (one per MRL GPD threshold) with the following format:

         out = numerical array with the following 5 rows
            row(01): mean values
            row(02): values of 2% percentile or 1st percentage of input "prc"
            row(03): values of 16% percentile or 2nd percentage of input "prc"
            row(04): values of 84% percentile or 3rd percentage of input "prc"
            row(05): values of 98% percentile or 4th percentage of input "prc"

         MRL_Crit = character vector indicating the MRL threshold
            selection criterion used for the HC_tbl_rsp_x.out record.

     > HC_emp: empirical HC; as a table array with column headings as follows:
         Response: Response vector sorted in descending order
         Rank: Rank or Weibull's plotting position
         CCDF: Complementary cumulative distribution function (CCDF)
         Hazard: hazard as AEF or AEP
         ARI: annual recurrence interval (ARI)

     > ME = error message when the tool failed to evaluate a dataset.

AUTHORS:
    Norberto C. Nadal-Caraballo, PhD (NCNC)
    Efrain Ramos-Santiago (ERS)

CONTRIBUTORS:
    ERDC-CHL Coastal Hazards Group

HISTORY OF REVISIONS:
20200903-ERS: revised.
20201015-ERS: Alpha v0.1: Updated documentation.
20201026-ERS: Added capability to include skew surge. Updated documentation and inputs.
20201031-ERS: Alpha v0.2: Reformated logic to reduce execution time. Added
    option to execute the tool in Regular mode or Fast mode.
20201202-ERS: Alpha v0.2: Reviewed logic, added extra layer to run simple
    mode w/o PCT, updated documentation.
20201203-ERS: Alpha v0.2: Updated documentation.
20201208-ERS: Alpha v0.2: Finalized draft documentation for this version.
20201218-ERS: Alpha v0.2: Corrected the input order in the plot function
    call when hasPCT=0 and GPD_TH_crit~=0. Also moved the checkpoint for TH_otlr
    to verify first if it's empty.
20201221-ERS: Alpha v0.2: Second input dataset is now being pre-processed
    for removal of invalid POT values.
20210113-ERS: Alpha v0.2: Changed hasPCT.m to assume pool is
    inactive when PCT is not found. In addition, when ind_Skew = 1, the
    second input dataset will be pre-processed.
20210303-ERS: alpha version 0.2: minor corrections in StormSim_SST_Fit.m.
20210311-ERS: alpha version 0.3: corrections in StormSim_SST_Fit.m,
    StormSim_SST_FitSimple.m and StormSim_SST_FitSimplePar.m: adjustment of
    hazards to be monotonic; creation of hazard tables.
20210325-ERS: alpha v0.4: modified outputs and plots to account for new predefined AEF table values. Also
    organized MRL script and output.
20210405-ERS: alpha v0.4: updated documentation
20210406-ERS: alpha v0.4: modified preprocessing of inputs datasets.
    Modified the MRL, the fit and plotting scripts to account for the
    computation of the default GPD threshold.
20210407-ERS: alpha v0.4: Modified the fit functions to account for small
    bootstrap samples.
20210412-ERS: alpha v0.4: Modified the fit functions to discard bootstrap
    samples with spurious values.
20210419-ERS: alpha v0.4: corrected evaluation of input TH_otlr.
20210420-ERS: alpha v0.4: expanded use of inputs yaxis_Label and yaxis_Limits
    (see description). Took out HC_tbl_rsp_y as another user input.
20210421-ERS: alpha v0.5: corrections for yaxis_Label and yaxis_Limits.
20210503-ERS: alpha v0.5: corrections applied to StormSim_MRL.m. Limits applied
    for the GPD shape parameter. Option provided to evaluate small POT samples
    with either GPD or empirical distribution.
20210505-ERS: alpha v0.5: the tool now will not apply skew tides when
    ind_Skew = 1 but the GPR model and/or 2nd dataset (with tides) have
    invalid formats. Added output Check_datasets to display a message and
    the list of stations, so the user can double check them. Check points
    expanded in all 3 fit scripts.
20210507-ERS: alpha v0.5: added input to modify the GPD shape parameter.
20210511-ERS: alpha v0.5: removed the options to modify the GPD shape
    param since a unique range is now enforced by default. TH_otlr was
    removed. Removed LICENSING and DISCLAIMER comments from internal
    functions.
20210512-ERS: alpha v0.5: re-enabled the patch of 20210412 to ignore bad
    random samples. Also had a succesful run while testing with time series data for NRC Pilot Study.
20210513-ERS: alpha v0.5: cleaned script and updated documentation.
20210517-ERS: alpha v0.5: corrected MRL script to ignore, error due to Inf
    weights. Found while doing Nantucket.
20210520-ERS: alpha v0.5: corrected error in POT script
20210525-ERS: alpha v0.5: corrected bug in preprocessing
20210526-ERS: alpha v0.5: now changing to NaN all values < AEF=10^-4 in the
    HC table summary for HC_tbl_rsp_y.
20210527-ERS: alpha v0.5: minor correction
20210601-ERS: alpha v0.5: added input to control activation of PCT.
20210713-ERS: alpha v0.5: to ensure a GPD threshold is found, reduced the kernel smoothing bandwidth in MRL script from 1/4 to 1/7.
20210719-ERS: alpha v0.5: added warning message when mean HC > 1.75*emp HC.
20210727-ERS: alpha v0.5: minor correction.
20210809-ERS: alpha v0.5: revised.
20231207-LAA: Revised to add noise to repeated values in the POT samples.


***************  ALPHA  VERSION  **  FOR INTERNAL TESTING ONLY ************
%}
function [HC_plt_x,HC_tbl_x,HC_tbl_rsp_y,Removed_datasets,Check_datasets,SST_output] = StormSim_SST_Tool_R1_v20210809(input_data,flag_value,tLag,lambda,Nyrs,path_out,staID,yaxis_Label,yaxis_Limits,prc,use_AEP,GPD_TH_crit,SLC,ind_Skew,gprMdl,DataType,ExecMode,HC_tbl_rsp_y,apply_GPD_to_SS,apply_Parallel, stat_print, app_type, y_log)
%% Other settings
if stat_print == 1
    clc;
    disp(['***********************************************************' newline...
        '***         StormSim-SST Tool Alpha Version 0.5         ***' newline...
        '***                Release 1 - 20210809                 ***' newline...
        '***                 FOR  TESTING  ONLY                  ***' newline...
        '***********************************************************' newline...
        '**********           NOTES TO THE USER           **********' newline...
        '*** 1) Refer to Quick Start Guide for a description     ***' newline...
        '***    of settings, inputs and outputs.                 ***' newline...
        '*** 2) Please report any error using the Feedback Form. ***' newline...
        '*** 3) For questions or help contact:                   ***' newline...
        '***    Efrain.Ramos-Santiago@usace.army.mil             ***' newline...
        '***********************************************************'])

    disp([newline '*** Step 1: Processing input arguments '])
end

% Turn off all warnings
warning('off','all');

% Check apply_GPD_to_SS
if sum(apply_GPD_to_SS==[0 1])~=1||isempty(apply_GPD_to_SS)||isnan(apply_GPD_to_SS)
    error('Input apply_GPD_to_SS must be 0 or 1')
end

% Check use_AEP
if sum(use_AEP==[0 1])~=1||isempty(use_AEP)||isnan(use_AEP)
    error('Input use_AEP must be 0 or 1')
end

% Set up probabilities for HC summary
if use_AEP %Select AEPs
    HC_tbl_x = 1./[2 5 10 20 50 100 200 500 1000 2000 5000 1e4 2e4 5e4 1e5 2e5 5e5 1e6];
else %Select AEFs
    %     HC_tbl_x = 1./[0.1,0.2,0.5,1,2,5,10,20,50,100,200,500,1000,2000,5000,10000,20000,50000,100000,200000,500000,1000000];
    HC_tbl_x = 1./[0.1,0.2,0.5,1,2,5,10,20,50,100,200,500,1000,2000,5000,10000];
end

% Set up responses for HC summary
if isempty(HC_tbl_rsp_y)
    HC_tbl_rsp_y =(0.01:0.01:20)';
elseif isrow(HC_tbl_rsp_y)
    HC_tbl_rsp_y =sort(HC_tbl_rsp_y)';
    if sum(HC_tbl_rsp_y<=0)~=0
        error('Input HC_tbl_rsp_y must be specified as a numerical vector of positive values')
    end
end

% Set up AEFs for full HC; in log10 scale (for plotting), from 10^1 to 10^-6
d=1/90; v=10.^(1:-d:0)'; HC_plt_x=v; x=10;
for i=1:6, HC_plt_x=[HC_plt_x; v(2:end)/x]; x=x*10; end %#ok<AGROW>
HC_plt_x=flipud(HC_plt_x);

% Check path to output folder
if isempty(path_out)
    path_out='SST_output';mkdir(path_out);
elseif ~exist(path_out,'dir')
    mkdir(path_out);
end
path_out=['.\',path_out,'\'];

% Check size and value of input arguments
sz = length(input_data);
if isempty(input_data)||~isstruct(input_data)
    error('Input input_data cannot be an empty or matrix array. Must be a structure array.')
end
if isempty(staID)||size(staID,1)~=sz||~iscellstr(staID)||isstring(staID)
    error('Input staID cannot be empty. Provide one ID number per dataset.')
end

% Evaluate parameters for POT or Time series input data
DataType = find(strcmp(DataType,{'Timeseries','POT'}));
switch DataType
    case 1 %Time series
        if sum(tLag<=0)~=0||isempty(tLag)
            error('When DataType = ''Timeseries'': Input tLag cannot be an empty array and must have positive values only')
        end
        if and(length(tLag)==1,sz>1)
            tLag=repmat(tLag,1,sz);
        end
        if sum(lambda<=0)~=0||isempty(lambda)
            error('When DataType is set to ''Timeseries'': Input lambda cannot be an empty array and must have positive values only')
        end
        if length(lambda)==1 && sz>1
            lambda=repmat(lambda,1,sz);
        end
        Nyrs=NaN(1,sz);
    case 2 %POT
        if sum(Nyrs<=0)~=0||isempty(Nyrs)
            error('When DataType is set to ''POT'': Input "Nyrs" cannot be empty and must have positive values only')
        end
        if length(Nyrs)==1 && sz>1
            Nyrs=repmat(Nyrs,1,sz);
        end
    otherwise
        error('Unrecognized value for DataType. Available options are ''Timeseries'' or ''POT'' ')
end

% Check if Parallel Computing Toolbox exists, start pool session and Turn off warnings
[id_PCT,id_act]=hasPCT;
if GPD_TH_crit~=0 && id_PCT && apply_Parallel
    if id_act
        parpool;
    end
    parfevalOnAll(gcp,@warning,0,'off','all');
end

% Other settings
if sum(GPD_TH_crit<0||GPD_TH_crit>2)~=0
    error('Input GPD_TH_crit has wrong values. Available options are 0, 1, or 2')
end

if strcmp(ExecMode,'Regular')
    if sum(strcmp(yaxis_Label,''))~=0||isempty(yaxis_Label)||~iscellstr(yaxis_Label)||isstring(yaxis_Label)
        error('Error found in input yaxis_Label. Refer to the Quick Start Guide for instructions on how to set up this input.');
    end
    if length(yaxis_Label)~=sz
        yaxis_Label = repmat(yaxis_Label,sz,1);
    end
else
    yaxis_Label=cell(sz,1);
end

if strcmp(ExecMode,'Regular')
    if ~isempty(yaxis_Limits)
        if isvector(yaxis_Limits)
            n=length(yaxis_Limits);
            if n~=2
                error(['When input yaxis_Limits is entered as a numeical vector, it must' newline...
                    'have two values.'])
            end
            yaxis_Limits=sort(yaxis_Limits);
            if iscolumn(yaxis_Limits)
                yaxis_Limits=yaxis_Limits';
            end
            yaxis_Limits = repmat(yaxis_Limits,sz,1);
        elseif ismatrix(yaxis_Limits)
            [m,n]=size(yaxis_Limits);
            if or(m~=sz,n~=2)
                error(['When input yaxis_Limits is entered as a numerical matrix, it must' newline...
                    'have two columns and one row per input dataset in input_data'])
            end
        else
            error('Error found in input yaxis_Limits. Refer to the Quick Start Guide for instructions on how to set up this input.');
        end
    else
        yaxis_Limits=double.empty(sz,0);
    end
else
    yaxis_Limits=double.empty(sz,0);
end

if isempty(prc)
    prc=[2.28 15.87 84.13 97.72]';
else
    if length(prc)>4||sum(isnan(prc))>0||sum(isinf(prc))>0||sum(prc<0)~=0
        error('Input prc can have 1 to 4 percentages in the interval [0,100].');
    end
    prc=sort(prc,'ascend'); prc=prc(:);
end
if isempty(SLC)
    SLC=0;
else
    if length(SLC)~=1||SLC<0||isnan(SLC)||isinf(SLC)
        error('Input SLC must be a positive scalar')
    end
end
if sum(ind_Skew==[0 1])~=1||isempty(ind_Skew)||isnan(ind_Skew)||isinf(ind_Skew)
    error('Input ind_Skew must be 0 or 1')
end
if ind_Skew==1
    if isempty(gprMdl)
        error('When ind_Skew = 1: Input gprMdl.mdl cannot be an empty structure')
    end
    if length(gprMdl)~=sz
        error(['Input gprMdl must be same size as input input_data:' newline 'Provide one GPR model per dataset included in input_data'])
    end
else
    for i=1:sz
        gprMdl(i).mdl=[];
    end
end

% Compatibility check
a=version('-release'); if a(end)=='a',a(end)='0';else; a(end)='1';end
a = str2double(a)<20200;

% Types of SST execution
ExecMode = find(strcmp(ExecMode,{'Regular','Fast'}));

% Pre-allocate output structure array
switch ExecMode
    case 1 %Regular
        SST_output = struct('staID','','RL',double.empty,'POT',double.empty,'MRL_output',double.empty,...
            'HC_plt',double.empty,'HC_tbl',double.empty,'HC_tbl_rsp_x',double.empty,'HC_emp',double.empty,'Warning','','ME',cell(1));
    case 2 %Fast
        SST_output = struct('staID','','HC_plt',double.empty,'HC_tbl',double.empty,'HC_tbl_rsp_x',double.empty,'Warning','','ME',cell(1));
    otherwise
        error('Unrecognized value for ExecMode. Available options are ''Regular'' or ''Fast''')
end

if stat_print == 1
    disp('*** Step 2: Verifying input datasets')
end
%% Data preprocessing: remove NaN, inf values; compute record length
procData(sz).dat = [];
procData(sz).dat2 = [];
procData(sz).id = [];
procData(sz).id2 = [];
sz = 1:sz;

switch DataType
    case 1 %Timeseries
        for i=sz %dataset loop
            data_time = input_data(i).time_values;
            data_values = input_data(i).data_values;

            % Remove flag values?
            if ~isempty(flag_value)
                data_time(data_values==flag_value)=[];
                data_values(data_values==flag_value)=[];
            end

            % Merge data and remove NaN, Inf values
            data_values=[data_time(:) data_values(:)];
            data_values(isinf(data_values(:,2))|isnan(data_values(:,2)),:)=[];

            procData(i).dat = data_values;

            % Compute record length: Effective duration method
            dt=[]; [dt(:,1),dt(:,2),dt(:,3)]=ymd(datetime(data_time,'ConvertFrom','datenum'));
            dt=unique(dt,'rows'); Nyrs(i)=size(dt,1)/365.25;

            % Can dataset be evaluated? Mark empty datasets to delete later
            if isempty(data_values)
                procData(i).id = i;
            end
        end

    case 2 %POT
        for i=sz %dataset loop

            %take datasets
            tt = input_data(i).time_values;
            data_values = input_data(i).data_values;

            if isempty(tt)
                tt = NaN(length(data_values),1);
            end

            if ind_Skew
                data_values2 = input_data(i).data_values2;
            end

            % Remove flag values?
            if ~isempty(flag_value)
                id_1 = data_values==flag_value;
                data_values(id_1)=[];
                tt(id_1)=[];
                if ind_Skew && ~isempty(data_values)
                    data_values2(id_1)=[];
                    data_values(data_values2==flag_value)=[];
                    tt(data_values2==flag_value)=[];
                    data_values2(data_values2==flag_value)=[];
                end
            end

            % Remove NaN, Inf and nonpositive values
            data_values = data_values(:);
            id_1 = isinf(data_values) | isnan(data_values) | data_values<=0;
            data_values(id_1,:)=[];
            tt(id_1,:)=[];

            if ind_Skew && ~isempty(data_values) %&& ~isempty(data_values2)
                data_values2 = data_values2(:);
                data_values2(id_1)=[];
                id_1 = isinf(data_values2)|isnan(data_values2)|data_values2<=0;
                data_values(id_1)=[];
                data_values2(id_1)=[];
                tt(id_1)=[];
            end

            % Sample only has the same value?
            [~,ia,~] = unique(data_values,'stable');
            ia = length(ia)<=3;

            % Merge data and store
            data_values = [tt data_values]; %#ok<AGROW>
            procData(i).dat = data_values;

            if ind_Skew && ~isempty(data_values) %&& ~isempty(data_values2)
                procData(i).dat2 = data_values2;
            end

            % Can dataset be evaluated? Mark empty datasets to delete later
            if isempty(data_values) || ia
                procData(i).id = i;
            end

            % If skew tides are needed, is there a valis model provided?
            if ind_Skew && (isempty(data_values2) || ~isobject(gprMdl(i).mdl))
                procData(i).id2 = i;
            else
                procData(i).id2 = 0;
            end
        end
end


%% Select dataset to evaluate
Removed_datasets = '';
id = [procData.id];
if ~isempty(id)
    sz(id)=[];
    Removed_datasets = {'Cannot evaluate these stations for any of the following reasons:';...
        '- dataset was empty after removal of NaN/Inf/flag values (and nonpositive values when input dataset is a POT)';...
        '- dataset consists of 3 or less unique values repeated many times'};

    for i=id
        Removed_datasets = [Removed_datasets; staID{i}]; %#ok<AGROW>
    end
end
j=0;


%% Store message that ind_Skew = 1 but invalid POT_samp2 and/or GPR model object
Check_datasets = '';
if ind_Skew
    id2 = [procData.id2];
    if ~isempty(id)
        id2(id)=[];
    end
    id2(id2==0)=[];
    if ~isempty(id2)
        Check_datasets = {'These stations were evaluated without applying skew tides since:';...
            '- ind_Skew = 1 but entered invalid values for either the second POT dataset (with tides) or the GPR model'};

        for i=id2
            Check_datasets = [Check_datasets; staID{i}]; %#ok<AGROW>
        end
    end
end


%% Perform SST
switch DataType
    case 1 %Timeseries
        if GPD_TH_crit==0 % Evaluate all MRL thresholds
            for i=sz %dataset loop
                if stat_print == 1
                    disp(['*** Step 3: Performing SST for station ',staID{i,1}]);
                end
                j=j+1;
                try
                    % Execute StormSim-POT
                    [POT_samp,~] = StormSim_POT(procData(i).dat(:,1),procData(i).dat(:,2),tLag(i),lambda(i),Nyrs(i));

                    % Execute StormSim-SST-Fit
                    [HC_emp,HC_plt,HC_plt_x2,HC_tbl,HC_tbl_rsp_x,MRL_output] = StormSim_SST_Fit(POT_samp(:,2),Nyrs(i),HC_plt_x,HC_tbl_x,HC_tbl_rsp_y,prc,use_AEP,GPD_TH_crit,ind_Skew,procData(i).dat2,SLC,gprMdl(i).mdl,staID(i,1),yaxis_Label{i},path_out,yaxis_Limits(i,:),apply_GPD_to_SS, app_type);

                    % Gather the output
                    switch ExecMode
                        case 1 %Regular
                            SST_output(j).staID = staID{i,1};
                            SST_output(j).RL = Nyrs(i);
                            SST_output(j).POT = POT_samp;
                            SST_output(j).MRL_output = MRL_output;
                            SST_output(j).HC_plt = HC_plt;
                            SST_output(j).HC_tbl = HC_tbl;
                            SST_output(j).HC_tbl_rsp_x = HC_tbl_rsp_x;
                            SST_output(j).HC_emp = HC_emp;

                            % Plot results
                            StormSim_SST_Plot(HC_plt,HC_emp,MRL_output,prc,staID(i,:),yaxis_Label{i},path_out,yaxis_Limits(i,:),use_AEP,GPD_TH_crit,a,HC_plt_x2,y_log)

                        case 2 %Fast
                            SST_output(j).staID = staID{i,1};
                            SST_output(j).HC_plt=HC_plt;
                            SST_output(j).HC_tbl=HC_tbl;
                            SST_output(j).HC_tbl_rsp_x=HC_tbl_rsp_x;
                    end
                catch ME
                    SST_output(j).staID = staID{i,1};
                    SST_output(j).ME = ME;
                end
            end

        elseif id_PCT && GPD_TH_crit~=0 && apply_Parallel % PCT available and evaluate only one MRL threshold
            for i=sz %dataset loop
                if stat_print == 1
                    disp(['*** Step 3: Performing SST for station ',staID{i,1}]);
                end
                j=j+1;
                try
                    % Execute StormSim-POT
                    [POT_samp,~] = StormSim_POT(procData(i).dat(:,1),procData(i).dat(:,2),tLag(i),lambda(i),Nyrs(i));

                    % Execute StormSim-SST-Fit-Simple
                    [HC_emp,HC_plt,HC_plt_x2,HC_tbl,HC_tbl_rsp_x,MRL_output,str1] = StormSim_SST_Fit_SimplePar(POT_samp(:,2),Nyrs(i),HC_plt_x,HC_tbl_x,HC_tbl_rsp_y,prc,use_AEP,GPD_TH_crit,ind_Skew,procData(i).dat2,SLC,gprMdl(i).mdl,apply_GPD_to_SS, app_type);

                    % Gather the output
                    switch ExecMode
                        case 1 %Regular
                            SST_output(j).staID = staID{i,1};
                            SST_output(j).RL = Nyrs(i);
                            SST_output(j).POT=POT_samp;
                            SST_output(j).MRL_output=MRL_output;
                            SST_output(j).HC_plt=HC_plt;
                            SST_output(j).HC_tbl=HC_tbl;
                            SST_output(j).HC_tbl_rsp_x=HC_tbl_rsp_x;
                            SST_output(j).HC_emp=HC_emp;
                            SST_output(j).Warning=str1;

                            % Plot results
                            StormSim_SST_Plot_Simple(HC_emp,HC_plt,HC_plt_x2,MRL_output,prc,use_AEP,staID(i,:),yaxis_Label{i},path_out,yaxis_Limits(i,:),a,GPD_TH_crit,y_log)

                        case 2 %Fast
                            SST_output(j).staID = staID{i,1};
                            SST_output(j).HC_plt=HC_plt;
                            SST_output(j).HC_tbl=HC_tbl;
                            SST_output(j).HC_tbl_rsp_x=HC_tbl_rsp_x;
                            SST_output(j).Warning=str1;
                    end
                catch ME
                    SST_output(j).staID = staID{i,1};
                    SST_output(j).ME = ME;
                end
            end

        else % PCT not available and evaluate only one MRL threshold
            for i=sz %dataset loop
                if stat_print == 1
                    disp(['*** Step 3: Performing SST for station ',staID{i,1}]);
                end
                j=j+1;
                try
                    % Execute StormSim-POT
                    [POT_samp,~] = StormSim_POT(procData(i).dat(:,1),procData(i).dat(:,2),tLag(i),lambda(i),Nyrs(i));

                    % Execute StormSim-SST-Fit-Simple
                    [HC_emp,HC_plt,HC_plt_x2,HC_tbl,HC_tbl_rsp_x,MRL_output,str1] = StormSim_SST_Fit_Simple(POT_samp(:,2),Nyrs(i),HC_plt_x,HC_tbl_x,HC_tbl_rsp_y,prc,use_AEP,GPD_TH_crit,ind_Skew,procData(i).dat2,SLC,gprMdl(i).mdl,apply_GPD_to_SS, app_type);

                    % Gather the output
                    switch ExecMode
                        case 1 %Regular
                            SST_output(j).staID = staID{i,1};
                            SST_output(j).RL = Nyrs(i);
                            SST_output(j).POT=POT_samp;
                            SST_output(j).MRL_output=MRL_output;
                            SST_output(j).HC_plt=HC_plt;
                            SST_output(j).HC_tbl=HC_tbl;
                            SST_output(j).HC_tbl_rsp_x=HC_tbl_rsp_x;
                            SST_output(j).HC_emp=HC_emp;
                            SST_output(j).Warning=str1;

                            % Plot results
                            StormSim_SST_Plot_Simple(HC_emp,HC_plt,HC_plt_x2,MRL_output,prc,use_AEP,staID(i,:),yaxis_Label{i},path_out,yaxis_Limits(i,:),a,GPD_TH_crit,y_log)

                        case 2 %Fast
                            SST_output(j).staID = staID{i,1};
                            SST_output(j).HC_plt=HC_plt;
                            SST_output(j).HC_tbl=HC_tbl;
                            SST_output(j).HC_tbl_rsp_x=HC_tbl_rsp_x;
                            SST_output(j).Warning=str1;
                    end
                catch ME
                    SST_output(j).staID = staID{i,1};
                    SST_output(j).ME = ME;
                end
            end
        end

    case 2 %POT

        %%% Add noise to duplicates in POT sample - LAA 2023/12/07
        for i=sz %dataset loop
            aux_pot=procData(i).dat(:,2);
            [~,w]=unique(aux_pot,'stable');
            duplicate_indices=setdiff(1:numel(aux_pot),w);
            aux_pot(duplicate_indices)=aux_pot(duplicate_indices)+1e-6;
            procData(i).dat(:,2)=aux_pot;
        end
        %%%

        if GPD_TH_crit==0
            for i=sz %dataset loop
                if stat_print == 1
                    disp(['*** Step 3: Performing SST for station ',staID{i,1}]);
                end
                j=j+1;
                try
                    % Execute StormSim-SST-Fit
                    [HC_emp,HC_plt,HC_plt_x2,HC_tbl,HC_tbl_rsp_x,MRL_output] = StormSim_SST_Fit(procData(i).dat(:,2),Nyrs(i),HC_plt_x,HC_tbl_x,HC_tbl_rsp_y,prc,use_AEP,GPD_TH_crit,ind_Skew,procData(i).dat2,SLC,gprMdl(i).mdl,staID(i,1),yaxis_Label{i},path_out,yaxis_Limits(i,:),apply_GPD_to_SS, app_type);

                    % Gather the output
                    switch ExecMode
                        case 1 %Regular
                            SST_output(j).staID = staID{i,1};
                            SST_output(j).RL = Nyrs(i);
                            SST_output(j).POT=procData(i).dat;
                            SST_output(j).MRL_output=MRL_output;
                            SST_output(j).HC_plt=HC_plt;
                            SST_output(j).HC_tbl=HC_tbl;
                            SST_output(j).HC_tbl_rsp_x=HC_tbl_rsp_x;
                            SST_output(j).HC_emp=HC_emp;

                            % Plot results
                            StormSim_SST_Plot(HC_plt,HC_emp,MRL_output,prc,staID(i,:),yaxis_Label{i},path_out,yaxis_Limits(i,:),use_AEP,GPD_TH_crit,a,HC_plt_x2,y_log)

                        case 2 %Fast
                            SST_output(j).staID = staID{i,1};
                            SST_output(j).HC_plt=HC_plt;
                            SST_output(j).HC_tbl=HC_tbl;
                            SST_output(j).HC_tbl_rsp_x=HC_tbl_rsp_x;
                    end
                catch ME
                    SST_output(j).staID = staID{i,1};
                    SST_output(j).ME = ME;
                end
            end

        elseif id_PCT && GPD_TH_crit~=0 && apply_Parallel % PCT available and evaluate only one MRL threshold
            for i=sz %dataset loop
                if stat_print == 1
                    disp(['*** Step 3: Performing SST for station ',staID{i,1}]);
                end
                j=j+1;
                try
                    % Execute StormSim-SST-Fit-Simple
                    [HC_emp,HC_plt,HC_plt_x2,HC_tbl,HC_tbl_rsp_x,MRL_output,str1] = StormSim_SST_Fit_SimplePar(procData(i).dat(:,2),Nyrs(i),HC_plt_x,HC_tbl_x,HC_tbl_rsp_y,prc,use_AEP,GPD_TH_crit,ind_Skew,procData(i).dat2,SLC,gprMdl(i).mdl,apply_GPD_to_SS, app_type);

                    % Gather the output
                    switch ExecMode
                        case 1 %Regular
                            SST_output(j).staID = staID{i,1};
                            SST_output(j).RL = Nyrs(i);
                            SST_output(j).POT=procData(i).dat;
                            SST_output(j).MRL_output=MRL_output;
                            SST_output(j).HC_plt=HC_plt;
                            SST_output(j).HC_tbl=HC_tbl;
                            SST_output(j).HC_tbl_rsp_x=HC_tbl_rsp_x;
                            SST_output(j).HC_emp=HC_emp;
                            SST_output(j).Warning=str1;

                            % Plot results
                            StormSim_SST_Plot_Simple(HC_emp,HC_plt,HC_plt_x2,MRL_output,prc,use_AEP,staID(i,:),yaxis_Label{i},path_out,yaxis_Limits(i,:),a,GPD_TH_crit,y_log)

                        case 2 %Fast
                            SST_output(j).staID = staID{i,1};
                            SST_output(j).HC_plt=HC_plt;
                            SST_output(j).HC_tbl=HC_tbl;
                            SST_output(j).HC_tbl_rsp_x=HC_tbl_rsp_x;
                            SST_output(j).Warning=str1;
                    end
                catch ME
                    SST_output(j).staID = staID{i,1};
                    SST_output(j).ME = ME;
                end
            end

        else % PCT not available and evaluate only one MRL threshold
            for i=sz %dataset loop
                if stat_print == 1
                    disp(['*** Step 3: Performing SST for station ',staID{i,1}]);
                end
                j=j+1;
                try
                    % Execute StormSim-SST-Fit-Simple
                    [HC_emp,HC_plt,HC_plt_x2,HC_tbl,HC_tbl_rsp_x,MRL_output,str1] = StormSim_SST_Fit_Simple(procData(i).dat(:,2),Nyrs(i),HC_plt_x,HC_tbl_x,HC_tbl_rsp_y,prc,use_AEP,GPD_TH_crit,ind_Skew,procData(i).dat2,SLC,gprMdl(i).mdl,apply_GPD_to_SS, app_type);

                    % Gather the output
                    switch ExecMode
                        case 1 %Regular
                            SST_output(j).staID = staID{i,1};
                            SST_output(j).RL = Nyrs(i);
                            SST_output(j).POT=procData(i).dat;
                            SST_output(j).MRL_output=MRL_output;
                            SST_output(j).HC_plt=HC_plt;
                            SST_output(j).HC_tbl=HC_tbl;
                            SST_output(j).HC_tbl_rsp_x=HC_tbl_rsp_x;
                            SST_output(j).HC_emp=HC_emp;
                            SST_output(j).Warning=str1;

                            % Plot results
                            StormSim_SST_Plot_Simple(HC_emp,HC_plt,HC_plt_x2,MRL_output,prc,use_AEP,staID(i,:),yaxis_Label{i},path_out,yaxis_Limits(i,:),a,GPD_TH_crit,y_log)

                        case 2 %Fast
                            SST_output(j).staID = staID{i,1};
                            SST_output(j).HC_plt=HC_plt;
                            SST_output(j).HC_tbl=HC_tbl;
                            SST_output(j).HC_tbl_rsp_x=HC_tbl_rsp_x;
                            SST_output(j).Warning=str1;
                    end
                catch ME
                    SST_output(j).staID = staID{i,1};
                    SST_output(j).ME = ME;
                end
            end
        end
end

if use_AEP %Convert to AEP
    HC_plt_x = aef2aep(HC_plt_x);
end

%% Save the output
if stat_print == 1
    disp(['*** Step 4: Saving results here: ',path_out]);
end
save([path_out,'StormSim_' staID{:} '_SST_output.mat'],'SST_output','HC_tbl_x','HC_plt_x','HC_tbl_rsp_y','Removed_datasets','Check_datasets','-v7.3')

[~,id_act]=hasPCT;if id_act==0,delete(gcp);end
if stat_print == 1
    disp('*** Evaluation finished.' )
    disp(['****** Remember to check outputs Check_datasets and Removed_datasets.' newline])
    disp('*** StormSim-SST Tool terminated.')
end
end