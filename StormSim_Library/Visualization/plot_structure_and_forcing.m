function plot_structure_and_forcing(config, Resp, structure, storm_type, outpath)
%% DEFINE INPUTS
% Determine If Frequency Vector Is AEP
use_aep = config.pros_use_aep;
% Get Savepoint Depth
sp_depth = config.chs_sp_depth;
% Define Years
s_years = [20,50,100,500];
% Get Frequency Vector
if use_aep == 1
    v_freq = ceil(1./aep2aef(Resp(1).x_table));
else
    v_freq = ceil(1./Resp(1).x_table);
end
% Color Vector
color_str = {'-b','-g','-y','-r'};
% Legend String
legend_str = {'20','50','100','500'};
% Toe_elevation
toe_elevation = structure.toe_elevation;
% Define Project Name
project_name = config.project_name;
% Define Prject Datum
project_datum = config.project_datum;
% Define Strucutre ID
structure_id = config.struc_id;
% Define Case Name
case_name = config.case_name;
%% SWL
% Search For SWL
SWL = Resp(strcmp({Resp.var},{'SWL'}));
% Search For SWL
Hm0 = Resp(strcmp({Resp.var},{'Hm0'}));
% Search For R2p
R2p = Resp(strcmp({Resp.var},{'R2p'}));
% Extract Freqeuncies Of Interest
f_indx = ismember(v_freq,s_years);

f_data = SWL.y_table(f_indx,:);
f_data2 = R2p.y_table(f_indx,:);

% Define CLs
CLs = SWL.CL;
% Loop Through Each CL
for ii = 1:length(CLs)
    % Create Figure (Sturcture) Cross-Section
    fig = plot_structure_geometry(config, structure);
    fig.Units = 'normalized';
    fig.Position = [0 0 1 1];
    ax = gca;hold(ax,'on');box on;
    ax.Color = [0.8 0.8 0.8];
    ylabel(['Elevation [',project_datum,', m]']);
    xlabel('X [m]');
    % Add Save Point Depth
    plot(ax, [1 1], [toe_elevation max(f_data(:,ii),[],'all','omitnan')],'-k','LineWidth',1.5);
    sp = plot(ax, 1, toe_elevation,'bo',"MarkerSize",7,'MarkerFaceColor','b','MarkerEdgeColor','b');
    % Add SWL HC Data
    dummy = [];
    for gg = 1:length(f_data(:,1))
        pp = plot(gca, [0 2], [f_data(gg,ii) f_data(gg,ii)],color_str{gg},'LineWidth',1.5);
        dummy = [dummy,pp];
    end
    % R2p
    plot(ax, [ax.XLim(2)-1 ax.XLim(2)-1], [toe_elevation max(f_data2(:,ii),[],'all','omitnan')],'-k','LineWidth',1.5);
    for gg = 1:length(f_data(:,1))
        plot(gca, [ax.XLim(2)-2 ax.XLim(2)], [f_data2(gg,ii) f_data2(gg,ii)],color_str{gg},'LineWidth',1.5);
    end
    % Change Title
    lg = legend([dummy,sp] ,[legend_str,{['SP Depth: ' num2str(sp_depth) '[m]']}],...
        'Orientation','horizontal','NumColumns',2,'Location','northwest','Color','w');
    title(lg, 'ARI [yrs]');
    ylim(ax, [toe_elevation-0.5 max([f_data,f_data2],[],'all','omitnan')+0.1]);
    t_str = ax.Title.String;
    t_str(1) = {strrep([strrep(t_str{1}, '_', ' ') ' | Case Name: ' case_name],'_',' ')};
    t_str(2) = {['CL: ' num2str(CLs(ii)) ' % | ' storm_type ' | SWL (left) | R_{2%} (right)']};
    title(ax, t_str,'Interpreter','tex');
    exportgraphics(fig, [outpath filesep project_name '_' structure_id '_' case_name '_SWL_and_R2p_' num2str(CLs(ii)) '_CL_' storm_type '_Hazards.png']);
    close all;
end

f_data = Hm0.y_table(f_indx,:);
% Loop Through Each CL
for ii = 1:length(CLs)
    % Create Figure (Sturcture) Cross-Section
    fig = plot_structure_geometry(config, structure);
    fig.Units = 'normalized';
    fig.Position = [0 0 1 1];
    ax = gca;hold(ax,'on');box on;
    ax.Color = [0.8 0.8 0.8];
    ylabel(['Elevation [',project_datum,', m]']);
    xlabel('X [m]');
    % Add Save Point Depth
    plot(ax, [1 1], [toe_elevation max(f_data(:,ii),[],'all','omitnan')],'-k','LineWidth',1.5);
    sp = plot(ax, 1, toe_elevation,'bo',"MarkerSize",7,'MarkerFaceColor','b','MarkerEdgeColor','b');
    % Add SWL HC Data
    dummy = [];
    for gg = 1:length(f_data(:,1))
        pp = plot(gca, [0 2], [f_data(gg,ii) f_data(gg,ii)],color_str{gg},'LineWidth',1.5);
        dummy = [dummy,pp];
    end
    % R2p
    plot(ax, [ax.XLim(2)-1 ax.XLim(2)-1], [toe_elevation max(f_data2(:,ii),[],'all','omitnan')],'-k','LineWidth',1.5);
    for gg = 1:length(f_data(:,1))
        plot(gca, [ax.XLim(2)-2 ax.XLim(2)], [f_data2(gg,ii) f_data2(gg,ii)],color_str{gg},'LineWidth',1.5);
    end
    % Change Title
    lg = legend([dummy,sp] ,[legend_str,{['SP Depth: ' num2str(sp_depth) '[m]']}],...
        'Orientation','horizontal','NumColumns',2,'Location','northwest','Color','w');
    title(lg, 'ARI [yrs]');
    ylim(ax, [toe_elevation-0.5 max([f_data,f_data2],[],'all','omitnan')+0.1]);
    t_str = ax.Title.String;
    t_str(1) = {strrep([strrep(t_str{1}, '_', ' ') ' | Case Name: ' case_name],'_',' ')};
    t_str(2) = {['CL: ' num2str(CLs(ii)) ' | Hm0 (left) | R_{2%} (right)']};
    title(ax, t_str,'Interpreter','tex');
    exportgraphics(fig, [outpath filesep project_name '_' structure_id '_' case_name '_Hm0_and_R2p_' num2str(CLs(ii)) '_CL_' storm_type '_Hazards.png']);
    close all;
end
end

