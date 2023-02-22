function [LC_SimOUT_hyd]=call_stormsim_mcs_timeseries(project_forcing, storm, prob_mass, storm_sampling)


%{
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
            (10) Year Storm Occoured      [years]


%}
%% DEFINE INPUTS
if contains(storm_sampling,{'TC','CC'})
    % Tropical Cyclones Sampled INtensity Vector
    tc_intensity = project_forcing.('TC').Peaks.TC_iclass; % 0 - Low 1 - High
else
    tc_intensity = [];
end
% MCS Sampling Scheme Per LC [ sampled_year, sampled_storm_type, storm_oucrrence_order @ sampled_year, storm_ID]
sampled_storms_indx = project_forcing.(storm_sampling).Peaks.sampled_storms_indx; %


% Create Status Message
msg = sprintf(['   Running life cycle timeseries generator....' newline]);
% Print Message
fprintf(msg);
% Print Completion Progress
fprintf(1,'      Completion Progress: %3d%%\n',0);
% Intialize Storage Variable
LC_SimOUT_hyd = [];
% Loop Through All LCs
for nLC = 1:length(sampled_storms_indx)
    % Loop Through Each Storm in LC
    data_2 = arrayfun(@(w,x,y,z) mcs_timeseries_life_cycle_formater(w,x,y,z,storm,prob_mass,tc_intensity(nLC).LCNUM),...
        sampled_storms_indx(nLC).LCNUM(:,1),sampled_storms_indx(nLC).LCNUM(:,2),...
        sampled_storms_indx(nLC).LCNUM(:,3),sampled_storms_indx(nLC).LCNUM(:,4),'un',false);
    %
    LC_SimOUT_hyd(nLC,1).LCNUM = cell2mat(data_2);
    %% PROGRESS BAR
    fprintf(1,'\b\b\b\b%3.0f%%',(100*(nLC/length(sampled_storms_indx))));
end % end of nLC's Loop
fprintf(1,['\b\b\b\b%3.0f%%' newline],(100*(nLC/length(sampled_storms_indx))));
end