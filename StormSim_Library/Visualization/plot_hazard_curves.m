function plot_hazard_curves(plt)
%% Plot hazard curves and save out
% Define Fonts
title_fnt = 20;
ax_label_fnt = title_fnt-2;
ax_tick_fnt = ax_label_fnt - 2;
% Remove Empty Fields 
plt(cellfun(@isempty,{plt.y_plot})) = [];
% Initialize Figure Handle
Figure0 = figure('Units','normalized','Position',[0 0 1 1],'Visible','off');
% Initialize Axes Handle
ax = gca;
% For Each Variable In PLOT
for k = 1:length(plt)
    % Grab CLs
    prc = plt(k).CL;
    % Define Y-Axis Type (Linear or Log)
    if plt(k).y_log_scale ==0
        set(ax,'XScale','log','YScale','linear','XGrid','on','XMinorTick','on','YGrid','on','YMinorTick','on',...
            'FontSize',ax_tick_fnt);
    else
        set(ax,'XScale','log','YScale','log','XGrid','on','XMinorTick','on','YGrid','on','YMinorTick','on',...
            'FontSize',ax_tick_fnt);
    end
    % Define Color Pallet
    colorstr = {'k-','b-.','r-.','r--','b--'};
    % Hold Axis Properties
    hold(ax,'on');
    % Enabel Box
    box(ax,'on');
    % For Each CL
    for i = 1:length(plt(k).y_plot(1,:))
        % Define Curve Name
        DataHeaders(i) = {[num2str(prc(i)) '_CL']};
        % PLot CL into Axes
        p = plot(ax,plt(k).x_plot(:,1),plt(k).y_plot(:,i),colorstr{i},'LineWidth',2,'DisplayName',[num2str(prc(i)) '%']);
        % Update Data Tip
        row = dataTipTextRow('RowID', 1:length(plt(k).x_plot(:,1)));
        % Append Neew Data Tip
        p.DataTipTemplate.DataTipRows(end+1) = row;
    end
    % Define Y Lim
    ax.YLim = [min(plt(k).y_plot,[],'all','omitnan'),max(plt(k).y_plot,[],'all','omitnan')];
    % Define Figure Title
    title(ax,plt(k).title,'FontSize',title_fnt);
    % Define X Label
    xlabel(ax,{'Annual Exceedance Frequency, AEF'},'FontSize',ax_label_fnt,'FontWeight','bold');
    % Define Y Label
    ylabel(ax,plt(k).y_label,'FontSize',ax_label_fnt,'FontWeight','bold');
    % Add Legend
    legend2 = legend(ax);
    % Get Legend Title Handle
    htitle = get(legend2,'Title');
    % Define Legend Location
    set(legend2,'Location','Best','FontSize',ax_tick_fnt,'Orientation','horizontal','NumColumns',3);
    % Define Legened Title
    set(htitle,'String','Confidence Levels');
    % Save Figure
    saveas(Figure0,plt(k).save_name,'png');
    % Clear Axes
    cla(ax);
end
close(Figure0);
end



