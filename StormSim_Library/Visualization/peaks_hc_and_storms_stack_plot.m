function peaks_hc_and_storms_stack_plot(config, Resp, project_forcing, ts_switch, outpath)
%% PULL DATA
workflow = config.workflow;
% Scan Peak Datasets
storm_types = sort(fieldnames(Resp));
storm_types = storm_types(contains(storm_types,{'XC','TC'}));
% HC Data
if ts_switch == 0
    resp_indx = find(sum(cell2mat(cellfun(@(x) strcmp(x,{'SWL','Hm0'}),{Resp.(storm_types{1}).('Peaks').('Maxima').var},'un',false)'),2)==1);
else
    resp_indx = find(sum(cell2mat(cellfun(@(x) strcmp(x,{'SWL','Hm0'}),{Resp.(storm_types{1}).('Timeseries').var},'un',false)'),2)==1);
end
% Remove Other HCs
for ii = 1:length(storm_types)
    % Timeseries/Peaks
    if ts_switch == 0 % Peaks
        % Find Peak Datasets Fieldnames
        pDatasets = fieldnames(Resp.(storm_types{ii}).Peaks);
        % Loop Through Fieldnames
        for jj = 1:length(pDatasets)
            % Grab HC Data
            hcData.(storm_types{ii}).(pDatasets{jj}) = Resp.(storm_types{ii}).('Peaks').(pDatasets{jj})(resp_indx);
            % Grab Forcing Data (Scatter)
            if workflow == 1 % StormSim: PROS
                sData.(storm_types{ii}).(pDatasets{jj}).SWL = project_forcing.(storm_types{ii}).('Peaks').(pDatasets{jj}).('SWL_no_rep');
                sData.(storm_types{ii}).(pDatasets{jj}).Hm0 = project_forcing.(storm_types{ii}).('Peaks').(pDatasets{jj}).('Hm0_no_rep');
            else % StormSim: EVA
                sData.(storm_types{ii}).(pDatasets{jj}).SWL = project_forcing.(storm_types{ii}).('Peaks').(pDatasets{jj}).('SWL');
                sData.(storm_types{ii}).(pDatasets{jj}).Hm0 = project_forcing.(storm_types{ii}).('Peaks').(pDatasets{jj}).('Hm0');
            end
        end
    else % Timeseries
        % Define Dummy Fieldname
        pDatasets = {'Maxima'};
        % Loop Through Fieldnames
        for jj = 1:length(pDatasets)
            % Grab HC Data
            hcData.(storm_types{ii}).(pDatasets{jj}) = Resp.(storm_types{ii}).('Timeseries')(resp_indx);
                        % Grab Forcing Data (Scatter)
            if workflow == 1 % StormSim: PROS
                sData.(storm_types{ii}).(pDatasets{jj}).SWL = cell2mat(cellfun(@(x) max(x),project_forcing.(storm_types{ii}).('Timeseries').('SWL_no_rep'),'un',false));
                sData.(storm_types{ii}).(pDatasets{jj}).Hm0 = cell2mat(cellfun(@(x) max(x),project_forcing.(storm_types{ii}).('Timeseries').('Hm0_no_rep'),'un',false));
            else
                sData.(storm_types{ii}).(pDatasets{jj}).SWL = cell2mat(cellfun(@(x) max(x),project_forcing.(storm_types{ii}).('Timeseries').('SWL'),'un',false));
                sData.(storm_types{ii}).(pDatasets{jj}).Hm0 = cell2mat(cellfun(@(x) max(x),project_forcing.(storm_types{ii}).('Timeseries').('Hm0'),'un',false));
            end
        end
    end
end

%% GRAB INFROMATION FROM "config"
% CHS Region
region = config.region;
% ADCIRC SP ID
sp_ID = config.sp_ID;
% Wave Model Savepoint
sp_ID_wave = strsplit(config.chs_tc_hm0_peaks{:},{'_','SP'});
sp_ID_wave = str2double(sp_ID_wave{5});
% Vertical Datum
datum = config.project_datum;
% Are HC In AEP or AEF
use_aep = config.pros_use_aep;
% Grab CLs
CLs = hcData.(storm_types{1}).('Maxima')(1).CL;

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
for jj = 1:length(pDatasets)
    for kk = 1:length(resp_indx)
        % Get Min/Max
        if isfield(hcData,'XC')
            % Min
            dmin = min(hcData.('XC').(pDatasets{jj})(kk).y_plot,[],'all','omitnan');
            % Get Max
            dmax = max(hcData.('XC').(pDatasets{jj})(kk).y_plot,[],'all','omitnan');
        else
            dmin = [];
            dmax = [];
        end
        if isfield(hcData,'TC')
            % Min
            dmin2 = min(hcData.('TC').(pDatasets{jj})(kk).y_plot,[],'all','omitnan');
            % Get Max
            dmax2 = max(hcData.('TC').(pDatasets{jj})(kk).y_plot,[],'all','omitnan');
        else
            dmin2 = [];
            dmax2 = [];
        end
        % Get Min
        dmin = min([dmin,dmin2]);
        % Get Max
        dmax = max([dmax,dmax2]);
        % Store Absolute Min For Dataset/Response
        y_limit.(pDatasets{jj})(kk).min = dmin;
        % Store Absolute Max For Dataset/Response
        y_limit.(pDatasets{jj})(kk).max = dmax;
    end
end


%% DEFINE XTICKS
if use_aep == 1
    xticks_data = fliplr([10^0, 10^-1, 10^-2, 10^-3]);
    xticks_data_lbl = fliplr({'10^0', '10^{-1}', '10^{-2}', '10^{-3}'});
    x_lim = [10^-3, 1];
else
    xticks_data = fliplr([10^0, 10^-1, 10^-2, 10^-3, 10^-4]);
    xticks_data_lbl = fliplr({'10^0', '10^{-1}', '10^{-2}', '10^{-3}', '10^{-4}'});
    x_lim = [10^-4 1];
end

%% PLOT EACH RESPONSE FOR EACH DATASET
% For Each Peaks Dataset (Maxima, WLP, WHP)
for ii = 1:length(pDatasets)
    % Initialize Figure Handle
    Figure0 = figure('Units','normalized','Position',[0 0 1 1],'Visible','off');
    % Grab Storm Type Dependant Fields
    % Extratropical
    if isfield(sData,'XC')
        % Number of XC's
        xc_nstm = num2str(length(sData.('XC').(pDatasets{ii}).SWL));
        % Grab AEP/AEF Vector
        xc_x = hcData.('XC').(pDatasets{ii})(1).x_plot; % SST
    else
        xc_nstm = '0';
    end
    % Tropical
    if isfield(sData,'TC')
        % Number of TC's
        tc_nstm = num2str(length(sData.('TC').(pDatasets{ii}).SWL));
        % Grab AEP/AEF Vector
        tc_x = hcData.('TC').(pDatasets{ii})(1).x_plot; % JPM
    else
        tc_nstm = '0';
    end


    % ---- FORMAT TC STORM DATA AXES----%
    % Define Axes Handle
    ax_tc = subplot(2,5,6);
    % Define Axes Properties
    set(ax_tc,'XGrid','on','XMinorTick','on','YGrid','on','YMinorTick','on',...
        'FontSize',ax_tick_fnt,'box','on');
    % Hold Properties
    hold(ax_tc,'on');
    % Add Y Label
    ylabel(ax_tc,'H_{m_{0}} [m]','FontSize',ax_label_fnt,'FontWeight','bold');
    % Add X Label
    xlabel(ax_tc,['SWL [m, ' datum ']'],'FontSize',ax_label_fnt,'FontWeight','bold');
    % Add Titles
    title(ax_tc,['TC Storms | ' tc_nstm],'FontSize',title_fnt,'FontWeight','bold');

    % ------- FORMAT TC HC DATA AXES -------
    % Initialize TCs Axes Handle
    ax_tc_hc_swl = subplot(2,5,[7 8]);
    ax_tc_hc_hm0 = subplot(2,5,[9 10]);
    % Define TC Axes Properties
    set(ax_tc_hc_swl,'XScale','log','YScale','linear','XGrid','on','XMinorTick','on','YGrid','on','YMinorTick','on',...
        'FontSize',ax_tick_fnt,'box','on','XDir','reverse');
    set(ax_tc_hc_hm0,'XScale','log','YScale','linear','XGrid','on','XMinorTick','on','YGrid','on','YMinorTick','on',...
        'FontSize',ax_tick_fnt,'box','on','XDir','reverse');
    % Hold Properties
    hold(ax_tc_hc_swl,'on');
    hold(ax_tc_hc_hm0,'on');
    % Add Y Label
    ylabel(ax_tc_hc_swl,['SWL [m, ' datum ']'],'FontSize',ax_label_fnt,'FontWeight','bold');
    ylabel(ax_tc_hc_hm0,'H_{m_{0}} [m]','FontSize',ax_label_fnt,'FontWeight','bold');

    % ---- FORMAT XC STORM DATA AXES----%
    % Define Axes Handle
    ax_xc = subplot(2,5,1);
    % Define Axes Properties
    set(ax_xc,'XGrid','on','XMinorTick','on','YGrid','on','YMinorTick','on',...
        'FontSize',ax_tick_fnt,'box','on');
    % Hold Properties
    hold(ax_xc,'on');
    % Add Y Label
    ylabel(ax_xc,'H_{m_{0}} [m]','FontSize',ax_label_fnt,'FontWeight','bold');
    % Add X Label
    xlabel(ax_xc,['SWL [m, ' datum ']'],'FontSize',ax_label_fnt,'FontWeight','bold');
    % Add Titles
    title(ax_xc,['XC Storms | ' xc_nstm],'FontSize',title_fnt,'FontWeight','bold');

    % ------- FORMAT XC HC DATA AXES -------
    % Initialize XCs Axes Handle
    ax_xc_hc_swl = subplot(2,5,[2 3]);
    ax_xc_hc_hm0 = subplot(2,5,[4 5]);
    % Define XC Axes Properties
    set(ax_xc_hc_swl,'XScale','log','YScale','linear','XGrid','on','XMinorTick','on','YGrid','on','YMinorTick','on',...
        'FontSize',ax_tick_fnt,'box','on','XDir','reverse'); % SWL
    set(ax_xc_hc_hm0,'XScale','log','YScale','linear','XGrid','on','XMinorTick','on','YGrid','on','YMinorTick','on',...
        'FontSize',ax_tick_fnt,'box','on','XDir','reverse'); % Hm0
    % Hold Properties
    hold(ax_xc_hc_swl,'on');
    hold(ax_xc_hc_hm0,'on');
    % Add Y Label
    ylabel(ax_xc_hc_swl,['SWL [m, ' datum ']'],'FontSize',ax_label_fnt,'FontWeight','bold');
    ylabel(ax_xc_hc_hm0,'H_{m_{0}} [m]','FontSize',ax_label_fnt,'FontWeight','bold');

    % ------ FORMAT TC & XC AXES -----
    % Add X Label
    if use_aep == 1
        xlabel(ax_tc_hc_swl,{'Annual Exceedance Probability, AEP'},'FontSize',ax_label_fnt,'FontWeight','bold');
        xlabel(ax_tc_hc_hm0,{'Annual Exceedance Probability, AEP'},'FontSize',ax_label_fnt,'FontWeight','bold');
    else
        xlabel(ax_tc_hc_swl,{'Annual Exceedance Frequency, AEF [1/yr]'},'FontSize',ax_label_fnt,'FontWeight','bold');
        xlabel(ax_tc_hc_hm0,{'Annual Exceedance Frequency, AEF [1/yr]'},'FontSize',ax_label_fnt,'FontWeight','bold');
    end
    % Add XC Titles
    title(ax_xc_hc_swl,['XC  | SWL | ' region ' | SP' num2str(sp_ID)],'FontSize',title_fnt,'FontWeight','bold');
    title(ax_xc_hc_hm0,['XC  | Hm0 | ' region ' | SP' num2str(sp_ID_wave)],'FontSize',title_fnt,'FontWeight','bold');
    % Add TC Titles
    title(ax_tc_hc_swl,['TC  | SWL | ' region ' | SP' num2str(sp_ID)],'FontSize',title_fnt,'FontWeight','bold');
    title(ax_tc_hc_hm0,['TC  | Hm0 | ' region ' | SP' num2str(sp_ID_wave)],'FontSize',title_fnt,'FontWeight','bold');
    % Define SWL Y Lim
    ax_tc_hc_swl.YLim = [y_limit.(pDatasets{ii})(1).min y_limit.(pDatasets{ii})(1).max];
    ax_xc_hc_swl.YLim = [y_limit.(pDatasets{ii})(1).min y_limit.(pDatasets{ii})(1).max];
    % Defien Hm0 Y Lim
    ax_tc_hc_hm0.YLim = [y_limit.(pDatasets{ii})(2).min y_limit.(pDatasets{ii})(2).max];
    ax_xc_hc_hm0.YLim = [y_limit.(pDatasets{ii})(2).min y_limit.(pDatasets{ii})(2).max];
    % Set XTicks
    helper_str = {'ax_tc_hc_swl','ax_tc_hc_hm0','ax_xc_hc_swl','ax_xc_hc_hm0'};
    for hh = 1:length(helper_str)
        eval([helper_str{hh} '.XTick = xticks_data;']);
        eval([helper_str{hh} '.XTickLabel = xticks_data_lbl;']);
        eval([helper_str{hh} '.XLim = x_lim;']);
    end
    % Create textbox
    annotation(Figure0,'textbox',...
        [0.5 0.967812729409427 0.056835935922572 0.0343818572767479],...
        'String',pDatasets(ii),...
        'FontWeight','bold',...
        'FontSize',title_fnt,...
        'FitBoxToText','on',...
        'EdgeColor','none');
    % Add Legend
    legend2 = legend(ax_xc_hc_swl);
    % Get Legend Title Handle
    htitle = get(legend2,'Title');
    % Define Legend Location
    set(legend2,'Location','southeast','FontSize',ax_tick_fnt,'Orientation','horizontal','NumColumns',3);
    % Define Legened Title
    set(htitle,'String','Confidence Levels');

    %----- PLOT DATA -------
    if contains('XC',storm_types)
        % Plot Each Storm
        p_xc = plot(ax_xc,sData.('XC').(pDatasets{ii}).SWL,sData.('XC').(pDatasets{ii}).Hm0,'o','MarkerSize',2);
        % Plot Each HC
        for i = 1:length(CLs)
            % Define Curve Name
            if CLs(i) == 50
                DataName = 'Best Estimate';
            else
                DataName = [num2str(CLs(i)) '%'];
            end
            % PLot CL into XC Axes
            p1 = plot(ax_xc_hc_swl,xc_x,hcData.('XC').(pDatasets{ii})(1).y_plot(:,i),colorstr{i},'LineWidth',2,'DisplayName',DataName);
            p2 = plot(ax_xc_hc_hm0,xc_x,hcData.('XC').(pDatasets{ii})(2).y_plot(:,i),colorstr{i},'LineWidth',2,'DisplayName',DataName);            % Update Data Tip
            % Create Data Tip Vector
            row = dataTipTextRow('RowID', 1:length(xc_x));
            % Append New Data Tip
            p1.DataTipTemplate.DataTipRows(end+1) = row;
            p2.DataTipTemplate.DataTipRows(end+1) = row;
        end
    end

    if contains('TC', storm_types)
        % Plot Each Storm
        p_tc = plot(ax_tc,sData.('TC').(pDatasets{ii}).SWL,sData.('TC').(pDatasets{ii}).Hm0,'o','MarkerSize',2);
        % Plot Each HC
        for i = 1:length(CLs)
            % Define Curve Name
            if CLs(i) == 50
                DataName = 'Best Estimate';
            else
                DataName = [num2str(CLs(i)) '%'];
            end
            % PLot CL into TC Axes
            p3 = plot(ax_tc_hc_swl,tc_x,hcData.('TC').(pDatasets{ii})(1).y_plot(:,i),colorstr{i},'LineWidth',2,'DisplayName',DataName);
            p4 = plot(ax_tc_hc_hm0,tc_x,hcData.('TC').(pDatasets{ii})(2).y_plot(:,i),colorstr{i},'LineWidth',2,'DisplayName',DataName);            % Update Data Tip
            % Create Data Tip Vector
            row2 = dataTipTextRow('RowID', 1:length(tc_x));
            % Append New Data Tip
            p3.DataTipTemplate.DataTipRows(end+1) = row2;
            p4.DataTipTemplate.DataTipRows(end+1) = row2;
        end
    end
    % Save Figure
    saveas(Figure0,[outpath filesep 'StormSim_' pDatasets{ii} '_Project_Forcing_and_Hazard_Curve_Comparison'],'png');
    close all;
end
end



