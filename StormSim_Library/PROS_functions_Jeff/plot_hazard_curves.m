function plot_hazard_curves(config,plt)
    
    %% CREATE OUTPUT DIR 
    % Define Project OPutputs Path 
    outName = ['PROS_Output' filesep config.casename filesep config.structID];
    % Create Directory
    mkdir(outName);
   
    %% Plot hazard curves and save out
    % Grab CLs
    prc = [50,cellfun(@str2double,strsplit(config.resp_CL(2:end-1),{' '}))];
    
    % For Each Variable In PLOT
    for k = 1:length(plt)
        % Initialize Figure Handle
        Figure0 = figure('Visible','off');
        % Initialize Axes Handle
        ax = gca;
        % Define Y-Axis Type (Linear or Log)
        if plt(k).yLogSwitch ==0
            set(ax,'XScale','log','YScale','linear','XGrid','on','XMinorTick','on','YGrid','on','YMinorTick','on',...
                'FontSize',16,'XTick',[1 10 100 1000 10000],...
                'XTickLabel',{'10^{0}','10^{-1}','10^{-2}','10^{-3}','10^{-4}'});
        else
            set(ax,'XScale','log','YScale','log','XGrid','on','XMinorTick','on','YGrid','on','YMinorTick','on',...
                'FontSize',16,'XTick',[1 10 100 1000 10000],...
                'XTickLabel',{'10^{0}','10^{-1}','10^{-2}','10^{-3}','10^{-4}'});
        end
        % Define Y Axis Limits
        if isempty(plt(k).minylim)==0
            ylim(ax,[plt(k).minylim inf])
        end
        % Define X Limits
        xlim(ax,[1 10000]);
        % Define Color Pallet
        colorstr = {'k-','b-.','r-.','r--','b--'};
        % Hold Axis Properties
        hold(ax,'on');
        % For Each CL
        for i = 1:length(plt(k).x(1,:))
            % Define Curve Name
            DataHeaders(i) = {[num2str(prc(i)) '_CL']};
            % PLot CL into Axes
            p = plot(ax,plt(k).x(:,i),plt(k).y(:,i),colorstr{i},'LineWidth',2,'DisplayName',[num2str(prc(i)) '%']);
            % Update Data Tip
            row = dataTipTextRow('RowID', 1:length(plt(k).x(:,i)));
            % Append Neew Data Tip
            p.DataTipTemplate.DataTipRows(end+1) = row;
        end
        % Determine Storm Sampling In Outputs
        sFlag = strsplit(plt(k).plotDesc,{'_',':'});sFlag = sFlag{2};
        % Define Figure Title
        title(ax,{['StormSim JPA ',char(8211),' SP: ',num2str(config.sp_ID)];...
            [plt(k).staID,' | ',sFlag,]},'FontSize',14);
        % Define X Label
        xlabel(ax,{'Annual Exceedance Frequency, AEF'},'FontSize',16);
        % Define Y Label
        if strcmp(plt(k).staID,'Dn50_LCBW')
            ylabel(ax,{['Dn50 LCBW',' [',plt(k).units,']']},'FontSize',16);
        else
            ylabel(ax,{[plt(k).staID,' [',plt(k).units,']']},'FontSize',16);
        end
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
        
        saveName = strcat([outName filesep 'StormSim_PROS_',config.casename,'_',config.structID,'_',plt(k).staID]);
        saveas(Figure0,saveName,'png')
        savefig(Figure0,saveName);
        
        % Clear Axes
        cla(ax);
    end
end



