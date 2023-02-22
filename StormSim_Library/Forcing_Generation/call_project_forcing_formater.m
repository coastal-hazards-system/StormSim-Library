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
workflow = config.cast_workflow;
% Define Storm Type ('XC' or 'TC')
storm_sampling = config.storm_sampling;
% Deifne Use Timeseries Flag
use_timeseries = config.use_timeseries;

%% FORMAT FORCING DATA ACCORDING TO WORKFLOW
% Prompt User
disp('Preping project forcing data....');
% Define Events Per Case
switch workflow
    case 1 % StormSim: PROS (Ressonse Base (RB1) Analysis)
        % Define Workflow Key Phrase
        wName = 'RB';
        % Tropical Cyclones
        if contains(storm_sampling,{'TC','CC'})
            % Reshape Forcing Parameters For RB Analysis (nStorms * normal_discretizations)
            project_forcing.('TC') = rb_forcing_formater(config, 'TC', storm.('TC'), prob_mass);
        end
        % Extratropical Storms
        if contains(storm_sampling,{'XC','CC'})
            % Reshape Forcing Parameters For RB Analysis (nStorms * normal_discretizations)
            project_forcing.('XC') = rb_forcing_formater(config, 'XC', storm.('XC'), []);
        end
    case {2,3} % StormSim: MCS/CSR (Life-Cycle Base Analysis)
        % Define Workflow Key Phrase
        wName = 'LCS';
        % Call StormSim: Monte Carlo Storm Sampler
        [project_forcing] = call_stormsim_mcs(config, storm, prob_mass);
        % Do you want to use timeseries
        if use_timeseries == 1 % Timeeseries follows the same sampling scheme as Maxima Peaks dataset
            [project_forcing.(storm_sampling).Timeseries]=call_stormsim_mcs_timeseries(project_forcing, storm, prob_mass, storm_sampling);
        end
end

%% EXPORT OUTPUTS
% Define Save Name
save_name = [config.project_name, filesep, config.struc_id, filesep,...
    config.project_name,'_', config.struc_id];
% Save Peaks Life Cycle Structures
save([save_name '_' wName '_project_forcing.mat'],'project_forcing','-v7.3');

end