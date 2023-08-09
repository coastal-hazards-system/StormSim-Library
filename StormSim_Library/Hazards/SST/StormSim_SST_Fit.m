%% StormSim_SST_Fit.m
%{
SOFTWARE NAME:
    StormSim-SST-Fit (Statistics)

DESCRIPTION:
   This script performs the Stochastic Simulation Technique (SST) to
   generate the hazard curve (HC) of a Peaks-Over-Threshold (POT) sample.
   The HC can be expressed in terms of annual exceedance frequencies (AEF)
   or equivalent annual exceedance probabilities (AEP).

INPUT ARGUMENTS:
  - POT_samp: POT values (no timestamps) or second column from the first
      output argument of StormSim_POT.m; specified as a column vector.
  - Nyrs: record length in years; specified as a positive scalar.
  - HC_plt_x: predefined AEF values used to plot the HC; specified as
      a vector of positive values. The script will convert it to AEP when
      use_AEP = 1.
  - HC_tbl_x: predefined AEP values used to summarize the HC; specified as
      a vector of positive values. The script will convert it to AEF when
      use_AEP = 0.
  - HC_tbl_rsp_y: predefined response values used to summarize the HC;
      specified as a vector.
  - prc: percentage values for computing the percentiles; specified as a
      scalar or vector of positive values. Leave empty [] to apply default
      values 2.28%, 15.87%, 84.13%, 97.72%. User can enter 1 to 4 values.
      Example: prc = [2 16 84 98];
  - use_AEP: indicator for expressing the hazard as AEF or AEP. Use 1 for
      AEP, 0 for AEF. Example: use_AEP = 1;
  - GPD_TH_crit: indicator for specifying the GPD threshold option of the
      Mean Residual Life (MRL) selection process; use as follows:
       0 to evaluate all thresholds identified by the MRL method (up to 3)
       1 to only evaluate the MRL threshold selected by the lambda criterion
       2 to only evaluate the MRL threshold selected by the minimum weight criterion
      Example: GPD_TH_crit = 0;
  - TH_otlr: 'ThresholdFactor' for the fillsoutlier function used to modify
      the GPD shape parameter collection resulting from the bootstrap process.
      Specified as a nonnegative scalar. Leave empty [] to apply default value: 3.
      Refer to MATLAB Documentation for 'fillsoutlier', 'ThresholdFactor' option.
      Example: TH_otlr = 3;
  - ind_Skew: indicator for computing/adding skew tides to the storm surge.
      This applies when the input is a storm surge dataset with/without SLC.
      Use as follows:
       1 for the tool to compute and add the skew tides
       0 otherwise
      Example: ind_Skew = 1;
  - POT_samp2: POT values (no timestamps) with tides, to replace POT_samp
      without tides when evaluating storm surge with skew tides; specified
      as a column vector. Cannot be empty when ind_Skew = 1.
  - SLC: magnitude of the sea level change implicit in the storm surge input
      dataset; specified as a positive scalar. Must have same units as the
      input dataset. Example: SLC = 1.8;
  - gprMdl: Gaussian process regression (GPR) model created with the MATLAB
function 'fitrgp'; specified as an object. Refer to MATLAB
      Documentation for 'fitrgp'. Train the GPR with storm surge as a
      predictor and skew tides as the response. Leave empty when ind_Skew = 0.
  - staID: gauge station information; specified as a cell array with format:
      Col(01): gauge station ID number; as a character vector. Example: '8770570'
      Col(02): station name (OPTIONAL); as a character vector. Example: 'Sabine Pass North TX'
  - yaxis_Label: parameter name/units/datum for label of the plot y-axis;
      specified as a character vector.
      > When ind_Skew = 1: Set yaxis_Label = 'Water level' with associated units
        and datum. Example: 'Still Water Level (m, MSL)'
  - path_out: path to output folder; specified as a character vector. Leave
      empty [] to apply default: '.\SST_output\'
  - yaxis_Limits: lower and upper limits for the plot y-axis; specified as a
      vector. Leave empty [] otherwise. Example: yaxis_Limits = [0 10];
  - apply_GPD_to_SS: indicates if the hazard of small POT samples should evaluated
      with either the empirical or the GPD. A small sample has a sample size < 20 events
      and a record length < 20 years. Use 1 for GPD, 0 for empirical. Example: apply_GPD_to_SS = 1;

OUTPUT ARGUMENTS:
  - HC_emp: empirical HC; as a table array with column headings as follows:
     Response: Response vector sorted in descending order
     Rank: Rank or Weibull's plotting position
     CCDF: Complementary cumulative distribution function (CCDF)
     Hazard: hazard as AEF or AEP
     ARI: annual recurrence interval (ARI)
  - HC_plt: full HC; as a structure array with two fields: 'out' and 'MRL_Crit'. It may contain
     up to two records (one per MRL GPD threshold) with the following format:
     
     out = numerical array with the following 5 rows
        row(01): mean values
        row(02): values of 2% percentile or 1st percentage of input "prc"
        row(03): values of 16% percentile or 2nd percentage of input "prc"
        row(04): values of 84% percentile or 3rd percentage of input "prc"
        row(05): values of 98% percentile or 4th percentage of input "prc"

     MRL_Crit = character vector indicating the MRL threshold
        selection criterion used for the HC_plt.out record.

  - HC_plt_x2: same as HC_plt_x but converted to either AEP or AEF.
  - HC_tbl: summarized HC; as a structure array with two fields: 'out' and 'MRL_Crit'. It may contain
     up to two records (one per MRL GPD threshold) with the following format:

     out = numerical array with the following 5 rows
        row(01): mean values
        row(02): values of 2% percentile or 1st percentage of input "prc"
        row(03): values of 16% percentile or 2nd percentage of input "prc"
        row(04): values of 84% percentile or 3rd percentage of input "prc"
        row(05): values of 98% percentile or 4th percentage of input "prc"

     MRL_Crit = character vector indicating the MRL threshold
        selection criterion used for the HC_tbl.out record.

  - HC_tbl_rsp_x: hazard values interpolated from the HC, that correspond
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

  - MRL_output: output of Mean Residual Life (MRL) function; as a structure array with fields:
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

AUTHORS:
    Norberto C. Nadal-Caraballo, PhD (NCNC)
    Efrain Ramos-Santiago (ERS)

CONTRIBUTORS:
    Victor M. Gonzalez-Nieves, PE

HISTORY OF REVISIONS:
20200903-ERS: revised.
20201015-ERS: revised. Updated documentation.
20201026-ERS: Added capability to include skew surge. Updated documentation and inputs.
20201125-ERS: Reviewed script. Updated documentation.
20201201-ERS: Reviewed script. Updated documentation.
20201222-ERS: Applied preprocessing rules of 1st POT sample to 2nd input POT sample.
20210303-ERS: Corrected bootstrap check plot; x values now being converted
    to AEP or AEF, depending on the case specified by user.
20210311-ERS: alpha version 3: created and applied a function to adjust the
    hazard mean and CLs, to make sure they are monotonic. Also corrected
    the interpolation scheme to compute the hazard tables.
20210324-ERS: alpha version 4: removed conversion of hazard table values
    since will be input in the correct definition.
20210325-ERS: alpha version 4: adjusted the script to read new format of
    MRL output. Bootstrap sample plot will now apply different x-axis
    labels based on value of use_AEP. Plot filename identifies by MRL
    criteria. Output structure arrays now include the MRL criteria. Update
    description of output. Negatives are changed to NaN in both hazard tables.
20210406-ERS: alpha v0.4: now storing the default GPD threshold inside MRL_output.
20210407-ERS: alpha v0.4: only bootstrap samples with >1 value are
    evaluated to avoid error of fitdist().
20210412-ERS: alpha v0.4: now discarding random samples from bootstrap
    with spurious values (>100) when skew tides are used (peak data from ADCIRC).
20210413-ERS: alpha v0.4: removed the patch of 20210413.
20210429-ERS: alpha v0.4: applied GPD Shape Parameter limits, resulting in
    representative fits of samples with less than 20 events.
20210503-ERS: alpha v0.4: added input argument apply_GPD_to_SS as an option to evaluate
    small POT samples with either GPD or empirical distribution.
20210505-ERS: alpha v0.4: added correction for the evaluation of skew tides
20210513-ERS: alpha v0.4: re-enabled the patch of 20210412. A try/catch
    statement was applied to ignore bad random samples. The preallocation of
    the arrays will make those NaN.

***************  ALPHA  VERSION  **  FOR INTERNAL TESTING ONLY ************
%}
function [HC_emp,HC_plt,HC_plt_x2,HC_tbl,HC_tbl_rsp_x,MRL_output] = StormSim_SST_Fit(POT_samp,Nyrs,HC_plt_x,HC_tbl_x,HC_tbl_rsp_y,prc,use_AEP,GPD_TH_crit,ind_Skew,POT_samp2,SLC,gprMdl,staID,yaxis_Label,path_out,yaxis_Limits,apply_GPD_to_SS)

%% Bootstrap Input Parameters
Nsim = 1e3; %Number of simulations (no less than 10,000)

%% Develop empirical CDF (using output of POT function)
POT_samp = sort(POT_samp,'descend'); %Sort POT sample in descending order
HC_emp = POT_samp; %Response vector sorted in descending order; positive values only

% Weibull Plotting Position, P = m/(n+1)
% where P = Exceedance probability
%       m = rank of descending response values, with largest equal to 1
%       n = number of response values
Nstrm_hist = length(HC_emp); % Weibull's "n"
HC_emp(:,2) = (1:Nstrm_hist)'; %Rank of descending response values
HC_emp(:,3) = HC_emp(:,2)/(Nstrm_hist+1); %Webull's "P"; NEEDS Lambda Correction

% Lambda Correction - Required for Partial Duration Series (PDS)
Lambda_hist = Nstrm_hist/Nyrs; % Lambda = sample intensity = events/year
HC_emp(:,4) = HC_emp(:,3)*Lambda_hist;

% Compute Annual Recurrence Interval (ARI)
HC_emp(:,5) = 1./HC_emp(:,4);
ecdf_y = HC_emp(:,1);


%% Perform bootstrap
% rng('default');

if ind_Skew && ~isempty(POT_samp2) && isobject(gprMdl)
    
    ecdf_y = ecdf_y - SLC;
    boot = ecdf_boot(ecdf_y,Nsim)';
    
    % Compute and add skew tides to bootstrap sample or surge
    for i=1:Nsim
        [skew_tide_mean,skew_tide_sd] = predict(gprMdl,boot(:,i));
        skew_tide_pred = skew_tide_mean + randn(length(skew_tide_mean),1).*skew_tide_sd;
        boot(:,i) = boot(:,i) + skew_tide_pred;
        boot(:,i) = sort(boot(:,i),'descend');
    end
    
    % Add the SLC amount
    boot = boot + SLC;
    
    %Substitute the empirical dist with user supplied surge + tides + SLC (WL)
    ecdf_y = sort(POT_samp2,'descend'); %Sort POT sample in descending order
    
    % Resizing
    szH = size(HC_emp,1); szy = length(ecdf_y);
    if szH>szy
        HC_emp = HC_emp(1:szy,:);
    elseif szH<szy
        ecdf_y = ecdf_y(1:szH);
    end
    HC_emp(:,1)=ecdf_y;
    boot = boot(1:length(ecdf_y),:);
else
    boot = ecdf_boot(ecdf_y,Nsim)';
end
boot(boot<0)=NaN;


%% Apply the GPD when empirical POT sample size is >20 and RL >20 yrs. Otherwise, compute HC using empirical.
if (length(ecdf_y)>=20 && Nyrs>=20) || apply_GPD_to_SS %apply GPD
    
    
    %% Apply "Mean Residual Life" Automated Threshold Detection
    MRL_output = StormSim_MRL(ecdf_y,Nyrs);
    
    
    %% MRL GPD Threshold condition
    switch GPD_TH_crit
        case 0 %user wants the 3 THs
            j=1:2;%length(TH);
            mrl_th = MRL_output.Selection.Threshold;%mrl(TH,1);
        case 1 %TH selected by lambda criterion
            j=1;
            mrl_th = MRL_output.Selection.Threshold(2);%mrl(TH,1);
        case 2 %TH selected by minimum weight criterion
            j=1;
            mrl_th = MRL_output.Selection.Threshold(1);
    end
    if isnan(mrl_th)
        j=1;
        MRL_output.Selection.Criterion(1) = {'Default'};
    else
        if iscolumn(mrl_th)
            mrl_th = mrl_th';
        end
        mrl_th = repmat(mrl_th,Nsim,1);
    end
    
    
    %% Take parameters and preallocate
    ecdf_x_adj=HC_emp(:,4); % for hazard computations, this must be AEF
    
    %pre-allocation for speed
    Resp_boot_plt=NaN(Nsim,length(HC_plt_x));
    pd_k_wOut=NaN(Nsim,1);
    pd_sigma=pd_k_wOut;
    pd_k_mod=pd_k_wOut;
    pd_TH_wOut=pd_k_wOut;
    
    HC_plt(j(end)).out=[];
    HC_plt(j(end)).MRL_Crit=[];
    HC_tbl=HC_plt;
    HC_tbl_rsp_x=HC_plt;
    
    
    %% Perform SST
    str = 'Annual Exceedance Frequency (yr^{-1})';
    if use_AEP %Convert to AEP
        HC_emp(:,4) = aef2aep(HC_emp(:,4));
        HC_plt_x2 = aef2aep(HC_plt_x);
        str = 'Annual Exceedance Probability';
    else %Convert to AEF
        HC_plt_x2 = HC_plt_x;
    end
    
    for i=j %MRL GPD Threshold loop
        
        % If the MRL didn't returned a threshold value, compute it from the
        % bootstrap samples. Then identify values above it.
        if isnan(mrl_th)
            sz = size(boot,1); %total events above threshold per simulation
            idx = ones(sz,Nsim)==1; %index of events above threshold per simulation
            idx2 = zeros(sz,Nsim)==1; %index of events below threshold per simulation
            sz = repmat(sz,1,Nsim);
            mrl_th = 0.99*min(boot,[],1,'omitnan')';
            MRL_output.Selection.Threshold(1) = mean(mrl_th,'omitnan');
            eMsg = 'No threshold found by MRL method. Default criterion applied: GPD threshold set to 0.99 times the minimum value of the bootstrap sample.';
        else
            idx = boot>mrl_th(1,i); %index of events above threshold per simulation
            sz = sum(idx,1); %total events above threshold per simulation
            idx2 = boot<=mrl_th(1,i); %index of events below threshold per simulation
            eMsg ='';
        end
        Lambda_mrl = sz/Nyrs; %annual rate of events
        
        % GPD fitting
        for k = 1:Nsim
            PEAKS_rnd = boot(:,k);
            try
                % Fit the GPD to a bootstrap data sample
                u = PEAKS_rnd(idx(:,k),1);
                pd = fitdist(u,'GeneralizedPareto','theta',mrl_th(k,i));
                pd_TH_wOut(k,i) = pd.theta;
                pd_k_wOut(k,i) = pd.k;
                pd_sigma(k,i) = pd.sigma;
            catch
            end
        end
        
        % Correction of GPD shape parameter values. Limits determined by NCNC.
        pd_k_mod(:,i) = pd_k_wOut(:,i);
        k_min=-0.5; k_max=0.3;
        pd_k_mod(pd_k_mod(:,i)<k_min,i) = k_min;
        pd_k_mod(pd_k_mod(:,i)>k_max,i) = k_max;
        
        for k = 1:Nsim
            try
                PEAKS_rnd = boot(:,k);
                
                % Compute the AEF from the GPD fit
                Resp_gpd = icdf('Generalized Pareto',1-HC_plt_x/Lambda_mrl(k),pd_k_mod(k,i),pd_sigma(k,i),pd_TH_wOut(k,i));
                AEF_gpd = HC_plt_x(~isnan(Resp_gpd));
                Resp_gpd(isnan(Resp_gpd))=[];
                
                % Take the empirical AEF from bootstrap sample
                Resp_ecdf = PEAKS_rnd(idx2(:,k));
                AEF_ecdf = ecdf_x_adj(idx2(:,k));
                
                % Merge the AEFs (empirical + fitted GPD)
                y_comb = [Resp_gpd;Resp_ecdf];
                x_comb = [AEF_gpd;AEF_ecdf];
                
                % Comvert to AEP?
                if use_AEP
                    x_comb = aef2aep(x_comb);
                end
                
                % Delete duplicates
                [~,ia,~]=unique(x_comb,'stable');
                x_comb=x_comb(ia,:);
                y_comb=y_comb(ia,:);
                
                [~,ia,~]=unique(y_comb,'stable');
                y_comb=y_comb(ia,:);
                x_comb=x_comb(ia,:);
                
                % Interpolate HC curve for table and plot
                Resp_boot_plt(k,:) = interp1(log(x_comb),y_comb,log(HC_plt_x2));
            catch
            end
        end
        
        
        %% Sample Plot for bootstrap process
        figure('Color',[1 1 1],'visible','off')
        axes('xscale','log','XGrid','on','XMinorTick','on','YGrid','on','YMinorTick','on','FontSize',12);
        if use_AEP
            xlim([1e-4 1]);
            XTick=[1e-4 1e-3 1e-2 1e-1 1];
        else
            xlim([1e-4 10]);
            XTick=[1e-4 1e-3 1e-2 1e-1 1 10];
        end
        if ~isempty(yaxis_Limits)
            ylim([yaxis_Limits(1) yaxis_Limits(2)]);
        end
        set(gca,'XDir','reverse','XTick',XTick)
        hold on
        
        % Historical
        scatter(HC_emp(:,4),ecdf_y,15,'g','filled','MarkerEdgeColor','k');
        
        % Resampling (last bootstrap sample)
        scatter(HC_emp(:,4),PEAKS_rnd,15,'r','filled','MarkerEdgeColor','k');
        
        % Comvert to AEP?
        if use_AEP
            AEF_ecdf = aef2aep(AEF_ecdf);
            AEF_gpd = aef2aep(AEF_gpd);
        end
        
        % Empirical
        plot(AEF_ecdf,Resp_ecdf,'y-','LineWidth',2)
        
        % MRL threshold
        th_x = interp1(y_comb,x_comb,pd_TH_wOut(k,i));
        scatter(th_x,pd_TH_wOut(k,i),15,'w','filled','MarkerEdgeColor','b');
        
        plot(AEF_gpd,Resp_gpd,'b-','LineWidth',2) % GPD with MRL
        if length(staID)==1
            title({'StormSim-SST ';['Station: ',staID{1}]},'FontSize',12);
        else
            title({'StormSim-SST ';['Station: ',staID{1},' ',staID{2}]},'FontSize',12);
        end
        xlabel(str,'FontSize',12);
        ylabel({yaxis_Label},'FontSize',12);
        legend({'Historical','Resampling','Empirical','MRL threshold','GPD'},...
            'Location','southoutside','Orientation','horizontal','NumColumns',4,'FontSize',10);
        hold off
        fname = [path_out,'SST_HC_bootCheck_',staID{1},'_TH_',MRL_output.Selection.Criterion{i},'.png'];
        saveas(gcf,fname,'png')
        
        
        %% Compute mean and percentiles
        Boot_mean_plt = mean(Resp_boot_plt,1,'omitnan');
        Boot_plt = prctile(Resp_boot_plt,prc,1);
        
        %Return an error when mean HC >= 1e3 meters
        if ind_Skew && max(Boot_mean_plt,[],'omitnan')>=1e3
            error('Values above 10^3 found in mean hazard curve')
        end
        
        Mean_p_CLs = [Boot_mean_plt;Boot_plt];
        
        % Monotonic adjustment
        for kk=1:size(Mean_p_CLs,1)
            Mean_p_CLs(kk,:) = Monotonic_adjustment(HC_plt_x2,Mean_p_CLs(kk,:));
        end
        
        % Store results for output
        HC_plt(i).out = Mean_p_CLs;
        HC_plt(i).MRL_Crit = MRL_output.Selection.Criterion{i};
        
        
        %% Interpolation to create hazard tables
        
        % preallocate
        HC_tbl_rsp_x2 = NaN(size(Mean_p_CLs,1),length(HC_tbl_rsp_y));
        HC_tbl_y2 = NaN(size(Mean_p_CLs,1),length(HC_tbl_x));
        HCmn = NaN(size(Mean_p_CLs,1),1);
        for kk=1:size(Mean_p_CLs,1)
            
            % Delete duplicates
            [~,ia,~] = unique(Mean_p_CLs(kk,:),'stable');
            dm1 = Mean_p_CLs(kk,ia); dm2 = log(HC_plt_x2(ia));
            
            % Delete NaN/Inf
            ia=isnan(dm1)|isinf(dm1); dm1(ia)=[]; dm2(ia)=[];
            
            % Interpolate
            HC_tbl_rsp_x2(kk,:) = exp(interp1(dm1,dm2,HC_tbl_rsp_y','linear','extrap'));
            HC_tbl_y2(kk,:) = interp1(dm2,dm1,log(HC_tbl_x),'linear','extrap');
            
            %interpol for 0.1 aep/aef
            HCmn(kk) = interp1(dm2,dm1,log(0.1),'linear','extrap');
            
        end
        
        % Change negatives to NaN
        HC_tbl_y2(HC_tbl_y2<0)=NaN;
        %         HC_tbl_rsp_x2(HC_tbl_rsp_x2<0)=NaN;
        HC_tbl_rsp_x2(HC_tbl_rsp_x2<1e-4)=NaN;
        
        % Compare if mean HC > 1.75* emp HC at 0.1 AEP/AEF,
        HCep = interp1(log(HC_emp(:,4)),HC_emp(:,1),log(0.1),'linear','extrap');
        str1 = {''};
        if HCmn(1)>1.75*HCep
            str1 = {'Warning: At 0.1 AEP/AEF, best estimate HC value is greater than 1.75 times the empirical HC value. Manual verification is recommended.'};
        end
        HC_plt(i).Warning = str1;
        
        % Store
        HC_tbl_rsp_x(i).out = HC_tbl_rsp_x2;
        HC_tbl_rsp_x(i).MRL_Crit = MRL_output.Selection.Criterion{i};
        HC_tbl(i).out = HC_tbl_y2;
        HC_tbl(i).MRL_Crit = MRL_output.Selection.Criterion{i};
    end
    
    
else %dont apply GPD, but compute HC + prc with empirical only
    
    
    %% Take parameters and preallocate
    Resp_boot_plt=NaN(Nsim,length(HC_plt_x));
    pd_k_wOut=NaN;
    pd_sigma=pd_k_wOut;
    pd_k_mod=pd_k_wOut;
    pd_TH_wOut=pd_k_wOut;
    HC_plt(1).out=[];
    HC_plt(1).MRL_Crit=[];
    HC_tbl=HC_plt;
    HC_tbl_rsp_x=HC_plt;
    eMsg = 'GPD not fit: POT sample size <20 and RL <20 years.';
    
    
    %% Conversion to AEF or AEP
    if use_AEP %Convert to AEP
        HC_emp(:,4) = aef2aep(HC_emp(:,4));
        HC_plt_x2 = aef2aep(HC_plt_x);
    else %Convert to AEF
        HC_plt_x2 = HC_plt_x;
    end
    
    
    %% Compute HC
    for k = 1:Nsim
        y_comb = boot(:,k);
        x_comb = HC_emp(:,4);
        
        % Delete duplicates
        [~,ia,~]=unique(x_comb,'stable');
        x_comb=x_comb(ia,:);
        y_comb=y_comb(ia,:);
        
        [~,ia,~]=unique(y_comb,'stable');
        y_comb=y_comb(ia,:);
        x_comb=x_comb(ia,:);
        
        % Interpolate HC curve for plot: lineal inside empirical, nearest neighbor outside
        HC_plt_x2a = HC_plt_x2(HC_plt_x2>=min(x_comb));
        HC_plt_x2b = HC_plt_x2(HC_plt_x2<min(x_comb));
        
        Resp_boot_plta = interp1(log(x_comb),y_comb,log(HC_plt_x2a),'linear');
        Resp_boot_pltb = interp1(log(x_comb),y_comb,log(HC_plt_x2b),'nearest','extrap');
        
        % merge results
        Resp_boot_plt(k,:) = [Resp_boot_pltb' Resp_boot_plta'];
    end
    
    
    %% Compute mean and percentiles
    Boot_mean_plt = mean(Resp_boot_plt,1,'omitnan');
    Boot_plt = prctile(Resp_boot_plt,prc,1);
    
    %For this application only: delete results if WL >= 1e3 meters
    if ind_Skew && max(Boot_mean_plt,[],'omitnan')>=1e3
        error('Values above 10^3 found in mean hazard curve')
    end
    
    Mean_p_CLs = [Boot_mean_plt;Boot_plt];
    
    % Monotonic adjustment
    for kk=1:size(Mean_p_CLs,1)
        Mean_p_CLs(kk,:) = Monotonic_adjustment(HC_plt_x2,Mean_p_CLs(kk,:));
    end
    
    % Store results for output
    HC_plt(1).out = Mean_p_CLs;
    HC_plt(1).MRL_Crit = 'None';
    
    
    %% Interpolation to create hazard tables
    
    % preallocate
    HC_tbl_rsp_x2 = NaN(size(Mean_p_CLs,1),length(HC_tbl_rsp_y));
    HC_tbl_y2 = NaN(size(Mean_p_CLs,1),length(HC_tbl_x));
    HCmn = NaN(size(Mean_p_CLs,1),1);
    for kk=1:size(Mean_p_CLs,1)
        
        % Delete duplicates
        [~,ia,~] = unique(Mean_p_CLs(kk,:),'stable');
        dm1 = Mean_p_CLs(kk,ia); dm2 = log(HC_plt_x2(ia));
        
        % Delete NaN/Inf
        ia=isnan(dm1)|isinf(dm1); dm1(ia)=[]; dm2(ia)=[];
        
        % Interpolate
        HC_tbl_rsp_x2(kk,:) = exp(interp1(dm1,dm2,HC_tbl_rsp_y','nearest','extrap'));
        HC_tbl_y2(kk,:) = interp1(dm2,dm1,log(HC_tbl_x),'nearest','extrap');
        
        %interpol for 0.1 aep/aef
        HCmn(kk) = interp1(dm2,dm1,log(0.1),'linear','extrap');
        
    end
    
    % Change negatives to NaN
    HC_tbl_y2(HC_tbl_y2<0)=NaN;
    HC_tbl_rsp_x2(HC_tbl_rsp_x2<1e-4)=NaN;
    
    % Compare if mean HC > 1.75* emp HC at 0.1 AEP/AEF,
    HCep = interp1(log(HC_emp(:,4)),HC_emp(:,1),log(0.1),'linear','extrap');
    str1 = {''};
    if HCmn(1)>1.75*HCep
        str1 = {'Warning: At 0.1 AEP/AEF, best estimate HC value is greater than 1.75 times the empirical HC value. Manual verification is recommended.'};
    end
    HC_plt(1).Warning = str1;
    
    % Store
    HC_tbl_rsp_x(1).out = HC_tbl_rsp_x2;
    HC_tbl_rsp_x(1).MRL_Crit = 'None';
    HC_tbl(1).out = HC_tbl_y2;
    HC_tbl(1).MRL_Crit = 'None';
end

%% Store parameters needed for manual GPD Shape parameter evaluation
MRL_output.pd_TH_wOut = pd_TH_wOut;
MRL_output.pd_k_wOut = pd_k_wOut;
MRL_output.pd_sigma = pd_sigma;
MRL_output.pd_k_mod = pd_k_mod;
MRL_output.Status = eMsg;
HC_emp = array2table(HC_emp,'VariableNames',{'Response','Rank','CCDF','Hazard','ARI'});

end