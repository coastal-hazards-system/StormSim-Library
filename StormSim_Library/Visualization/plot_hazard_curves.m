function plot_hazard_curves(plt, use_aep)
%% Plot hazard curves and save out
% Define Fonts
title_fnt = 28;
ax_label_fnt = title_fnt-2;
ax_tick_fnt = ax_label_fnt - 2;
% Remove Empty Fields
plt(cellfun(@isempty,{plt.y_plot})) = [];
% Define XTick Labels And XTicks
if use_aep == 1
    xticks_data = fliplr([10^0, 10^-1, 10^-2, 10^-3]);
    xticks_data_lbl = fliplr({'10^0', '10^{-1}', '10^{-2}', '10^{-3}'});
    x_lim = [10^-3, 1];
else
    xticks_data = fliplr([10^0, 10^-1, 10^-2, 10^-3, 10^-4]);
    xticks_data_lbl = fliplr({'10^0', '10^{-1}', '10^{-2}', '10^{-3}', '10^{-4}'});
    x_lim = [10^-4 1];

end
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
            'FontSize',ax_tick_fnt,'XDir','reverse');
    else
        set(ax,'XScale','log','YScale','log','XGrid','on','XMinorTick','on','YGrid','on','YMinorTick','on',...
            'FontSize',ax_tick_fnt,'XDir','reverse');
    end
    % Hold Axis Properties
    hold(ax,'on');
    % Define Color Pallet
    colorstr = {'k-','b-.','r-.','r--','b--'};
    % Enabel Box
    box(ax,'on');
    % For Each CL
    for i = 1:length(plt(k).y_plot(1,:))
        % Define Curve Name
        if prc(i) == 50
            DataName = 'Best Estimate';
        else
            DataName = [num2str(prc(i)) '%'];
        end
        % PLot CL into Axes
        p = plot(ax,plt(k).x_plot(:,1),plt(k).y_plot(:,i),colorstr{i},'LineWidth',2,'DisplayName',DataName);
        % Update Data Tip
        row = dataTipTextRow('RowID', 1:length(plt(k).x_plot(:,1)));
        % Append Neew Data Tip
        p.DataTipTemplate.DataTipRows(end+1) = row;
    end
    % Define Y Lim
    ax.YLim = [min(plt(k).y_plot,[],'all','omitnan'),max(plt(k).y_plot,[],'all','omitnan')];
    % Set XTicks
    ax.XTick = xticks_data;
    ax.XTickLabel = xticks_data_lbl;
    % Define X Lim
    ax.XLim = x_lim;
    % Define Figure Title
    title(ax,plt(k).title,'FontSize',title_fnt);
    % Define X Label
    if use_aep == 1
        xlabel(ax,{'Annual Exceedance Probability, AEP'},'FontSize',ax_label_fnt,'FontWeight','bold');
    else
        xlabel(ax,{'Annual Exceedance Frequency, AEF [1/yr]'},'FontSize',ax_label_fnt,'FontWeight','bold');
    end
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
close all;
end



