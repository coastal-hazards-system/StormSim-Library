%% StormSim_JPM_Tool.m
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
    StormSim-JPM (Integration)

DESCRIPTION:
    This script receives and process the input parameters necessary to perform
    the Joint Probability Method (JPM) integration. All other necessary scripts
    to generate the hazard curve (HC) are nested within this script. The resulting
    HC is expressed in terms of annual exceedance probability. The user can choose
    one of the following integration methodologies to incorporate the uncertainty:

    1) PCHA ATCS (approach with augmented TC suite)
    2) PCHA Standard (general approach)
    3) JPM Standard (approach with full storm suite)

INPUT ARGUMENTS:
 - Resp: Response data; specified as a numerical array. Each row represents an event
    (e.g., storm). Each column represents a location (e.g., virtual gauge, savepoint, or node).
 - ProbMass: Probability mass per event; specified as a vector or a matrix. Each
    row represents an event. Each column represents a virtual gauge.
 - vg_id: ID number to label the location (savepoint, virtual gauge or node) to be
    evaluated; specified as a positive scalar or vector of positive integers.
    Must have one value per column of input Resp. Otherwise, leave empty [] to
    automatically generate the IDs. Example: vg_id = [1 2 3 4 5 10 100 1500];
 - vg_ColNum: Specific locations (columns in input Resp) to be evaluated; specified
    as a positive scalar or vector of positive integers. Otherwise, leave empty
    [ ] to evaluate all locations. Example: if input Resp has 1000 columns
    (for 1000 virtual gauges) but only want to evaluate columns 1, 5, and 100,
    enter sp_ColNum = [1 5 100];
 - U_a: Absolute uncertainty associated to the response. This uncertainty has same
    units of the response. The tool will apply this uncertainty depending on the
    value of inputs uncert_treatment and ind_method. Specified as a non-negative scalar.
    Otherwise, leave empty [ ]. Example: U_a = 0.20 meters;
 - U_r: Relative uncertainty associated to the response and is dimensionless since
    is a fraction. The tool will apply this uncertainty depending on the value of
    inputs uncert_treatment and ind_method. Specified as a non-negative scalar. Otherwise,
    leave empty [ ]. Example: U_r = 0.15;
 - U_tide_type: Type of tide uncertainty; specified as a character vector. Current options are:

      'SD' = tide uncertainty in the form of a standard deviation, which is
      distributed and added to the responses. This can be combined with
      the absolute and relative uncertainties.

      'Skew' = tide uncertainty in the form of a skew or offset, which is
      added to the responses. Skew tides will not be combined with other
      uncertainties.

      Otherwise, set U_tide_type = [] when no tide uncertainty applies (or U_tide = []).

 - U_tide: Uncertainty associated to tides. Current options for this input
      vary depending on the value of input argument U_tide_type, as follows:
      
      When U_tide_type = 'SD', input U_tide represents the tide uncertainty
      in the form of a standard deviation. Can be specified as a non-negative
      scalar when only one value applies to all locations. Can also be
      specified as a vector of non-negative values, with one value per
      location. Cannot be a matrix array.
      
      When U_tide_type = 'Skew', input U_tide represents the tide uncertainty
      in the form of a skew or offset, and is superimpose to the responses.
      In this case, U_tide can be specified in one of the following formats:
        1) numerical scalar (one skew value applies to all virtual gauges)
        2) numerical vector (with as many values as virtual gauges)
        3) numerical matrix (with one value per event per virtual gauge)
      Cannot have NaN or inf values.

      Otherwise, set U_tide = [] when no tide uncertainty applies (or U_tide_type = []).

 - U_tide_app: Indicates how the tool should apply the tide uncertainty.
      This uncertainty will be applied differently depending on the selected
      integration method (integrate_Method) and uncertainty treatment (uncert_treatment).
      Available options are as follows:

      U_tide_app = 0:
        The tide uncertainty is not applied, regardless of the values of
        inputs integrate_Method and uncert_treatment.
      
      U_tide_app = 1:
        When integrate_Method = 'PCHA ATCS' or integrate_Method = 'PCHA Standard', the
          tide uncertainty (as a standard deviation) is combined with U_a, U_r or both, depending on
          the value of input uncert_treatment, and then applied to the confidence limits.
        When integrate_Method = 'JPM Standard', the tide uncertainty is combined with
          U_a, U_r or both, depending on the value of input uncert_treatment, and then
          applied to the response.
      
      U_tide_app = 2:
        The tide uncertainty is applied to the response before any of the other
        uncertainties, regardless of the values of inputs integrate_Method and uncert_treatment.
        The value of input U_tide_type determines how it is added, as follows:
          When U_tide_type = 'Skew': the tide uncertainty is added to the
            response.
          When U_tide_type = 'SD': the tide uncertainty is distributed and
            then added to the response. The distribution is random when
            integrate_Method = 'PCHA ATCS'. Otherwise, the uncertainty is distributed
            using a discrete Gaussian distribution when integrate_Method = 'PCHA Standard'.
          
 - uncert_treatment: Indicates the uncertainty treatment to use; specified as a character vector.
      Determines how the absolute (U_a) and relative (U_r) uncertainties are applied.
      Current options are:
        uncert_treatment = 'absolute': only U_a is applied
        uncert_treatment = 'relative': only U_r is applied
        uncert_treatment = 'combined': both U_a and U_r are applied
      These uncertainties can also be combined with the tide uncertainty depending
      on the values of inputs U_tide_app and integrate_Method.

 - prc: Percentage values for computing the percentiles; specified as a
      scalar or vector of positive values. Leave empty [] to apply default
      values 2.28%, 15.87%, 84.13%, 97.72%. User can enter 1 to 4 values.
      Example: prc = [2 16 84 98];

 - integrate_Method: Integration method; specified as a character vector.
      Currently, the tool can apply one of three integration methodologies,
      which share the same integration equation but have unique ways of
      incorporating the uncertainties. Current options are described as follows:

      integrate_Method = 'PCHA ATCS': Refers to the Probabilistic Coastal Hazard Analysis (PCHA)
        with Augmented Tropical Cyclone Suite (ATCS) methodology. This approach is
        preferred when hazard curves with associated confidence limit (CL) curves
        are to be estimated using the synthetic storm suite augmented through Gaussian
        process metamodelling (GPM). The different uncertainties are incorporated into
        either the response or the percentiles, depending on the settings specified for
        U_tide_app and uncert_treatment. With the exception of when U_tide_type = 'Skew', the
        uncertainties are distributed randomly before application. This methodology
        has been applied in the following studies:
        a) South Atlantic Coast Study (SACS) - Phases 1 (PRUSVI), 2 (NCSFL) and 3 (SFLMS)
        b) Louisiana Coast Protection and Restoration (LACPR) Study
        c) Coastal Texas Study (CTXS) - Revision


      integrate_Method = 'PCHA Standard': Refers to the PCHA Standard methodology. This
        approach is preferred when hazards with CLs are to be estimated using the
        synthetic storm suite is used "as is" (not augmented). The absolute and
        relative uncertainties are initially partitioned. Then, the different
        uncertainties are incorporated into either the response or the percentiles,
        depending on the settings specified for U_tide_app and uncert_treatment. With the
        exception of when U_tide_type = 'Skew', the uncertainties are normally
        distributed using a discrete Gaussian before application. This methodology
        has been used in the following studies:
        a) North Atlantic Coast Comprehensive Study (NACCS)
        b) Coastal Texas Study (CTXS) - Initial study


      integrate_Method = 'JPM Standard': Refers to the Standard JPM approach. This approach
        incorporates all uncertainties into a single hazard curve and does not
        generate CL curves. The uncertainties are applied and/or combined depending
        on the settings specified for U_tide_app and uncert_treatment. With the exception
        of when U_tide_type = 'Skew', the uncertainties are normally distributed
        using a discrete Gaussian before application.

 - path_out: Path to output folder; specified as a character vector. Leave
      empty [] to apply default: '.\JPM_output\'

 - yaxis_label: Parameter name/units/datum for label of the plot y-axis;
      specified as a character vector. Example: 'Still Water Level (m, MSL)'

 - yaxis_limits: Lower and upper limits for the plot y-axis; specified as a
      vector. Leave empty [] otherwise. Example: yaxis_limits = [0 10];

 - SLC: Magnitude of the sea level change associated to the responses (without steric adjustments);
      specified as a positive scalar. Otherwise, leave empty.

 - plot_results: Enter one (1) to also generate hazard plots; enter zero (0) otherwise.

 - ind_aep: indicator for expressing the hazard as AEF or AEP. Use 1 for
      AEP, 0 for AEF. Example: ind_aep = 1;
 
 - apply_Parallel: Enter one (1) to run tool in parallel; enter zero (0)
      otherwise. The tool will execute in parallel ONLY if the Parallel
      Computing Toolbox is installed and integrate_Method = 'PCHA Standard' or
      integrate_Method = 'JPM Standard'.


OUTPUT ARGUMENTS:
 - JPM_output: full HC per virtual gage; as a structure variable with the following fields:
     vg_ID = virtual gauge ID number specified by the user
     x = predefined vector of probabilities used to plot the HC. The type is:
        > AEP when ind_aep = 1
        > AEF when ind_aep = 0
     y = numerical array with the following 5 columns
        col(01): best estimate or mean response (full HC)
        col(02): values of 2% percentile or 1st percentage of input prc
        col(03): values of 16% percentile or 2nd percentage of input prc
        col(04): values of 84% percentile or 3rd percentage of input prc
        col(05): values of 98% percentile or 4th percentage of input prc
     HC_tbl_y = summarized HC and percentiles, corresponding to the values in HC_tbl_x.
        col(01): best estimate or mean response (full HC)
        col(02): values of 2% percentile or 1st percentage of input prc
        col(03): values of 16% percentile or 2nd percentage of input prc
        col(04): values of 84% percentile or 3rd percentage of input prc
        col(05): values of 98% percentile or 4th percentage of input prc
	 HC_tbl_rsp_x = hazard values interpolated from the HC and percentiles, that correspond to the responses in HC_tbl_rsp_y.
        col(01): best estimate or mean response (full HC)
        col(02): values of 2% percentile or 1st percentage of input prc
        col(03): values of 16% percentile or 2nd percentage of input prc
        col(04): values of 84% percentile or 3rd percentage of input prc
        col(05): values of 98% percentile or 4th percentage of input prc

 - HC_tbl_x: predefined vector of probabilities used to summarize the HC. The type is:
    > AEP when ind_aep = 1
    > AEF when ind_aep = 0

 - HC_tbl_rsp_y: predefined vector of response values used to summarize the HC.
 

AUTHORS:
    Norberto C. Nadal-Caraballo, PhD (NCNC)
    Efrain Ramos-Santiago (ERS)

CONTRIBUTORS:
    Alexandros A. Taflanidis, PhD (AAT)
    Victor M. Gonzalez, PE (VMG)

HISTORY OF REVISIONS:
20200904-ERS: revised.
20201001-ERS: revised.
20201011-ERS: updated. Input ProbMass can be specified either as a vector or matrix.
20201013-ERS: added capability to evaluate a specific set of savepoints
    instead of all savepoints in the input. Also, user can now input a custom ID
    number for the savepoints.
20210202-ERS: added scheme to partition the inputs when has more than 5000
    virtual gauges.
20210402-ERS: alpha version 0.1: added option to switch between AEF/AEP;
    organized script; added code to verify/validate format of input data and
    settings; updated documentation.
20210601-ERS: alpha version v0.2: corrected bugs. Added capability to run in parallel.
20210701-ERS: alpha version v0.2: percentiles now interpolated for summary
    table. Tables now stored inside the struct array JPM_output (previously HC_plot).
20210809-ERS: alpha version v0.2: revised. Added Removed_vg as an
    output. Modified the integration script to only evaluate feasible
    datasets. Reorganized the outputs. Changed input names.
20210831-ERS: alpha version v0.3: duplicates now removed from x values when
    interpolating HC plot in the integration script.

***************  ALPHA  VERSION  **  FOR INTERNAL TESTING ONLY ************
%}
function [JPM_output,HC_plt_x,HC_tbl_x,HC_tbl_rsp_y,Removed_vg] = StormSim_JPM_Tool_R1_v20210831(Resp,ProbMass,vg_id,vg_ColNum,U_a,U_r,U_tide,U_tide_app,U_tide_type,uncert_treatment,prc,integrate_Method,path_out,yaxis_label,yaxis_limits,SLC,plot_results,ind_aep,apply_Parallel,HC_tbl_rsp_y)
%% General settings
clc;disp(['***********************************************************' newline...
    '***         StormSim-JPM Tool Alpha Version 0.3         ***' newline...
    '***                Release 1 - 20210831                 ***' newline...
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

% Turn off all warnings
warning('off','all');

% Check ind_aep
if sum(ind_aep==[0 1])~=1||isempty(ind_aep)||isnan(ind_aep)
    error('Input ind_aep must be 0 or 1')
end

% Set up probabilities for HC summary
if ind_aep %Select AEPs
    HC_tbl_x = 1./[2 5 10 20 50 100 200 500 1e3 2e3 5e3 1e4 2e4 5e4 1e5 2e5 5e5 1e6];
else %Select AEFs
    HC_tbl_x = 1./[0.1 0.2 0.5 1 2 5 10 20 50 100 200 500 1e3 2e3 5e3 1e4 2e4 5e4 1e5 2e5 5e5 1e6];
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
if isempty(path_out),path_out='JPM_output';mkdir(path_out);elseif ~exist(path_out,'dir'),mkdir(path_out);end
path_out=['.\',path_out,'\'];

% Check if Parallel Computing Toolbox exists, start pool session and Turn off warnings
[id_PCT,id_act]=hasPCT;
if id_PCT&&apply_Parallel,if id_act,parpool;end;parfevalOnAll(gcp,@warning,0,'off','all');end

% Discretized Gaussian z-scores
dscrtGauss = [1.9982;1.5632;1.3064;1.1147;0.957;0.8202;0.6973;0.5841;0.478;0.377;0.2798;0.1852;0.0922;0;-0.0922;-0.1852;-0.2798;-0.377;-0.478;-0.5841;-0.6973;-0.8202;-0.957;-1.1147;-1.3064;-1.5632;-1.9982];

% Compatibility check
a=version('-release');if a(end)=='a',a(end)='0';else;a(end)='1';end;a=str2double(a)<20200;

%% Check size and value of inputs Resp and Probmass
if isempty(Resp),error('Input Resp cannot be an empty array');end
if isempty(ProbMass),error('Input ProbMass cannot be an empty array');end
[m,n]=size(Resp);
if isvector(ProbMass)
    ProbMass=ProbMass(:);
    ProbMass=repmat(ProbMass,1,n);
elseif isscalar(ProbMass)
    error(['Input ProbMass cannot be a scalar array. Enter the ProbMass as ' newline...
        'a numerical vector or a matrix with same size as Resp. ProbMass' newline ...
        'must have one probability mass for each storm or response value.'])
else
    [m2,n2]=size(ProbMass);
    if ~(m==m2 && n==n2)
        error(['Inputs ProbMass and Resp not same size. Provide one ' newline ...
            'probability mass for each storm or response value.'])
    end
end


%% Check inputs vg_ColNum and vg_id
if ~isempty(vg_ColNum)
    if length(vg_ColNum)>n
        error('The size of input vg_ColNum cannot exceed the total number of columns in input Resp.')
    end
    if max(vg_ColNum,[],'omitnan')>n
        error('The maximum value of input vg_ColNum cannot exceed the total number of columns in input Resp.')
    end
end

if isempty(vg_id)
    vg_id=1:n;
else
    if length(vg_id)~=n,error('Input vg_id must have as many values as columns in input Resp.');end
end


%% Check the uncertainties
if U_a<0||~isscalar(U_a)||isempty(U_a)||isinf(U_a),error('Input U_a must be a positive scalar.');end
if U_r<0||~isscalar(U_r)||isempty(U_r)||isinf(U_r),error('Input U_r must be a positive scalar.');end
if U_a==0,U_a=1e-7;end; if U_r==0,U_r=1e-7;end


%% Check U_tide_app
switch U_tide_app
    case 0
        if or(~isempty(U_tide),~isempty(U_tide_type))
            error(['Double check your selection of the following setting: ' newline...
                '  U_tide_app' newline...
                '  U_tide' newline...
                '  U_tide_type' newline...
                'When U_tide_app = 0, U_tide and U_tide_type must be empty. ' newline...
                'Refer to the quick start guide for mode details.'])
        end
    case 1
        if and(strcmp(U_tide_type,'SD'),isempty(U_tide))
            error(['Double check your selection of the following setting: ' newline...
                '  U_tide_app' newline...
                '  U_tide' newline...
                '  U_tide_type' newline...
                'When U_tide_app = 1, set U_tide_type = ''SD'' and enter U_tide in ' newline...
                '  the form of a standard deviation. U_tide cannot be empty.' newline...
                'Refer to the quick start guide for mode details.'])
        end
    case 2
        if or(isempty(U_tide),isempty(U_tide_type))
            error(['Double check your selection of the following setting: ' newline...
                '  U_tide_app' newline...
                '  U_tide' newline...
                '  U_tide_type' newline...
                'When U_tide_app = 2, U_tide and U_tide_type cannot be empty. ' newline...
                'Refer to the quick start guide for mode details.'])
        end
    otherwise
        error(['Unrecognized value of input U_tide_app. Available options are 0, 1 or 2.' newline...
            'Refer to the quick start guide for mode details.'])
end


%% Check U_tide, U_tide_type
if ~isempty(U_tide_type)
    switch U_tide_type
        case 'SD' %Tide unc as a standard deviation
            if isscalar(U_tide)
                U_tide=repmat(U_tide,1,n);
            elseif isvector(U_tide)
                if length(U_tide)~=n
                    error(['When U_tide_type = ''SD'', input U_tide can be either a non-negative' newline...
                        'scalar or a vector of non-negative values with as many values as columns' newline...
                        'in Resp. Cannot have NaN or inf values.'])
                end
                if iscolumn(U_tide),U_tide = U_tide';end
            else
                error(['When U_tide_type = ''SD'', input U_tide can be either a non-negative' newline...
                    'scalar or a vector of non-negative values with as many values as columns' newline...
                    'in Resp. Cannot have NaN or inf values.'])
            end
            if sum(U_tide<0)>0||sum(isinf(U_tide))>0||sum(isnan(U_tide))>0 %check for negatives
                error(['When U_tide_type = ''SD'', input U_tide can be either a non-negative' newline...
                    'scalar or a vector of non-negative values with as many values as columns' newline...
                    'in Resp. Cannot have NaN or inf values.'])
            end
        case 'Skew' %Tide unc as a skew
            if isscalar(U_tide)
                U_tide=repmat(U_tide,1,n);
            elseif isvector(U_tide)
                if length(U_tide)~=n
                    error(['When U_tide_type = ''Skew'', input U_tide can have one of the following formats:' newline...
                        '  1) numerical scalar (one skew value applies to all virtual gauges),' newline...
                        '  2) numerical vector (with as many values as virtual gauges),' newline...
                        '  3) numerical matrix (with one value per event per virtual gauge).' newline...
                        'Cannot have NaN or inf values.'])
                end
                if iscolumn(U_tide),U_tide = U_tide';end
            else
                [m2,n2]=size(U_tide);
                if m2~=m && n2~=n
                    error(['When U_tide_type = ''Skew'', input U_tide can have one of the following formats:' newline...
                        '  1) numerical scalar (one skew value applies to all virtual gauges),' newline...
                        '  2) numerical vector (with as many values as virtual gauges),' newline...
                        '  3) numerical matrix (with one value per event per virtual gauge).' newline...
                        'Cannot have NaN or inf values.'])
                end
            end
            if sum(sum(isinf(U_tide)))>0||sum(sum(isnan(U_tide)))>0
                error('When U_tide_type = ''Skew'', input U_tide cannot have NaN or inf values.')
            end
        otherwise
            error('Unrecognized value of input U_tide_type. Available options are ''SD'' and ''Skew'' ')
    end
else
    U_tide = zeros(1,n);
end


%% Check SLC
if isempty(SLC)||isnan(SLC)||isinf(SLC)||ischar(SLC),SLC = 0;end
if length(SLC)~=1||SLC<0,error('Input SLC must be a non-negative scalar value.');end


%% Check prc, yaxis_label, yaxis_limits, plot_results
if isempty(prc)
    prc=[2.28 15.87 84.13 97.72]';
else
    if length(prc)>4||sum(isnan(prc))>0||sum(isinf(prc))>0||sum(prc<0)~=0
        error('Input prc can have 1 to 4 percentages in the interval [0,100].');
    end
    prc=sort(prc,'ascend'); prc=prc(:);
end
z=norminv(prc/100)'; %compute Normal Z-scores
if sum(plot_results==[0 1])~=1
    error('Unrecognized value of input plot_results. Available options are 0 or 1.');
end
if plot_results
    if strcmp(yaxis_label,'')||~ischar(yaxis_label)
        error('Input yaxis_label cannot be an empty array.');
    end
    if ~isempty(yaxis_limits)
        if length(yaxis_limits)~=2
            error('Input yaxis_limits must be a vector with two values')
        end
    end
end


%% Check uncert_treatment, integrate_Method
if sum(strcmp(uncert_treatment,{'absolute','relative','combined'}))~=1
    error(['Unrecognized value of input uncert_treatment. Available options' newline...
        'are ''absolute'', ''relative'' or ''combined'''])
end
dm_met={'PCHA ATCS','PCHA Standard','JPM Standard'};
if sum(strcmp(integrate_Method,dm_met))~=1
    error(['Unrecognized value of input integrate_Method. Available options' newline...
        'are ''PCHA ATCS'', ''PCHA Standard'' or ''JPM Standard'''])
end
integrate_Method=find(strcmp(integrate_Method,dm_met));%change to number, avoiding constant txt evaluation


%% Take data for User-specified virtual gauges
if ~isempty(vg_ColNum)
    ProbMass=ProbMass(:,vg_ColNum);Resp=Resp(:,vg_ColNum);vg_id=vg_id(vg_ColNum);
    %Note: at this point in the script, U_tide is either a row vector or a numerical array
    if isvector(U_tide),U_tide=U_tide(vg_ColNum);else,U_tide=U_tide(:,vg_ColNum);end
end
if isvector(U_tide),U_tide = repmat(U_tide,m,1);end
%Note: at this point in the script, U_tide is always a numerical array
Resp(Resp<0)=NaN; %Working with extreme events: Change negative values to NaN.


%% Check number of virtual gauges and partition the inputs if necessary
[~,n]=size(Resp);
sz = (n <= 5000);
switch sz
    case 1
        
        disp(['*** Step 2: Partition of input data not necessary' newline...
            '****** User entered less than 5000 virtual gages'])

        % Perform integration
        disp('*** Step 3: Performing integration')
        [JPM_output,Removed_vg] = StormSim_JPM_Integrate(Resp,ProbMass,vg_id,U_a,U_r,U_tide,U_tide_app,U_tide_type,uncert_treatment,integrate_Method,SLC,dscrtGauss,HC_tbl_rsp_y,HC_tbl_x,z,ind_aep,id_PCT,apply_Parallel,HC_plt_x);
        
        % Change AEF to AEP?
        if ind_aep
            HC_plt_x=aef2aep(HC_plt_x);
        end

        % Plot hazard curves
        if plot_results
            disp('****** Plotting hazard curves')
            StormSim_JPM_Plot(JPM_output,vg_id,path_out,yaxis_label,yaxis_limits,integrate_Method,prc,ind_aep,a,HC_plt_x)
        end
        
        % Store output
        disp(['*** Step 4: Saving results here: ',path_out])
        save([path_out,'StormSim_JPM_output.mat'],'JPM_output','HC_plt_x','HC_tbl_x','HC_tbl_rsp_y','Removed_vg','-v7.3')
        
    case 0
        
        % Set path directory to stored partitioned "Response" files
        pth_inp = 'JPM_input_partitioned';
        if ~exist(pth_inp,'dir'),mkdir(pth_inp);end; pth_inp=['.\',pth_inp,'\'];
        
        % Display status
        disp(['*** Step 2: Partitioning input data ' newline...
            '****** User entered more than 5000 virtual gages'])
        
        % Split the inputs (big files) into partitions of 5000 virtual gages
        Np = round((n+5000)/5000); %number of partitions
        Nc = 1:5000; %counter of nodes
        for i = 1:Np %partition loop
            Resp_p=Resp(:,Nc);ProbMass_p=ProbMass(:,Nc);sp_id_p=vg_id(:,Nc);U_tide_p=U_tide(:,Nc);
            
            %Export partition
            save([pth_inp,'InputPartition_',int2str(i),'.mat'],'Resp_p','ProbMass_p','sp_id_p','U_tide_p')
            
            %Execute counter for next loop
            Nc = Nc+5000;
        end
        
        % Now, create and export the last partition
        Resp_p=Resp(:,Nc(1):n);ProbMass_p=ProbMass(:,Nc(1):n);sp_id_p=vg_id(:,Nc(1):n);U_tide_p=U_tide(:,Nc(1):n);
        save([pth_inp,'InputPartition_',int2str(Np),'.mat'],'Resp_p','ProbMass_p','sp_id_p','U_tide_p')
%         Np = Np-1;
        
        %Display status
        disp([' ****** Finished. Partitioned input files stored in ' pth_inp])
        
        % Delete original inputs from workspace
        clearvars Resp ProbMass U_tide vg_id;
        
        % Do evaluation, one partition at a time
        disp('*** Step 3: Performing integration')
        HC_plt_x2=HC_plt_x;
        for i = 1:Np %partition loop
            
            % Load files
            load([pth_inp,'InputPartition_',int2str(i),'.mat'],'Resp_p','ProbMass_p','sp_id_p','U_tide_p')
            
            % Display status
            disp(['****** Working partition file ',int2str(i),': virtual gauges ',int2str(sp_id_p(1)),' - ',int2str(sp_id_p(end))]) 
            
            % Perform integration
            [JPM_output,Removed_vg] = StormSim_JPM_Integrate(Resp_p,ProbMass_p,sp_id_p,U_a,U_r,U_tide_p,U_tide_app,U_tide_type,uncert_treatment,integrate_Method,SLC,dscrtGauss,HC_tbl_rsp_y,HC_tbl_x,z,ind_aep,id_PCT,apply_Parallel,HC_plt_x2);
            
            % Change AEF to AEP?
            if ind_aep
                HC_plt_x=aef2aep(HC_plt_x2);
            end

            % Plot hazard curves
            if plot_results
                disp('****** Plotting hazard curves')
                StormSim_JPM_Plot(JPM_output,sp_id_p,path_out,yaxis_label,yaxis_limits,integrate_Method,prc,ind_aep,a,HC_plt_x)
            end

            % Export output per partition
            save([path_out,'StormSim_JPM_output_Part_',int2str(i),'.mat'],'JPM_output','HC_plt_x','HC_tbl_x','HC_tbl_rsp_y','Removed_vg','-v7.3')
        end
        disp(['*** Step 4: Results stored here: ',path_out])
end
[~,id_act]=hasPCT;if id_act==0,delete(gcp);end
disp('*** Evaluation finished.')
disp('*** StormSim-JPM Tool terminated.')
end