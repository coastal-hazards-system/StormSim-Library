function project_forcing = rb_forcing_formater(config, sType, storm, prob_mass)

%% GRAB INFORMATION FROM "config"
% Define PROS Analysis Type (RB1, RB3)
aType = config.pros_mode;

%% GRAB INFORMATION FROM "prob_mass"
% TC Storm Probability Masses
if strcmp(sType,'TC')
    TC_Freq = prob_mass.TC_Freq;
end

%% LOAD NORMAL DISCRETIZATION BASED ON STORM TYPE
% Execute Code Block According To Strom Type Being Called
switch sType
    case 'TC' % Tropical Cyclones - 444 Replicates
        % Discrete Normal Distribution: (NCNC)
        RandNorm = 444; % 444 values covering the (-3,3) z-score range
    case 'XC' % Extratropical Storms - 20 Replicates
        % Discrete Normal Distribution:
        RandNorm = 20; % 20 values for XC because there is 1000 bootstrap samples in SST code
end

%% RESHAPE FORCING PARAMETERS FOR RB1 ANALYSIS
switch aType
    case 'RB1'
        % Disp
        disp(['Reshaping ' sType ' forcing data for RB1 analysis....']);
        % Reshape SWL To Be nStorms * normal_discretization
        project_forcing.('Peaks').SWL = repmat(storm(:,1),1,RandNorm);
        % Reshape Hm0 To Be nStorms * normal_discretization
        project_forcing.('Peaks').Hm0 = repmat(storm(:,2),1,RandNorm);
        % Reshape Tp To Be nStorms * normal_discretization
        project_forcing.('Peaks').Tp = repmat(storm(:,3),1,RandNorm);
        % Reshape Storm Probability Masses To Be nStorms * normal_discretization
        if strcmp(sType,'TC')
            project_forcing.('Peaks').TC_Freq = repmat(TC_Freq, 1, RandNorm);
        end
    case 'RB3'
                % Disp
        disp(['Reshaping ' sType ' forcing data for RB3 analysis....']);
        % Reshape SWL To Be nStorms * normal_discretization
        project_forcing.('Timeseries').SWL = repmat(storm(:,1),1,RandNorm);
        % Reshape Hm0 To Be nStorms * normal_discretization
        project_forcing.('Timeseries').Hm0 = repmat(storm(:,2),1,RandNorm);
        % Reshape Tp To Be nStorms * normal_discretization
        project_forcing.('Timeseries').Tp = repmat(storm(:,3),1,RandNorm);
        % Reshape Storm Probability Masses To Be nStorms * normal_discretization
        if strcmp(sType,'TC')
            project_forcing.('Timeseries').TC_Freq = repmat(TC_Freq, 1, RandNorm);
        end
end

% % Save Point Depth
% if exist(confg.sp_depth,'var')
% h_SP =  repmat(config.sp_depth,size(SWL,1),1)+SWL; % SP Depth Convention Is Positive Below Datum Zero;
% else
%     h_SP = repmat(-1*config.toe_elevation,size(SWL,1),1)+SWL;
% end
% % Structure Toe Depth
% toe = repmat(-1*config.toe_elevation,size(SWL,1),1)+SWL; % Toe Is Negative Below Datum 0

% 1. Create bare parameter structure for hazard SST analysis
%                 project_forcing.(sType).SWL_noreps = SWL;
%                 project_forcing.(sType).Hm0_noreps = Hm0;
%                 project_forcing.(sType).Tp_noreps = Tp;
%                 project_forcing.(sType).h_SP_noreps = h_SP; % use SP for hazards
% 2. no need for XC reps with no uncertainty
% 3. Create parameter structure with reps and uncertainty for input to structure response calcs
%                [Resp.SWL_XC,Resp.Hm0_XC,Resp.Tp_XC,Resp.h_XC] = uncertainty_scheme(config.swl_prop_u,...
%                    config.swl_u_max, config.hm0_prop_u, config.hm0_u_max,...
%                    SWL,Hm0,Tp,config.sp_depth,RandNorm);
% here we use toe depth for structure response calculation
%                 [project_forcing.(sType).SWL, project_forcing.(sType).Hm0, project_forcing.(sType).Tp, project_forcing.(sType).h] = uncertainty_scheme_v20230110(U_a_SWL,...
%                     U_r_SWL, U_a_Hm0, U_r_SWL, SWL, Hm0, Tp, toe, RandNorm);
%                 % Verify For Depth Limited Waves
%                 project_forcing.(sType).Hm0 = depth_limitation_check(project_forcing.(sType).Hm0,project_forcing.(sType).Tp,project_forcing.(sType).h);
end

