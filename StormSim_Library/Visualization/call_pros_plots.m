function call_pros_plots(config, structure, project_forcing, Resp)
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
%
data_type =  fieldnames(Resp);
% Define Plots Subfolders Out Path
subDir = fullfile(config.outfolder, project_name, struc_id, case_name, 'PROS');
% Define Workflow ID String
if workflow == 4
    % Define Workflow Name
    wName = 'FB';
else
    % Define Workflow Name
    wName = 'RB';
end
plot_prioty_comp = config.pros_plot_prioty_comp;
plot_hc_xsec = config.pros_plot_hc_xsec;
plot_forcing_hc_w_pot = config.pros_plot_forcing_hc_w_pot;
plot_hc = config.pros_plot_hc;
forcing_hc = config.pros_compute_forcing_HC;

%% CALL PLOT ROUTINES
for ii = 1:length(data_type)
    % Get Data Match Types
    match_type = fieldnames(Resp.(data_type{ii}));
    % Loop For Each Match Type
    for jj = 1:length(match_type)
        %
        storm_type = fieldnames(Resp.(data_type{ii}).(match_type{jj}));
        % Loop For Each Storm Type
        for kk = 1:length(storm_type)
            % Define Aux Variables
            switch data_type{ii}
                case 'Peaks'
                    fill_str = [wName '1_' match_type{jj}];
                    var_list = {Resp.(data_type{ii}).(match_type{jj}).(storm_type{kk}).var};
                case 'Timeseries'
                    fill_str = [wName '3'];
                    var_list = {Resp.(data_type{ii}).(match_type{jj}).(storm_type{kk}).var};
            end
            % Pass Flag For hazard Cross-section
            pass_flag = sum(cell2mat(cellfun(@(x) strcmp(var_list', x),{'SWL','Hm0','R2p'},'un',false)),1)'>=1;
            pass_flag = pass_flag(3) && sum(pass_flag(1:2)) >= 1;
            % ---------- Individual Responses Hazard Curves -----------
            if plot_hc == 1
                % Make Directory
                if ~exist(fullfile(subDir, fill_str),'dir')
                    mkdir(fullfile(subDir, fill_str));
                else % Directory Exist
                    % Delete Existing Files
                    delete([fullfile(subDir, fill_str) filesep '*' storm_type{kk} '*']);
                end
                % Make Plot
                plot_hazard_curves(Resp.(data_type{ii}).(match_type{jj}).(storm_type{kk}), use_aep);
            end
            % ---------- Hazard Cross-Section Plots -----------
            if plot_hc_xsec == 1 && pass_flag
                if ~exist(fullfile(subDir, [ fill_str '_Hazards_Cross-Sections']),'dir')
                    mkdir(fullfile(subDir, [ fill_str '_Hazards_Cross-Sections']));
                else % Directory Exist
                    % Delete Existing Files
                    delete([fullfile(subDir, [ fill_str '_Hazards_Cross-Sections']) filesep '*' storm_type{kk} '*']);
                end
                %
                plot_structure_and_forcing(config, Resp.(data_type{ii}).(match_type{jj}).(storm_type{kk}),...
                    structure, storm_type{kk}, fullfile(subDir, [ fill_str '_Hazards_Cross-Sections']));
            end
        end
        % ---------- Forcing Hazard Curves & POT's Screening Plots -----------
        if plot_forcing_hc_w_pot == 1  &&  forcing_hc == 1
            % Create Project Forcing + HC Comparison Figure
            peaks_hc_and_storms_stack_plot(config, Resp.(data_type{ii}).(match_type{jj}),...
                project_forcing.(data_type{ii}).(match_type{jj}),...
                match_type{jj}, fullfile(subDir, [ fill_str '_Project_Forcing_Comparison']));
        end
    end
end
% ---------- Peaks Priority Individual Responses Hazard Curves Comparison -----------
if plot_prioty_comp == 1 && contains(fieldnames(Resp), 'Peaks') && length(fieldnames(Resp.Peaks)) > 1
    %
    storm_type = fieldnames(Resp.Peaks.Default);
    % Loop For Each Storm Type
    for kk = 1:length(storm_type)
        % Make Directory
        if ~exist(fullfile(subDir, [ wName '1_Comparison']),'dir')
            mkdir(fullfile(subDir, [ wName '1_Comparison']));
        else % Directory Exist
            % Delete Existing Files
            delete([fullfile(subDir, [ wName '1_Comparison']) filesep '*' storm_type{kk} '*']);
        end
        % Create Comparison Figure
        peaks_hc_stack_plot(Resp.Peaks, storm_type{kk}, use_aep, 'h', fullfile(subDir, [ wName '1_Comparison']));
    end
end
end
