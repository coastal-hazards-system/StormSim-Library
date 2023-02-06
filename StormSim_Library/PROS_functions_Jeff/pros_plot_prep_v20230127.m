function plt = pros_plot_prep_v20230127(config,OUTPUT,datum_str)
    
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
    StormSim_PROS_PlotHCs.m

PURPOSE:
    Plots hazard curves

INPUTS:
|   Vars Name   |  Vars Type  |               Description                |
|---------------|-------------|------------------------------------------|
|     OUTPUT    |  Structure  |  Contains combined hazard responses      |
|---------------|-------------|------------------------------------------|


AUTHORS:
    Abigail L. Stehno

MODIFICATIONS:
|  DATE (mm/dd/yyy) |  EDITOR          |          Description             |
|-------------------|------------------|----------------------------------|
|    04/12/21       | A Stehno         | Created                          |
|-------------------|------------------|----------------------------------|
|    05/28/21       | A Stehno         | Mod for new JPM                  |
|-------------------|------------------|----------------------------------|
|    07/02/21       | A Stehno         | Mod for new new JPM              |
|-------------------|------------------|----------------------------------|
|    11/29/22       | J Melby          | Fixed code to work with revised  |
SST output arrays. Added comments.  Changed plt(ctr).plotDesc so that it is not hard
coded.
|-------------------|------------------|----------------------------------|
    %}
    % clear plt
    % config.storm_sampling = 'XC';
    %  disp('    Plotting hazard curve for responses')
    ctr=1;

% JAM introduced convValue here because it was not assigned a value in some
% cases and it is always equal to 1.  We will have to add a conversion
% routine later.
convValue=1;
%% Extratropical plotting arrays
    if contains(config.storm_sampling,{'XC','XH','CC'})
        for i = 1:length(OUTPUT.XC.SST_output) % process each parameter from list below
            plt(ctr).staID = OUTPUT.XC.SST_output(i).SST_output.staID;

% JAM 11/29/22. Following line is replacement for plt(ctr).plotDesc large hard coded switch complex
            plt(ctr).plotDesc = ['PROS_XC: ',plt(ctr).staID];
%             switch plt(ctr).staID
%                 case 'q'
%                     plt(ctr).plotDesc = ['PROS_XC: SST Overtopping Discharge Rate'];
%                     convValue = 1;
%                 case 'R2p'
%                     plt(ctr).plotDesc = ['PROS_XC: SST Run-up'];
%                     convValue = 1;
%                 case 'R2p+SWL'
%                     plt(ctr).plotDesc = ['PROS_XC: SST Run-up + SWL'];
%                     convValue = 1;
%                 case 'p1'
%                     plt(ctr).plotDesc = ['PROS_XC: SST Pressure at SWL'];
%                     convValue = 1;
%                 case 'SWL'
%                     plt(ctr).plotDesc = ['PROS_XC: SST Still Water Level'];
%                     convValue = 1;
%                 case 'Hm0'
%                     plt(ctr).plotDesc = ['PROS_XC: SST Wave Height'];
%                     convValue = 1;
%                 case 'Tp'
%                     plt(ctr).plotDesc = ['PROS_XC: SST Peak Period'];
%                     convValue = 1;
%                 case 'p2'
%                     plt(ctr).plotDesc = ['PROS_XC: SST Pressure at Top of Structure'];
%                     convValue = 1;
%                 case 'p3'
%                     plt(ctr).plotDesc = ['PROS_XC: SST Pressure at Structure Toe'];
%                     convValue = 1;
%                 case 'Dn50'
%                     plt(ctr).plotDesc = ['PROS_XC: SST Median Stone Size'];
%                     convValue = 1;
%                 case 'Dn50_LCBW'
%                     plt(ctr).plotDesc = ['PROS_XC: SST LCBW Median Stone Size'];
%                     
%             end
% JAM changed the following on 11/28/22
%            plt(ctr).x = flipud(1./OUTPUT.XC.HC_plt_x);
%            plt(ctr).x_table = flipud(1./OUTPUT.XC.HC_tbl_x');
% load plot arrays with ARI for x axis and response for y axis
% x arrays have one column while y arrays have one column per confidence level
% The following if-else defaults to large array but will use small table if
% large array not available.
            plt(ctr).x = flipud(1./OUTPUT.XC.SST_output(i).HC_plt_x); % 631 x 1
            plt(ctr).x_table = flipud(1./OUTPUT.XC.SST_output(i).HC_tbl_x');
            indxS =  plt(ctr).x_table <=1000;
            plt(ctr).x_table = plt(ctr).x_table(indxS);
%            if ~isempty(OUTPUT.XC.SST_output(i).HC_plt)
            if ~isempty(OUTPUT.XC.SST_output(i).SST_output.HC_plt)
%                plt(ctr).y = flipud(transpose(OUTPUT.XC.SST_output(i).HC_plt.*convValue));
                temp1=OUTPUT.XC.SST_output(i).SST_output.HC_plt;
                plt(ctr).y = flipud(transpose(temp1.*convValue)); % 631 x number of Conf. Levels
            else
%                plt(ctr).y = flipud(transpose(OUTPUT.XC.SST_output(i).HC_tbl.*convValue));
%                plt(ctr).x = flipud(1./OUTPUT.XC.HC_tbl_x');
                temp2=OUTPUT.XC.SST_output(i).SST_output.HC_tbl; % 2 x 18, low to high
                plt(ctr).y = flipud(transpose(temp2.*convValue)); %18 x 2, high to low
                plt(ctr).x = flipud(1./OUTPUT.XC.SST_output.HC_tbl_x');
            end
%            plt(ctr).y_table = flipud(transpose(OUTPUT.XC.SST_output(i).HC_tbl.*convValue));
% Following 2 lines provide the same as above but small table of 9 ARI values.
            temp3 = OUTPUT.XC.SST_output(i).SST_output.HC_tbl;
            plt(ctr).y_table = flipud(transpose(temp3.*convValue));
            plt(ctr).y_table = plt(ctr).y_table(indxS,:);
% Finally generate x column for every y column.  Why?
            plt(ctr).x = repmat(plt(ctr).x,1,length(plt(ctr).y(1,:)));% 631 x numCL           
            ctr = ctr + 1;
        end
        % Nappe
        if config.strucType == 2
            varsToPull = {'X_c_surge','theta_center','Bjet','Vjet','Fjet'};
            for vp = 1:length(varsToPull)
                plt(ctr).staID = varsToPull{vp};
                plt(ctr).x = flipud(1./OUTPUT.XC.HC_tbl_x');
                indxS =  plt(ctr).x <=1000;
                
                switch plt(ctr).staID
                    case 'X_c_surge'
                        plt(ctr).plotDesc = ['PROS_XC: SST X_c_surge'];
                    case 'theta_center'
                        plt(ctr).plotDesc = ['PROS_XC: SST Nappe Geometry Jet Center Incident Angle (theta_c)'];
                    case 'Bjet'
                        plt(ctr).plotDesc = ['PROS_XC: SST Nappe Geometry Jet Width (Bjet)'];
                    case 'Vjet'
                        plt(ctr).plotDesc = ['PROS_XC: SST Nappe Geometry Jet Velocity (Vjet)'];
                    case 'Fjet'
                        plt(ctr).plotDesc = ['PROS_XC: SST Nappe Geometry Jet Force (Fjet)'];
                end
                eval([' plt(ctr).y = flipud(transpose(OUTPUT.XC.Nappe.' varsToPull{vp} '));']);
                plt(ctr).x_table = plt(ctr).x(indxS);
                plt(ctr).y_table = plt(ctr).y(indxS,:);
                plt(ctr).x = repmat(plt(ctr).x,1,length(plt(ctr).y(1,:)));% 18 x numCL
                ctr = ctr + 1;
            end
        end
    end
    if contains(config.storm_sampling,{'TC','TS','CC'})
        out_steps = length(OUTPUT.TC.JPM_output);
        %     if strcmp(OUTPUT.TC.JPM_output(length(OUTPUT.TC.JPM_output)).staID,'Tp')==1
        %         out_steps = out_steps - 1;
        %     end     
        for i = 1:out_steps
            plt(ctr).staID = OUTPUT.TC.JPM_output(i).staID;
            plt(ctr).plotDesc = ['PROS_TC: ',plt(ctr).staID];   
%             switch plt(ctr).staID
%                 case 'q'
%                     plt(ctr).plotDesc = ['PROS_TC: JPM Overtopping Discharge Rate'];
%                     convValue = 1;
%                 case 'R2p'
%                     plt(ctr).plotDesc = ['PROS_TC: JPM Run-up'];
%                     convValue = 1;
%                 case 'R2p+SWL'
%                     plt(ctr).plotDesc = ['PROS_TC: JPM Run-up + SWL'];
%                     convValue = 1;
%                 case 'p1'
%                     plt(ctr).plotDesc = ['PROS_TC: JPM Pressure at SWL'];
%                     convValue = 1;
%                 case 'SWL'
%                     plt(ctr).plotDesc = ['PROS_TC: JPM Still Water Level'];
%                     convValue = 1;
%                 case 'Hm0'
%                     plt(ctr).plotDesc = ['PROS_TC: JPM Wave Height'];
%                     convValue = 1;
%                 case 'Tp'
%                     plt(ctr).plotDesc = ['PROS_TC: JPM Peak Period'];
%                     convValue = 1;
%                 case 'p2'
%                     plt(ctr).plotDesc = ['PROS_TC: JPM Pressure at Top of Structure'];
%                     convValue = 1;
%                 case 'p3'
%                     plt(ctr).plotDesc = ['PROS_TC: JPM Pressure at Structure Toe'];
%                     convValue = 1;
%                 case 'Dn50'
%                     plt(ctr).plotDesc = ['PROS_TC: JPM Median Stone Size'];
%                     convValue = 1;
%                 case 'Dn50_LCBW'
%                     plt(ctr).plotDesc = ['PROS_TC: JPM LCBW Median Stone Size'];
%             end
            if isempty(OUTPUT.TC.JPM_output(i).HC_tbl_x)
                plt(ctr).x = flipud(1./OUTPUT.TC.JPM_output(1).HC_tbl_x'); % 631 x 1
                indxS =  plt(ctr).x <=1000;
                plt(ctr).y = flipud(OUTPUT.TC.JPM_output(i).HC_data.HC_tbl_y.*convValue); % 631 x number of CLs
                plt(ctr).x_table = plt(ctr).x(indxS);
                plt(ctr).y_table = plt(ctr).y(indxS,:);
            else
                plt(ctr).x = 1./OUTPUT.TC.JPM_output(i).HC_plt_x; % 631 x 5
                plt(ctr).y = OUTPUT.TC.JPM_output(i).HC_data.HC_plt_y.*convValue;
                plt(ctr).x_table = flipud(1./OUTPUT.TC.JPM_output(i).HC_tbl_x');
                indxS =  plt(ctr).x_table <=1000;
                plt(ctr).x_table = plt(ctr).x_table(indxS);
                plt(ctr).y_table = flipud(OUTPUT.TC.JPM_output(i).HC_data.HC_tbl_y.*convValue);
                try    %This is temporary , copy previous data
                    plt(ctr).y_table = plt(ctr).y_table(indxS,:);
                catch
                    plt(ctr).y_table = NaN(size(plt(ctr-1).y_table));
                    plt(ctr).y = NaN(size(plt(ctr-1).y));
                    
                end
            end
            plt(ctr).x = repmat(plt(ctr).x,1,length(plt(ctr).y(1,:)));% 631 x numCL
            ctr = ctr + 1;
        end
        % Nappe
        if config.strucType == 2
            varsToPull = {'X_c_surge','theta_center','Bjet','Vjet','Fjet'};
            for vp = 1:length(varsToPull)
                
                plt(ctr).staID = varsToPull{vp};
                plt(ctr).x = flipud(1./OUTPUT.TC.JPM_output(1).HC_tbl_x');
                indxS =  plt(ctr).x <=1000;
                switch plt(ctr).staID
                    case 'X_c_surge'
                        plt(ctr).plotDesc = ['PROS_TC: JPM X_c_surge'];
                    case 'theta_center'
                        plt(ctr).plotDesc = ['PROS_TC: JPM Nappe Geometry Jet Center Incident Angle (theta_c)'];
                    case 'Bjet'
                        plt(ctr).plotDesc = ['PROS_TC: JPM Nappe Geometry Jet Width (Bjet)'];
                    case 'Vjet'
                        plt(ctr).plotDesc = ['PROS_TC: JPM Nappe Geometry Jet Velocity (Vjet)'];
                    case 'Fjet'
                        plt(ctr).plotDesc = ['PROS_TC: JPM Nappe Geometry Jet Force (Fjet)'];
                end
                eval([' plt(ctr).y = flipud(OUTPUT.TC.Nappe.' varsToPull{vp} ');']);
                
                plt(ctr).x_table = plt(ctr).x(indxS);
                plt(ctr).y_table = plt(ctr).y(indxS,:);
                plt(ctr).x = repmat(plt(ctr).x,1,length(plt(ctr).y(1,:)));% 18 x numCL
                ctr = ctr + 1;
            end
        end
    end
    if contains(config.storm_sampling,{'CC'})
        
        % combined
        for i = 1:length(OUTPUT.CC_ARI)
            plt(ctr).staID = OUTPUT.CC_ARI(i).staID;
            plt(ctr).plotDesc = ['PROS_TC: ',plt(ctr).staID];  
%             switch plt(ctr).staID
%                 case 'q'
%                     plt(ctr).plotDesc = ['PROS_CC: ARI Overtopping Discharge Rate'];
%                     convValue = 1;
%                 case 'R2p'
%                     plt(ctr).plotDesc = ['PROS_CC: ARI Run-up'];
%                     convValue = 1;
%                 case 'R2p+SWL'
%                     plt(ctr).plotDesc = ['PROS_CC: ARI Run-up + SWL'];
%                     convValue = 1;
%                 case 'p1'
%                     plt(ctr).plotDesc = ['PROS_CC: ARI Pressure at SWL'];
%                     convValue = 1;
%                 case 'SWL'
%                     plt(ctr).plotDesc = ['PROS_CC: ARI Still Water Level'];
%                     convValue = 1;
%                 case 'Hm0'
%                     plt(ctr).plotDesc = ['PROS_CC: ARI Wave Height'];
%                     convValue = 1;
%                 case 'Tp'
%                     plt(ctr).plotDesc = ['PROS_CC: ARI Peak Period'];
%                     convValue = 1;
%                 case 'p2'
%                     plt(ctr).plotDesc = ['PROS_CC: ARI Pressure at Top of Structure'];
%                     convValue = 1;
%                 case 'p3'
%                     plt(ctr).plotDesc = ['PROS_CC: ARI Pressure at Structure Toe'];
%                     convValue = 1;
%                 case 'Dn50'
%                     plt(ctr).plotDesc = ['PROS_CC: ARI Median Stone Size'];
%                     convValue = 1;
%                 case 'Dn50_LCBW'
%                     plt(ctr).plotDesc = ['PROS_CC: ARI LCBW Median Stone Size'];
%             end
            plt(ctr).x = flipud(OUTPUT.CC_ARI(i).HC_tbl_x); % n x numCL
            indxS =  plt(ctr).x(:,1) <=1000;
            plt(ctr).y = flipud(OUTPUT.CC_ARI(i).HC_tbl_y).*convValue; % n x numCL
            plt(ctr).y_table = flipud(OUTPUT.CC_ARI(i).HC_tbl_y).*convValue; % n x numCL
            plt(ctr).y_table = plt(ctr).y_table(indxS,:); % n x numCL
            plt(ctr).x_table = flipud(OUTPUT.CC_ARI(i).HC_tbl_x(:,1)); % n x numCL
            plt(ctr).x_table = plt(ctr).x_table(indxS); % n x numCL
            ctr = ctr + 1;
        end
    end
    
    %% Def units for each variable
    for j = 1:length(plt)
        if strcmp(plt(j).staID,'q')==1
            plt(j).units = 'm^3 / s / m';
            plt(j).yLogSwitch = 1;
            plt(j).minylim = 1e-4;
        elseif sum(strcmp(plt(j).staID,{'R2p','R2p+SWL','SWL'}))==1
            plt(j).units = ['m, ',datum_str];
            plt(j).yLogSwitch = 0;
        elseif sum(strcmp(plt(j).staID,{'Hm0','Dn50','Dn50_LCBW'}))==1
            plt(j).units = 'm';
            plt(j).yLogSwitch = 0;
        elseif strcmp(plt(j).staID,'p1')==1
            plt(j).units = 'N/m^2';
            plt(j).yLogSwitch = 0;
        elseif strcmp(plt(j).staID,'Tp')==1
            plt(j).units = 's';
            plt(j).yLogSwitch = 0;
        elseif strcmp(plt(j).staID,'p2')==1
            plt(j).units = 'N/m^2';
            plt(j).yLogSwitch = 0;
        elseif strcmp(plt(j).staID,'p3')==1
            plt(j).units ='N/m^2';
            plt(j).yLogSwitch = 0;
        elseif strcmp(plt(j).staID,'X_c_surge')==1
            plt(j).units = 'm';
            plt(j).yLogSwitch = 0;
        elseif strcmp(plt(j).staID,'theta_center')==1
            plt(j).units = 'deg';
            plt(j).yLogSwitch = 0;
        elseif strcmp(plt(j).staID,'Bjet')==1
            plt(j).units = 'm';
            plt(j).yLogSwitch = 0;
        elseif strcmp(plt(j).staID,'Vjet')==1
            plt(j).units = 'm/s';
            plt(j).yLogSwitch = 0;
        elseif strcmp(plt(j).staID,'Fjet')==1
            plt(j).units = 'N/m';
            plt(j).yLogSwitch = 0;
        end
    end
end
%
%% Plot hazard curves and save out




