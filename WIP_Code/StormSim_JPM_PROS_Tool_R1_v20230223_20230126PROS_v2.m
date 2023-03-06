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
	 HC_plt_rsp_x = hazard values interpolated from the HC and percentiles, that correspond to the responses in HC_plt_rsp_y.
        col(01): best estimate or mean response (full HC)
        col(02): values of 2% percentile or 1st percentage of input prc
        col(03): values of 16% percentile or 2nd percentage of input prc
        col(04): values of 84% percentile or 3rd percentage of input prc
        col(05): values of 98% percentile or 4th percentage of input prc
    HC_tbl_rsp_x = hazard values interpolated from the HC and percentiles, that correspond to the responses in HC_tbl_rsp_y.

 - HC_tbl_x: predefined vector of probabilities used to summarize the HC. The type is:
    > AEP when ind_aep = 1
    > AEF when ind_aep = 0
 - HC_plt_rsp_y: predefined vector of response values used to summarize the HC.
 - HC_tbl_rsp_y: lower resolution vector of response values used to summarize the HC.
 
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
20230126-JAM: Minor change to U_a input check line
20230223-LAA: Edited StormSim_JPM_Integrate.m to produce rsp_x variables at the same resolution as the HC_tbl
    and the HC_plt variables. Added statements to NaN rsp_x less than 1e-6.
***************  ALPHA  VERSION  **  FOR INTERNAL TESTING ONLY ************
%}
function [JPM_output,HC_plt_x,HC_tbl_x,HC_plt_rsp_y,HC_tbl_rsp_y,Removed_vg] = StormSim_JPM_PROS_Tool_R1_v20230223_20230126PROS(Resp,ProbMass,vg_id,vg_ColNum,U_a,U_r,U_tide,U_tide_app,U_tide_type,uncert_treatment,prc,integrate_Method,path_out,yaxis_label,yaxis_limits,SLC,plot_results,ind_aep,apply_Parallel,HC_plt_rsp_y,HC_tbl_rsp_y)
%% General settings
% clc;disp(['***********************************************************' newline...
%     '***         StormSim-JPM Tool Alpha Version 0.3         ***' newline...
%     '***                Release 1 - 20210831                 ***' newline...
%     '***                 FOR  TESTING  ONLY                  ***' newline...
%     '***********************************************************' newline...
%     '**********           NOTES TO THE USER           **********' newline...
%     '*** 1) Refer to Quick Start Guide for a description     ***' newline...
%     '***    of settings, inputs and outputs.                 ***' newline...
%     '*** 2) Please report any error using the Feedback Form. ***' newline...
%     '*** 3) For questions or help contact:                   ***' newline...
%     '***    Efrain.Ramos-Santiago@usace.army.mil             ***' newline...
%     '***********************************************************'])
% 
% disp([newline '*** Step 1: Processing input arguments '])
% 
% % Turn off all warnings
% warning('off','all');

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

% Set up AEFs for full HC; in log10 scale (for plotting), from 10^1 to 10^-6
d=1/20; v=10.^(1:-d:0)'; HC_plt_x=v; x=10;
for i=1:6, HC_plt_x=[HC_plt_x; v(2:end)/x]; x=x*10; end %#ok<AGROW>
HC_plt_x=flipud(HC_plt_x);

% Default responses for HC summary table HC_plt_rsp_x
if isempty(HC_plt_rsp_y)
    d=(20-0.01)/(length(HC_plt_x)-1); HC_plt_rsp_y=(0.01:d:20)';    
elseif isrow(HC_plt_rsp_y)
    HC_plt_rsp_y = sort(HC_plt_rsp_y)';
    if sum(HC_plt_rsp_y<=0)~=0
        error('Input HC_plt_rsp_y must be specified as a numerical vector of positive values')
    end
end

% Default responses for HC summary table HC_tbl_rsp_x
if isempty(HC_tbl_rsp_y)
    d=(20-0.01)/(length(HC_tbl_x)-1); HC_tbl_rsp_y=(0.01:d:20)';    
elseif isrow(HC_tbl_rsp_y)
    HC_tbl_rsp_y = sort(HC_tbl_rsp_y)';
    if sum(HC_tbl_rsp_y<=0)~=0
        error('Input HC_tbl_rsp_y must be specified as a numerical vector of positive values')
    end
end

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
% JAM changed following line on 1/26/23
%if U_a<0||~isscalar(U_a)||isempty(U_a)||isinf(U_a),error('Input U_a must be a positive scalar.');end
if U_a<0,error('Input U_a must be a positive scalar.');end
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
        
%         disp(['*** Step 2: Partition of input data not necessary' newline...
%             '****** User entered less than 5000 virtual gages'])

        % Perform integration
%         disp('*** Step 3: Performing integration')
        [JPM_output,Removed_vg] = StormSim_JPM_Integrate(Resp,ProbMass,vg_id,U_a,U_r,U_tide,U_tide_app,U_tide_type,uncert_treatment,integrate_Method,SLC,dscrtGauss,HC_plt_rsp_y,HC_tbl_rsp_y,HC_tbl_x,z,ind_aep,id_PCT,apply_Parallel,HC_plt_x);
        
        % Change AEF to AEP?
        if ind_aep
            HC_plt_x=aef2aep(HC_plt_x);
        end

        % Plot hazard curves
        if plot_results
%             disp('****** Plotting hazard curves')
            StormSim_JPM_Plot(JPM_output,vg_id,path_out,yaxis_label,yaxis_limits,integrate_Method,prc,ind_aep,a,HC_plt_x)
        end
        
        % Store output
%         disp(['*** Step 4: Saving results here: ',path_out])
        save([path_out,'StormSim_JPM_output.mat'],'JPM_output','HC_plt_x','HC_tbl_x','HC_tbl_rsp_y','Removed_vg','-v7.3')
        
    case 0
        
        % Set path directory to stored partitioned "Response" files
        pth_inp = 'JPM_input_partitioned';
        if ~exist(pth_inp,'dir'),mkdir(pth_inp);end; pth_inp=['.\',pth_inp,'\'];
        
        % Display status
%         disp(['*** Step 2: Partitioning input data ' newline...
%             '****** User entered more than 5000 virtual gages'])
        
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
%         disp([' ****** Finished. Partitioned input files stored in ' pth_inp])
        
        % Delete original inputs from workspace
        clearvars Resp ProbMass U_tide vg_id;
        
        % Do evaluation, one partition at a time
%         disp('*** Step 3: Performing integration')
        HC_plt_x2=HC_plt_x;
        for i = 1:Np %partition loop
            
            % Load files
            load([pth_inp,'InputPartition_',int2str(i),'.mat'],'Resp_p','ProbMass_p','sp_id_p','U_tide_p')
            
            % Display status
%             disp(['****** Working partition file ',int2str(i),': virtual gauges ',int2str(sp_id_p(1)),' - ',int2str(sp_id_p(end))]) 
            
            % Perform integration
            [JPM_output,Removed_vg] = StormSim_JPM_Integrate(Resp_p,ProbMass_p,sp_id_p,U_a,U_r,U_tide_p,U_tide_app,U_tide_type,uncert_treatment,integrate_Method,SLC,dscrtGauss,HC_tbl_rsp_y,HC_tbl_x,z,ind_aep,id_PCT,apply_Parallel,HC_plt_x2);
            
            % Change AEF to AEP?
            if ind_aep
                HC_plt_x=aef2aep(HC_plt_x2);
            end

            % Plot hazard curves
            if plot_results
%                 disp('****** Plotting hazard curves')
                StormSim_JPM_Plot(JPM_output,sp_id_p,path_out,yaxis_label,yaxis_limits,integrate_Method,prc,ind_aep,a,HC_plt_x)
            end

            % Export output per partition
            save([path_out,'StormSim_JPM_output_Part_',int2str(i),'.mat'],'JPM_output','HC_plt_x','HC_tbl_x','HC_tbl_rsp_y','Removed_vg','-v7.3')
        end
%         disp(['*** Step 4: Results stored here: ',path_out])
end
[~,id_act]=hasPCT;if id_act==0,delete(gcp);end
% disp('*** Evaluation finished.')
% disp('*** StormSim-JPM Tool terminated.')
end

%%
function [in] = aef2aep(in)
in = (exp(in)-1)./exp(in);
end

%% hasPCT.m
%{
By: E. Ramos
Description: Function to determine if MATLAB has the Parallel Computing
   Toolbox (PCT) and if a pool is active.
   Inputs: None.
   Outputs: id_PCT = 1 when the PCT is found.
            id_PCT = 0 otherwise.
            id_act = 1 when the parallel pool is not active.
            id_act = 0 otherwise
History of revisions:
20201201-ERS: created.
20210113-ERS: now initially assuming id_act=1, to avoid evaluating gcp()
    when id_PCT=0.
%}
function [id_PCT,id_act]=hasPCT()
ver2=ver;
ver2={ver2.Name};
id_PCT=sum(ver2=="Parallel Computing Toolbox");
id_act=1;%initially assume pool is inactive
if id_PCT
    id_act=isempty(gcp('nocreate'));
end
end

%% StormSim_JPM_Integrate.m
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
 - SLC: Magnitude of the sea level change associated to the responses (without steric adjustments);
      specified as a positive scalar. Otherwise, leave empty.
 - ind_aep: indicator for expressing the hazard as AEF or AEP. Use 1 for
      AEP, 0 for AEF. Example: ind_aep = 1;
 - dscrtGauss: Gaussian distribution discretized with 27 values, used for
      distributing the uncertainty.
 - HC_tbl_rsp_y: predefined response values used to summarize the HC;
      specified as a vector.
 - HC_tbl_x: predefined AEP values used to summarize the HC; specified as
      a vector of positive values. The script will convert it to AEF when
      ind_aep = 0.
 - z: Normal Z-scores corresponding to the values in prc. Used to compute
      the CLs.
OUTPUT ARGUMENTS:
 - JPM_output: full HC per virtual gage; as a structure variable with the following fields:
     vg_ID = virtual gauge ID number specified by the user
     x = predefined vector of probabilities used to plot the HC. The type is:
        > AEP when ind_aep = 1
        > AEF when ind_aep = 0
     y = best estimate or mean full HC
     y_perc = numerical array with the following 4 columns
        col(01): values of 2% percentile or 1st percentage of input prc
        col(02): values of 16% percentile or 2nd percentage of input prc
        col(03): values of 84% percentile or 3rd percentage of input prc
        col(04): values of 98% percentile or 4th percentage of input prc
 - HC_tbl_y: summarized HC, corresponding to the values in HC_tbl_x.
 - HC_plt_rsp_x: hazard values interpolated from the HC, that correspond
         to the responses in HC_plt_rsp_y.
 - HC_tbl_rsp_x: Lower resolution version of "HC_plt_rsp_x" based on the
        predefined responses in HC_tbl_rsp_y.
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
20210402-ERS: organized script; express hazards as AEF or AEP; changed the combined
    uncertainty equation; generalized the uncertainty treatment to be
    compatible with existing CHS studies.
20210601-ERS: corrected bugs. Added capability to run in parallel.
20210831-ERS: duplicates now removed from x values when interpolating HC plot in the integration script.
20230223-LAA: Edited to produce rsp_x variables at the same resolution as the HC_tbl
    and the HC_plt variables. Added statements to NaN rsp_x less than 1e-6.
***************  ALPHA  VERSION  **  FOR INTERNAL TESTING ONLY  ***********
%}
function [JPM_output,Removed_vg] = StormSim_JPM_Integrate(Resp,ProbMass,vg_id,U_a,U_r,U_tide,U_tide_app,U_tide_type,uncert_treatment,integrate_Method,SLC,dscrtGauss,HC_plt_rsp_y,HC_tbl_rsp_y,HC_tbl_x,z,ind_aep,id_PCT,apply_Parallel,HC_plt_x)

%% Define needed quantities

% Total of virtual gauges and events (e.g., storms)
[Ntc,Nvg] = size(Resp);
%     Nstrm = No. of storms
%     Nvg = No. of virtual gauges

dscrt=sort(repmat(dscrtGauss,Ntc,1));pm_sz=size(ProbMass,1);
if integrate_Method==2||integrate_Method==3
    Ndscrt=length(dscrtGauss);ProbMass=repmat(ProbMass./Ndscrt,Ndscrt,1);
    pm_sz=size(ProbMass,1);Resp=repmat(Resp,Ndscrt,1);
    U_tide=repmat(U_tide,Ndscrt,1);[Ntc,Nvg]=size(Resp);
end

% Remove sea level change (without steric adjustment) from response data
Resp = Resp - SLC;

%% Application of Uncertainty to response per JPM approach
switch integrate_Method % integration method
    
    case 1 %'PCHA ATCS'
        switch U_tide_app
            case 0 %No tide unc; abs and rel unc applied to percentiles
                switch uncert_treatment
                    case 'absolute'
                        CL_unc =@(y,U_t) y + z.*U_a.*ones(length(y),1);
                    case 'relative'
                        CL_unc =@(y,U_t) y + z.*y.*U_r;
                    case 'combined'
%                         CL_unc =@(y,U_t) y + z.*(U_a.*ones(length(y),1) + y.*U_r)/2;
                        CL_unc =@(y,U_t) y + z.*1./sqrt(1/U_a^2 + 1./(y.*U_r).^2);
                end
                randomNorm = 0; %dummy
                U_tide_r = zeros(pm_sz,Nvg); %dummy
            case 1 %Tide, abs and rel unc applied to percentiles; tide unc as SD
                switch uncert_treatment
                    case 'absolute'
                        CL_unc =@(y,U_t) y + z.*sqrt(U_a.^2 + U_t.^2);%.*ones(length(y),1);
                    case 'relative'
                        CL_unc =@(y,U_t) y + z.*y.*sqrt((y.*U_r).^2 + U_t.^2);
                    case 'combined'
%                         CL_unc =@(y,U_t) y + z.*sqrt(((U_a + y.*U_r)/2).^2 + U_t.^2);
                        CL_unc =@(y,U_t) y + z.*1./sqrt(1/U_a^2 + 1./(y.*U_r).^2 + 1./U_t.^2);
                end
                randomNorm = 0; %dummy
                U_tide_r = zeros(pm_sz,Nvg); %dummy
            case 2 %Tide unc applied to response randomly distributed; abs and rel unc applied to percentiles
                if strcmp(U_tide_type,'SD')
                    rng('default'); randomNorm = randn(pm_sz,1);
                    U_tide_r = U_tide;%repmat(U_tide,Ntc,1);
                elseif strcmp(U_tide_type,'Skew')
                    randomNorm=1;
                    U_tide_r = U_tide; %dummy
                else %no tide unc
                    randomNorm=0;
                    U_tide_r = zeros(pm_sz,Nvg); %dummy
                end
                switch uncert_treatment
                    case 'absolute'
                        CL_unc =@(y,U_t) y + z.*U_a.*ones(length(y),1);
                    case 'relative'
                        CL_unc =@(y,U_t) y + z.*y.*U_r;
                    case 'combined'
%                         CL_unc =@(y,U_t) y + z.*(U_a.*ones(length(y),1) + y.*U_r)/2;
                        CL_unc =@(y,U_t) y + z.*1./sqrt(1/U_a^2 + 1./(y.*U_r).^2);
                end
        end
        
    case 2 %'PCHA Standard'
        
        % NOTA: La Intencion: que el usuario indique si aplicar partiones o no
        %      Default por ahora: se aplican las particiones a la incertidumbre
        
        %partition of the absolute unc
        p1_a = 0.1; %same units as response array
        if U_a^2 >= p1_a^2
            U_a = sqrt(U_a^2-p1_a^2);
        end
        
        %partition of the relative unc
        p1_r = .1; %dimensionless fraction
        if U_r^2 >= p1_r^2
            U_r = sqrt(U_r^2-p1_r^2);
        end
        
        % Application of first partition to response
        Resp = Resp + dscrt.*(p1_a + Resp.*p1_r)/2;
        
        % Apply uncertainties
        switch U_tide_app
            case 0 %No tide unc; abs and rel unc applied to percentiles
                switch uncert_treatment
                    case 'absolute'
                        CL_unc =@(y,U_t) y + z.*U_a.*ones(length(y),1);
                    case 'relative'
                        CL_unc =@(y,U_t) y + z.*y.*U_r;
                    case 'combined'
%                         CL_unc =@(y,U_t) y + z.*(U_a.*ones(length(y),1) + y.*U_r)/2;
                        CL_unc =@(y,U_t) y + z.*1./sqrt(1/U_a^2 + 1./(y.*U_r).^2);
                end
                randomNorm = 0; %dummy
                U_tide_r = zeros(Ntc,Nvg); %dummy
            case 1 %Tide, abs and rel unc applied to percentiles; tide unc as SD
                switch uncert_treatment
                    case 'absolute'
                        CL_unc =@(y,U_t) y + z.*sqrt(U_a.^2 + U_t.^2).*ones(length(y),1);
                    case 'relative'
                        CL_unc =@(y,U_t) y + z.*y.*sqrt((y.*U_r).^2 + U_t.^2);
                    case 'combined'
%                         CL_unc =@(y,U_t) y + z.*sqrt(((U_a + y.*U_r)/2).^2 + U_t.^2);
                        CL_unc =@(y,U_t) y + z.*1./sqrt(1/U_a^2 + 1./(y.*U_r).^2 + 1./U_t.^2);
                end
                randomNorm = 0; %dummy
                U_tide_r = zeros(Ntc,Nvg); %dummy
            case 2 %Unc tide applied to response randomly distributed; abs and rel unc applied to percentiles
                if strcmp(U_tide_type,'SD')
                    randomNorm = dscrt;
                    U_tide_r = U_tide;%repmat(U_tide,Ntc,1);
                elseif strcmp(U_tide_type,'Skew')
                    randomNorm=1;
                    U_tide_r = U_tide; %dummy
                else %no tide unc
                    randomNorm=0;
                    U_tide_r = zeros(Ntc,Nvg); %dummy
                end
                switch uncert_treatment
                    case 'absolute'
                        CL_unc =@(y,U_t) y + z.*U_a.*ones(length(y),1);
                    case 'relative'
                        CL_unc =@(y,U_t) y + z.*y.*U_r;
                    case 'combined'
%                         CL_unc =@(y,U_t) y + z.*(U_a.*ones(length(y),1) + y.*U_r)/2;
                        CL_unc =@(y,U_t) y + z.*1./sqrt(1/U_a^2 + 1./(y.*U_r).^2);
                end
        end
        
    case 3 %'JPM Standard'
        switch U_tide_app
            case 0
                switch uncert_treatment %No tide unc; abs and rel unc applied to response
                    case 'absolute'
                        Resp = Resp + dscrt.*U_a;
                    case 'relative'
                        Resp = Resp + dscrt.*Resp.*U_r;
                    case 'combined'
%                         Resp = Resp + dscrt.*(U_a + Resp.*U_r)/2;
                        Resp = Resp + dscrt.*1./sqrt(1/U_a^2 + 1./(Resp.*U_r).^2);
                end
            case 1 %Tide, abs and rel unc applied to response; tide unc as SD
                switch uncert_treatment
                    case 'absolute'
                        Resp = Resp + dscrt.*sqrt(U_a.^2 + U_tide.^2);
                    case 'relative'
                        Resp = Resp + dscrt.*sqrt((Resp.*U_r).^2 + U_tide.^2);
                    case 'combined'
%                         Resp = Resp + dscrt.*sqrt(((U_a + Resp.*U_r)/2).^2 + U_tide.^2);
                        Resp = Resp + dscrt.*1./sqrt(1/U_a^2 + 1./(Resp.*U_r).^2 + 1./U_tide.^2);
                end
            case 2 %First apply unc tide to response; then apply abs and rel unc to response
                if strcmp(U_tide_type,'SD')
                    Resp = Resp + dscrt.*U_tide;
                elseif strcmp(U_tide_type,'Skew')
                    Resp = Resp + U_tide;
                end
                
                switch uncert_treatment
                    case 'absolute'
                        Resp = Resp + dscrt.*U_a;
                    case 'relative'
                        Resp = Resp + dscrt.*Resp.*U_r;
                    case 'combined'
%                     Resp = Resp(:,N) + dscrt.*(U_a + Resp(:,N).*U_r)/2;
                        Resp = Resp + dscrt.*1./sqrt(1/U_a^2 + 1./(Resp.*U_r).^2);
                end
        end
        randomNorm = 0;%ones(length(Prob),1); %dummy
        U_tide_r = zeros(pm_sz,Nvg); %dummy
        CL_unc =@(y,U_t) []; %dummy function
end


%% Add uncertainty (or skews) and sea level change to responses
Resp = Resp + randomNorm.*U_tide_r + SLC;

%% Filter feasible virtual gauges
id= ~isnan(Resp)&Resp>0;
% id2=find(sum(id,1)>=size(Resp,1)*0.05);
id2=1:size(Resp,2); %********** HARDCODED for the S2G study only
% id3=find(sum(id,1)<size(Resp,1)*0.05);
id=id(:,id2);Resp=Resp(:,id2);ProbMass=ProbMass(:,id2);U_tide=U_tide(:,id2);

%% Select dataset to evaluate
Removed_vg='';
% if ~isempty(id3)
%     id3 = cellstr(int2str(id3'));
%     Removed_vg = {'The following virtual gauges were excluded from the evaluation, since:';...
%         '- the number of response values/events in the input dataset is less than 0.05 times the sample size'};
%     Removed_vg = [Removed_vg; id3];
% end


%% preallocate 
JPM_output = struct('vg_id',strsplit(int2str(vg_id(id2)),' '));
JPM_output(1).HC_plt_y=[];JPM_output(1).HC_tbl_y=[];JPM_output(1).HC_plt_rsp_x=[];


%% Perform Integration
if ~isempty(id2)
    switch id_PCT && integrate_Method~=1 && apply_Parallel
        case 0            
            for N = 1:length(id2) %Virtual Gauge loop
               
                %Integrate
                index_n = find(id(:,N));
                [y,I]=sort(Resp(index_n,N),'descend');%sort response for non-dry storms; 
                   % y: Response, thresholds for defining hazard curve
                x = cumsum(ProbMass(index_n(I),N)); %HC_Prob: exceedance of threshold rates
                x(x==0)=1e-16;
                
                % Sort in ascending order
                dm = sortrows([x y],1,'ascend');                
                x=dm(:,1);y=dm(:,2);
                
                % remove duplicates from x values
                [~,ia,~]=unique(x,'stable');y=y(ia);x=x(ia);

                % Compute percentiles
                resp_perc = CL_unc(y,U_tide(:,N));
                
                % merge best estimate with percentiles
                y = [y resp_perc]; %#ok<AGROW>
                
                % Interpolate AEF curve for plot
                Lx=log(x);
                y_plt = interp1(Lx,y,log(HC_plt_x));
                
                % Interpolation to create hazard tables
                n=size(y,2);
                HC_plt_rsp_x=NaN(length(HC_plt_rsp_y),n);
                HC_tbl_rsp_x=NaN(length(HC_tbl_rsp_y),n);
                HC_tbl_y = interp1(Lx,y,log(HC_tbl_x),'linear','extrap');
                for NN=1:n
                    [~,ia,~]=unique(y(:,NN),'stable');y2=y(ia,NN);Lx2=Lx(ia);
                    HC_plt_rsp_x(:,NN)=exp(interp1(y2,Lx2,HC_plt_rsp_y,'linear','extrap'));
                    HC_tbl_rsp_x(:,NN)=exp(interp1(y2,Lx2,HC_tbl_rsp_y,'linear','extrap'));
                end
                
                %Change negatives to NaN
                HC_tbl_y(HC_tbl_y<1e-6)=NaN;
                HC_plt_rsp_x(HC_plt_rsp_x<1e-6)=NaN;
                HC_tbl_rsp_x(HC_tbl_rsp_x<1e-6)=NaN;
                y_plt(y_plt<0)=NaN;

                % Convert to AEP?
                if ind_aep
                    HC_plt_rsp_x=aef2aep(HC_plt_rsp_x);
                    HC_tbl_rsp_x=aef2aep(HC_tbl_rsp_x);
                end
                
                % Store results
                JPM_output(N).HC_plt_y=y_plt;
                JPM_output(N).HC_tbl_y=HC_tbl_y;
                JPM_output(N).HC_plt_rsp_x=HC_plt_rsp_x;
                JPM_output(N).HC_tbl_rsp_x=HC_tbl_rsp_x;
            end
        case 1
            Resp = parallel.pool.Constant(Resp);
            ProbMass = parallel.pool.Constant(ProbMass);
            
            parfor N = 1:length(id2) %Virtual Gauge loop
                    
                %Integrate
                index_n = find(id(:,N));
                [y,I]=sort(Resp.Value(index_n,N),'descend');%sort response for non-dry storms
                   % y: Response, thresholds for defining hazard curve
                x = cumsum(ProbMass.Value(index_n(I),N)); %x: exceedance of threshold rates
                x(x==0)=1e-16;
                
                % Sort in ascending order
                dm = sortrows([x y],1,'ascend');
                x=dm(:,1);y=dm(:,2);
                
                % remove duplicates from x values
                [~,ia,~]=unique(x,'stable');y=y(ia);x=x(ia);

                % Compute percentiles
                resp_perc = CL_unc(y,U_tide(:,N)); %#ok<PFBNS>

                % merge best estimate with percentiles
                y = [y resp_perc]; 

                % Interpolate AEF curve for plot
                Lx=log(x);
                y_plt = interp1(Lx,y,log(HC_plt_x));
                                
                % Interpolation to create hazard tables
                n=size(y,2);
                HC_plt_rsp_x=NaN(length(HC_plt_rsp_y),n);
                HC_tbl_rsp_x=NaN(length(HC_tbl_rsp_y),n);
                HC_tbl_y = interp1(Lx,y,log(HC_tbl_x),'linear','extrap');
                for NN=1:n           
                    [~,ia,~]=unique(y(:,NN),'stable');y2=y(ia,NN);Lx2=Lx(ia);
                    HC_plt_rsp_x(:,NN)=exp(interp1(y2,Lx2,HC_plt_rsp_y,'linear','extrap'));
                    HC_tbl_rsp_x(:,NN)=exp(interp1(y2,Lx2,HC_tbl_rsp_y,'linear','extrap'));
                end

                %Change negatives to NaN
                HC_tbl_y(HC_tbl_y<1e-6)=NaN;
                HC_plt_rsp_x(HC_plt_rsp_x<1e-6)=NaN;
                HC_tbl_rsp_x(HC_tbl_rsp_x<1e-6)=NaN;
                y_plt(y_plt<0)=NaN;

                % Convert to AEP?
                if ind_aep
                    HC_plt_rsp_x=aef2aep(HC_plt_rsp_x);
                    HC_tbl_rsp_x=aef2aep(HC_tbl_rsp_x);
                end
                
                % Store results
                JPM_output(N).HC_plt_y=y_plt;
                JPM_output(N).HC_tbl_y=HC_tbl_y;
                JPM_output(N).HC_plt_rsp_x=HC_plt_rsp_x;                
                JPM_output(N).HC_tbl_rsp_x=HC_tbl_rsp_x; 
            end
    end
end
end

%% StormSim_JPM_Plot.m
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
   StormSim-JPM-Plot (Plot Integration)
DESCRIPTION:
   This script plots the response hazard curves developed with the Joint
   Probability Method (JPM) integration script StormSim_JPM.m
INPUT ARGUMENTS:
 - JPM_output: output from StormSimJPM.m . Full hazard curves per virtual gauge;
      as a structure variable with fields:
         sp_ID: savepoint ID number
         x: AEP values
         y: response hazard values
 - sp_id: ID number of the savepoints; specified as a vector of positive
      integers. Example: sp_id = [1 2 3 4 5 10 100 1500];
 - path_out: path to output folder; specified as a character string.
      Leave empty to apply default path in current folder: '.\HC_plots\'
 - yaxis_label: y-axis label for response variable; specified as a character
      vector. Example: 'Still Water Level, SWL (m)'
 - y_ax_Lims: y-axis limits of the plot; specified as a vector. Leave
      empty [] or use this format:
      Col(01): lower limit
      Col(02): upper limit
 - integrate_Method: JPM method to apply; specified as a character vector. Current options
      are 'JPM Standard', 'PCHA ATCS', or 'PCHA Standard'
 - prc: confidence level percentage; specified as a scalar or vector. Leave
      empty [] to apply default values: [2 15 84 98].
OUTPUT ARGUMENTS:
   None. The plot is automatically stored in the output path.
AUTHORS:
   Norberto C. Nadal-Caraballo, PhD (NCNC)
   Efrain Ramos-Santiago (ERS)
CONTRIBUTORS:
   Alexandros A. Taflanidis, PhD (AAT)
   Victor M. Gonzalez, PE (VMG)
HISTORY OF REVISIONS:
20200904-ERS: revised.
20201011-ERS: updated.
***************  ALPHA  VERSION  ***************  FOR TESTING  ************
%}
function [] = StormSim_JPM_Plot(JPM_output,sp_id,path_out,yaxis_label,y_ax_Lims,integrate_Method,prc,ind_aep,a,HC_plt_x)

%% Other parameters
dm_met={'PCHA ATCS','PCHA Standard','JPM Standard'};
str=[dm_met{integrate_Method},' Method'];N=length(JPM_output);cs={'r-.','b--','b--','r-.'};
if length(prc)<4,cs={'r-.','b-.','m-.'};end;prc=round(prc);

% Axes limits
if ind_aep
    XLim=[1e-4 1];XTick=[1e-4 1e-3 1e-2 1e-1 1];
else
    XLim=[1e-4 10];XTick=[1e-4 1e-3 1e-2 1e-1 1 10];
end

% Axes labels
if ind_aep
    XLab = 'Annual Exceedance Probability';
else
    XLab = 'Annual Exceedance Frequency (yr^{-1})';
end

%% Plot hazard curves
if integrate_Method==3 %'JPM Standard'
    for i=1:N
        str2 = int2str(sp_id(i));
        if ~isempty(JPM_output(i).HC_plt_y)
            figure('Color',[1 1 1],'visible','off')
            axes('XScale','log','XGrid','on','XMinorTick','on','YGrid','on','YMinorTick','on','FontSize',12)
            xticks(XTick); xlim(XLim);
            set(gca,'XDir','reverse')
            if ~isempty(y_ax_Lims)
                ylim([min(yaxis_limits) max(yaxis_limits)]);
            end
            hold on
            plot(HC_plt_x,JPM_output(i).HC_plt_y,'b','LineWidth',2);
            title({'Coastal Hazards System | StormSim - JPM';...
                str;...
                ['(Virtual Gauge ',str2,')']},'FontSize',12);
            xlabel(XLab,'FontSize',12);
            ylabel({yaxis_label},'FontSize',12);
            hold off
            fname=[path_out,'HC_vg_',str2,'.png'];
            switch a
                case 0
                    exportgraphics(gcf,fname,'Resolution',150)
                case 1
                    saveas(gcf,fname,'png')
            end
        end
    end
else %'PCHA ATCS' or 'PCHA Standard'
    for i=1:N
        str2 = int2str(sp_id(i));
        if ~isempty(JPM_output(i).HC_plt_y)
            
            % Take percentiles
            y = JPM_output(i).HC_plt_y(:,1);
            Boot_plt = JPM_output(i).HC_plt_y(:,2:end);
            
            figure('Color',[1 1 1],'visible','off')
            axes('XScale','log','XGrid','on','XMinorTick','on','YGrid','on','YMinorTick','on','FontSize',12)
            xticks(XTick); xlim(XLim);
            set(gca,'XDir','reverse')
            if ~isempty(y_ax_Lims)
                ylim([y_ax_Lims(1) y_ax_Lims(2)]);
            end
            hold on
            
            % Process the percentiles
            pObj=struct('o',[],'n',[],'L','');
            for j=1:length(prc)
                pObj(j).o = plot(HC_plt_x,Boot_plt(:,j),cs{j},'LineWidth',2);
                pObj(j).n = prc(j);
                pObj(j).L = {['CL',int2str(prc(j)),'%']};
            end
            pObj_t = struct2table(pObj);
            pObj_t = sortrows(pObj_t,'n','descend'); % sort the table by 'n'
            
            % Take percentiles
            t1 = pObj_t(pObj_t.n>50,:); t1 = table2struct(t1); %above the mean
            t2 = pObj_t(pObj_t.n<50,:); t2 = table2struct(t2); %below the mean
            
            % Mean
            h1 = plot(HC_plt_x,y,'k','LineWidth',2);
            title({'Coastal Hazards System | StormSim - JPM'; str;...
                ['(Virtual Gauge ',str2,')']},'FontSize',12);
            xlabel(XLab,'FontSize',12);
            ylabel({yaxis_label},'FontSize',12);
            legend([[t1.o],h1,[t2.o]],{t1.L,'Mean',t2.L},'Location','NorthWest','FontSize',12);
            
            hold off
            fname=[path_out,'HC_vg_',str2,'.png'];
            switch a
                case 0
                    exportgraphics(gcf,fname,'Resolution',150)
                case 1
                    saveas(gcf,fname,'png')
            end
        end
    end
end
end