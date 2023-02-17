function plot_hazard_curves(plot_data)
    
    %% Plot hazard curves and save out
    % Grab CLs
    prc = plot_data.CL;
    % For Each Variable In PLOT
    for k = 1:length(plot_data)
        % Initialize Figure Handle
        Figure0 = figure('Visible','on');
        % Initialize Axes Handle
        ax = gca;
        % Define Y-Axis Type (Linear or Log)
        if plot_data(k).y_log_scale ==0
            set(ax,'XScale','log','YScale','linear','XGrid','on','XMinorTick','on','YGrid','on','YMinorTick','on',...
                'FontSize',16);
        else
            set(ax,'XScale','log','YScale','log','XGrid','on','XMinorTick','on','YGrid','on','YMinorTick','on',...
                'FontSize',16);
        end
%         % Define Y Axis Limits
%         if isempty(plot_data(k).minylim)==0
%             ylim(ax,[plot_data(k).minylim inf])
%         end
        % Define X Limits
        xlim(ax,[min(plot_data(k).x_plot) max(plot_data(k).x_plot)]);
        % Define Color Pallet
        colorstr = {'k-','b-.','r-.','r--','b--'};
        % Hold Axis Properties
        hold(ax,'on');
        % For Each CL
        for i = 1:length(plot_data(k).x_plot(1,:))
            % Define Curve Name
            DataHeaders(i) = {[num2str(prc(i)) '_CL']};
            % PLot CL into Axes
            p = plot(ax,plot_data(k).x_plot(:,i),plot_data(k).y_plot(:,i),colorstr{i},'LineWidth',2,'DisplayName',[num2str(prc(i)) '%']);
            % Update Data Tip
            row = dataTipTextRow('RowID', 1:length(plot_data(k).x_plot(:,i)));
            % Append Neew Data Tip
            p.DataTipTemplate.DataTipRows(end+1) = row;
        end
        % Define Figure Title
        title(ax,plot_data(k).title,'FontSize',14);
        % Define X Label
        xlabel(ax,{'Annual Exceedance Frequency, AEF'},'FontSize',16);
        % Define Y Label
            ylabel(ax,plot_data(k).y_label,'FontSize',16);
        % Add Legend
        legend2 = legend(ax);
        % Get Legend Title Handle
        htitle = get(legend2,'Title');
        % Define Legend Location
        % if strcmp(plt(k).staID,'q')==1
        %     set(legend2,'Location','NorthWest','FontSize',14);
        % else
        set(legend2,'Location','Best','FontSize',9,'Orientation','horizontal','NumColumns',3);
        % end
        % Define Legened Title
        set(htitle,'String','Confidence Levels');
        % Build Export Name        
        saveas(Figure0,plot_data(k).save_name);
        
        % Clear Axes
%         cla(ax);
    end
end



