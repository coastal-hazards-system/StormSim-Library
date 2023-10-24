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
fig.Position = [0.5,0.35,0.40,0.45];
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
    case 1 % Levee
        % Define Seward Slope
        seaside_slope = structure.('seaside_slope');
        % Define Landward Slope
        leeside_slope = structure.('leeside_slope');
        % Initialize Shape Variables
        xs = zeros(1,5);ys=xs;
        % Point 1 - Seaside Toe
        ys(1) = toe;xs(1) = 0;
        % Point 2 - Toe to Seaside Crest Path
        b = (-1/seaside_slope)*xs(1)+ys(1);% Y Intercept of line
        ys(2) = crest_elevation;xs(2) = (ys(2) - b)*seaside_slope;
        % Point 3 - Crest Width
        ys(3) = ys(2);xs(3) = xs(2) + crest_width;
        % Point 4 - Leeside Toe
        b = (1/leeside_slope)*xs(3)+ys(3);
        ys(4) = ys(1);xs(4) = (ys(4) - b)*-leeside_slope;
        % Point 5
        xs(5) = xs(1);ys(5) = ys(1);
        % Horizontal Shift (Make Structure Centralized)
        xs = xs + 1;
    case 2 % Floodwalls
        %%%%% Create Berm
        % Define Berm Slope
        berm_slope = structure.('berm_slope');
        % Define Berm Elevation
        berm_elev = structure.('berm_elevation');
        % Define Berm Width
        berm_width = structure.('berm_width');
        % Initialize Shape Variables
        xs_berm = zeros(1,4);ys_berm=xs_berm;
        % Wall Toe
        xs_berm(1) = 0;ys_berm(1) = toe;
        % Point 2 - Toe to Seaside Crest Path
        b = (-1/berm_slope)*xs_berm(1)+ys_berm(1);
        % Y Intercept of line
        ys_berm(2) = berm_elev;xs_berm(2) = (ys_berm(2) - b)*berm_slope;
        % Point 3 - Crest Width
        ys_berm(3) = ys_berm(2);xs_berm(3) = xs_berm(2) + berm_width;
        % Wall Width (Width Is Visual Only)
        xs_berm(4) = xs_berm(3) + 0.25+0.5;ys_berm(4) = ys_berm(3);
        xs_berm(5) = xs_berm(4);ys_berm(5) = ys_berm(1);
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
    case 3 % Rubblemound
        % Define Seward Slope
        seaside_slope = structure.('seaside_slope');
        % Define Landward Slope
        leeside_slope = structure.('leeside_slope');
        % Initialize Shape Variables
        xs = zeros(1,5);ys=xs;
        % Point 1 - Seaside Toe
        ys(1) = toe;xs(1) = 0;
        % Point 2 - Toe to Seaside Crest Path
        b = (-1/seaside_slope)*xs(1)+ys(1);% Y Intercept of line
        ys(2) = crest_elevation;xs(2) = (ys(2) - b)*seaside_slope;
        % Point 3 - Crest Width
        ys(3) = ys(2);xs(3) = xs(2) + crest_width;
        % Point 4 - Leeside Toe
        b = (1/leeside_slope)*xs(3)+ys(3);
        ys(4) = ys(1);xs(4) = (ys(4) - b)*-leeside_slope;
        % Point 5
        xs(5) = xs(1);ys(5) = ys(1);
end

%% FORMAT AXIS LIMITS AND PLOT GEOMETRIES
% Define Axis Limits
if structure_type~=2
    % Horizontal Shift (Make Structure Centralized)
    xs = xs + 4;
    % Define Limits
    ax.XLim = [0 max(xs)+1];
else
    xs_berm = xs_berm + 1;
    xs = xs + 1;
    ax.XLim = [0 max([xs;xs_berm],[],'all')];
    % Create Berm Geo
    berm_geo = polyshape(xs_berm,ys_berm);
    % Plot Structure
    plot(ax,berm_geo,'FaceColor',[0.65,0.65,0.65],'FaceAlpha',1);
end
ax.YLim = [toe-0.5 max(ys)+0.5];
% Create Structure Polyshape
struc_geo = polyshape(xs,ys);
% Create "Sand" Polyshape
sand_geo = polyshape([ax.XLim(1) ax.XLim(1) ax.XLim(2)+4 ax.XLim(2)+4],[toe-6 toe toe toe-6]);
% Plot Structure
plot(ax,struc_geo,'FaceColor',[0.65,0.65,0.65],'FaceAlpha',1);
% Plot Sand
plot(ax,sand_geo,'FaceColor',[0.9 0.72 0.31],'FaceAlpha',1);

%% EXPORT FIGURE
saveas(fig, [project_name filesep structure_id filesep case_name filesep project_name '_' structure_id '_' case_name '_structure_cross_section.png']);
warning('on','all');
end