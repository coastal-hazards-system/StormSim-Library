function lcs_damage_analysis_plots(project_forcing, Resp, dmg_type, storm_type, nYears, S_bin_edges, S_bin_x_ticks, S_bin_x_ticks_labels, S_bin_cb_ticks, S_bin_cb_lim, cmap_to_use)
%% PROCESS DAMAGE CURVES
% Define Damage Variables To Call
switch dmg_type
    case 'leeside'
        dmg_vars = {'S_leeside_no_repairs','SLee_no_repairs', 'LSmax'};
        x_label = 'S Leeside';
    case 'seaside'
        dmg_vars = {'S_seaside_no_repairs','Ssea_no_repairs', 'Smax'};
        x_label = 'S Seaside';
end
% Get StormSim: LCS Forcing Data (project_forcing)
stm_data = project_forcing.(storm_type).Timeseries;
% Point towards diagnostics data
diag_data = Resp.(storm_type).Timeseries.S.diagnostics;
% Get StormSim: LCS S Outputs
resp = Resp.(storm_type).Timeseries.S;
% Find The Maximum Accumulated Damage At The End Of All LC's
s_max = cellfun(@(x) x(end),resp.(dmg_vars{1}));
% Get Cummulative Mean Maximum Damage (S)
Smax = resp.(dmg_vars{3});
% Find Damaging And Submergance Instances
[C,ia,ic] = cellfun(@(x) unique(x.(dmg_vars{2}),'stable'), diag_data, 'un', false);
% Remove Zero Damage Instances
ia = cellfun(@(x,y) x(y),ia,cellfun(@(x) x~=0,C,'un',false),'un',false);
% Extract Damaging Instances
dmg_events = cellfun(@(x,y) x(y,:), diag_data, ia, 'un',false);
% Find Instances Where Rc < 0
dmg_events_bool = cellfun(@(x) x.Rc<0, dmg_events,'un',false);
% Find Total Number Of Submerged Damaging Timesteps
dmg_events_len = cellfun(@length, dmg_events_bool);
% Sum total Number Of Submerged Damaging Instances
dmg_events_sub = cellfun(@sum, dmg_events_bool);
% Compute Percentage
dmg_events_sub_percent = cell2mat(arrayfun(@(x, y) 100.*x./y, dmg_events_sub,dmg_events_len,'un',false));
% Bin Storms Rc By Year And LC
[,~,~,Rc_binning] = compute_lcs_yearly_curve({stm_data.LCNUM}, cellfun(@(x) x.Rc, resp.diagnostics, 'un', false), nYears);

%% FIGURE 2: PLOT Damaging Events Submergance Percentage
figure('Units','Normalized','Position',[0.15078125,0.165972222222222,0.3328125,0.459027777777778]);
hh = histogram(dmg_events_sub_percent,'DisplayName','Submerged Damaging Instances','FaceColor','g','FaceAlpha',1);hold(hh.Parent,'on');
title(hh.Parent,'Distribution of Damaging Instances Submergance Status (Rc<0)');
xlabel(hh.Parent ,'Percentage of Total Damaging Timesteps');
ylabel(hh.Parent ,'Number of Life Cycles');
hh = histogram(100-dmg_events_sub_percent, 'DisplayName','Emergent Damaging Instances','FaceColor','r','FaceAlpha',0.5);
lg = legend(hh.Parent, 'Location', 'northoutside','Orientation','horizontal');
set(gca, 'FontSize',16, 'FontWeight', 'bold','XGrid','on','XMinorGrid','on','YGrid','on','YMinorGrid','on','Box','on');
hold(hh.Parent,'off');

% Plot Total Damage Events Accross LC's
figure('Units','Normalized','Position',[0.15078125,0.165972222222222,0.30234375,0.403472222222222]);
hh = histogram(dmg_events_len);
title(hh.Parent,'Total Damaging Instances On StormSim:LCS-CSR Simulation');
xlabel(hh.Parent ,'Total Number Of Damaging Timesteps Across LCs');
ylabel(hh.Parent ,'Number of Life Cycles');
set(gca, 'FontSize',16, 'FontWeight', 'bold','XGrid','on','XMinorGrid','on','YGrid','on','YMinorGrid','on','Box','on');

%% PLOT: STRUCTURE SUBMERGANCE (Per LCs)
% Compute Total Number Of Timesteps Accross Each Life Cycle
base_len = cellfun(@length, Rc_binning);base_len(base_len == 1) = 0;
base_len = sum(base_len, 1); % Replace NaN entries With 0 length
% Compute Percentage of Submergance Across All LCs
dummy2 = 100.*sum(cell2mat(cellfun(@(x) sum(x<0),Rc_binning,'un',false)),1)./base_len;
% Initialize Figure
figure('Units','Normalized','Position',[0.15078125,0.165972222222222,0.2796875,0.360416666666667]);
% Initialize Axes
ax = axes('FontSize',16, 'FontWeight', 'bold','XGrid','on','XMinorGrid',...
    'on','YGrid','on','YMinorGrid','on','Box','on');
% Hold Properties
hold(ax, 'on');
% Add Labels
ax.XLabel.String = 'Total Submergance Percentage Accross LCs';
ax.YLabel.String = 'Number Of Life Cycles';
% Histogram
hh = histogram(dummy2);

%% PLOT: STRUCTURE SUBMERGANCE (Yearly)
% Compute Total Number Of Timesteps Accross Each Life Cycle
base_len = cellfun(@length, Rc_binning);base_len(base_len == 1) = 0;
base_len = sum(base_len, 2); % Replace NaN entries With 0 length
% Compute Percentage of Submergance Across All LCs
dummy2 = 100.*sum(cell2mat(cellfun(@(x) sum(x<0),Rc_binning,'un',false)),2)./base_len;
% Initialize Figure
figure('Units','Normalized','Position',[0.15078125,0.165972222222222,0.337890625,0.395833333333333]);
% Initialize Axes
ax = axes('FontSize',16, 'FontWeight', 'bold','XGrid','on','XMinorGrid',...
    'on','YGrid','on','YMinorGrid','on','Box','on');
% Hold Properties
hold(ax, 'on');
% Add Labels
ax.YLabel.String = 'Total Yearly Submergance Percentage';
ax.XLabel.String = 'Simulation Year';
% Histogram
hh = plot(1:nYears,dummy2,'-k','LineWidth',1.5,'DisplayName','Yearly Submergance %');
plot([1, nYears], [mean(dummy2), mean(dummy2)],'DisplayName',['Mean Yearly Submergance % (' num2str(round(mean(dummy2),2)) '%)']);
legend('Location','northoutside','Orientation','horizontal');

%% PLOT S DAMAGE ASSESMENT
figure('Units','Normalized','Position',[0.15078125,0.165972222222222,0.696875,0.480555555555556]);
ax1 = subplot(1,3,1);hold(ax1, 'on');
xlabel(ax1, 'Sim Year');ylabel(ax1, 'Yearly Maximum Mean Cummulative Damage');
plot(ax1, 0:nYears,Smax,'-k','LineWidth',1.5,'DisplayName',['S_{@' num2str(nYears) 'yr}=' num2str(round(Smax(end),3))]);
legend(ax1,'Location','northwest');
title(ax1, 'Yearly Maximum Mean Cummulative Damage');
set(ax1, 'FontSize',13, 'FontWeight', 'bold','XGrid','on','XMinorGrid','on','YGrid','on','YMinorGrid','on','Box','on');

ax2 = subplot(1,3,2);hold(ax2, 'on');
xlabel(ax2, 'Life Cycle');ylabel(ax2, 'Maximum Cummulative Damage');
plot(ax2, 1:length(s_max), s_max,'-r','LineWidth',1.5,'DisplayName','S_{max} per LC');
plot(ax2, [1,length(s_max)], [mean(s_max), mean(s_max)],'--k','LineWidth',2, 'DisplayName', ['S_{mean}=' num2str(round(mean(s_max),3))]);
legend(ax2);
title(ax2,'Maximum Cummulative Damage Per LC');
set(ax2, 'FontSize',13, 'FontWeight', 'bold','XGrid','on','XMinorGrid','on','YGrid','on','YMinorGrid','on','Box','on');

% Initialize Axis
ax3 = subplot(1,3,3);
% Format Axis
set(ax3, 'FontSize',13, 'FontWeight', 'bold','XGrid','on','XMinorGrid','on','YGrid','on','YMinorGrid','on','Box','on');
% Populate Bin Plot
ax3 = lcs_bin_plot(ax3, stm_data, cellfun(@(x) struct('LCNUM',x),resp.(dmg_vars{1})','un',true),...
    nYears, x_label, S_bin_edges, 'percent', 0,...
    S_bin_x_ticks, S_bin_x_ticks_labels, S_bin_cb_ticks, S_bin_cb_lim, cmap_to_use, 1);
% Remove Hold Properties
hold(ax1, 'off');
hold(ax2, 'off');
end