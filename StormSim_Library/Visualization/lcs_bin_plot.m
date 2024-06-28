function [ax, bin_data, xx, yy] = lcs_bin_plot(ax, stm_data, resp_vector, nYears, resp_var, bin_edges, norm_type, log_x_scale, x_ticks, x_ticks_str, cb_ticks, cb_lim, cmap_to_use, grid_on)
% Define Normalization
switch norm_type
    case 'count'
        bin_type = 1;
        y_label_cb = 'Count of Total Events On Yearly Bin';
    case 'percent'
        bin_type = 0;
        y_label_cb = 'Percentage of Total Events On Yearly Bin';
    otherwise
        print('Please use ''count'' or ''percent'' as the normalization type. Defaulting to percent');
        bin_type = 0;
        y_label_cb = 'Percentage of Total Events On Yearly Bin';
end
% Define Current Axes
if isempty(ax)
    % Initialize Figure
    figure('Units','Normalized','Position',[0.15078125,0.165972222222222,0.743359375,0.549305555555555]);
    ax = gca;
    % Hold On
    hold(ax,'on');
    % Add Title
    title({[resp_var ' Distribution By Sim Year']});
else
    hold(ax,'on');
end

% Compute Mesh Grid
[xx,yy] = meshgrid(bin_edges, 1:nYears);
% Compute Mean Maximum Yearly Curve (q)
[~,~,yBox,~] = compute_lcs_yearly_curve({stm_data.LCNUM}, {resp_vector.LCNUM}, nYears, 0);
% Initialize Histogram Count Matrix
bin_percent=[];bin_count = [];
% Loop Across All Years
for mm = 1:nYears
    % Compute Histogram Count For All Storm At Year N
    [Nq, edgesq] = histcounts(yBox{mm},bin_edges);
    % Compute Percentage of Each Bin Give Sample Size
    bin_percent= [bin_percent; 100*(Nq/sum(Nq))];
    bin_count = [bin_count; Nq];
end
% Remove 0% Entries
bin_percent(bin_percent == 0) = NaN;
bin_count(bin_count == 0) = NaN;
% Pick Data To Plot
if bin_type == 1
    bin_data = bin_count;
else
    bin_data = bin_percent;
end
%
if log_x_scale == 1
    %
    number = num2str(round(max(cellfun(@max, yBox)),2));
   
    %
    x_ticks_str(end) = {['x<' number]};
else
    x_ticks_str(end) = {['x<' num2str(round(max(cellfun(@max, yBox)),2))]};
end
%% ADJUST X TICKS IF NEEDED
if log_x_scale == 1
    if x_ticks(1) == 0
        n = floor(log(abs(x_ticks(2)))./log(10));
        x_ticks(1) = (x_ticks(2)-5*(10^n/10));
    end
    x_scale = 'log';
else
    x_scale = 'linear';
end
% Replace Infinity Entries For Plot Purposes
if xx(1,end) == Inf
    xx(xx == Inf) = x_ticks(end);
end
% Replace -Infinity Entries For Plot Purposes
if xx(1,1) == -Inf
    xx(xx == -Inf) = x_ticks(1);
end

%% INITIALIZE AND FORMAT AXES
% Format Axis
set(ax,'FontSize',16, 'FontWeight', 'bold','XGrid','on','XMinorGrid',...
    'off','YGrid','on','YMinorGrid','off','Box','on');
% Format X Ticks
xticks(ax, x_ticks);
xticklabels(ax, x_ticks_str);
xlim(ax, [min(x_ticks) max(x_ticks)]);
ylim(ax, [1, nYears]);
% Add Labels
xlabel(ax, [resp_var ' Bins']);
ylabel(ax, 'Simulation Year');
% Define Colormap
if isempty(cmap_to_use)
    customColormap = ss_colormap; % Call Custom Colormap
    colormap(ax,customColormap);
else
    try
        colormap(ax,cmap_to_use);
    catch
        customColormap = ss_colormap; % Call Custom Colormap
        colormap(ax,customColormap);
    end
end
% Add Colorbars
hb = colorbar(ax);
% Limit Color Scaling
if ~isempty(cb_lim)
    clim(cb_lim);
end
% Add Ticks TO Colorbar If Needed
if ~isempty(cb_ticks)
    % Set the colorbar tick locations
    hb.Ticks = cb_ticks;
end
% y Label For Colorbar
ylabel(hb, y_label_cb);

%% PLOT BIN DATA
% Plot Percent PColor
if log_x_scale == 1
    pp=pcolor(ax, xx, yy, [bin_data,nan(size(bin_data, 1), 1)]);
    ax.XScale = x_scale;
else
    pp=pcolor(ax, xx, yy, [bin_data,nan(size(bin_data, 1), 1)]);
end
if grid_on == 1
    pp.EdgeColor = 'k';
    pp.LineWidth = 1.3;
end

%% ADD DATA TIP FOR COLOR
% Add Z Value To Data Tip
% Generate an invisible datatip to ensure that DataTipTemplate is generated
dt = datatip(pp,pp.XData(1),pp.YData(1),'Visible','off');
% Replace datatip row labeled Z with CData
idx = strcmpi('Z',{pp.DataTipTemplate.DataTipRows.Label});
newrow = dataTipTextRow('C',pp.CData);
pp.DataTipTemplate.DataTipRows(idx) = newrow;
% Remove invisible datatip
delete(dt);
% Remove Hold On Axes
hold(ax, 'off');
end
