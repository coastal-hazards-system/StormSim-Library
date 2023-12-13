function peaks_hc_stack_plot(Resp, storm_type, use_aep, orientation, outpath)

%% PULL DATA
Resp = Resp.(storm_type).('Peaks');

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
% Scan Peak Datasets
pDatasets = fieldnames(Resp);
% Compute Logical Vector
s_lim_indx = Resp.(pDatasets{1})(1).x_plot>=x_lim(1);

for ii = 1:length(pDatasets)
    for jj = 1:length(Resp.(pDatasets{ii}))
        % Get Min
        dmin = min(Resp.(pDatasets{ii})(jj).y_plot(s_lim_indx, :),[],'all','omitnan');
        % Get Max
        dmax = max(Resp.(pDatasets{ii})(jj).y_plot(s_lim_indx, :),[],'all','omitnan');
        % Store Absolute Min For Dataset/Response
        y_min_list(jj,ii) = dmin;
        % Store Absolute Max For Dataset/Response
        y_max_list(jj,ii) = dmax;
    end
end
% Get Absolute Max/Min Global
y_min_list = min(y_min_list,[],2,"omitnan");
y_max_list = max(y_max_list,[],2,"omitnan");

%% DEFINE INDEXES BASED ON ORIENTATION
switch orientation
    case 'h'
        % X Label
        x_indx_label = -9; % For All Subplots
        % Y Label
        y_indx_label = 1; % First Subplot
        % Subplot Indexes Definitions
        srow = 1;
        scol = 3;
        % Title
        title_indx = 2;
        xticks_label = -9;
    case 'v'
        x_indx_label = 3;
        y_indx_label = -9;
        srow = 3;
        scol = 1;
        title_indx = 1;
        xticks_label = 3;
end

%% PLOT EACH RESPONSE FOR EACH DATASET
% Find response Lengths
[plen, ilen] = max(cell2mat(cellfun(@(x) length({Resp.(x).var}), pDatasets, 'un', false)));
resp_list = cellfun(@(x) {Resp.(x).var}, pDatasets, 'un', false);
resp_list = resp_list{ilen};
% For Each Variable In PLOT
for k = 1:plen
    % Initialize Figure Handle
    Figure0 = figure('Units','normalized','Position',[0 0 1 1],'Visible','off');
    for ll = 1:length(pDatasets)
        plt = Resp.(pDatasets{ll});
        if any(strcmp(resp_list{k}, {plt.var}))
            % Grab Variable Index 
            pvar_indx = strcmp({plt.var}, resp_list{k});
            % Initialize Axes Handle
            ax = subplot(srow,scol,ll);
            % Grab CLs
            prc = plt(pvar_indx).CL;
            % Define Y-Axis Type (Linear or Log)
            if plt(pvar_indx).y_log_scale ==0
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
            for i = 1:length(plt(pvar_indx).y_plot(1,:))
                % Define Curve Name
                if prc(i) == 50
                    DataName = 'Best Estimate';
                else
                    DataName = [num2str(prc(i)) '%'];
                end
                % PLot CL into Axes
                p = plot(ax,plt(pvar_indx).x_plot(:,1),plt(pvar_indx).y_plot(:,i),colorstr{i},'LineWidth',2,'DisplayName',DataName);
                % Update Data Tip
                row = dataTipTextRow('RowID', 1:length(plt(pvar_indx).x_plot(:,1)));
                % Append Neew Data Tip
                p.DataTipTemplate.DataTipRows(end+1) = row;
            end
            % Define Y Lim
            try
                ax.YLim = [y_min_list(k) y_max_list(k)];
            end
            % Set XTicks
            ax.XTick = xticks_data;
            if ll==xticks_label || xticks_label==-9
                ax.XTickLabel = xticks_data_lbl;
            else
                ax.XTickLabel = [];
            end
            % Define X Lim
            ax.XLim = x_lim;
            % Define Figure Title
            tstr = plt(pvar_indx).title;
            % Append To Second Cell
            tstr(2) = {[tstr{2} ' | ' pDatasets{ll}]};
            if ll ~= title_indx
                % Make First Cell Empty
                tstr(1) = {''};
            end
            title(ax,tstr,'FontSize',title_fnt);
            % Define X Label
            if ll == x_indx_label || x_indx_label == -9
                if use_aep == 1
                    xlabel(ax,{'Annual Exceedance Probability, AEP'},'FontSize',ax_label_fnt,'FontWeight','bold');
                else
                    xlabel(ax,{'Annual Exceedance Frequency, AEF [1/yr]'},'FontSize',ax_label_fnt,'FontWeight','bold');
                end
            end
            % Define Y Label
            if ll == y_indx_label || y_indx_label == -9
                ylabel(ax,plt(k).y_label,'FontSize',ax_label_fnt,'FontWeight','bold');
            end
            % Add Legend
            if ll==1
                legend2 = legend(ax);
                % Get Legend Title Handle
                htitle = get(legend2,'Title');
                % Define Legend Location
                set(legend2,'Location','southeast','FontSize',ax_tick_fnt,'Orientation','horizontal','NumColumns',3);
                % Define Legened Title
                set(htitle,'String','Confidence Levels');
            end
        else
            continue;
        end
    end
    % Save Figure
    switch storm_type
        case 'TC'
            modelstr = 'TC';
        case 'XC'
            modelstr = 'XC';
        case 'CC'
            modelstr = 'CC';
    end
    saveas(Figure0,[outpath filesep  'RB1_StormSim_Peaks_' resp_list{k} '_' modelstr '_Hazard_Curve_Comparison'],'png');
    close all;
end

end



