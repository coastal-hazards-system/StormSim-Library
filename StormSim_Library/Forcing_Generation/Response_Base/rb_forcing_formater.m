function project_forcing = rb_forcing_formater(config, sType, storm, prob_mass)

%% GRAB INFORMATION FROM "config"
% Define PROS Analysis Type (RB1, RB3)
% aType = config.pros_mode;
use_timeseries = config.use_timeseries;
use_peaks = config.use_peaks;
workflow = config.workflow;
storm_duration = config.storm_duration;
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
% Disp
disp(['Reshaping ' sType ' forcing data for response base analysis....']);
if use_peaks == 1
    % Define Filednames In Storm
    fnames = fieldnames(storm.('Peaks'));
    % Remove Unwanted Fields
    fnames = fnames(contains(fnames,{'Maxima','WLP','WHP'}));
    % Reshape Peaks Data
    for ii = 1:length(fnames)
        % Reshape Peaks Data To Be nStorms * normal_discretization
        project_forcing.('Peaks').(fnames{ii}).SWL = repmat(storm.('Peaks').(fnames{ii})(:,1),1,RandNorm); % SWL
        project_forcing.('Peaks').(fnames{ii}).Hm0 = repmat(storm.('Peaks').(fnames{ii})(:,2),1,RandNorm); % Hm0
        project_forcing.('Peaks').(fnames{ii}).Tp = repmat(storm.('Peaks').(fnames{ii})(:,3),1,RandNorm); % Tp

        % Add No Replicate Fields For Forcing HC Computations
        if workflow == 1
            project_forcing.('Peaks').(fnames{ii}).SWL_no_rep = storm.('Peaks').(fnames{ii})(:,1); % SWL
            project_forcing.('Peaks').(fnames{ii}).Hm0_no_rep = storm.('Peaks').(fnames{ii})(:,2); % Hm0
            project_forcing.('Peaks').(fnames{ii}).Tp_no_rep = storm.('Peaks').(fnames{ii})(:,3); % Tp
        end
    end
end
% Reshape Storm Probability Masses To Be nStorms * normal_discretization
if strcmp(sType,'TC')
    %
    project_forcing.TC_Freq = repmat(TC_Freq, 1, RandNorm);
    project_forcing.TC_Prob = project_forcing.TC_Freq./RandNorm;
end
% Reshape Timeseries Data
if use_timeseries == 1
    % Reshape Peaks Data To Be nStorms * normal_discretization
    project_forcing.('Timeseries').SWL = cellfun(@(x) repmat(x(:,2),1,RandNorm),storm.('Timeseries')(:,2),'un',false); % SWL
    project_forcing.('Timeseries').Hm0 = cellfun(@(x) repmat(x(:,3),1,RandNorm),storm.('Timeseries')(:,2),'un',false); % Hm0
    project_forcing.('Timeseries').Tp = cellfun(@(x) repmat(x(:,4),1,RandNorm),storm.('Timeseries')(:,2),'un',false); % Tp
    % Reshape Peaks Data To Be nStorms * normal_discretization
    if workflow == 1
        project_forcing.('Timeseries').SWL_no_rep = cellfun(@(x) x(:,2),storm.('Timeseries')(:,2),'un',false); % SWL
        project_forcing.('Timeseries').Hm0_no_rep = cellfun(@(x) x(:,3),storm.('Timeseries')(:,2),'un',false); % Hm0
        project_forcing.('Timeseries').Tp_no_rep = cellfun(@(x) x(:,4),storm.('Timeseries')(:,2),'un',false); % Tp
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

