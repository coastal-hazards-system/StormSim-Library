function output =combine_hazard_curves_v20230126(OUTPUT,rp_out)

%{ 
LICENSING:
    This code is part of StormSim software suite developed by the U.S. Army
    Engineer Research and Development Center Coastal and Hydraulics Laboratory
    (hereinafter “ERDC-CHL”). This material is distributed in accordance with DoD
    Instruction 5230.24. Recipient agrees to abide by all notices, and distribution
    and license markings. The controlling DOD office is the U.S. Army Engineer
    Research and Development Center (hereinafter, "ERDC"). This material shall be
    handled and maintained in accordance with For Official Use Only, Export Control,
    and AR 380-19 requirements. ERDC-CHL retains all right, title and interest in
    StormSim and any portion thereof and in all copies, modifications and derivative
    works of StormSim and any portions thereof including, without limitation, all
    rights to patent, copyright, trade secret, trademark and other proprietary or
    intellectual property rights. Recipient has no rights, by license or otherwise, to
    use, disclose or disseminate StormSim, in whole or in part.

DISCLAIMER:
    STORMSIM IS PROVIDED “AS IS” BY ERDC-CHL AND THE RESPECTIVE COPYRIGHT HOLDERS.
    ERDC-CHL MAKES NO OTHER WARRANTIES WHATSOEVER EITHER EXPRESS OR IMPLIED WITH RESPECT
    TO STORMSIM OR ANYTHING PROVIDED BY ERDC-CHL, AND EXPRESSLY DISCLAIMS ALL WARRANTIES
    OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING WITHOUT LIMITATION, WARRANTIES OF
    MERCHANTABILITY, NON-INFRINGEMENT, FITNESS FOR A PARTICULAR PURPOSE, FREEDOM FROM BUGS,
    CORRECTNESS, ACCURACY, RELIABILITY, AND RESULTS, AND REGARDING THE USE AND RESULTS OF THE
    USE, AND THAT THE ASSOCIATED SOFTWARE’S USE WILL BE UNINTERRUPTED. ERDC-CHL DISCLAIMS ALL
    WARRANTIES AND LIABILITIES REGARDING THIRD PARTY SOFTWARE, IF PRESENT IN STORMSIM, AND
    DISTRIBUTES IT “AS IS.” RECIPIENT AGREES TO WAIVE ANY AND ALL CLAIMS AGAINST ERDC-CHL, THE
    UNITED STATES GOVERNMENT AND ITS CONTRACTORS AND SUBCONTRACTORS, AND SHALL INDEMNIFY AND HOLD
    HARMLESS ERDC-CHL, THE UNITED STATES GOVERNMENT AND ITS CONTRACTORS AND SUBCONTRACTORS FOR ANY
    LIABILITIES, DEMANDS, DAMAGES.

SCRIPT NAME: 
    StormSim_PROS_ComboHCs.m

PURPOSE: 
    Combines hazard curves from SST and JPM 

INPUTS: 
|   Vars Name   |  Vars Type  |               Description                |
|---------------|-------------|------------------------------------------|
|     OUTPUT    |  Structure  |  Contains hazard responses               |
|---------------|-------------|------------------------------------------|
|     rp_out    |  Double     |  Contains return periods                 |
|---------------|-------------|------------------------------------------|

OUTPUTS:
|   Vars Name   |  Vars Type  |               Description                |
|---------------|-------------|------------------------------------------|
|     output    |  Structure  |  Contains combined hazard responses      |
|---------------|-------------|------------------------------------------|

OUTPUT HEADERS:
    OUTPUT 
        OUTPUT.staID       - String defining response
        OUTPUT.FREQ_x      - (f x n) AEF values, n = # CLs, f = # AEF
        OUTPUT.yval        - (f x 1) y values for AEF, n = # CLs, f = # AEF
        OUTPUT.ARI         - (# rp x n) table of AEF responses, n = # CLs

AUTHORS: 
    Abigail L. Stehno, Victor Gonzalez, Jeffrey Melby, Norberto
    Nadal-Caraballo

MODIFICATIONS: 
|  DATE (mm/dd/yyy) |  EDITOR          |          Description             |
|-------------------|------------------|----------------------------------|
|    04/02/21       | A Stehno         | Created for Norfolk CSRM         |
|-------------------|------------------|----------------------------------|
|    04/12/21       | A Stehno         | Modified for PROS                |
|-------------------|------------------|----------------------------------|
|    05/28/21       | A Stehno         | Modified for new JPM             |
|-------------------|------------------|----------------------------------|
|    07/01/21       | A Stehno         | Modified for new-new JPM         |
|-------------------|------------------|----------------------------------|
|    07/08/21       | A Stehno         | Zero probability for y vals outside range |
|-------------------|------------------|----------------------------------|

20230126-JAM: Modified parameter names to make compatible with updated PROS

%}
disp('    Combining hazard for tropical & extra-tropical responses')
    out_steps = length(OUTPUT.TC.JPM_output);
    if strcmp(OUTPUT.TC.JPM_output(length(OUTPUT.TC.JPM_output)).staID,'Tp')==1
        out_steps = out_steps - 1; 
    end
    if strcmp(OUTPUT.TC.JPM_output(length(OUTPUT.TC.JPM_output)).staID,'p3 (static+dynamic)')==1
        out_steps = out_steps - 3; 
    end
for j = 1:out_steps % for each parameter
    % JAM fixed following line on 11/28/22
%    for i = 1:size(OUTPUT.XC.SST_output(j).HC_tbl_rsp_x,1)
    for i = 1:size(OUTPUT.XC.SST_output(j).SST_output.HC_tbl_rsp_x,1) %2 parameters, SWL, Hm0
        output(j).staID = OUTPUT.TC.JPM_output(j).staID; % for each CL
        if isempty(OUTPUT.TC.JPM_output(j).HC_data.HC_tbl_rsp_x)==1
            OUTPUT.TC.JPM_output(j).HC_data.HC_tbl_rsp_x(1:2000,size(OUTPUT.XC.SST_output(j).HC_tbl_rsp_x,1)) = NaN; 
    % JAM fixed following line on 11/28/22
%        elseif isempty(OUTPUT.XC.SST_output(j).HC_tbl_rsp_x')==1
        elseif isempty(OUTPUT.XC.SST_output(j).SST_output.HC_tbl_rsp_x')==1
    % JAM fixed following line on 11/28/22
%            OUTPUT.XC.SST_output(j).HC_tbl_rsp_x(size(OUTPUT.XC.SST_output(j).HC_tbl_rsp_x,1),1:2000) = NaN; 
            OUTPUT.XC.SST_output(j).SST_output.HC_tbl_rsp_x(size(OUTPUT.XC.SST_output(j).SST_output.HC_tbl_rsp_x,1),1:2000) = NaN; 
        end        
            

    %% Add the probabilities for each y-value
    % JAM fixed following line on 11/28/22
        FREQ_mean_1 = OUTPUT.XC.SST_output(j).SST_output.HC_tbl_rsp_x(i,:); 
%        FREQ_mean_1 = OUTPUT.XC.SST_output.SST_output(j).HC_tbl_rsp_x(i,:).out; 
        FREQ_mean_1 = FREQ_mean_1(1,:)';
        FREQ_mean_2 = OUTPUT.TC.JPM_output(j).HC_data.HC_tbl_rsp_x(:,i);
    % JAM fixed following 2 lines on 11/28/22
%        FREQ_mean_1(isnan(FREQ_mean_1)==1)=0; %zero probability of these events occuring
%        FREQ_mean_2(isnan(FREQ_mean_2)==1)=0; % allows for addition of TC and XC.
    % JAM fixed following line on 11/28/22
    % problem here is that FREQ_mean_1 is a 2x1 structure whereas
    % FREQ_mean_2 is a 2000x1 double.  FREQ_mean_1 needs to be a double for
    % this to work.
        FREQ_mean_1(isnan(FREQ_mean_1))=0; %zero probability of these events occuring
        FREQ_mean_2(isnan(FREQ_mean_2))=0; % allows for addition of TC and XC.
        FREQ_mean_3 = (FREQ_mean_1 + FREQ_mean_2);

        FREQ_mean_3(FREQ_mean_3==0)=NaN; % revert back for zero probs for both TC and XC 

    % Convert from AEF to RP
        FREQ_mean_1(:,2) = 1./FREQ_mean_1;
        FREQ_mean_2(:,2) = 1./FREQ_mean_2;
        FREQ_mean_3(:,2) = 1./FREQ_mean_3;

        %% Process data for interpolation (remove NaN, inf, and repeats)
            x1 = FREQ_mean_3(:,2);

    y1 = OUTPUT.XC.SST_output(j).HC_tbl_rsp_y(:,1); %there is one exactly like this for TC

    % JAM fixed following line on 11/28/22
%    y1(isnan(x1)==1)=[]; x1(isnan(x1)==1)=[];
    y1(isnan(x1))=[]; x1(isnan(x1))=[];
    y1(x1==Inf)=[]; x1(x1==Inf)=[]; x1 = log(x1);
    [C, ia, ~] = unique(x1,'stable');
    x1 = C; y1 = y1(ia,1);
      
%% Interpolate to compute ARI for each y-value
    try
    ari_out1 = interp1(x1,y1,log(rp_out),'linear','extrap');
    ari_out1(1,ari_out1(1,:)<0)=NaN;
        output(j).HC_tbl_x(:,i) = rp_out;
    output(j).HC_tbl_y(:,i) = ari_out1;
    catch
        output(:,j).HC_tbl_y(:,i) = NaN; 
    end
    
    output(:,j).HC_tbl_rsp_x(:,i) = FREQ_mean_3(:,2); 
    
    output(:,j).HC_plt_y(:,i) = NaN(size(output(:,j).HC_tbl_rsp_x(:,i))); 
    output(:,j).HC_plt_y(1:length(y1),i) = y1; 
    
    end
end
