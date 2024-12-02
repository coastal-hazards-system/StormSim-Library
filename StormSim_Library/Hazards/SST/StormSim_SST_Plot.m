%% StormSim_SST_Plot.m
%{
SOFTWARE NAME:
    StormSim-SST-Plot (Plot Statistics)

DESCRIPTION:
   This script plots the outputs of the StormSim_MRL.m function and the
   hazard curve generated with the StormSim_SST_Fit.m

INPUT ARGUMENTS:
  - HC_emp: output from StormSim_SST_Fit.m
  - HC_plt: output from StormSim_SST_Fit.m
  - HC_plt_x: output from StormSim_SST_Fit.m
  - MRL_out: output from StormSim_SST_Fit.m
  - prc: percentage values for computing the percentiles; specified as a
      scalar or vector of positive values. Leave empty [] to apply default
      values 2%,16%,84%,98%. User can enter 1 to 4 values.
      Example: prc = [2 16 84 98];
  - use_AEP: indicator for expressing the hazard as AEF or AEP. Use 1 for
      AEP, 0 for AEF. Example: use_AEP = 1;
  - staID: gauge station information; specified as a cell array with format:
      Col(01): gauge station ID number; as a character vector. Example: '8770570'
      Col(02): station name (OPTIONAL); as a character vector. Example: 'Sabine Pass North TX'
  - yaxis_Label: parameter name/units/datum for label of the plot y-axis;
      specified as a character vector. Example: 'Still Water Level (m, MSL)'
  - path_out: path to output folder; specified as a character vector. Leave
      empty [] to apply default: '.\SST_plots\'
  - yaxis_Limits: lower and upper limits for the plot y-axis; specified as a
      vector. Leave empty [] otherwise. Example: yaxis_Limits = [0 10];
  - GPD_TH_crit: indicator for specifying the GPD threshold option of the
      Mean Residual Life (MRL) selection process; specified as a scalar. Use as follows:
      > GPD_TH_crit = 0: to evaluate all thresholds identified by the MRL method
      > GPD_TH_crit = 1: to evaluate the MRL threshold selected by the Sample Intensity criterion
      > GPD_TH_crit = 2: to evaluate the MRL threshold selected by the minimum WMSE criterion
  - a: MATLAB release; used to select either "exportgraphics" or "saveas"
      as the method for saving the plots.

OUTPUT ARGUMENTS:
   The output are plots automatically stored in the output path. The plots
   are of hazard curves with confidence levels the specified in input "prc".

AUTHORS:
    Norberto C. Nadal-Caraballo, PhD (NCNC)
    Efrain Ramos-Santiago (ERS)

HISTORY OF REVISIONS:
20200903-ERS: revised.
20201015-ERS: revised. Updated documentation.
20210324-ERS: alpha version 4: updated the x label for the hazard plots.
20210325-ERS: alpha version 4: adjusted the script to read new format of
    MRL output. Hazard plots will now apply different x-axis labels based on
    value of use_AEP. Plot filename identifies by MRL criteria.
20210406-ERS: alpha v0.4: modified to account for the default GPD threshold.
20210430-ERS: alpha v0.4: updated.

***************  ALPHA  VERSION  **  FOR INTERNAL TESTING ONLY ************
%}
function StormSim_SST_Plot(HC_plt,HC_emp,MRL_output,prc,staID,yaxis_Label,path_out,yaxis_Limits,use_AEP,GPD_TH_crit,a,HC_plt_x)

% Colors for percentiles plots
cs={'r-.','b--','b--','r-.'};
if length(prc)<4,cs={'r-.','b-.','m-.'};end
prc=round(prc);

if ~strcmp(HC_plt(1).MRL_Crit,'None') %plot these only when the GPD fit occurred
    
    %% Plot Mean residual life results
    mrl = MRL_output.Summary;
    TH = MRL_output.Selection.Threshold;
    crit = MRL_output.Selection.Criterion;
    if strcmp(MRL_output.Status,'')
        
        fig=figure('units','inches','Position',[1 1 6 6],'Color',[1 1 1],'visible','off');
        axes('XGrid','on','XMinorTick','on','YGrid','on','YMinorTick','on','FontSize',12);
        
        subplot(5,1,1)
        hold on
        ylim([round(min(mrl.Rate)-0.01,2) round(max(mrl.Rate)+0.01,2)]);
        yl=ylim;
        plot(mrl.Threshold,mrl.Rate,'g-','LineWidth',2);
        str={'k:','k--'};
        if ~isempty(TH)
            for i=1:length(TH)
                h(i).p = plot([TH(i) TH(i)],[yl(1) yl(2)],str{i},'LineWidth',2); %#ok<AGROW>
            end
            legend([h.p],crit,'Location','NorthEast')
        end
        
        if length(staID)==1
            title({'StormSim-SST - Mean Residual Life';['Station: ',staID{1}]},'FontSize',12);
        else
            title({'StormSim-SST ';['Station: ',staID{1},' ',staID{2}]},'FontSize',12);
        end
        
        ylabel({'Events';'per year'},'FontSize',12);
        hold off
        
        subplot(5,1,2)
        hold on
        ylim([round(min(mrl.WMSE)-0.01,2) round(max(mrl.WMSE)+0.01,2)]);
        yl=ylim;
        plot(mrl.Threshold,mrl.WMSE,'LineWidth',2,'Color','m');
        
        if ~isempty(TH)
            for i=1:length(TH)
                plot([TH(i) TH(i)],[yl(1) yl(2)],str{i},'LineWidth',2);
            end
        end
        ylabel({'Weighted';'MSE'},'FontSize',12);
        hold off
        
        subplot(5,1,3)
        hold on
        ylim([round(min(mrl.MeanExcess)-0.01,2) round(max(mrl.MeanExcess)+0.01,2)]);
        yl = ylim;
        plot(mrl.Threshold,mrl.MeanExcess,'LineWidth',2,'Color','k');
        
        if ~isempty(TH)
            for i=1:length(TH)
                plot([TH(i) TH(i)],[yl(1) yl(2)],str{i},'LineWidth',2);
            end
        end
        
        ylabel({'Mean';'Excess'},'FontSize',12);
        hold off
        
        subplot(5,1,4)
        hold on
        ylim([round(min(mrl.GPD_Shape)-0.01,2) round(max(mrl.GPD_Shape)+0.01,2)]);
        yl = ylim;
        plot(mrl.Threshold,mrl.GPD_Shape,'LineWidth',2,'Color','b');
        if ~isempty(TH)
            for i=1:length(TH)
                plot([TH(i) TH(i)],[yl(1) yl(2)],str{i},'LineWidth',2);
            end
        end
        ylabel({'Shape';'Parameter'},'FontSize',12);
        hold off
        
        subplot(5,1,5)
        hold on
        ylim([round(min(mrl.GPD_Scale)-0.01,2) round(max(mrl.GPD_Scale)+0.01,2)]);
        yl = ylim;
        plot(mrl.Threshold,mrl.GPD_Scale,'LineWidth',2,'Color','r');
        if ~isempty(TH)
            for i=1:length(TH)
                plot([TH(i) TH(i)],[yl(1) yl(2)],str{i},'LineWidth',2);
            end
        end
        xlabel(['Threshold: ',yaxis_Label],'FontSize',12);
        ylabel({'Scale';'Parameter'},'FontSize',12);
        hold off
        
        fname = [path_out,'SST_','MRL_',staID{1},'.png'];
        switch a
            case 0
                exportgraphics(gcf,fname,'Resolution',150)
            case 1
                saveas(gcf,fname,'png')
        end
        close(fig);
    end
    
    %% Plot GPD parameters from bootstrap per threshold
    mn_k = mean(MRL_output.pd_k_wOut,1,'omitnan');
    mn_k2 = mean(MRL_output.pd_k_mod,1,'omitnan');
    if isempty(TH),sz=1;else,sz=length(TH);end
    pObj(sz).p=[];
    
    fig=figure('Color','w','visible','off');
    for j=1:sz
        switch crit{j}
            case 'CritWMSE'
                str = 'WMSE Criterion';
            case 'CritSI'
                str = 'Sample Intensity Criterion';
            case 'Default'
                str = 'Default';
            otherwise
                str = 'None';
        end
        
        pObj(j).p = subplot(sz,1,j);
        subplot(sz,1,j)
        hold on
        histogram(MRL_output.pd_k_wOut(:,j),'BinWidth',.05,'FaceColor','b') %original
        histogram(MRL_output.pd_k_mod(:,j),'BinWidth',.05,'FaceColor','r') %w/outliers filled
        y1=ylim;
        plot([mn_k(j) mn_k(j)],[y1(1) y1(2)],'b-','LineWidth',2)
        plot([mn_k2(j) mn_k2(j)],[y1(1) y1(2)],'r-.','LineWidth',2)
        xlabel(['GPD Shape Parameter - MRL Threshold - ',str],'FontSize',12);
        ylabel('Count','FontSize',12)
        hold off
    end
    
    legend(pObj(1).p,{'hist w/outliers','hist w/o outliers','mean w/outliers',...
        'mean w/o outliers'},'Location','northwest','FontSize',8)
    fname = [path_out,'SST_CompareGPDShape_',staID{1},'.png'];
    switch a
        case 0
            exportgraphics(gcf,fname,'Resolution',150)
        case 1
            saveas(gcf,fname,'png')
    end
    close(fig);

    %% Plot Hazard Curve
    j=1:length(TH);
    for k=j %TH loop
        
        % Take probs and mean values
        Boot_mean_plt = HC_plt(k).out(1,:);
        
        % Take percentiles
        Boot_plt=[];
        if size(HC_plt(k).out,1)>2
            Boot_plt = HC_plt(k).out(2:end,:);
        end
        
        % Do plot
        fig=figure('Color',[1 1 1],'visible','off');
        axes('xscale','log','XGrid','on','XMinorTick','on','YGrid','on','YMinorTick','on','FontSize',12);
        if use_AEP
            xlim([1e-4 1]);
            XTick=[1e-4 1e-3 1e-2 1e-1 1];
        else
            xlim([1e-4 10]);
            XTick=[1e-4 1e-3 1e-2 1e-1 1 10];
        end
        
        if ~isempty(yaxis_Limits)
            ylim([min(yaxis_Limits) max(yaxis_Limits)]);
        end
        set(gca,'XDir','reverse','XTick',XTick)
        hold on
        
        % Process the percentiles
        pObj=struct('o',[],'n',[],'L','');
        for i=1:length(prc)
            pObj(i).o = plot(HC_plt_x,Boot_plt(i,:),cs{i},'LineWidth',2);
            pObj(i).n = prc(i);
            pObj(i).L = {['CL',int2str(prc(i)),'%']};
        end
        pObj_t = struct2table(pObj);
        pObj_t = sortrows(pObj_t,'n','descend'); % sort the table by 'n'
        
        % Take percentiles
        t1 = pObj_t(pObj_t.n>50,:); t1 = table2struct(t1); %above the mean
        t2 = pObj_t(pObj_t.n<50,:); t2 = table2struct(t2); %below the mean
        
        % Mean and Empirical
        h1 = plot(HC_plt_x,Boot_mean_plt,'k-','LineWidth',2); % Mean
        h2 = scatter(HC_emp.Hazard,HC_emp.Response,10,'g','filled','MarkerEdgeColor','k'); % Historical
        
        % Title
        if length(staID)==1
            title({'StormSim-SST ';['Station: ',staID{1}]},'FontSize',12);
        else
            title({'StormSim-SST ';['Station: ',staID{1},' ',staID{2}]},'FontSize',12);
        end
        
        % Axes labels
        if use_AEP
            xlabel('Annual Exceedance Probability','FontSize',12);
        else
            xlabel('Annual Exceedance Frequency (yr^{-1})','FontSize',12);
        end
        ylabel({yaxis_Label},'FontSize',12);
        
        % Legend
        legend([[t1.o],h1,[t2.o],h2],{t1.L,'Mean',t2.L,'Empirical'},...
            'Location','southoutside','Orientation','horizontal','NumColumns',5,'FontSize',10);
        hold off
        
        % Filename
        if GPD_TH_crit==0
            fname = [path_out,'SST_','HC_',staID{1},'_TH_',crit{k},'.png'];
        else
            fname = [path_out,'SST_','HC_',staID{1},'.png'];
        end
        
        % Save figure
        switch a
            case 0
                exportgraphics(gcf,fname,'Resolution',150)
            case 1
                saveas(gcf,fname,'png')
        end
        close(fig);
    end
else
    
    %% Plot Hazard Curve
    
    % Take probs and mean values
    Boot_mean_plt = HC_plt(1).out(1,:);
    
    % Take percentiles
    Boot_plt=[];
    if size(HC_plt(1).out,1)>2
        Boot_plt = HC_plt(1).out(2:end,:);
    end
    
    % Do plot
    fig=figure('Color',[1 1 1],'visible','off');
    axes('xscale','log','XGrid','on','XMinorTick','on','YGrid','on','YMinorTick','on','FontSize',12);
    if use_AEP
        xlim([1e-4 1]);
        XTick=[1e-4 1e-3 1e-2 1e-1 1];
    else
        xlim([1e-4 10]);
        XTick=[1e-4 1e-3 1e-2 1e-1 1 10];
    end
    
    if ~isempty(yaxis_Limits)
        ylim([min(yaxis_Limits) max(yaxis_Limits)]);
    end
    set(gca,'XDir','reverse','XTick',XTick)
    hold on
    
    % Process the percentiles
    pObj=struct('o',[],'n',[],'L','');
    for i=1:length(prc)
        pObj(i).o = plot(HC_plt_x,Boot_plt(i,:),cs{i},'LineWidth',2);
        pObj(i).n = prc(i);
        pObj(i).L = {['CL',int2str(prc(i)),'%']};
    end
    pObj_t = struct2table(pObj);
    pObj_t = sortrows(pObj_t,'n','descend'); % sort the table by 'n'
    
    % Take percentiles
    t1 = pObj_t(pObj_t.n>50,:); t1 = table2struct(t1); %above the mean
    t2 = pObj_t(pObj_t.n<50,:); t2 = table2struct(t2); %below the mean
    
    % Mean and Empirical
    h1 = plot(HC_plt_x,Boot_mean_plt,'k-','LineWidth',2); % Mean
    h2 = scatter(HC_emp.Hazard,HC_emp.Response,10,'g','filled','MarkerEdgeColor','k'); % Historical
    
    % Title
    if length(staID)==1
        title({'StormSim-SST ';['Station: ',staID{1}]},'FontSize',12);
    else
        title({'StormSim-SST ';['Station: ',staID{1},' ',staID{2}]},'FontSize',12);
    end
    
    % Axes labels
    if use_AEP
        xlabel('Annual Exceedance Probability','FontSize',12);
    else
        xlabel('Annual Exceedance Frequency (yr^{-1})','FontSize',12);
    end
    ylabel({yaxis_Label},'FontSize',12);
    
    % Legend
    legend([[t1.o],h1,[t2.o],h2],{t1.L,'Mean',t2.L,'Empirical'},...
        'Location','southoutside','Orientation','horizontal','NumColumns',5,'FontSize',10);
    hold off
    
    % Filename
    fname = [path_out,'SST_','HC_',staID{1},'_TH_None.png'];
    
    % Save figure
    switch a
        case 0
            exportgraphics(gcf,fname,'Resolution',150)
        case 1
            saveas(gcf,fname,'png')
    end
    close(fig);
end
end