function [fig] = call_structure_geometry_plotter(config, structure)
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
    
    %% DEFINE FIGURE PROPERTIES
    % Figure Title
    fig_title = {['CAST Project: ',project_name,' | Transect ID: ',structure_id,''];'Structure Cross-section'};
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
        case 2 % Floodwalls
            % Initialize Shape Variables
            xs = zeros(1,5);ys=xs;
            % Wall Toe
            xs(1) = 0;ys(1) = toe;
            % Wall Toe To Crest Path
            xs(2) = 0;ys(2) = (crest_elevation);
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
    % Horizontal Shift (Make Structure Centralized)
    xs = xs + 1;
    
    %% FORMAT AXIS LIMITS AND PLOT GEOMETRIES
    % Define Axis Limits
    ax.XLim = [0 max(xs)+1];
    ax.YLim = [toe-0.5 max(ys)+0.5];
    % Create Structure Polyshape
    struc_geo = polyshape(xs,ys);
    % Create "Sand" Polyshape
    sand_geo = polyshape([ax.XLim(1) ax.XLim(1) ax.XLim(2) ax.XLim(2)],[toe-0.5 toe toe toe-0.5]);
    % Plot Structure
    plot(ax,struc_geo,'FaceColor',[0.65,0.65,0.65],'FaceAlpha',1);
    % Plot Sand
    plot(ax,sand_geo,'FaceColor',[0.9 0.72 0.31],'FaceAlpha',1);
    
    %% EXPORT FIGURE 
    saveas(fig, [project_name filesep structure_id filesep case_name filesep project_name '_' structure_id '_structure_cross_section.png']);
end