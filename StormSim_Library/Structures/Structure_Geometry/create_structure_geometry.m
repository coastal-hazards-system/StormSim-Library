function [structure] = create_structure_geometry(config, show_plot)
%{
    %% DESCRIPTION
        This function creates MATLAB struture object containing project structure geometry.
    
    %% INPUTS
        config: Parsed CAST input file. | struc | 1 x number_of_inputs
        Required fields are listed below:
            config.
                   crest_elevation: Structure crest elevation
                   crest_width: Strucutre crest width.
                   seaside slope: Structure seaward slope.
                   leeside slope: Strucutre landward slope.
                   toe_elevation: Structure toe elevation (Nevative below datum zero)
    
    %% OUTPUTS
        structure: Formatted structure geometry details | struc | 1 x varies_per_struc_type
            structure.
         ------- All Structure Types Fields -------
                   crest_elevation: Structure crest elevation
                   crest_width: Structure crest width.
                   toe_elevation: Structure toe elevation (Negative below datum zero)
                   sp_depth: CHS savepoint depth.
  
        ------- Rubblemound & Levee Only Fields -------
                   seaside_slope: Structure seaward slope.
                   leeside_slope: Structure landward slope.
    
            ------- Rubblemound Only Fields -------
                   armor_delta: Armor stone immersed relative density. (1-rho_s/rho_h20)
                   seaside_limit_S: Rubblemound structure seaward face damage limit (S).
                   cem_P: Mean permeability coefficient (From CEM).
    
              --- StormSim: MCS/CSR Only Fields ---
                   water_density: Water Density.
                   seaside_mass: Rubblemound structure seaward face stone mass.
                   seaside_init_S: Structure seaward face damage initiation limit (S).
                   leeside_mass: Rubblemound structure landward face stone mass.
                   leeside_init_S: Structure landward face damage initiation limit (S).
                   leeside_limit_S: Rubblemound structure landward face damage limit (S).
   
 %% DEV SIGNATURE
    Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}
%% GRAB INPUT FROM "config"
%{
        This section meant to provide an easy way to make changes to config
        variable calls without having to alter core code.
%}
% Structure Type
struc_type = config.struc_type;
% Workflow To Call
workflow = config.cast_workflow;
% Storm Sampling Scheme
storm_sampling = config.storm_sampling;
% Project Name
project_name = config.project_name;
% Transect Id
struc_id = config.struc_id;
% Define Case  Name 
case_name = config.case_name;
% Define Save Name
save_name = [project_name filesep struc_id filesep case_name filesep project_name...
    '_' struc_id '_' case_name '_config_file.mat'];

%% DEFINE VARIBALES TO GRAB FROM CONFIG PER STRUCTURE TYPE & WORKFLOW
% Evaluate Case Per Structure Type
switch struc_type
    case 1 % Levee
        % Define Structure Type String
        s_type = 'levee';
        % Define "config" Vars To Grab
        vars_2_grab = {'crest_elevation','crest_width','toe_elevation','seaside_slope',...
            'leeside_slope','structure_dir','berm_width','berm_elevation',...
            'water_density','roughness_ifactor'};
    case 2 % Floodwall
        % Define Structure Type String
        s_type = 'floodwall';
        % Define "config" Vars To Grab
        vars_2_grab = {'crest_elevation','crest_width','toe_elevation',....
            'structure_dir','berm_width','berm_elevation',...
            'water_density','roughness_ifactor'};
    case 3 % Rubblemound
        % Define Structure Type String
        s_type = 'rubblemound';
        % Define Workflow String
        w_type = 'StormSim: MCS/CSR';
        % Define Vars To Grab
        vars_2_grab = {'crest_elevation','crest_width','toe_elevation','seaside_slope',...
            'leeside_slope','structure_dir','berm_width','berm_elevation',...
            'armor_delta','seaside_mass','leeside_mass','water_density','cem_P',...
            'seaside_limit_S','leeside_limit_S','seaside_init_S','leeside_init_S',...
            'roughness_ifactor'};
end

%% EXTRACT AND FORMAT "config" DATA
% Display Status Message
disp(['Creating ',s_type,' geometry....']);
% Loop Through All Variables
for ii = 1:length(vars_2_grab)
    % Extract Data
    switch eval(['class(config.' vars_2_grab{ii} ')'])
        case 'double'
            eval(['structure.(''' vars_2_grab{ii} ''') = config.' vars_2_grab{ii} ';']); % Mean
%             eval(['structure.std.(''' vars_2_grab{ii} ''') = ''NA'';']); % Standard Deviation
        otherwise
            eval(['structure.(''' vars_2_grab{ii} ''') = config.' vars_2_grab{ii} '.mean;']); % Mean
            eval(['structure.std.(''' vars_2_grab{ii} ''') = config.' vars_2_grab{ii} '.std;']); % Standard Deviation
    end
end

%% CREATE CROSS_SECTION PLOT
% Create Figure
fig = plot_structure_geometry(config, structure);
% Show/Close Figure According To User
if show_plot == 1
    fig.Visible = true;
else
    close(fig);
end
%% APPEND TO .MAT File 
if exist(save_name,'file') == 2
    % Append To Existing .mat For Loading
    save(save_name,'structure','-append');
end
%% RESHAPE STRUCTURE TO MATCH FORCING FIELD
% Evaluate Case According To Workflow
% switch workflow
%     case 1 % Response Base Analysis (RB1) - PROS
%         % Define Structure Fields To Reshape
%         vars_2_reshape = fieldnames(structure);
%         % Remove Standard Deviation
%         vars_2_reshape = vars_2_reshape(~strcmp(vars_2_reshape,'std'));
%         % Need To Discuss With Jeff - Hardcoded For Now
%         %         vars_2_reshape = {'toe_elevation'};
%         % Reshape Variables
%         for kk = 1:length(vars_2_reshape)
%                 % Store Reshape Fields For RB 1 Analysis
%                 structure.Peaks.(vars_2_reshape{kk}) = structure.(vars_2_reshape{kk});%repmat(structure.(vars_2_reshape{kk}),xc_shape);
%         end
%     otherwise % Lice Cycle Base Analyssi (MCS/CSR)
%                 % Define Structural Parameters 
%         vars_2_reshape = [fieldnames(structure.std),struct2cell(structure.std)];
%         % Remove Parameters That Have No Uncertainty 
%         indx = ~contains(cellfun(@class,vars_2_reshape(:,2),'un',false),'char');
%         % Remove Parameter
%         vars_2_reshape = vars_2_reshape(indx,:);
%         % Reshape Variables
%         for lc = 1:length(project_forcing.(storm_sampling).Peaks.Maxima)
%             for kk = 1:length(vars_2_reshape)
%                 % Check For Timeseries
%                 if isfield(project_forcing.(storm_sampling),'Timeseries')
%                     % Store Reshaped Fields For Timeseries Analysis
%                     structure.(storm_sampling).Timeseries(lc).(vars_2_reshape{kk}) = repmat(structure.(vars_2_reshape{kk}),size(project_forcing.(storm_sampling).Timeseries(lc).LCNUM,1),1);
%                 end
%                 % Store Reshaped Fields For Peaks Analysis (Maxima, WLP & WHP have the same shape)
%                 structure.(storm_sampling).Peaks(lc).(vars_2_reshape{kk}) = repmat(structure.(vars_2_reshape{kk}),size(project_forcing.(storm_sampling).Peaks.Maxima(lc).LCNUM,1),1);
%             end
%         end
% end

end

