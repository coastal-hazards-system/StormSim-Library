function project_forcing = call_project_forcing_formater(config, storm, prob_mass)
%{
    %% DESCRIPTION
        This function is responsible for formating parsed Coastal Hazards
        System (CHS) .h5 storm "Peaks" & "Timeseries" data based on specified
        framework.
    
    Formats
    
    LifeCycle Base
        Peaks
            LC_MCSimOUT -> struc | 1 x number_of_life_cycles
                    each life cycle has storms sampled through Monte Carlo
                    Simulation.
        LC_MCSimOUT(# of LC's).LCNUM:
        Size (number_of_storms_sampled, 8) -> (Rows,Col)
        (01) Storm Year                   [-]
        (02) Cyclone Type                 [XC=0; TC=1]
        (03) Same year counter            [-]
        (04) Water Level                  [meters, MSL]
        (05) Wave Height                  [meters]
        (06) Peak Wave Period             [seconds]
        (07) Wave Direction               [degrees; N=0, E=+90, S=+/-180, W=-90]
        (08) Storm ID                     [-]
    
    timeseries
    LC_SimOUT_hyd:
        First Level:
            Size (# of LC's, 1) -> (Rows,Col)
            Each row contains a matrix which size depends on the ammount of
            storms sampled for that specific life cyccle.
        Second Level:
            (01) Storm ID                 [-]
            (02) Time Series Length       [-]
            (03) Timestep Counter         [-]
            (04) Date/Time                [-]
            (05) Water Level              [meters, MSL]
            (06) Wave Height              [meters]
            (07) Peak Wave Period         [seconds]
            (08) Wave Direction           [degrees; N=0, E=+90, S=+/-180, W=-90]
            (09) Storm Duration           [days]
    
       MC_indx:
        First Level:
            Size (# of LC's, 1) -> (Rows,Col)
            Each row contains a vector which size depends on the ammount of
            storms sampled for that specific life cyccle.
        Second Level:
            (01) Storm Year               [-]
            (02) Storm Type               [-]
            (03) Same Year Counter        [-]
            (04) Storm ID                 [-]
    
    
    
    %% INPUTS
                
    %% OUTPUTS
       
    %% DEV SIGNATURE
        Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}
%% GRAB INPUT FROM "config"
%{
        This section meant to provide an easy way to make changes to config
        variable calls without having to alter core code.
%}
% Define Requested Workflow (1 -> RB1 Approach, other-> Life-Cycle Base)
workflow = config.workflow;
% Define Storm Type ('XC' or 'TC')
storm_sampling = config.storm_sampling;
% Define Use Timeseries Flag
use_timeseries = config.use_timeseries;
% Define Use Timeseries Flag
use_peaks = config.use_peaks;
% Define Save Name
save_name = fullfile(config.outfolder, config.project_name, config.struc_id,...
    config.case_name , [config.project_name,'_', config.struc_id]);
% Define MCS Project Forcing Mode
load_project_forcing = config.load_project_forcing;
% Define Reference Case_name
ref_case_name = config.ref_case_name;

%% FORMAT FORCING DATA ACCORDING TO WORKFLOW
% Prompt User
disp('Preping project forcing data....');
% Define Events Per Case
switch workflow
    case {1,2,4} % StormSim: PROS (Ressonse Base (RB1) Analysis)
        % Define Workflow Key Phrase
        switch workflow
            case 1 % PROS - RB
                wName = 'PROS';
            case 2 % PROS - EVA
                wName = 'PROS-EVA';
            case 4 % PROS - FB
                wName = 'PROS-FB';
        end
        % Build Ref Case Path
        mcs_ref_pth = fullfile(config.outfolder, config.project_name, config.struc_id,...
            ref_case_name, [config.project_name,'_', config.struc_id, '_' wName '_project_forcing.mat']);
        % Evaluate According To User Selection
        if load_project_forcing == 1 && exist(mcs_ref_pth,'file')
            try
                % Load Project Forcing
                load(mcs_ref_pth,'project_forcing');
                % Copy To Current Case
                if ~exist([save_name '_' wName '_project_forcing.mat'], 'file')
                    copyfile(mcs_ref_pth, [save_name '_' wName '_project_forcing.mat']);
                end
            catch
                % Tropical Cyclones
                if contains(storm_sampling,{'TC','CC'})
                    % Reshape Forcing Parameters For RB Analysis (nStorms * noyrmal_discretizations)
                    project_forcing.('TC') = rb_forcing_formater(config, 'TC', storm.('TC'), prob_mass);
                end
                % Extratropical Storms
                if contains(storm_sampling,{'XC','CC'})
                    % Reshape Forcing Parameters For RB Analysis (nStorms * normal_discretizations)
                    project_forcing.('XC') = rb_forcing_formater(config, 'XC', storm.('XC'), []);
                end
                % Save Peaks Life Cycle Structures
                save([save_name '_' wName '_project_forcing.mat'],'project_forcing','-v7.3');
            end
        else
            % Tropical Cyclones
            if contains(storm_sampling,{'TC','CC'})
                % Reshape Forcing Parameters For RB Analysis (nStorms * noyrmal_discretizations)
                project_forcing.('TC') = rb_forcing_formater(config, 'TC', storm.('TC'), prob_mass);
            end
            % Extratropical Storms
            if contains(storm_sampling,{'XC','CC'})
                % Reshape Forcing Parameters For RB Analysis (nStorms * normal_discretizations)
                project_forcing.('XC') = rb_forcing_formater(config, 'XC', storm.('XC'), []);
            end
            % Save Peaks Life Cycle Structures
            save([save_name '_' wName '_project_forcing.mat'],'project_forcing','-v7.3');
        end
    case 3 % StormSim: MCS-LC (Life-Cycle Base Analysis)
        % Define Workflow Key Phrase
        wName = 'LCS';
        % Build Ref Case Path
        mcs_ref_pth = fullfile(config.outfolder, config.project_name, config.struc_id,...
            ref_case_name, [config.project_name,'_', config.struc_id, '_' wName '_project_forcing.mat']);
        % Evaluate According To User Selection
        if load_project_forcing == 1 && exist(mcs_ref_pth,'file')
            try
                % Load Project Forcing
                load(mcs_ref_pth,'project_forcing');
                % Copy To Current Case
                if ~exist([save_name '_' wName '_project_forcing.mat'], 'file')
                    copyfile(mcs_ref_pth, [save_name '_' wName '_project_forcing.mat']);
                end
            catch
                % Call StormSim: Monte Carlo Storm Sampler
                if use_peaks == 1
                    % Get Storm Sampling Using Peaks Files
                    [project_forcing] = call_stormsim_mcs(config, storm, prob_mass);
                    % Do you want to use timeseries
                    if use_timeseries == 1 % Timeeseries follows the same sampling scheme as Maxima Peaks dataset
                        [project_forcing.(storm_sampling).Timeseries]=call_stormsim_mcs_timeseries(project_forcing, storm, prob_mass, storm_sampling);
                    end
                else % Timeseries Only
                    % Get Storm Types In Data
                    level_1 = fieldnames(storm);
                    % Create Dummy Peaks Field
                    for kk = 1:length(level_1)
                        dummy_data = cell2mat(cellfun(@(x) max(x,[],1),storm.(level_1{kk}).('Timeseries')(:,2), 'un', false));
                        storm.(level_1{kk}).('Peaks').('Maxima') = [dummy_data(:,2:5),cell2mat(storm.(level_1{kk}).('Timeseries')(:,1)),dummy_data(:,1)];
                    end
                    % Get Storm Sampling Using Peaks Files
                    [aux_var] = call_stormsim_mcs(config, storm, prob_mass);
                    % Do you want to use timeseries
                    [project_forcing.(storm_sampling).Timeseries]=call_stormsim_mcs_timeseries(aux_var, storm, prob_mass, storm_sampling);
                end
                % Save Peaks Life Cycle Structures
                save([save_name '_' wName '_project_forcing.mat'],'project_forcing','-v7.3');
            end
        else
            % Call StormSim: Monte Carlo Storm Sampler
            if use_peaks == 1
                % Get Storm Sampling Using Peaks Files
                [project_forcing] = call_stormsim_mcs(config, storm, prob_mass);
                % Do you want to use timeseries
                if use_timeseries == 1 % Timeeseries follows the same sampling scheme as Maxima Peaks dataset
                    [project_forcing.(storm_sampling).Timeseries]=call_stormsim_mcs_timeseries(project_forcing, storm, prob_mass, storm_sampling);
                end
            else % Timeseries Only
                % Get Storm Types In Data
                level_1 = fieldnames(storm);
                % Create Dummy Peaks Field
                for kk = 1:length(level_1)
                    dummy_data = cell2mat(cellfun(@(x) max(x,[],1),storm.(level_1{kk}).('Timeseries')(:,2), 'un', false));
                    storm.(level_1{kk}).('Peaks').('Maxima') = [dummy_data(:,2:5),cell2mat(storm.(level_1{kk}).('Timeseries')(:,1)),dummy_data(:,1)];
                end
                % Get Storm Sampling Using Peaks Files
                [aux_var] = call_stormsim_mcs(config, storm, prob_mass);
                % Do you want to use timeseries
                [project_forcing.(storm_sampling).Timeseries]=call_stormsim_mcs_timeseries(aux_var, storm, prob_mass, storm_sampling);
            end
            % Save Peaks Life Cycle Structures
            save([save_name '_' wName '_project_forcing.mat'],'project_forcing','-v7.3');
        end
end
end