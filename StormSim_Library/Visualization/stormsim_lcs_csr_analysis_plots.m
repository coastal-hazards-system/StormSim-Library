clc; clear all;close all;

%% DEFINE INPUTS
% Define Simulation Years
nYears =  50; % Must be the same as the loaded data
dmg_type = 'leeside';%'seaside'
storm_type = 'CC'; % Storm Sampling Done
% Resp File 
resp_file = ['StormSim_Outputs\Deer_Island\Transect_001\Optimized_Stone_Size_S_' num2str(1) '\Life_Cycle_Simulation\Deer_Island_Transect_001_Optimized_Stone_Size_S_' num2str(1) '_LCS_project_responses.mat'];
% project_forcing file 
project_forcing_file = ['StormSim_Outputs\Deer_Island\Transect_001\Optimized_Stone_Size_S_'  num2str(1) '\Deer_Island_Transect_001_LCS_project_forcing.mat'];
% Want To Remove 0 From q debug histograms (Final Section)
zero_rm = 0;
% PCOLOR Axes Set-up
cmap_to_use = []; % Empty uses custom jet map | 'Jet', 'Parula', ...
% SWL
swl_ax_setup.('bin_edges') = 0:0.1:7; 
swl_ax_setup.('x_ticks') = 0:7;
swl_ax_setup.('x_ticks_labels') = cellfun(@num2str,num2cell(swl_ax_setup.('x_ticks')),'un',false);
swl_ax_setup.('counts_cb_ticks') = [];
swl_ax_setup.('counts_cb_limits') = [0 200];
swl_ax_setup.('perc_cb_limits') = [0 15];
swl_ax_setup.('perc_cb_ticks') = [0 1 5 10 15];
% Hm0
hm0_ax_setup.('bin_edges') = 0:0.1:5; 
hm0_ax_setup.('x_ticks') = 0:5;
hm0_ax_setup.('x_ticks_labels') = cellfun(@num2str,num2cell(hm0_ax_setup.('x_ticks') ),'un',false);
hm0_ax_setup.('counts_cb_ticks') = [];
hm0_ax_setup.('counts_cb_limits') = [0 200];
hm0_ax_setup.('perc_cb_limits') = [0 15];
hm0_ax_setup.('perc_cb_ticks') = [0 1 5 10 15];
% q Set-up (combined and wave ot)
q_ax_setup.('bin_edges') =  unique([0, logspace(-4,-3,10),...
logspace(-3,-2,10),...
logspace(-2,-1,10),...
logspace(-1,0,10),...
logspace(0,1,10), Inf]);
q_ax_setup.('x_ticks') = [0 10^-4, 10^-3, 10^-2, 10^-1, 10^0, 10^1, 25];
q_ax_setup.('x_ticks_labels') = {'0','10^{-4}','10^{-3}','10^{-2}','10^{-1}','1', '10^1', 'Inf'};
q_ax_setup.('counts_cb_ticks') = [];
q_ax_setup.('counts_cb_limits') = [0 150];
q_ax_setup.('perc_cb_ticks') = [0 1 5 10 15];
q_ax_setup.('perc_cb_limits') = [0 15];
% S Set-up
S_ax_setup.('bin_edges') = unique([0:0.5:20, Inf]);
S_ax_setup.('x_ticks') = [0:2:20,20+0.2];
S_ax_setup.('x_ticks_labels') = cellstr(num2str(S_ax_setup.('x_ticks')'));
S_ax_setup.('perc_cb_ticks') = [0 1 5 10 15];
S_ax_setup.('perc_cb_limits') = [0 15];

%% Load Project Forcing & Resp
load(resp_file);
load(project_forcing_file);

%% LCS SAMPLING 
[sampled_TC_SRR] = stormsim_lcs_storm_sampling_plots(project_forcing, storm_type);

%% CREATE LCS DAMAGE PLOTS
lcs_damage_analysis_plots(project_forcing, Resp, dmg_type, storm_type, nYears,...
    S_ax_setup.('bin_edges'), S_ax_setup.('x_ticks'), S_ax_setup.('x_ticks_labels'),...
    S_ax_setup.('perc_cb_ticks'), S_ax_setup.('perc_cb_limits'), cmap_to_use);

%% SWL 2D HISTOGRAM 
% Create Aux Var
aux_var = cellfun(@(x) x(:, 5), {project_forcing.(storm_type).Timeseries.LCNUM},'un',false)';
aux_var = cellfun(@(x) struct('LCNUM',x), aux_var, 'un', true);
% Initialize Figure
figure('Units','Normalized','Position',[0.15078125,0.165972222222222,0.7140625,0.5625]);
% Initialize Subplot
ax1 = subplot(1,2,1);
% Add Title
title(ax1,'SWL Distribution By Sim Year (Percent)');
% Plot 2D Histogram (Percent)
[ax1,~,~,~] = lcs_bin_plot(ax1, project_forcing.(storm_type).Timeseries, aux_var,...
    nYears, 'SWL [m]', swl_ax_setup.('bin_edges'), 'percent', 0,...
    swl_ax_setup.('x_ticks'), swl_ax_setup.('x_ticks_labels'),...
    swl_ax_setup.('perc_cb_ticks'), swl_ax_setup.('perc_cb_limits'), cmap_to_use, 1);
% Initialize Subplot
ax2 = subplot(1,2,2);
% Add Title
title(ax2,'SWL Distribution By Sim Year (Counts)');
% Plot 2D Histogram (Counts)
[ax2,~,~,~] = lcs_bin_plot(ax2, project_forcing.(storm_type).Timeseries, aux_var,...
    nYears, 'q [m^3/s per m]', swl_ax_setup.('bin_edges'), 'count', 0,...
    swl_ax_setup.('x_ticks'), swl_ax_setup.('x_ticks_labels'),...
    swl_ax_setup.('counts_cb_ticks'), swl_ax_setup.('counts_cb_limits'), cmap_to_use, 1);

%% Hm0 2D HISTOGRAM
% Create Aux Var
aux_var = cellfun(@(x) x(:, 6), {project_forcing.(storm_type).Timeseries.LCNUM},'un',false)';
aux_var = cellfun(@(x) struct('LCNUM',x), aux_var, 'un', true);
% Initialize Figure
figure('Units','Normalized','Position',[0.15078125,0.165972222222222,0.7140625,0.5625]);
% Initialize Subplot
ax1 = subplot(1,2,1);
% Add Title
title(ax1,'Hm0 Distribution By Sim Year (Percent)');
% Plot 2D Histogram (Percent)
[ax1 ,~,~,~] = lcs_bin_plot(ax1, project_forcing.(storm_type).Timeseries, aux_var,...
    nYears, 'Hm0 [m]', hm0_ax_setup.('bin_edges'), 'percent', 0,...
    hm0_ax_setup.('x_ticks'), hm0_ax_setup.('x_ticks_labels'),...
    hm0_ax_setup.('perc_cb_ticks'), hm0_ax_setup.('perc_cb_limits'), cmap_to_use, 1);
% Initialize Subplot
ax2 = subplot(1,2,2);
% Add Title
title(ax2,'Hm0 Distribution By Sim Year (Counts)');
% Plot 2D Histogram (Counts)
[ax2 ,~,~,~] = lcs_bin_plot(ax2, project_forcing.(storm_type).Timeseries, aux_var,...
    nYears, 'hm0 [m]', hm0_ax_setup.('bin_edges'), 'count', 0,...
    hm0_ax_setup.('x_ticks'), hm0_ax_setup.('x_ticks_labels'),...
    hm0_ax_setup.('counts_cb_ticks'), hm0_ax_setup.('counts_cb_limits'), cmap_to_use, 1);

%% q 2D HISTOGRAM
% ------------- q Combined ----------------------
% Initialize Figure
figure('Units','Normalized','Position',[0.15078125,0.165972222222222,0.7140625,0.5625]);
% Initialize Subplot
ax1 = subplot(1,2,1);
% Add Title
title(ax1,'q Distribution By Sim Year (Percent)');
% Plot 2D Histogram (Percent)
[ax1 ,~,~,~] = lcs_bin_plot(ax1, project_forcing.(storm_type).Timeseries, Resp.(storm_type).Timeseries.q,...
    nYears, 'q [m^3/s per m]', q_ax_setup.('bin_edges'), 'percent', 1,...
    q_ax_setup.('x_ticks'), q_ax_setup.('x_ticks_labels'),...
    q_ax_setup.('perc_cb_ticks'), q_ax_setup.('perc_cb_limits'), cmap_to_use, 1);
% Count Plot
ax2 = subplot(1,2,2);
% Add Title
title(ax2,'q Distribution By Sim Year (Counts)');
% Plot 2D Histogram (Counts)
[ax2 ,~,~,~] = lcs_bin_plot(ax2, project_forcing.(storm_type).Timeseries, Resp.(storm_type).Timeseries.q,...
    nYears, 'q [m^3/s per m]', q_ax_setup.('bin_edges'), 'count', 1,...
    q_ax_setup.('x_ticks'), q_ax_setup.('x_ticks_labels'),...
    q_ax_setup.('counts_cb_ticks'), q_ax_setup.('counts_cb_limits'), cmap_to_use, 1);

%% q Distribution Debug
% Grab LC q Data
q_data = {Resp.(storm_type).Timeseries.q.LCNUM}; % Combined 
q_wave_ot = {Resp.(storm_type).Timeseries.q_wave_ot.LCNUM}; % Wave Overtopping 
q_overflow = cellfun(@(x,y) x-y,q_data,q_wave_ot,'un',false)'; % Overflow ( q - q_wave_ot )
% Bin Max q Responses Per Storm At Each Simulation Year Through All LC's
[~,~,qyBox,~] = compute_lcs_yearly_curve_fgm({project_forcing.(storm_type).Timeseries.LCNUM}, q_data, nYears, 0);
[~,~,q_wave_yBox,~] = compute_lcs_yearly_curve_fgm({project_forcing.(storm_type).Timeseries.LCNUM}, q_wave_ot, nYears, 0);
[~,~,q_of_yBox,~] = compute_lcs_yearly_curve_fgm({project_forcing.(storm_type).Timeseries.LCNUM}, q_overflow, nYears, 0);
% Make Yearly q Max Responses Distribution
q_data_debug = NaN(nYears, max(cellfun(@length, qyBox)));
q_wave_debug = NaN(nYears, max(cellfun(@length, q_wave_yBox)));
q_overflow_debug = NaN(nYears, max(cellfun(@length, q_of_yBox)));
% Reshape Resulting Binning Into Data Matrix
for mm = 1:nYears
    % Compute Histogram Count For All Storm At Year N
    q_data_debug(mm, 1:length(qyBox{mm})) = qyBox{mm};
    q_wave_debug(mm, 1:length(qyBox{mm})) = q_wave_yBox{mm};
    q_overflow_debug(mm, 1:length(qyBox{mm})) = q_of_yBox{mm};
end
% Remove Zeros If Needed
if zero_rm == 1
    q_data_debug(q_data_debug == 0) = NaN;
    q_wave_debug(q_wave_debug == 0) = NaN;
    q_overflow_debug(q_overflow_debug == 0) = NaN;
end
% Create Histogram Plots
% ---- q_combined ---------
% Initialize Figure 
figure;
% Initialize Axis 
ax = gca;
% Set Properties
set(ax,'FontSize',16, 'FontWeight', 'bold','XGrid','on','XMinorGrid',...
    'on','YGrid','on','YMinorGrid','on','Box','on');
% Hold
hold(ax, 'on');
% Create q combined histogram
h1 = histogram(q_data_debug,q_ax_setup.('bin_edges'),'DisplayName','q combined','FaceColor','b');
% Replace 0 Bin With 10^-5
h1.BinEdges(1) = 10^-5;
% Replace Bin Tick Mark 
ax.XTickLabel(1) = {'0'};
% Title And Labels
title('Overtopping Discharge Rate Year Peak Distributions');
xlabel('q bin [m^3/s per m]');
ylabel('Count');

% ------- q_wave -----------
% Create Invisible Figure To Append New Histogram
fig2 = figure('Visible','off');
% Create Histogram
h2 = histogram(q_wave_debug,q_ax_setup.('bin_edges'),'DisplayName','q wave ot','FaceColor','g');
% Replace 0 Bin 
h2.BinEdges(1) = 10^-5;
% Append To Initial Axes
copyobj(h2,ax);

% ----------- q Overflow -----------
% Create Invisible Figure To Append New Histogram
fig3 =  figure('Visible','off');
% Create Histogram
h3 = histogram(q_overflow_debug,q_ax_setup.('bin_edges'),'DisplayName','q overflow','FaceColor','r');
% Replace 0 Bin 
h3.BinEdges(1) = 10^-5;
% Append To Initial Axes
copyobj(h3,ax);

set(ax, 'XScale','log');
close(fig2);close(fig3);
lg = legend(ax);
lg.Location = 'northoutside';
lg.Orientation = 'hoirzontal';

%% SWL & Hm0 Debug Distributions
% Bin Max SWL & Hm0 Responses Per Storm At Each Simulation Year Through All LC's
[swlmax,~,swlyBox,swldbug] = compute_lcs_yearly_curve_fgm({project_forcing.CC.Timeseries.LCNUM}, cellfun(@(x) x(:,5), {project_forcing.CC.Timeseries.LCNUM}, 'un', false), nYears, 0);
[hm0max,~,hm0yBox,hm0dbug] = compute_lcs_yearly_curve_fgm({project_forcing.CC.Timeseries.LCNUM}, cellfun(@(x) x(:,6), {project_forcing.CC.Timeseries.LCNUM}, 'un', false), nYears, 0);
% Reshape Resulting Binning Into Data Matrix
for mm = 1:nYears
% Compute Histogram Count For All Storm At Year N
swl_data_debug(mm, 1:length(swlyBox{mm})) = swlyBox{mm};
hm0_data_debug(mm, 1:length(hm0yBox{mm})) = hm0yBox{mm};
end
% Create Histogram Plots
figure;
histogram(swl_data_debug);
title('Peak SWL Distribution For Complete Simulation');
xlabel('SWL [m]');
ylabel('Count');
figure;
histogram(hm0_data_debug);
title('Peak Hm0 Distribution For Complete Simulation');
xlabel('Hm0 [m]');
ylabel('Count');
