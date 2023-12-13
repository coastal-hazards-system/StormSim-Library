function call_pros_plots(config, structure, project_forcing, prob_mass, Resp)
%% GRAB INPUTS
% Define Workflow
workflow = config.workflow;
% Project Name
project_name = config.project_name;
% Transect Id
struc_id = config.struc_id;
% Define Case  Name
case_name = config.case_name;
% Define Frequnecy Type
use_aep = config.pros_use_aep;
% Determine Storm Types Available
level_1 = fieldnames(Resp);
% Determine Datasets To Process
level_2 = fieldnames(Resp.(level_1{1}));
level_2 = level_2(contains(level_2,{'Peaks','Timeseries'}));
% Look For Additional Level If Peaks Exist
if any(contains(level_2, 'Peaks'))
    level_3 = fieldnames(Resp.(level_1{1}).('Peaks'));
else
    level_3 = [];
end
% Define Plots Subfolders Out Path
subDir = fullfile(config.outfolder, project_name, struc_id, case_name);
% Define Workflow ID String
if workflow == 4
    % Define Workflow Name
    wName = 'PROS-FB';
    subDir = fullfile(subDir, 'PROS-FB');
else
    % Define Workflow Name
    wName = 'PROS';
    subDir = fullfile(subDir, 'PROS');
end
plot_prioty_comp = config.pros_plot_prioty_comp;
plot_hc_xsec = config.pros_plot_hc_xsec;
plot_forcing_hc_w_pot = config.pros_plot_forcing_hc_w_pot;
plot_hc = config.pros_plot_hc;

%% CALL PLOT ROUTINES
for ii = 1:length(level_1) % For Each Storm Type
    for jj = 1:length(level_2) % For Each Dataset
        % Define Next Loop
        if isempty(level_3) || strcmp(level_2{jj},'Timeseries')
            l_end = 1;
        else
            l_end = length(level_3);
        end
        %
        for kk = 1:l_end
            % Define Aux Variables
            switch level_2{jj}
                case 'Peaks'
                    fill_str = ['_RB1_' level_3{kk}];
                    fill_str2 = '_RB1';
                    ts_switch = 0;
                    var_list = {Resp.(level_1{ii}).('Peaks').(level_3{kk}).var};
                case 'Timeseries'
                    fill_str = '_RB3';
                    fill_str2 = '_RB3';
                    ts_switch = 1;
                    var_list = {Resp.(level_1{ii}).('Timeseries').var};
            end
            % Pass Flag For hazard Cross-section
            pass_flag = sum(cell2mat(cellfun(@(x) strcmp(var_list', x),{'SWL','Hm0','R2p'},'un',false)),1)'>=1;
            pass_flag = pass_flag(3) && sum(pass_flag(1:2)) >= 1;
            % ---------- Individual Responses Hazard Curves -----------
            if plot_hc == 1
                % Make Directory
                if ~exist(fullfile(subDir, [ wName fill_str ]),'dir')
                    mkdir(fullfile(subDir, [ wName fill_str ]));
                else % Directory Exist
                    % Delete Existing Files
                    delete([fullfile(subDir, [ wName fill_str ]) filesep '*' level_1{ii} '*']);
                end
                % Extract HC Data From Resp
                switch level_2{jj}
                    case 'Peaks'
                        aux_var = Resp.(level_1{ii}).('Peaks').(level_3{kk});
                    case 'Timeseries'
                        aux_var = Resp.(level_1{ii}).('Timeseries');
                end
                % Make Plot
                plot_hazard_curves(aux_var, use_aep);
            end
            % ---------- Forcing Hazard Curves & POT's Screening Plots -----------
            if plot_forcing_hc_w_pot == 1
                % Create Project Forcing + HC Comparison Figure
                peaks_hc_and_storms_stack_plot(config, Resp, project_forcing, prob_mass, ts_switch, fullfile(subDir, [ wName fill_str2 '_Project_Forcing_Comparison']));
            end
            % ---------- Hazard Cross-Section Plots -----------
            if plot_hc_xsec == 1 && pass_flag
                % Extract HC Data From Resp
                switch level_2{jj}
                    case 'Peaks'
                        aux_var = Resp.(level_1{ii}).('Peaks').(level_3{kk});
                    case 'Timeseries'
                        aux_var = Resp.(level_1{ii}).('Timeseries');
                end
                %
                if ~exist(fullfile(subDir, [ wName fill_str '_Hazards_Cross-Sections']),'dir')
                    mkdir(fullfile(subDir, [ wName fill_str '_Hazards_Cross-Sections']));
                else % Directory Exist
                    % Delete Existing Files
                    delete([fullfile(subDir, [ wName fill_str '_Hazards_Cross-Sections']) filesep '*' level_1{ii} '*']);
                end
                %
                plot_structure_and_forcing(config, aux_var,...
                    structure, level_1{ii}, [subDir wName fill_str '_Hazards_Cross-Sections']);
            end
        end
        % ---------- Peaks Priority Individual Responses Hazard Curves Comparison -----------
        if plot_prioty_comp == 1 && contains(level_2{jj},'Peaks') && length(level_3) > 1
            % Make Directory
            if ~exist(fullfile(subDir, [ wName '_RB1_Comparison']),'dir')
                mkdir(fullfile(subDir, [ wName '_RB1_Comparison']));
            else % Directory Exist
                % Delete Existing Files
                delete([fullfile(subDir, [ wName '_RB1_Comparison']) filesep '*' level_1{ii} '*']);
            end
            % Create Comparison Figure
            peaks_hc_stack_plot(Resp, level_1{ii}, use_aep, 'h', fullfile(subDir, [ wName '_RB1_Comparison']));
        end
    end
end
end
