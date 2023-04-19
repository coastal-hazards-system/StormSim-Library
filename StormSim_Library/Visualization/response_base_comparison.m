function response_base_comparison(Resp_RB1, Resp_RB3, storm_type, use_aep, orientation, outpath)

%% PULL DATA


%% DEFINE FONTS
% Title Font
title_fnt = 26;
% Axis Labels Font
ax_label_fnt = title_fnt-2;
% TickLabel Font
ax_tick_fnt = ax_label_fnt - 2;

%% Define XTick Labels And XTicks
if use_aep == 1
    xticks_data = fliplr([10^0, 10^-1, 10^-2, 10^-3]);
    xticks_data_lbl = fliplr({'10^0', '10^{-1}', '10^{-2}', '10^{-3}'});
    x_lim = [10^-3, 1];
else
    xticks_data = fliplr([10^0, 10^-1, 10^-2, 10^-3, 10^-4]);
    xticks_data_lbl = fliplr({'10^0', '10^{-1}', '10^{-2}', '10^{-3}', '10^{-4}'});
    x_lim = [10^-4 1];
end


%% DETERMINE ABSOLUTE MIN/MAX
% Compute Logical Vector
s_lim_indx = Resp_RB1(1).x_plot>=x_lim(1);
% Loop Through Responses
for ii = 1:length(Resp_RB1)
    % Get Min
    dmin = min(Resp_RB1(ii).y_plot(s_lim_indx, :),[],'all','omitnan');
    dmin_2 = min(Resp_RB3(ii).y_plot(s_lim_indx, :),[],'all','omitnan');
    % Get Max
    dmax = max(Resp_RB1(ii).y_plot(s_lim_indx, :),[],'all','omitnan');
    dmax_2 = max(Resp_RB3(ii).y_plot(s_lim_indx, :),[],'all','omitnan');
    % Store Absolute Min For Dataset/Response
    y_min_list(ii) = min([dmin,dmin_2],[],2);
    % Store Absolute Max For Dataset/Response
    y_max_list(ii) = max([dmax,dmax_2],[],2);
end

%% PLOT EACH RESPONSE FOR EACH DATASET]


% For Each Variable In PLOT
for k = 1:length(Resp_RB1)
    % Initialize Figure Handle
    Figure0 = figure('Units','normalized','Position',[0 0 1 1],'Visible','off');
    for ll = 1:2
        % Initialize Axes Handle
        ax = subplot(1,2,ll);
        % Grab CLs
        prc = Resp_RB1(k).CL;
        % Define Y-Axis Type (Linear or Log)
        if Resp_RB1(k).y_log_scale == 0
            set(ax,'XScale','log','YScale','linear','XGrid','on','XMinorTick','on','YGrid','on','YMinorTick','on',...
                'FontSize',ax_tick_fnt,'XDir','reverse');
        elseif Resp_RB1(k).y_log_scale == 1
            set(ax,'XScale','log','YScale','log','XGrid','on','XMinorTick','on','YGrid','on','YMinorTick','on',...
                'FontSize',ax_tick_fnt,'XDir','reverse');
        end
        % Hold Axis Properties
        hold(ax,'on');
        % Define Color Pallet
        colorstr = {'k-','b-.','r-.','r--','b--'};
        % Enabel Box
        box(ax,'on');
        % Define Plot Object
        switch ll
            case 1
                plt = Resp_RB1;
            case 2
                plt = Resp_RB3;
            case 3
                for kk = 1:length(Resp_RB1)
                    plt(kk).var = Resp_RB1(kk).var;
                    plt(kk).x_plot = Resp_RB1(kk).x_plot;
                    plt(kk).y_plot = abs(Resp_RB3(kk).y_plot - Resp_RB1(kk).y_plot)./((Resp_RB3(kk).y_plot + Resp_RB1(kk).y_plot).*0.5) .* 100;
                end
        end
        % For Each CL
        for i = 1:length(plt(k).y_plot(1,:))
            % Define Curve Name
            if prc(i) == 50
                DataName = 'Best Estimate';
            else
                DataName = [num2str(prc(i)) '%'];
            end
            % PLot CL into Axes
            p = plot(ax,plt(k).x_plot(s_lim_indx,1),plt(k).y_plot(s_lim_indx,i),colorstr{i},'LineWidth',2,'DisplayName',DataName);
            % Update Data Tip
            row = dataTipTextRow('RowID', 1:length(plt(k).x_plot(:,1)));
            % Append Neew Data Tip
            p.DataTipTemplate.DataTipRows(end+1) = row;
        end
        % Define Y Lim
        if ll ~= 3
            ax.YLim = [y_min_list(k) y_max_list(k)];
        else
            ax.YLim = [min(plt(kk).y_plot(s_lim_indx, :),[],'all','omitnan') max(plt(kk).y_plot(s_lim_indx, :),[],'all','omitnan')];
        end
        % Set XTicks
        if ll~=3
        ax.XTick = xticks_data;
        ax.XTickLabel = xticks_data_lbl;
        % Define X Lim
        ax.XLim = x_lim;
        end
        % Get Response Variable
        resp_name = plt(k).y_label;
        % Remove Units
        resp_name = strsplit(resp_name,{' ['});
        resp_name = resp_name{1};
        % Define Figure Title
        switch ll
            case 1
                tstr = {'StormSim: PROS | RB1';[storm_type ' | ' resp_name]};
            case 2
                tstr = {'StormSim: PROS | RB3';[storm_type ' | ' resp_name]};
            case 3
                tstr = {'StormSim: PROS | % Diff RB3 vs RB1';[storm_type ' | ' resp_name]};
        end
        % Add Title
        title(ax,tstr,'FontSize',title_fnt);
        % Define X Label
        if use_aep == 1
            xlabel(ax,{'Annual Exceedance Probability, AEP'},'FontSize',ax_label_fnt,'FontWeight','bold');
        elseif use_aep == 0
            xlabel(ax,{'Annual Exceedance Frequency, AEF [1/yr]'},'FontSize',ax_label_fnt,'FontWeight','bold');
        end
        % Define Y Label
        if ll == 1
            ylabel(ax,plt(k).y_label,'FontSize',ax_label_fnt,'FontWeight','bold');
            % Add Legend
            legend2 = legend(ax);
            % Get Legend Title Handle
            htitle = get(legend2,'Title');
            % Define Legend Location
            set(legend2,'Location','southeast','FontSize',ax_tick_fnt,'Orientation','horizontal','NumColumns',3);
            % Define Legened Title
            set(htitle,'String','Confidence Levels');
        elseif ll == 3
            ylabel(ax,'% Difference','FontSize',ax_label_fnt,'FontWeight','bold');
        end
    end
    % Save Figure
    switch storm_type
        case 'TC'
            modelstr = 'JPM';
        case 'XC'
            modelstr = 'SST';
        case 'CC'
            modelstr = 'CC';
    end

    saveas(Figure0,[outpath filesep  'RB1_vs_RB3_' modelstr '_' Resp_RB1(k).var '_Hazard_Curve_Comparison'],'png');
    close all;
end



end