function [fig] = plot_structure_geometry(config, structure)
%{
    %% DESCRIPTION
        This function creates MATLAB struture object containing project structure geometry.
    
    %% INPUTS
        config: Parsed CAST input file. | struc | 1 x number_of_inputs
        Required fields are listed below:
            config.
                   crest_elevation: Structure crest elevation
                   crest_width: Strucutre crest width.
                   seaside_slope: Structure seaward slope.
                   leeside_slope: Strucutre landward slope.
                   toe_elevation: Structure toe elevation (Nevative below datum zero)
    
    %% OUTPUTS
        structure: Formatted structure geometry details | struc | 1 x varies_per_struc_type
            structure.
         ------- All Structure Types Fields -------
                   crest_elevation: Structure crest elevation
                   crest_width: Structure crest width.
                   toe_elevation: Structure toe elevation (Negative below datum zero)
  
        ------- Rubblemound & Levee Only Fields -------
                   seaside slope: Structure seaward slope.
                   leeside slope: Structure landward slope.
   
 %% DEV SIGNATURE
    Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}
warning('off','all');
%% GRAB INPUT FROM "config"
%{
        This section meant to provide an easy way to make changes to config
        variable calls without having to alter core code.
%}
% Define Project Name
project_name = config.project_name;
% Define Prject Datum
project_datum = config.project_datum;
% Define Strucutre ID
structure_id = config.struc_id;
% Define Structure Type
structure_type = config.struc_type;
% Define Case Name
case_name = config.case_name;
% Datum
datum = config.project_datum;
%
outfolder = config.outfolder;

%% DEFINE FIGURE PROPERTIES
% Figure Title
fig_title = {['StormSim Project: ',project_name,' | Transect ID: ',structure_id,''];'Structure Cross-section'};
% Title Font
font_title = 20;
% Axis Title
font_axes = font_title - 3;
% X Axes Label
x_label = 'X [m]';
% Y Axes Label
y_label = ['Elevation [',project_datum,', m]'];

%% INITIALIZE & FORMAT FIGURE/AXES
% Initialize Figure Handle
fig = figure('Name','Structure_Cross-section','Visible','off','Units','Normalized');
% Resize Figure
fig.Position = [0.5,0.35,0.40,0.70];
% Initialize Figure Axes
ax = gca;
% Enable Hold Properties Option
hold(ax,'on');
% Turn On Axes Grid
grid(ax,'on');
grid(ax,'minor');
% Define Axes Font Size
ax.FontSize = font_axes;
ax.FontWeight = 'bold';
% Labels
xlabel(ax, 'X Distance [m]');
ylabel(ax, ['Elevation ,' datum ' [m]']);
% Create Title
title(fig_title, 'FontWeight', 'bold', 'FontSize', font_title, 'Interpreter', 'none');

%% CREATE STRUCTURE GEOMETRY
% Define Toe Elevation
toe = structure.('toe_elevation');
% Define Crest Elevation
crest_elevation = structure.('crest_elevation');
% Define Crest Width
crest_width = structure.('crest_width');
switch structure_type
    case {1,3} % Levee
        % Define Seward Slope
        seaside_slope = 1/structure.('seaside_slope');
        % Define Landward Slope
        leeside_slope = 1/structure.('leeside_slope');
        % Initialize Shape Variables
        xs = zeros(1,5);ys=xs;
        % Point 1 - Seaside Toe
        ys(1) = toe;xs(1) = 0;
        % Point 2 - Toe to Seaside Crest Path
        b = (-1.*seaside_slope)*xs(1)+ys(1);% Y Intercept of line
        ys(2) = crest_elevation;xs(2) = (ys(2) - b).*(1./seaside_slope);
        % Point 3 - Crest Width
        ys(3) = ys(2);xs(3) = xs(2) + crest_width;
        % Point 4 - Leeside Toe
        b = (leeside_slope)*xs(3)+ys(3);
        ys(4) = ys(1);xs(4) = (ys(4) - b)*-(1/leeside_slope);
        % Point 5
        xs(5) = xs(1);ys(5) = ys(1);
        % Horizontal Shift (Make Structure Centralized)
        xs = xs + 1;
    case 2 % Floodwalls
        %%% Create Floodwall
        % Define Wall Bottom Elevation
        wall_bottom = structure.('wall_bottom_elevation');
        % Initialize Shape Variables
        xs = zeros(1,5);ys=xs;
        % Wall Toe
        xs(1) = xs_berm(3);ys(1) = wall_bottom;
        % Wall Toe To Crest Path
        xs(2) =  xs(1);ys(2) = (crest_elevation);
        % Wall Width (Width Is Visual Only)
        xs(3) = xs(2) + 0.25;ys(3) = ys(2);
        % Crest to Leeside Toe Path
        xs(4) = xs(3);ys(4) = ys(1);
        % Close Polyshape
        xs(5) = xs(1);ys(5) = ys(1);
end

%% FORMAT AXIS LIMITS AND PLOT GEOMETRIES
% Define Axis Limits
if structure_type~=2
    % Horizontal Shift (Make Structure Centralized)
    xs = xs + 1;
    % Define Limits
    ax.XLim = [0 max(xs)+1];
else
    xs = xs + 1;
    ax.XLim = [0 xs];
end
axis equal;
ax.YLim = [toe-0.5 max(ys)+0.5];
% Create Structure Polyshape
struc_geo = polyshape(xs,ys);
% Plot Structure
plot(ax,struc_geo,'FaceColor',[0.65,0.65,0.65],'FaceAlpha',1);

%% EXPORT FIGURE
saveas(fig, fullfile(outfolder, project_name, structure_id, case_name, [project_name '_' structure_id '_' case_name '_structure_cross_section.png']));
warning('on','all');
end