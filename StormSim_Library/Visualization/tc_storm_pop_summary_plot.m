function tc_storm_pop_summary_plot(config, sData, prob_mass, ts_switch, outpath)
%% PULL DATA
% Define Plot Field
plt_fld = 'y_plot';
plt_fld_x = 'x_plot';
nrows = 1;
ncols = 2;
%
workflow = config.workflow;
% Scan Peak Datasets
storm_types = sort(fieldnames(sData));
storm_types = storm_types(contains(storm_types,{'XC','TC'}));

% Remove Other HCs
for ii = 1:length(storm_types)
    % Timeseries/Peaks
    if ts_switch == 0 % Peaks
        % Find Peak Datasets Fieldnames
        pDatasets = fieldnames(sData.(storm_types{ii}).Peaks);
        % Loop Through Fieldnames
        for jj = 1:length(pDatasets)
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
sp_ID_wave = config.sp_ID_wave;
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

%% PLOT EACH RESPONSE FOR EACH DATASET
% For Each Peaks Dataset (Maxima, WLP, WHP)
for ii = 1:length(pDatasets)
    % Initialize Figure Handle
    Figure0 = figure('Units','normalized','Position',[0 0 1 1],'Visible','off');
    % Create textbox
    annotation(Figure0,'textbox',...
        [0.5 0.967812729409427 0.056835935922572 0.0343818572767479],...
        'String',pDatasets(ii),...
        'FontWeight','bold',...
        'FontSize',title_fnt,...
        'FitBoxToText','on',...
        'EdgeColor','none');
        % Number of TC's
        tc_nstm = num2str(length(sData.('TC').(pDatasets{ii}).SWL));

    % ---- FORMAT TC STORM DATA AXES----%
    % Initialize Event Population Axes Handle
    ax_tc = subplot(nrows, ncols, 1);
    ax_tc = ax_ini(ax_tc, ax_tick_fnt, ax_label_fnt, title_fnt, ['SWL [m, ' datum ']'], 'H_{m_{0}} [m]', ['TC Storms | ' tc_nstm ' | Color: AEF']);
    % Initialize Population Frequency
    ax_tc_freq = subplot(nrows, ncols,2);
    ax_tc_freq = ax_ini(ax_tc_freq, ax_tick_fnt, ax_label_fnt, title_fnt, hc_label, ['SWL [m, ' datum ']'], 'H_{m_{0}} [m]', ['TC Storms | ' tc_nstm ' | Color: Storminess Bin']);

    %----- PLOT DATA -------
        % Plot Each Storm
         p_tc = scatter(ax_tc, sData.('TC').(pDatasets{ii}).SWL, sData.('TC').(pDatasets{ii}).Hm0, 5, prob_mass.TC_Freq, 'filled');
        p = plot(ax_tc_freq, sData.('TC').(pDatasets{ii}).SWL(prob_mass.Param(:,5)>=48), sData.('TC').(pDatasets{ii}).Hm0(prob_mass.Param(:,5)>=48), 'r','LineWidth',2,'DisplayName','/deltaP >= 48');
        p = plot(ax_tc_freq, sData.('TC').(pDatasets{ii}).SWL(prob_mass.Param(:,5)<28), sData.('TC').(pDatasets{ii}).Hm0(prob_mass.Param(:,5)<28), 'g','LineWidth',2,'DisplayName','/deltaP >= 48');
        p = plot(ax_tc_freq, sData.('TC').(pDatasets{ii}).SWL(prob_mass.Param(:,5)>=28 && prob_mass.Param(:,5)<48), sData.('TC').(pDatasets{ii}).Hm0(prob_mass.Param(:,5)>=28 && prob_mass.Param(:,5)<48), 'y','LineWidth',2,'DisplayName',' 28 < /deltaP < 48');

hc = colorbar(ax_tc);
colormap(hc,'jet');
            % Add Legend
    legend2 = legend(ax_tc_freq);
    % Get Legend Title Handle
%     htitle = get(legend2,'Title');
    % Define Legend Location
    set(legend2,'Location','southeast','FontSize',ax_tick_fnt,...
        'Orientation','horizontal','NumColumns',3,...
        'FontSize', 16);
    % Define Legened Title
%     set(htitle,'String','Confidence Levels','FontSize',16);
    % Save Figure
    saveas(Figure0,[outpath filesep 'StormSim_' pDatasets{ii} '_Project_Forcing_and_Hazard_Curve_Comparison'],'png');
    close all;
end
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
end



