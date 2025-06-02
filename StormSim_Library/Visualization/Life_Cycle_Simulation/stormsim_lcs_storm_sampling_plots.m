function tc_sampled_srr = stormsim_lcs_storm_sampling_plots(project_forcing, storm_type)
%% GET INPUTS
% Make Sure To Exit Of XC Only
switch storm_type
    case 'XC'
        error('Unsupported storm type. Must be TC or CC.');
end
% Grab Peaks Data
data = project_forcing.(storm_type).Peaks.Maxima;

%% COMPUTE STORM RECURRENCE RATES OF SAMPLED TCs & TC CLASS DISTRIBUTION
% Get TC Sampled Intensities
tc_iclass = {project_forcing.TC.Peaks.TC_iclass.LCNUM};
% Get Number Of Storms Per LC
tc_stms_per_lc = cellfun(@length, {project_forcing.TC.Peaks.Maxima.LCNUM},'un',true)';
% Compute Average N Events Per LC
stms_per_lc = mean(cellfun(@length, {data.LCNUM},'un',true));
% Compute Rates
tc_sampled_srr = [mean(cellfun(@(x) sum(x==0), tc_iclass,'un',true)'./tc_stms_per_lc),...
    mean(cellfun(@(x) sum(x==2), tc_iclass,'un',true)'./tc_stms_per_lc),...
    mean(cellfun(@(x) sum(x==1), tc_iclass,'un',true)'./tc_stms_per_lc)];
% Compute Total Sampled SRR
tc_sampled_srr = [tc_sampled_srr, sum(tc_sampled_srr)];


%% PLOT STORM SAMPLING BAR PLOT (TCs & XCs)
switch storm_type
    case 'TC'
        % Get Tropical Cyclone Intensity Distribution
        N_TCs = sum([cellfun(@(x) sum(x==0), tc_iclass,'un',true)',...
            cellfun(@(x) sum(x==2), tc_iclass,'un',true)',...
            cellfun(@(x) sum(x==1), tc_iclass,'un',true)'],1);
        N_XCs = 0;
    case 'CC'
        N_TCs = sum([cellfun(@(x) sum(x==0), tc_iclass,'un',true)',...
            cellfun(@(x) sum(x==2), tc_iclass,'un',true)',...
            cellfun(@(x) sum(x==1), tc_iclass,'un',true)'],1);
        N_XCs = sum(cellfun(@length, {project_forcing.XC.Peaks.Maxima.LCNUM},'un',true));
end
% Create Plot Variables
y_data = 100.*[N_TCs,N_XCs]./sum([N_TCs,N_XCs]);
x_data = categorical({'TC Low','TC Mid','TC High','XC'});
% Initialize Figure
figure('Units','normalized','Position',[0.268359375,0.177777777777778,0.406640625,0.511805555555556]);
% Format Axes
set(gca, 'FontSize',16, 'FontWeight', 'bold','XGrid','on','XMinorGrid',...
    'on','YGrid','on','YMinorGrid','on','Box','on');hold(gca, 'on');
%
ylabel(gca, 'Storm Type Distribution %');
% Generate Bar Plot
bar(x_data, y_data);
% Add Text On Top
for gg = 1:length(x_data)
    text(x_data(gg),...
        y_data(gg),...
        [num2str(y_data(gg) ,'%0.2f') ' %'],...
        'HorizontalAlignment','center',...
        'VerticalAlignment','bottom','FontWeight','bold','FontSize',14);
end
% Title
title({'StormSim: LCS Storm Sampling Distribution Over Entire Simulation',...
    ['Total Number of Storms (N): ' num2str(sum([N_TCs,N_XCs])) ' (N_{mean} per LC: ' num2str(round(stms_per_lc,1)) ')']});
end