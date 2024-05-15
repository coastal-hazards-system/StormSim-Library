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

 - HC_tbl_rsp_x: hazard values interpolated from the HC, that correspond
         to the responses in HC_tbl_rsp_y.

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
20231207-LAA: duplicates now removed from y values when interpolating HC plot in the integration script.

***************  ALPHA  VERSION  **  FOR INTERNAL TESTING ONLY  ***********
%}
function [JPM_output,Removed_vg] = StormSim_JPM_Integrate(Resp,ProbMass,vg_id,U_a,U_r,U_tide,U_tide_app,U_tide_type,uncert_treatment,integrate_Method,SLC,dscrtGauss,HC_tbl_rsp_y,HC_tbl_x,z,ind_aep,id_PCT,apply_Parallel,HC_plt_x)

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
id2=find(sum(id,1)>=size(Resp,1)*0.05);
id3=find(sum(id,1)<size(Resp,1)*0.05);
id=id(:,id2);Resp=Resp(:,id2);ProbMass=ProbMass(:,id2);U_tide=U_tide(:,id2);

%% Select dataset to evaluate
Removed_vg='';
if ~isempty(id3)
    id3 = cellstr(int2str(id3'));
    Removed_vg = {'The following virtual gauges were excluded from the evaluation, since:';...
        '- the number of response values/events in the input dataset is less than 0.05 times the sample size'};
    Removed_vg = [Removed_vg; id3];
end


%% preallocate 
JPM_output = struct('vg_id',strsplit(int2str(vg_id(id2)),' '));
JPM_output(1).HC_plt_y=[];JPM_output(1).HC_tbl_y=[];JPM_output(1).HC_tbl_rsp_x=[];


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
                
                x=log(x);
                % remove duplicates from x values
                [~,ia,~]=unique(x,'stable');y=y(ia);x=x(ia);

                %%% remove duplicates from y values - LAA 2023/12/07
                [~,iy,~]=unique(y,'stable');y=y(iy);x=x(iy);
                %%%

                % Compute percentiles
                resp_perc = CL_unc(y,U_tide(:,N));
                
                % merge best estimate with percentiles
                y = [y resp_perc]; %#ok<AGROW>
                
                % Interpolate AEF curve for plot
                Lx=x;
                y_plt = interp1(Lx,y,log(HC_plt_x));
                
                % Interpolation to create hazard tables
                n=size(y,2);
                HC_tbl_rsp_x=NaN(length(HC_tbl_rsp_y),n);
                HC_tbl_y = interp1(Lx,y,log(HC_tbl_x),'linear','extrap');
                for NN=1:n
                    [~,ia,~]=unique(y(:,NN),'stable');y2=y(ia,NN);Lx2=Lx(ia);
                    HC_tbl_rsp_x(:,NN)=exp(interp1(y2,Lx2,HC_tbl_rsp_y,'linear','extrap'));
                end
                
                %Change negatives to NaN
                HC_tbl_y(HC_tbl_y<0)=NaN;
                HC_tbl_rsp_x(HC_tbl_rsp_x<0)=NaN;
                y_plt(y_plt<0)=NaN;

                % Convert to AEP?
                if ind_aep
                    HC_tbl_rsp_x=aef2aep(HC_tbl_rsp_x);
                end
                
                % Store results
                JPM_output(N).HC_plt_y=y_plt;
                JPM_output(N).HC_tbl_y=HC_tbl_y;
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
                
                x=log(x);
                % remove duplicates from x values
                [~,ia,~]=unique(x,'stable');y=y(ia);x=x(ia);

                %%% remove duplicates from y values - LAA 2023/12/07
                [~,iy,~]=unique(y,'stable');y=y(iy);x=x(iy);
                %%%

                % Compute percentiles
                resp_perc = CL_unc(y,U_tide(:,N)); %#ok<PFBNS>

                % merge best estimate with percentiles
                y = [y resp_perc]; 

                % Interpolate AEF curve for plot
                Lx=x;
                y_plt = interp1(Lx,y,log(HC_plt_x));
                                
                % Interpolation to create hazard tables
                n=size(y,2);
                HC_tbl_rsp_x=NaN(length(HC_tbl_rsp_y),n);
                HC_tbl_y = interp1(Lx,y,log(HC_tbl_x),'linear','extrap');
                for NN=1:n           
                    [~,ia,~]=unique(y(:,NN),'stable');y2=y(ia,NN);Lx2=Lx(ia);
                    HC_tbl_rsp_x(:,NN)=exp(interp1(y2,Lx2,HC_tbl_rsp_y,'linear','extrap'));
                end

                %Change negatives to NaN
                HC_tbl_y(HC_tbl_y<0)=NaN;
                HC_tbl_rsp_x(HC_tbl_rsp_x<0)=NaN;
                y_plt(y_plt<0)=NaN;

                % Convert to AEP?
                if ind_aep
                    HC_tbl_rsp_x=aef2aep(HC_tbl_rsp_x);
                end
                
                % Store results
                JPM_output(N).HC_plt_y=y_plt;
                JPM_output(N).HC_tbl_y=HC_tbl_y;
                JPM_output(N).HC_tbl_rsp_x=HC_tbl_rsp_x;                
            end
    end
%     % Convert to AEP?
%     if ind_aep
%         HC_plt_x=aef2aep(HC_plt_x);
%     end
%     JPM_output(1).HC_plt_x=HC_plt_x;
end
end