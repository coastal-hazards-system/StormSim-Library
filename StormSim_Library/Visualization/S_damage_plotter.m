function S_damage_plotter(config, TimeSeries, pctl, show_figs)
disp('Plotting StormSim: CSR - Damage Progression Analysis outputs... ');
%% GRAB DETAILS FROM "config"
% Define Project CHS Region
loc = config.region;
% Define Savepoint ID
spoint = config.sp_ID;
% Define Percentiles 
prc = strsplit(config.project_CLs(2:end-1),{' '});
% Define Simulation Length 
nyears = [0:config.mcs_nYears];
% Output Save Dir
outDir = [config.project_name, filesep, config.struc_id, filesep,...
    config.project_name,'_', config.struc_id];
% Make Figures Visibles/Invisible
if show_figs==1
    fig_stat = 'on';
else
    fig_stat = 'off';
end

%% EXTRACT FIELDS FROM DATA STRUCTURE
% if repair_switch==1
% Seaside Damage All LC's
Ssea_All_LC = TimeSeries.S_seaside_with_repairs;
% Leeside Damage All LC's
Slee_All_LC = TimeSeries.S_leeside_with_repairs;
% else
% Seaside Damage All LC's
Ssea_All_LC_no = TimeSeries.S_seaside_no_repairs;
% Leeside Damage All LC's
Slee_All_LC_no = TimeSeries.S_leeside_no_repairs;
% end
% Seaside Yearly Maximum Averages
Smax = TimeSeries.Smax;
%Leeside Yearly Maximum Averages
LSmax = TimeSeries.LSmax;
% Seaside Yearly Maximum Averages Percentile Curves
SPcurves = TimeSeries.SPcurves;
% Leeside Yearly Maximum Averages Percentile Curves
LSPcurves = TimeSeries.LSPcurves;

%
% PLOT SEASIDE DAMAGE FOR ALL LC'S
% Seaside Damage Figure Setup
fig1 = figure('Name','Seaside Damage (All LC)','units','normalized','outerposition',[0 0 1 1],'visible',fig_stat);
ax1=gca;
set(ax1,'FontSize',18,'FontWeight','bold');
xlabel(ax1,{'Cumulative Storm Hours'},'FontSize',20,'Interpreter','Latex');
ylabel(ax1,{'Cummulative Damage [S]'},'FontSize',20,'Interpreter','Latex');
title(ax1,{'Seaside Damage Progession (with Repairs) of Rubble Mound Structure';...
    ['Location: ',loc,', Save Point: ',num2str(spoint),'']},'FontSize',24,'FontWeight','bold');
box(ax1,'on');
grid(ax1,'on');
grid(ax1,'minor');
hold(ax1,'on');

cellfun(@(x) plot(ax1,[1:size(x,1)],x,'LineWidth',1.5),Ssea_All_LC,'UniformOutput',false);% Plot Damage

%% PLOT LEESIDE DAMAGE FOR ALL LC'S
% Leeside Damage Figure Setup
fig2 = figure('Name','Leeside Damage (All LC)','units','normalized','outerposition',[0 0 1 1],'visible',fig_stat);
ax2=gca;
set(ax2,'FontSize',18,'FontWeight','bold');
xlabel(ax2,{'Cumulative Storm Hours'},'FontSize',20,'Interpreter','Latex');
ylabel(ax2,{'Cumulative Damage $\bar{S}$'},'FontSize',20,'Interpreter','Latex');
title(ax2,{'Leeside Damage Progession (with Repairs) of Rubble Mound Structure';...
    ['Location: ',loc,', Save Point: ',num2str(spoint),'']},'FontSize',24,'FontWeight','bold');
box(ax2,'on');
grid(ax2,'on');
grid(ax2,'minor');
hold(ax2,'on');

cellfun(@(x) plot(ax2,[1:size(x,1)],x,'LineWidth',1.5),Slee_All_LC,'UniformOutput',false);% Plot Damage

%% PLOT SEASIDE DAMAGE FOR ALL LC'S (No repairs)
% Seaside Damage Figure Setup
fig5 = figure('Name','Seaside Damage (All LC)','units','normalized','outerposition',[0 0 1 1],'visible',fig_stat);
ax1=gca;
set(ax1,'FontSize',18,'FontWeight','bold');
xlabel(ax1,{'Cumulative Storm Hours'},'FontSize',20,'Interpreter','Latex');
ylabel(ax1,{'Cummulative Damage [S]'},'FontSize',20,'Interpreter','Latex');
title(ax1,{'Seaside Damage Progession (No Repairs) of Rubble Mound Structure';...
    ['Location: ',loc,', Save Point: ',num2str(spoint),'']},'FontSize',24,'FontWeight','bold');
box(ax1,'on');
grid(ax1,'on');
grid(ax1,'minor');
hold(ax1,'on');

cellfun(@(x) plot(ax1,[1:size(x,1)],x,'LineWidth',1.5),Ssea_All_LC_no,'UniformOutput',false);% Plot Damage

%% PLOT LEESIDE DAMAGE FOR ALL LC'S (No Repairs)
% Leeside Damage Figure Setup
fig6 = figure('Name','Leeside Damage (All LC)','units','normalized','outerposition',[0 0 1 1],'visible',fig_stat);
ax2=gca;
set(ax2,'FontSize',18,'FontWeight','bold');
xlabel(ax2,{'Cumulative Storm Hours'},'FontSize',20,'Interpreter','Latex');
ylabel(ax2,{'Cumulative Damage $\bar{S}$'},'FontSize',20,'Interpreter','Latex');
title(ax2,{'Leeside Damage Progession (No Repairs) of Rubble Mound Structure';...
    ['Location: ',loc,', Save Point: ',num2str(spoint),'']},'FontSize',24,'FontWeight','bold');
box(ax2,'on');
grid(ax2,'on');
grid(ax2,'minor');
hold(ax2,'on');

cellfun(@(x) plot(ax2,[1:size(x,1)],x,'LineWidth',1.5),Slee_All_LC_no,'UniformOutput',false);% Plot Damage

%% SEASIDE YEARLY VALUES PLOTS
% Figure Setup
fig3 = figure('Name','Seaside Damage (Mean)','units','normalized','outerposition',[0 0 1 1],'visible',fig_stat);
ax3=gca;
set(ax3,'FontSize',18,'FontWeight','bold');
xlabel(ax3,{'Years'},'FontSize',20,'Interpreter','Latex');
ylabel(ax3,{'Yearly Mean Maximum Cummulative Damage $\bar{S}$'},'FontSize',20,'Interpreter','Latex');
title(ax3,{'Seaside Damage Progession of Rubble Mound Structure';...
    ['Location: ',loc,', Save Point: ',num2str(spoint),'']},'FontSize',24,'FontWeight','bold');
box(ax3,'on');grid(ax3,'on');
hold(ax3,'on');grid(ax3,'minor');

% Plot
plot(ax3,nyears,Smax,'--k','LineWidth',2,'DisplayName','$\bar{S}$');% Plot Damage
if pctl==1
    cellfun(@(x,y) plot(ax3, nyears, SPcurves(:,x),'LineWidth',2,'DisplayName',['Percentile: ',y,' \%']),num2cell(1:length(prc)),prc,'un',false);
    legend(ax3,'Location','Best','Interpreter','Latex');
end



%% LEESIDE YEARLY VALUES PLOTS
% Figure Setup
fig4 = figure('Name','Leeside Damage (Mean)','units','normalized','outerposition',[0 0 1 1],'visible',fig_stat);
ax4=gca;
set(ax4,'FontSize',18,'FontWeight','bold');
xlabel(ax4,{'Years'},'FontSize',20,'Interpreter','Latex');
ylabel(ax4,{'Yearly Mean Maximum Cummulative Damage $\bar{S}$'},'FontSize',20,'Interpreter','Latex');
title(ax4,{'Leeside Damage Progession of Rubble Mound Structure';...
    ['Location: ',loc,', Save Point: ',num2str(spoint),'']},'FontSize',24,'FontWeight','bold');
box(ax4,'on');grid(ax4,'on');grid(ax4,'minor');
hold(ax4,'on');

% Plot
plot(ax4,nyears,LSmax,'--k','LineWidth',2,'DisplayName','$\bar{S}$');% Plot Damage
if pctl==1
    cellfun(@(x,y) plot(ax4, nyears, LSPcurves(:,x),'LineWidth',2,'DisplayName',['Percentile: ',y,' \%']),num2cell(1:length(prc)),prc,'un',false);
    legend(ax4,'Location','Best','Interpreter','Latex');
end


%% SAVE FIGURES AND PNG'S

% Save Seaside PNG
saveas(fig1,[outDir '_Seaside_Damage_All_LCS.png']);
% Save Seaside PNG
saveas(fig5,[outDir '_Seaside_Damage_All_LCS_No_Repairs.png']);

% Save Leeside PNG
saveas(fig2,[outDir '_Leeside_Damage_All_LCS.png']);
% Save Leeside PNG
saveas(fig6,[outDir '_Leeside_Damage_All_LCS_No_Repairs.png']);

% Save Figure
saveas(fig3,[outDir  '_Mean_Seaside_Damage.png']);
saveas(fig4,[outDir '_Mean_Leeside_Damage.png']);

if show_figs==1
    % Do Nothing
else
    close all;
end
end
