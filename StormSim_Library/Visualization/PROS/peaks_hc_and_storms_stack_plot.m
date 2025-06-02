function peaks_hc_and_storms_stack_plot(config, Resp, project_forcing, pDatasets, outpath)
%% PULL DATA
% Define Plot Field
plt_fld = 'y_plot';
plt_fld_x = 'x_plot';
% Scan Peak Datasets
storm_types = fieldnames(Resp);
storm_types = storm_types(contains(storm_types, {'TC','XC'}));

%% GRAB INFROMATION FROM "config"
% CHS Region
region = config.region;
% ADCIRC SP ID
sp_ID = config.sp_ID;
% Wave Model Savepoint
sp_ID_wave = config.sp_ID_wave;
% Vertical Datum
datum = config.project_datum;
% Are HC In AEP or AEF
use_aep = config.pros_use_aep;
% Grab CLs
CLs = Resp.(storm_types{1})(1).CL;
%
if use_aep
    x_lim = [10^-3, 1];
else
    x_lim = [10^-4, 1];
end

%% DEFINE FONTS
% Title Font
title_fnt = 22;
% Axis Labels Font
ax_label_fnt = title_fnt-2;
% TickLabel Font
ax_tick_fnt = ax_label_fnt - 2;
% Define Color Vector
colorstr = {'k-','b-.','r-.','r--','b--'};

%% CREATE OUTPUT DIR
% Make Dir
if ~exist(outpath,'dir')
    mkdir(outpath);
else
    delete([outpath filesep '*.png']);
end

%% DETERMINE ABSOLUTE MIN/MAX
y_limit = [];
for ii = 1:length(storm_types)
    % HC Data
    resp_indx = cellfun(@(x) find(strcmp(x, {Resp.(storm_types{ii}).var})), {'SWL'; 'Hm0'; 'Tp'}, 'un', true);
    % Grab HC Data
    hcData.(storm_types{ii}) = Resp.(storm_types{ii})(resp_indx);
    % Loop For Each Storm Type
    for kk = 1:length(resp_indx)
        % Compute Logical Vector
        s_lim_indx = hcData.(storm_types{ii})(kk).(plt_fld_x)>=x_lim(1);
        % Min
        dmin(kk, ii) = min(hcData.(storm_types{ii})(kk).(plt_fld)(s_lim_indx, :),[],'all','omitnan');
        % Max
        dmax(kk, ii) = max(hcData.(storm_types{ii})(kk).(plt_fld)(s_lim_indx, :),[],'all','omitnan');
        %
        if ii == length(storm_types)
            % Store Absolute Min For Dataset/Response
            y_limit(kk).min = min(dmin(kk, :));
            % Store Absolute Max For Dataset/Response
            y_limit(kk).max = max(dmax(kk, :));
            %
            y_limit(kk).var = hcData.(storm_types{ii})(kk).var;
        end
    end
    % Grab Forcing Data (Scatter)
    sData.(storm_types{ii}).SWL =cellfun(@(x) max(x),project_forcing.(storm_types{ii}).('SWL_no_rep'),'un',true);
    sData.(storm_types{ii}).Hm0 = cellfun(@(x) max(x),project_forcing.(storm_types{ii}).('Hm0_no_rep'),'un',true);
end

%% PLOT EACH RESPONSE FOR EACH DATASET
% Initialize Figure Handle
Figure0 = figure('Units','normalized','Position',[0 0 1 1],'Visible','off');
% Create textbox
annotation(Figure0,'textbox',...
    [0.5 0.967812729409427 0.056835935922572 0.0343818572767479],...
    'String',pDatasets,...
    'FontWeight','bold',...
    'FontSize',title_fnt,...
    'FitBoxToText','on',...
    'EdgeColor','none');

%% PLOT XC DATA
if contains('XC',storm_types)
    % Number of XC's
    xc_nstm = num2str(length(sData.('XC').SWL));
    % Grab AEP/AEF Vector
    xc_x = hcData.('XC')(1).(plt_fld_x);
    %
    ax_xc_objs = axes_formater(Figure0, use_aep, 'XC', xc_nstm, 0); % XC
    % Plot Each Storm
    p_xc = plot(ax_xc_objs(1), sData.('XC').SWL, sData.('XC').Hm0, 'bo', 'MarkerSize',2);
    % Plot Each HC
    for i = 1:length(CLs)
        % Define Curve Name
        if CLs(i) == 50
            DataName = 'Best Estimate';
        else
            DataName = [num2str(CLs(i)) '%'];
        end
        % PLot CL into XC Axes
        for pp = 1:length({hcData.('XC').var})
            p = plot(ax_xc_objs(pp+1), xc_x, hcData.('XC')(pp).(plt_fld)(:,i),...
                colorstr{i}, 'LineWidth', 2, 'DisplayName', DataName);
            % Create Data Tip Vector
            row = dataTipTextRow('RowID', 1:length(xc_x));
            % Append New Data Tip
            p.DataTipTemplate.DataTipRows(end+1) = row;
        end
    end
end

% Add Legend
legend2 = legend(ax_xc_objs(2));
% Define Legend Location
set(legend2,'Location','southeast','FontSize',ax_tick_fnt,...
    'Orientation','horizontal','NumColumns',3,...
    'FontSize', 16);

%% PLOT TC DATA
if contains('TC',storm_types)
    % Number of TC's
    tc_nstm = num2str(length(sData.('TC').SWL));
    % Grab AEP/AEF Vector
    tc_x = hcData.('TC')(1).(plt_fld_x); % JPM
    %
    ax_tc_objs = axes_formater(Figure0, use_aep, 'TC', tc_nstm, 4); % XC
    % Plot Each Storm
    p_tc = plot(ax_tc_objs(1), sData.('TC').SWL, sData.('TC').Hm0, 'bo', 'MarkerSize',2);
    % Plot Each HC
    for i = 1:length(CLs)
        % Define Curve Name
        if CLs(i) == 50
            DataName = 'Best Estimate';
        else
            DataName = [num2str(CLs(i)) '%'];
        end
        % PLot CL into XC Axes
        for pp = 1:length({hcData.('TC').var})
            p = plot(ax_tc_objs(pp+1), tc_x, hcData.('TC')(pp).(plt_fld)(:,i),...
                colorstr{i}, 'LineWidth', 2, 'DisplayName', DataName);
            % Create Data Tip Vector
            row = dataTipTextRow('RowID', 1:length(tc_x));
            % Append New Data Tip
            p.DataTipTemplate.DataTipRows(end+1) = row;
        end
    end
end

%% Save Figure
saveas(Figure0, [outpath filesep 'StormSim_' pDatasets '_Project_Forcing_and_Hazard_Curve_Comparison'],'png');
close all;

%% AUX FUNCTIONS
% --------- CLEAN-UP LOCAL FUNCTION ---------
    function ax_tc = ax_ini(ax_tc, ax_tick_fnt, ax_label_fnt, title_fnt, x_label, y_label, t_label)
        % Define Axes Properties
        set(ax_tc,'XGrid','on','XMinorTick','on','YGrid','on','YMinorTick','on',...
            'FontSize',ax_tick_fnt,'box','on');
        % Hold Properties
        hold(ax_tc,'on');
        % Add Y Label
        ylabel(ax_tc, y_label,'FontSize',ax_label_fnt,'FontWeight','bold');
        % Add X Label
        xlabel(ax_tc, x_label,'FontSize',ax_label_fnt,'FontWeight','bold');
        % Add Titles
        title(ax_tc,t_label,'FontSize',title_fnt,'FontWeight','bold');
    end

    function ax_objs = axes_formater(fig, use_aep, st_type, nstm, col_indx)
        ax_f = @(a, b, c, d) ax_ini(d, ax_tick_fnt, ax_label_fnt, title_fnt, a, b, c);
        nrows = 2;
        ncols = 4;
        if use_aep == 1
            xticks_data = fliplr([10^0, 10^-1, 10^-2, 10^-3]);
            xticks_data_lbl = fliplr({'10^0', '10^{-1}', '10^{-2}', '10^{-3}'});
            x_lim = [10^-3, 1];
            hc_label = 'Annual Exceedance Probability, AEP';
            hc_label2 = 'AEP';
        else
            xticks_data = fliplr([10^0, 10^-1, 10^-2, 10^-3, 10^-4]);
            xticks_data_lbl = fliplr({'10^0', '10^{-1}', '10^{-2}', '10^{-3}', '10^{-4}'});
            x_lim = [10^-4 1];
            hc_label = 'Annual Exceedance Frequency, AEF [1/yr]';
            hc_label2 = 'AEF [1/yr]';
        end
        y_labels = ["H_{m_{0}} [m]", string(['SWL [m, ' datum ']']), "Hm0 [m]", "Tp [s]"];
        x_labels = [string(['SWL [m, ' datum ']']), hc_label, hc_label2, hc_label2];
        title_labels = [string([st_type ' Storms | ' nstm]),...
            string([st_type ' | SWL | ' region ' | SP' num2str(sp_ID)]),...
            string([st_type ' | Hm0 | ' region ' | SP' num2str(sp_ID_wave)]),...
            string([st_type ' | Tp | ' region ' | SP' num2str(sp_ID_wave)])];
        var_list = {'None','SWL','Hm0','Tp'};
        for jj = 1:4
            %
            ax = subplot(nrows, ncols, col_indx+jj);
            ax_objs(jj,1) = ax_f(x_labels(jj), y_labels(jj), title_labels(jj), ax);
            %
            if contains(var_list{jj}, {y_limit.var})
                ax_objs(jj,1).YLim = [y_limit(contains({y_limit.var}, var_list{jj})).min y_limit(contains({y_limit.var}, var_list{jj})).max];
            end
            %
            if jj>1
                ax_objs(jj,1).XTick = xticks_data;
                ax_objs(jj,1).XTickLabel = xticks_data_lbl;
                ax_objs(jj,1).XLim = x_lim;
                ax_objs(jj,1).XScale = 'log';
                ax_objs(jj,1).YScale = 'linear';
                ax_objs(jj,1).XDir = 'reverse';
            end
        end
    end
end



